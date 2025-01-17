`timescale 1ps/1ps
module core(input[1:0] coreNum, input clk, output halt_, input[16:0] pc_passed, input[2:0] stall_num,
	output[15:0] pc_, input[15:0] rdata0_,
	output[16:1] raddr1_, input[17:0] rdata1_,
	output wen_, output[15:1] waddr_, output[15:0] wdata_,
	output[3:0] pauseResume, output[18:0] pc_out, output awake);

// PC
reg[15:0] pc;
assign pc_ = pc;

// Indicator for whether or not this core is awake and running code.
// Once a core has been awoken, it cannot go back to sleep, although it can
// be paused indefinitely or asked to awaken to a different pc
reg isAwake = 0;
assign awake = isAwake | pc_passed[16] === 1;

reg halt = 0;
assign halt_ = halt;

// Read and write ports for memory, not unique to this core
assign raddr1_ = raddr1;
assign wen_ = wen; 
assign waddr_ = waddr;
assign wdata_ = wdata;

wire[15:1] raddr0;
wire[15:0] rdata0 = rdata0_;
wire[16:1] raddr1;
wire[17:0] rdata1 = rdata1_;
wire wen;
wire[15:1] waddr;
wire[15:0] wdata;

// Read and write ports for register file, unique to this core
wire[3:0] regs_addr0;
wire[15:0] regs_data0;
wire[3:0] regs_addr1;
wire[15:0] regs_data1;
wire regs_wen;
wire[3:0] regs_waddr;
wire[15:0] regs_wdata;

// DO actually want 17 bits here, one is the valid bit
reg[16:0] predictor_table[1023:0];

regs regs(clk,
	regs_addr0, regs_data0,
	regs_addr1, regs_data1,
	regs_wen, regs_waddr, regs_wdata);

// ================================= FETCH 0 ================================

reg[15:0] pc_fetch0;
reg valid_fetch0;
wire[15:0] predicted = predictor_table[pc[10:1]][16] === 1 ? predictor_table[pc[10:1]][15:0] : pc + 2;

wire stall1 = 0;

always @(posedge clk) begin
	pc_fetch0 <= (shouldStall >= 1) === 1 ? pc_fetch0 : pc;
	valid_fetch0 <= isFlushing === 1 | shouldStall === 1 ? 0 :
		shouldStall >= 1 ? valid_fetch0 :
		1;
end

// ================================= FETCH 1 ================================

reg[15:0] pc_fetch1;
reg valid_fetch1;
reg[16:0] instruction_copy;

wire stall2 = 0;

always @(posedge clk) begin
	if(shouldContinue) begin
		pc_fetch1 <= (shouldStall >= 2) === 1 ? pc_fetch1 : pc_fetch0;
		valid_fetch1 <= (isFlushing === 1 | shouldStall === 2) ? 0 :
			shouldStall >= 2 ? valid_fetch1: 
			valid_fetch0;

		buffer_f1 <= instruction_copy[16] === 1 ? buffer_f1[16] === 1 ? buffer_f1 : {1'b1, rdata0} : 17'b0;
		instruction_copy[15:0] <= instruction;
		instruction_copy[16] <= (shouldStall >= 2) === 1;
	end
end

// Create a buffer and a copy of this instruction so that when we have to
// stall we don't lose the instruction coming out of memory, if we realize the
// buffer is full then read from it after the stall is complete
reg[16:0] buffer_f1;
wire[15:0] instruction = instruction_copy[16] === 1 ? instruction_copy[15:0] : 
	buffer_f1[16] === 1 ? buffer_f1[15:0] : 
	rdata0;

wire[3:0] opcode = instruction[15:12];
wire[3:0] xop = instruction[7:4];

wire[3:0] rt = instruction[3:0];
wire[3:0] ra = instruction[11:8];
wire[3:0] rb = instruction[7:4];

wire isSub_f1 = opcode == 0;
wire isAdd_f1 = opcode == 1;
wire isCmp_f1 = opcode == 5;

wire isLd_f1 = opcode == 15 & xop == 0;
wire isSt_f1 = opcode == 15 & xop == 1;

assign regs_addr0 = ra;
assign regs_addr1 = (isSub_f1 | isAdd_f1 | isCmp_f1) ? rb : rt;

// ======================================== EXECUTE 0 ==========================

reg[3:0] regs_addr0_execute0;
reg[3:0] regs_addr1_execute0;
reg[15:0] pc_execute0;
reg[15:0] instruction_execute0;
reg valid_execute0;

wire[3:0] opcode_e0 = instruction_execute0[15:12];
wire[3:0] xop_e0 = instruction_execute0[7:4];

wire[3:0] rt_e0 = instruction_execute0[3:0];
wire[3:0] ra_e0 = instruction_execute0[11:8];
wire[3:0] rb_e0 = instruction_execute0[7:4];

wire isSub_e0 = opcode_e0 == 0;
wire isAdd_e0 = opcode_e0 == 1;
wire isCmp_e0 = opcode_e0 == 5;

wire isLd_e0 = opcode_e0 == 15 & xop_e0 == 0 & valid_execute0 === 1;
wire isSt_e0 = opcode_e0 == 15 & xop_e0 == 1; 

// Code checking if the instructions ahead are loads or stores that would
// create data hazards with this instruction, if so stalls this instruction so
// that it does not move onwards
wire st_stall = isLd_f1 & ((isSt_e0 === 1 & valid_execute0) | (isSt_e1 === 1 & valid_execute1));
wire ld_stall = isLd_f1 & ((isLd_e0 === 1 & ra === rt_e0 & valid_execute0) | (isLd_e1 === 1 & ra === rt_e1 & valid_execute1));

wire stall3 = (st_stall | ld_stall) & valid_fetch1;

wire[2:0] internalStall = stall6 === 1 ? 6 :
	stall5 === 1 ? 5 :
	stall4 === 1 ? 4 :
	stall3 === 1 ? 3 :
	stall2 === 1 ? 2 :
	stall1 === 1 ? 1 :
	0;

reg[16:0] regs0_e0_buffer = 0;
reg[16:0] regs1_e0_buffer = 0;
// Combination of the interal and external stall signals, to take care of data
// hazards within this core and resource hazards detected by the CPU
wire[2:0] shouldStall =  stall_num > internalStall ? stall_num : internalStall;
always @(posedge clk) begin
	if(shouldContinue) begin
		regs_addr0_execute0 <= (shouldStall >= 3) === 1 ? regs_addr0_execute0 : regs_addr0;
		regs_addr1_execute0 <= (shouldStall >= 3) === 1 ? regs_addr1_execute0 : regs_addr1;

		pc_execute0 <= (shouldStall >= 3) === 1 ? pc_execute0 : pc_fetch1;
		instruction_execute0 <= (shouldStall >= 3) === 1 ? instruction_execute0 : instruction;

		valid_execute0 <= (isFlushing === 1 | shouldStall === 3) ? 0 :
			shouldStall >= 3 ? valid_execute0 : 
			valid_fetch1;

		regs0_e0_buffer <= (shouldStall >= 3) === 1 && regs0_e0_buffer[16] === 1 ? {1'b1,regs0_e0_buffer[15:0]} : (shouldStall >= 3) === 1 ? {1'b1, regs_data0} :  {1'b0,regs_data0};
		regs1_e0_buffer <= (shouldStall >= 3) === 1 && regs1_e0_buffer[16] === 1 ? {1'b1,regs1_e0_buffer[15:0]} : (shouldStall >= 3) === 1 ? {1'b1, regs_data1} :  {1'b0,regs_data1};
	end
end

// Sets the read port memory address, based on either the forwarded addresses
// from future stages or the register data we just read from (as normal for
// a load)
assign raddr1[15:1] = instruction_execute0[11:8] == 0 ? 0 :
	forward_e2 ? reg_out_e2[15:1] :
	forward_wb ? reg_out[15:1] :
	regs_data0[15:1];
assign raddr1[16] = isLd_e0;

// Helper wires to indicate if data was forwarded
wire forward_e2 = regs_addr0_execute0 === rt_e2 & regs_wen_e2 === 1; 
wire forward_wb = regs_addr0_execute0 === rt_wb & regs_wen === 1; 

// ========================================= EXECUTE 1 ======================

reg[3:0] regs_addr0_execute1;
reg[3:0] regs_addr1_execute1;
reg[15:0] regs_data0_execute1;
reg[15:0] regs_data1_execute1;
reg[15:0] pc_execute1;
reg[15:0] instruction_execute1;
reg valid_execute1;
reg[16:1] raddr1_execute1;

wire[3:0] opcode_e1 = instruction_execute0[15:12];
wire[3:0] xop_e1 = instruction_execute0[7:4];
wire[3:0] rt_e1 = instruction_execute0[3:0];

wire isLd_e1 = opcode_e1 == 15 & xop_e1 == 0;
wire isSt_e1 = opcode_e1 == 15 & xop_e1 == 1;

wire stall4 = 0;

always @(posedge clk) begin
	if(shouldContinue) begin
		regs_addr0_execute1 <= (shouldStall >= 4) === 1 ? regs_addr0_execute1 : regs_addr0_execute0;
		regs_addr1_execute1 <= (shouldStall >= 4) === 1 ? regs_addr1_execute1 : regs_addr1_execute0;

		regs_data0_execute1 <= (shouldStall >= 4) === 1 ? regs_data0_execute1 :
			regs_addr0_execute0 == 0 ? 16'b0 :
			regs_addr0_execute0 == regs_waddr & regs_wen ? reg_out :
			regs0_e0_buffer[16] === 1 ? regs0_e0_buffer[15:0] : regs_data0[15:0];  

		regs_data1_execute1 <= (shouldStall >= 4) === 1 ? regs_data1_execute1 :
			regs_addr1_execute0 === 0 ? 16'b0 :
			regs_addr1_execute0 === regs_waddr & regs_wen ? reg_out :
			regs1_e0_buffer[16] === 1 ? regs1_e0_buffer[15:0] : regs_data1[15:0];  

		pc_execute1 <= (shouldStall >= 4) === 1 ? pc_execute1 : pc_execute0;
		instruction_execute1 <= (shouldStall >= 4) === 1 ? instruction_execute1 : instruction_execute0;

		raddr1_execute1 <= (shouldStall >= 4) === 1 ? raddr1_execute1 : raddr1;
		valid_execute1 <= (isFlushing === 1 | shouldStall === 4) ? 0 :
			shouldStall >= 4 ? valid_execute1 : 
			valid_execute0;
	end
end

// ========================================= EXECUTE 2 ======================

reg[3:0] regs_addr0_execute2;
reg[3:0] regs_addr1_execute2;
reg[15:0] regs_data0_execute2;
reg[15:0] regs_data1_execute2;
reg[15:0] pc_execute2;
reg[15:0] instruction_execute2;
reg[15:0] predicted_pc_execute2;
reg valid_execute2;
reg[16:1] raddr1_execute2;

wire[3:0] opcode_e2 = instruction_execute1[15:12];
wire[7:0] imm_e2 = instruction_execute1[11:4];
wire[3:0] xop_e2 = instruction_execute1[7:4];
wire[3:0] ra_e2 = instruction_execute1[11:8];
wire[3:0] rb_e2 = instruction_execute1[7:4];
wire[3:0] rt_e2 = instruction_execute1[3:0];

// Here we want to calculate the output value, or at least what it would be if
// this instruction is not a load. This is to ensure that this value can be
// forwarded back so that our load instruction farther back in the pipeline
// does not run into data hazards and can read from the correct memory address
wire isSub_e2 = (opcode_e2 == 0);
wire isAdd_e2 = (opcode_e2 == 1);
wire isInc_e2 = (opcode_e2 == 2);
wire isDec_e2 = (opcode_e2 == 3);
wire isCmp_e2 = (opcode_e2 == 5);
wire isMovl_e2 = (opcode_e2 == 8);
wire isMovh_e2 = (opcode_e2 == 9);
wire isLd_e2 = (opcode_e2 == 15) & (xop_e2 == 0);
wire isSt_e2 = (opcode_e2 == 15) & (xop_e2 == 1);

wire updateRegs_e2 = (isSub_e2 | isAdd_e2 | isInc_e2 | isDec_e2 | isCmp_e2 | isMovl_e2 | isMovh_e2 | isLd_e2) & valid_execute1;
wire regs_wen_e2 = updateRegs_e2 & rt_e2 != 0; 

wire stall5 = 0;

wire[15:0] va_e2 = ra_e2 == 0 ? 0 : 
	ra_e2 === regs_waddr & regs_wen ? reg_out :
	regs_data0_execute1;
wire[15:0] vb_e2 = rb_e2 == 0 ? 0 : 
	rb_e2 === regs_waddr & regs_wen ? reg_out :
	regs_data1_execute1;
wire[15:0] vt_e2 = rt_e2 == 0 ? 0 : 
	rt_e2 === regs_waddr & regs_wen ? reg_out :
	regs_data1_execute1;

wire[16:0] reg_out_e2 = isSub_e2 ? va_e2 - vb_e2 :
	isAdd_e2 ? va_e2 + vb_e2 :
	isInc_e2 ? vt_e2 + imm_e2 :
	isDec_e2 ? vt_e2 - imm_e2 :
	isCmp_e2 ? va_e2 === vb_e2 :
	isMovl_e2 ? { {8{imm_e2[7]}}, imm_e2} :
	isMovh_e2 ? ((vt_e2 & 16'hff) | { imm_e2, 8'h0 }) :
	0;

always @(posedge clk) begin
	if(shouldContinue) begin
		regs_data0_execute2 <= (shouldStall >= 5) === 1 ? regs_data0_execute2 :
			regs_addr0_execute1 == 0 ? 16'b0 :
			regs_addr0_execute1 == regs_waddr & regs_wen ? reg_out :
			regs_data0_execute1;  
		regs_data1_execute2 <= (shouldStall >= 5) === 1 ? regs_data1_execute2 :
			regs_addr1_execute1 === 0 ? 16'b0 :
			regs_addr1_execute1 === regs_waddr & regs_wen ? reg_out :
			regs_data1_execute1;

		pc_execute2 <= (shouldStall >= 5) === 1 ? pc_execute2 : pc_execute1;
		instruction_execute2 <= (shouldStall >= 5) === 1 ? instruction_execute2 : instruction_execute1;

		raddr1_execute2 <= (shouldStall >= 5) === 1 ? raddr1_execute2 : raddr1_execute1;
		valid_execute2 <= (isFlushing === 1 | shouldStall === 5) ? 0 :
			shouldStall >= 5 ? valid_execute2 : 
			valid_execute1;
	end
end

// ========================= WRITE BACK ====================================

wire[3:0] opcode_wb = instruction_execute2[15:12];
wire[7:0] imm = instruction_execute2[11:4];
wire[3:0] xop_wb = instruction_execute2[7:4];

wire[3:0] ra_wb = instruction_execute2[11:8];
wire[3:0] rb_wb = instruction_execute2[7:4];
wire[3:0] rt_wb = instruction_execute2[3:0];

wire isSub = opcode_wb == 0;
wire isAdd = opcode_wb == 1;
wire isInc = opcode_wb == 2;
wire isDec = opcode_wb == 3;
wire isCmp = opcode_wb == 5;

wire isAwaken = opcode_wb == 6 & xop_wb == 0;
wire isPause = opcode_wb == 6 & xop_wb == 1;
wire isResume = opcode_wb == 6 & xop_wb == 2;

wire isPrint = opcode_wb === 7;

wire isMovl = opcode_wb == 8;
wire isMovh = opcode_wb == 9;
wire isLd = opcode_wb == 15 & xop_wb == 0;
wire isSt = opcode_wb == 15 & xop_wb == 1;

wire isJz = opcode_wb == 14 & xop_wb == 0;
wire isJnz = opcode_wb == 14 & xop_wb == 1;
wire isJs = opcode_wb == 14 & xop_wb == 2;
wire isJns = opcode_wb == 14 & xop_wb == 3;

wire[15:0] va_wb = ra_wb == 0 ? 0 : regs_data0_execute2;
wire[15:0] vb_wb = rb_wb == 0 ? 0 : regs_data1_execute2;
wire[15:0] vt_wb = rt_wb == 0 ? 0 : regs_data1_execute2;

wire isJumping = (isJz & (va_wb == 0)) |
	(isJnz & (va_wb != 0)) |
	(isJs & (va_wb[15] == 1)) |
	(isJns & (va_wb[15] == 0));

// Second buffer to catch things coming out of memory, in this case it is the
// data relevant for a load. Here we use the same buffer/copy principle as
// before to store the data and then read from it when we need to output
wire[15:0] ld_out = data_copy[16] === 1 ? data_copy[15:0] :
	buffer_wb[16] === 1 ? buffer_wb[15:0] :
	rdata1[15:0];

// Check if there is some self-modfying code here, if there is or there is
// a previous load then just flush the pipeline
wire isSt_needsFlush = isSt === 1 & (waddr === pc_execute1[15:1] | waddr === pc_execute0[15:1] | waddr === pc_fetch1[15:1] | waddr === pc_fetch0[15:1] | waddr === pc[15:1]);

// If any of the above cases are met, flush the pipeline
wire isFlushing = (((pc_real != pc_execute1) | isSt_needsFlush === 1) & valid_execute2 & valid_execute1) | pc_passed[16] === 1;

// This is the halting logic, if we get an instruction we don't recognize and
// its valid bit is set to 0 then we are done executing
wire isValidIns = isSub | isAdd | isInc | isDec | isCmp | isPause | isResume | isAwaken | isPrint | isMovl | isMovh | isJz | isJnz | isJs | isJns | isLd | isSt | valid_execute2 === 0;
wire shouldContinue = isValidIns === 1'b1 | isValidIns === 1'bx;
wire updateRegs = isSub | isAdd | isInc | isDec | isCmp | isMovl | isMovh | isLd;

// Calculate the actual write value
wire[16:0] reg_out = isSub ? va_wb - vb_wb :
	isAdd ? va_wb + vb_wb :
	isInc ? vt_wb + imm :
	isDec ? vt_wb - imm :
	isCmp ? va_wb === vb_wb :
	isMovl ? { {8{imm[7]}}, imm} :
	isMovh ? ((vt_wb & 16'hff) | { imm, 8'h0 }) :
	isLd ? ld_out :
	0;

// Write to either the register file or memory, as appropriate
assign regs_wdata = reg_out;
assign regs_waddr = rt_wb;
assign regs_wen = updateRegs & (rt_wb != 0) & valid_execute2 === 1 & (shouldStall !== 6); 

assign wen = isSt & (valid_execute2 === 1); 
assign waddr = va_wb[15:1];
assign wdata = vt_wb;

// 1st bit is valid bit, 2nd bit indicates whether it is a pause or a resume,
// 3rd/4th bits indicate which core we are operating on (0 indexed)
assign pauseResume[3] = (isPause === 1 | isResume === 1) & valid_execute2 === 1;
assign pauseResume[2] = isResume === 1;
assign pauseResume[1:0] = va_wb[1:0];

// Used for the awaken instruction
// 1st bit is valid bit, 2nd/3rd bits indicate which core we are operating on,
// 4th bit indicates the pc to be passed
assign pc_out[18] = isAwaken === 1 & valid_execute2 === 1;
assign pc_out[17:16] = va_wb[1:0];
assign pc_out[15:0] = vt_wb;

wire stall6 = 0;
reg[16:0] buffer_wb;
reg[16:0] data_copy;

// Calculate what the real PC should be, so that we can compare to see if our
// prediction was correct
wire[15:0] pc_real = isJumping === 1 & valid_execute2 === 1 ? vt_wb : pc_execute2 + 2;

always @(posedge clk) begin
	if(shouldContinue) begin
		//$write("%d %d %d %d\n", regs0_e0_buffer, regs_data0, regs1_e0_buffer, regs_data1);
		/*
		if (coreNum === 1)begin
			$write("Stall %d\n", shouldStall);
			$write("RegData0 %d, RegData1 %d, buff1: %d, buff2: %d\n", regs_data0[15:0], regs_data1[15:0], regs0_e0_buffer, regs1_e0_buffer);
			$write("E2 Ins:%h R0:%d R1:%d\n", instruction_execute2, regs_data0_execute2, regs_data1_execute2);
			$write("E1 Ins:%h R0%d R1%d\n", instruction_execute1, regs_data0_execute1, regs_data1_execute1);
			$write("E0 Ins: %h\n\n\n", instruction_execute0);
		end
		*/
		pc <= pc_passed[16] === 1 ? pc_passed[15:0] :
			isFlushing === 1 ? pc_real : 
			shouldStall >= 1 ? pc : 
			predicted;
		if(isFlushing === 1 & isJumping === 1 & valid_execute2 === 1)
			predictor_table[pc_execute2[10:1]] <= {1'b1, pc_real};
		if (updateRegs & (rt_wb == 0) & valid_execute2 === 1 & (shouldStall !== 6))
			$write("%c", regs_wdata[7:0]);
		if(isPrint === 1 & valid_execute2 === 1 & shouldStall != 6)
			$write("%d\n", vt_wb);
		if(pc_passed[16] === 1)
			isAwake <= 1;
		buffer_wb <= data_copy[16] === 1 ? buffer_wb[16] === 1 ? buffer_wb : {1'b1, rdata1[15:0]} : 17'b0;
		data_copy[15:0] <= rdata1[15:0];
		data_copy[16] <= (shouldStall >= 6) === 1;

	end else begin
		halt <= 1;
	end
end

endmodule
