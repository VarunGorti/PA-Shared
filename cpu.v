`timescale 1ps/1ps

module main();

initial begin
	$dumpfile("cpu.vcd");
	$dumpvars(0,main);
end

// clock
wire clk;
clock c0(clk);

reg halt = 0;

counter ctr(halt,clk);

// PC
reg [15:0]pc = 16'h0000;

wire[15:1] raddr0;
wire[15:0] rdata0;
wire[15:1] raddr1;
wire[15:0] rdata1;
wire wen;
wire[15:1] waddr;
wire[15:0] wdata;

// read from memory
mem mem(clk,
	pc[15:1], rdata0,
	raddr1, rdata1,
	wen, waddr, wdata); 

wire[3:0] regs_addr0;
wire[15:0] regs_data0;
wire[3:0] regs_addr1;
wire[15:0] regs_data1;
wire regs_wen;
wire[3:0] regs_waddr;
wire[15:0] regs_wdata;

regs regs(clk,
	regs_addr0, regs_data0,
	regs_addr1, regs_data1,
	regs_wen, regs_waddr, regs_wdata);

// ================================= FETCH 0 ================================

reg[15:0] pc_fetch0;
always @(posedge clk) begin
	pc_fetch0 <= loadStall === 1 ? pc_fetch0 : pc;
end

// ================================= FETCH 1 ================================

reg[15:0] pc_fetch1;
reg[1:0] jumpCounter = 0;
reg[1:0] loadStallCounter = 0;

always @(posedge clk) begin
	if(shouldContinue) begin
		pc_fetch1 <= loadStall === 1 ? pc_fetch1 : pc_fetch0;
	end
	if(isFlushing === 1)
		jumpCounter <= 2;
	else begin
		if(jumpCounter != 0)
			jumpCounter <= jumpCounter - 1;
	end
	if(loadStall === 1)
		loadStallCounter <= 2;
	else begin
		if(loadStallCounter != 0)
			loadStallCounter <= loadStallCounter - 1;
	end
end

wire[15:0] instruction;
assign instruction = ((isFlushing === 1) | (jumpCounter != 0)) ? 16'he010 : 
	((loadStall === 1) | (loadStallCounter != 0)) ? instruction : 
	rdata0;

wire[3:0] opcode = instruction[15:12];
wire[3:0] xop_f1 = instruction[7:4];

wire[3:0] rt = instruction[3:0];
wire[3:0] ra = instruction[11:8];
wire[3:0] rb = instruction[7:4];

wire loadStall = (opcode == 15) & (xop_f1 == 0) & (loadStallCounter == 0);

wire isSub = opcode == 0;
assign regs_addr0 = ra;
assign regs_addr1 = isSub ? rb : rt;

// ======================================== DECODE 1 ==========================

reg[3:0] regs_addr0_decode1;
reg[3:0] regs_addr1_decode1;
reg[15:0] pc_decode1;
reg[15:0] instruction_decode1;

always @(posedge clk) begin
	if(shouldContinue) begin
		regs_addr0_decode1 <= regs_addr0 ;
		regs_addr1_decode1 <= regs_addr1;

		pc_decode1 <= pc_fetch1;
		instruction_decode1 <= isFlushing === 1 | loadStall === 1 ? 16'he010 : instruction;
	end
end

assign raddr1 = instruction[11:8] == 0 ? 0 :
	(regs_addr0 == ra_d2) & regs_wen_d2 ? reg_out_d2[15:1] :
	(regs_addr0 == regs_waddr) & regs_wen ? reg_out[15:1] :
	regs_data0[15:1];

// ========================================= DECODE 2 ======================

reg[3:0] regs_addr0_decode2;
reg[3:0] regs_addr1_decode2;
reg[15:0] regs_data0_decode2;
reg[15:0] regs_data1_decode2;
reg[15:0] pc_decode2;
reg[15:0] instruction_decode2;

wire[3:0] opcode_d2 = instruction_decode1[15:12];

wire[7:0] imm_d2 = instruction_decode1[11:4];
wire[3:0] xop_d2 = instruction_decode1[7:4];
wire[3:0] ra_d2 = instruction_decode1[11:8];
wire[3:0] rb_d2 = instruction_decode1[7:4];
wire[3:0] target_d2 = instruction_decode1[3:0];

wire isSub_d2 = (opcode_d2 == 0);
wire isMovl_d2 = (opcode_d2 == 8);
wire isMovh_d2 = (opcode_d2 == 9);

// Note that this does not include LOAD, because if it is a load we can't
// really forward from this stage in the first place
wire updateRegs_d2 = isSub_d2 | isMovl_d2 | isMovh_d2;
wire regs_wen_d2 = updateRegs_d2 & (target_d2 != 0); 

wire[15:0] va_d2 = ra_d2 == 0 ? 0 : regs_data0;
wire[15:0] vb_d2 = rb_d2 == 0 ? 0 : regs_data1;
wire[15:0] vt_d2 = target_d2 == 0 ? 0 : regs_data1;

wire[16:0] reg_out_d2 = isSub_d2 ? va_d2 - vb_d2 :
	isMovl ? { {8{imm_d2[7]}}, imm_d2} :
	isMovh ? ((vt_d2 & 16'hff) | { imm_d2, 8'h0 }) :
	0;

always @(posedge clk) begin
	if(shouldContinue) begin
		regs_addr0_decode2 <= isFlushing === 1 ? 0 : regs_addr0_decode1;
		regs_addr1_decode2 <= isFlushing === 1 ? 0 : regs_addr1_decode1;

		regs_data0_decode2 <= regs_addr0_decode1 == 0 ? 16'b0 :
			(regs_addr0_decode1 == regs_waddr) & regs_wen ? reg_out :
			regs_data0;  

		regs_data1_decode2 <= regs_addr1_decode1 === 0 ? 16'b0 :
			(regs_addr1_decode1 === regs_waddr) & regs_wen ? reg_out :
			regs_data1;  
		pc_decode2 <= pc_decode1;
		instruction_decode2 <= isFlushing === 1 ? 16'he010 : instruction_decode1;
	end
end

// ========================= WRITE BACK ====================================

wire[3:0] opcode_wb = instruction_decode2[15:12];
wire[7:0] imm = instruction_decode2[11:4];
wire[3:0] xop = instruction_decode2[7:4];

wire[3:0] ra_wb = instruction_decode2[11:8];
wire[3:0] rb_wb = instruction_decode2[7:4];
wire[3:0] target = instruction_decode2[3:0];

wire isSub_wb = (opcode_wb == 0);
wire isMovl = (opcode_wb == 8);
wire isMovh = (opcode_wb == 9);
wire isLd = (opcode_wb == 15) & (xop == 0);
wire isSt = (opcode_wb == 15) & (xop == 1);

wire isJz = (opcode_wb == 14) & (xop == 0);
wire isJnz = (opcode_wb == 14) & (xop == 1);
wire isJs = (opcode_wb == 14) & (xop == 2);
wire isJns = (opcode_wb == 14) & (xop == 3);

wire[15:0] va_wb = ra_wb == 0 ? 0 : regs_data0_decode2;
wire[15:0] vb_wb = rb_wb == 0 ? 0 : regs_data1_decode2;
wire[15:0] vt_wb = target == 0 ? 0 : regs_data1_decode2;

wire isJumping = (isJz & (va_wb == 0)) |
	(isJnz & (va_wb != 0)) |
	(isJs & (va_wb[15] == 1)) |
	(isJns & (va_wb[15] == 0));

wire isFlushing = isJumping | isLd | isSt;

wire isValidIns = isSub_wb | isMovl | isMovh | isJz | isJnz | isJs | isJns | isLd | isSt;
wire shouldContinue = isValidIns === 1'b1 | isValidIns === 1'bx;
wire updateRegs = isSub_wb | isMovl | isMovh | isLd;

wire[16:0] reg_out = isSub_wb ? va_wb - vb_wb :
	isMovl ? { {8{imm[7]}}, imm} :
	isMovh ? ((vt_wb & 16'hff) | { imm, 8'h0 }) :
	isLd ? rdata1 :
	0;

assign regs_wdata = reg_out;
assign regs_waddr = target;
assign regs_wen = updateRegs & (target != 0); 

assign wen = isSt;	
assign waddr = va_wb[15:1];
assign wdata = vt_wb;

always @(posedge clk) begin
	if(shouldContinue) begin     
		pc <= (isJumping === 1) ? vt_wb :
			(isLd === 1 | isSt === 1) ? pc_decode2 + 2 :
			(loadStall === 1) ? pc - 2 :
			pc + 2;
		if (updateRegs & (target == 0))
			$write("%c", regs_wdata[7:0]);
	end else begin
		halt <= 1;
	end
end

endmodule
