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
reg valid_fetch0;
always @(posedge clk) begin
	pc_fetch0 <= pc;
	valid_fetch0 <= isFlushing === 1 ? 0 : 1;
end

// ================================= FETCH 1 ================================

reg[15:0] pc_fetch1;
reg[1:0] jumpCounter = 0;
reg[1:0] loadStallCounter = 0;
reg valid_fetch1;

always @(posedge clk) begin
	if(shouldContinue) begin
		pc_fetch1 <= pc_fetch0;
		valid_fetch1 <= isFlushing === 1 ? 0 : valid_fetch0;
	end
end

wire[15:0] instruction = rdata0;

wire[3:0] opcode = instruction[15:12];
wire[3:0] xop_f1 = instruction[7:4];

wire[3:0] rt = instruction[3:0];
wire[3:0] ra = instruction[11:8];
wire[3:0] rb = instruction[7:4];

wire isSub = opcode == 0;
assign regs_addr0 = ra;
assign regs_addr1 = isSub ? rb : rt;

// ======================================== EXECUTE 0 ==========================

reg[3:0] regs_addr0_execute0;
reg[3:0] regs_addr1_execute0;
reg[15:0] pc_execute0;
reg[15:0] instruction_execute0;
reg valid_execute0;

always @(posedge clk) begin
	if(shouldContinue) begin
		regs_addr0_execute0 <= regs_addr0 ;
		regs_addr1_execute0 <= regs_addr1;

		pc_execute0 <= pc_fetch1;
		instruction_execute0 <= instruction;

		valid_execute0 <= isFlushing === 1 ? 0 : valid_fetch1;
	end
end

assign raddr1 = instruction[11:8] == 0 ? 0 :
//	(regs_addr0 == ra_d2) & regs_wen_d2 ? reg_out_d2[15:1] :
	(regs_addr0 == regs_waddr) & regs_wen ? reg_out[15:1] :
	regs_data0[15:1];

// ========================================= EXECUTE 1 ======================

reg[3:0] regs_addr0_execute1;
reg[3:0] regs_addr1_execute1;
reg[15:0] regs_data0_execute1;
reg[15:0] regs_data1_execute1;
reg[15:0] pc_execute1;
reg[15:0] instruction_execute1;
reg valid_execute1;

/*
wire[3:0] opcode_d2 = instruction_execute0[15:12];
wire[7:0] imm_d2 = instruction_execute0[11:4];
wire[3:0] xop_d2 = instruction_execute0[7:4];
wire[3:0] ra_d2 = instruction_execute0[11:8];
wire[3:0] rb_d2 = instruction_execute0[7:4];
wire[3:0] target_d2 = instruction_execute0[3:0];

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
*/
always @(posedge clk) begin
	if(shouldContinue) begin
		regs_addr0_execute1 <= regs_addr0_execute0;
		regs_addr1_execute1 <= regs_addr1_execute0;

		regs_data0_execute1 <= regs_addr0_execute0 == 0 ? 16'b0 :
			(regs_addr0_execute0 == regs_waddr) & regs_wen ? reg_out :
			regs_data0;  

		regs_data1_execute1 <= regs_addr1_execute0 === 0 ? 16'b0 :
			(regs_addr1_execute0 === regs_waddr) & regs_wen ? reg_out :
			regs_data1;  
		pc_execute1 <= pc_execute0;
		instruction_execute1 <= instruction_execute0;

		valid_execute1 <= isFlushing === 1 ? 0 : valid_execute0;
	end
end

// ========================================= EXECUTE 2 ======================

reg[3:0] regs_addr0_execute2;
reg[3:0] regs_addr1_execute2;
reg[15:0] regs_data0_execute2;
reg[15:0] regs_data1_execute2;
reg[15:0] pc_execute2;
reg[15:0] instruction_execute2;
reg valid_execute2;

/*
wire[3:0] opcode_e2 = instruction_execute1[15:12];
wire[7:0] imm_e2 = instruction_execute1[11:4];
wire[3:0] xop_e2 = instruction_execute1[7:4];
wire[3:0] ra_e2 = instruction_execute1[11:8];
wire[3:0] rb_e2 = instruction_execute1[7:4];
wire[3:0] target_e2 = instruction_execute1[3:0];

wire isSub_e2 = (opcode_e2 == 0);
wire isMovl_e2 = (opcode_e2 == 8);
wire isMovh_e2 = (opcode_e2 == 9);
wire isLd_e2 = (opcode_e2 == 15) & (xop_e2 == 0);

// Note that this does not include LOAD, because if it is a load we can't
// really forward from this stage in the first place
wire updateRegs_e2 = isSub_e2 | isMovl_e2 | isMovh_e2;
wire regs_wen_e2 = updateRegs_e2 & (target_e2 != 0); 

wire[15:0] va_e2 = ra_e2 == 0 ? 0 : regs_data0;
wire[15:0] vb_e2 = rb_e2 == 0 ? 0 : regs_data1;
wire[15:0] vt_e2 = target_e2 == 0 ? 0 : regs_data1;

wire[16:0] reg_out_e2 = isSub_e2 ? va_e2 - vb_e2 :
	isMovl ? { {8{imm_e2[7]}}, imm_e2} :
	isMovh ? ((vt_e2 & 16'hff) | { imm_e2, 8'h0 }) :
	0;
*/
always @(posedge clk) begin
	if(shouldContinue) begin
		regs_addr0_execute2 <= regs_addr0_execute1;
		regs_addr1_execute2 <= regs_addr1_execute1;

		regs_data0_execute2 <= regs_addr0_execute1 == 0 ? 16'b0 :
			(regs_addr0_execute1 == regs_waddr) & regs_wen ? reg_out :
			regs_data0_execute1;  
		regs_data1_execute2 <= regs_addr1_execute1 === 0 ? 16'b0 :
			(regs_addr1_execute1 === regs_waddr) & regs_wen ? reg_out :
			regs_data1_execute1;

		pc_execute2 <= pc_execute1;
		instruction_execute2 <= instruction_execute1;

		valid_execute2 <= isFlushing === 1 ? 0 : valid_execute1;

	end
end

// ========================= WRITE BACK ====================================

wire[3:0] opcode_wb = instruction_execute2[15:12];
wire[7:0] imm = instruction_execute2[11:4];
wire[3:0] xop = instruction_execute2[7:4];

wire[3:0] ra_wb = instruction_execute2[11:8];
wire[3:0] rb_wb = instruction_execute2[7:4];
wire[3:0] target = instruction_execute2[3:0];

wire isSub_wb = (opcode_wb == 0);
wire isMovl = (opcode_wb == 8);
wire isMovh = (opcode_wb == 9);
wire isLd = (opcode_wb == 15) & (xop == 0);
wire isSt = (opcode_wb == 15) & (xop == 1);

wire isJz = (opcode_wb == 14) & (xop == 0);
wire isJnz = (opcode_wb == 14) & (xop == 1);
wire isJs = (opcode_wb == 14) & (xop == 2);
wire isJns = (opcode_wb == 14) & (xop == 3);

wire[15:0] va_wb = ra_wb == 0 ? 0 : regs_data0_execute2;
wire[15:0] vb_wb = rb_wb == 0 ? 0 : regs_data1_execute2;
wire[15:0] vt_wb = target == 0 ? 0 : regs_data1_execute2;

wire isJumping = (isJz & (va_wb == 0)) |
	(isJnz & (va_wb != 0)) |
	(isJs & (va_wb[15] == 1)) |
	(isJns & (va_wb[15] == 0));

wire isFlushing = (isJumping | isLd | isSt) & valid_execute2;

wire isValidIns = isSub_wb | isMovl | isMovh | isJz | isJnz | isJs | isJns | isLd | isSt | (valid_execute2 === 0);
wire shouldContinue = isValidIns === 1'b1 | isValidIns === 1'bx;
wire updateRegs = isSub_wb | isMovl | isMovh | isLd;

wire[16:0] reg_out = isSub_wb ? va_wb - vb_wb :
	isMovl ? { {8{imm[7]}}, imm} :
	isMovh ? ((vt_wb & 16'hff) | { imm, 8'h0 }) :
	isLd ? rdata1 :
	0;

assign regs_wdata = reg_out;
assign regs_waddr = target;
assign regs_wen = updateRegs & (target != 0) & (valid_execute2 === 1); 

assign wen = isSt & (valid_execute2 === 1);	
assign waddr = va_wb[15:1];
assign wdata = vt_wb;

wire printing = updateRegs & (target == 0) & (valid_execute2 === 1);

wire debugging = 0;

always @(posedge clk) begin
	if(shouldContinue) begin     
		pc <= (isJumping === 1 & valid_execute2 === 1) ? vt_wb :
			((isLd === 1 | isSt === 1) & (valid_execute2 === 1)) ? pc_execute2 + 2 :
			pc + 2;
		if (updateRegs & (target == 0) & (valid_execute2 === 1))
			$write("%c", regs_wdata[7:0]);
	end else begin
		halt <= 1;
	end

	if(debugging) begin
		$write("**********************pc = %x\n", pc);
		$write("                 Fetch 1 = %x  %b\n", pc_fetch0, valid_fetch0);
		$write("               Execute 0 = %x  %b  %x\n", pc_fetch1, valid_fetch1, instruction);
		$write("               Execute 1 = %x  %b  %x\n", pc_execute0, valid_execute0, instruction_execute0);
		$write("               Execute 2 = %x  %b  %x\n", pc_execute1, valid_execute1, instruction_execute1);
		$write("              Write Back = %x  %b  %x\n", pc_execute2, valid_execute2, instruction_execute2);
		//$write("waddr = %x\n", waddr);
		//$write("wdata = %x\n", wdata);
		//$write("wen = %b\n", wen);
		$write("regs_waddr = %x\n", regs_waddr);
		$write("regs_wdata = %x\n", regs_wdata);
		$write("regs_wen = %b\n", regs_wen);
		//$write("printing = %b\n", printing);
		$write("isLd = %b\n", isLd);
		$write("rdata1 = %x\n", rdata1);
		
		$write("raddr1 = %x\n", raddr1);
		$write("instruction = %x\n", instruction);
		$write("regs_data0 = %x\n", regs_data0);

		$write("isJumping = %b\n", isJumping);
		$write("va_wb = %x\n", va_wb);
		$write("vb_wb = %x\n", vb_wb);
		$write("vt_wb = %x\n", vt_wb);
		$write("\n");
	end
end

endmodule
