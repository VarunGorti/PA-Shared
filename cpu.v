`timescale 1ps/1ps

module main();

initial begin
	$dumpfile("cpu.vcd");
	$dumpvars(0,main);

	// Initialize all cores to the running state
	// Note that cores 2-4 are still "asleep" so will not run at the
	// beginning regardless of this
	runState_1 <= 1;
	runState_2 <= 1;
	runState_3 <= 1;
	runState_4 <= 1;
end

wire clk;
clock c0(clk);

// Calculate the pc's passed into the cores to activate them, based on the
// pc's coming out of the other cores
wire[16:0] pc_passed_1 = first_cycle === 1 ? {1'b1, 16'h0} :
	pc_out_1[18:16] === 3'b100 ? {1'b1, pc_out_1[15:0]} :
	pc_out_2[18:16] === 3'b100 ? {1'b1, pc_out_2[15:0]} :
	pc_out_3[18:16] === 3'b100 ? {1'b1, pc_out_3[15:0]} : 
	pc_out_4[18:16] === 3'b100 ? {1'b1, pc_out_4[15:0]} :
	0;
wire[16:0] pc_passed_2 = first_cycle === 1 ? 0 :
	pc_out_1[18:16] === 3'b101 ? {1'b1, pc_out_1[15:0]} :
	pc_out_2[18:16] === 3'b101 ? {1'b1, pc_out_2[15:0]} :
	pc_out_3[18:16] === 3'b101 ? {1'b1, pc_out_3[15:0]} : 
	pc_out_4[18:16] === 3'b101 ? {1'b1, pc_out_4[15:0]} :
	0;
wire[16:0] pc_passed_3 = first_cycle == 1 ? 0 :
	pc_out_1[18:16] === 3'b110 ? {1'b1, pc_out_1[15:0]} :
	pc_out_2[18:16] === 3'b110 ? {1'b1, pc_out_2[15:0]} :
	pc_out_3[18:16] === 3'b110 ? {1'b1, pc_out_3[15:0]} : 
	pc_out_4[18:16] === 3'b110 ? {1'b1, pc_out_4[15:0]} :
	0;
wire[16:0] pc_passed_4 = first_cycle == 1 ? 0 :
	pc_out_1[18:16] === 3'b111 ? {1'b1, pc_out_1[15:0]} :
	pc_out_2[18:16] === 3'b111 ? {1'b1, pc_out_2[15:0]} :
	pc_out_3[18:16] === 3'b111 ? {1'b1, pc_out_3[15:0]} : 
	pc_out_4[18:16] === 3'b111 ? {1'b1, pc_out_4[15:0]} :
	0;

reg first_cycle = 1;

// Calculate stall numbers for all of the processors based on resource
// hazards, giving priority to the lower-numbered cores in the event of
// a conflict
wire[2:0] stall_num_1;
assign stall_num_1 = runState_1 === 0 ? 6 :
	0;

wire[2:0] stall_num_2;
assign stall_num_2 = runState_2 === 0 ? 6 :
	(wen_1 & wen_2) === 1 ? 6 : 
	(raddr1_1[16] & raddr1_2[16]) === 1 ? 4 : 
	0;

wire[2:0] stall_num_3;
assign stall_num_3 = runState_3 === 0 ? 6 :
	((wen_1 | wen_2) & wen_3) === 1 ? 6 : 
	((raddr1_1[16] | raddr1_2[16]) & raddr1_3[16]) === 1 ? 4 : 
	0;

wire[2:0] stall_num_4;
assign stall_num_4 = runState_4 === 0 ? 6 :
	((wen_1 | wen_2 | wen_3) & wen_4) === 1 ? 6 : 
	((raddr1_1[16] | raddr1_2[16] | raddr1_3[16]) & raddr1_4[16]) === 1 ? 4 : 
	0;

wire[15:0] pc_1;
wire[15:0] rdata0_1;
wire[16:1] raddr1_1;
wire wen_1;
wire[15:1] waddr_1;
wire[15:0] wdata_1;
wire[3:0] pauseResume_1;
wire[18:0] pc_out_1;
reg[1:0] runState_1;
wire awake_1;

wire[15:0] pc_2;
wire[15:0] rdata0_2;
wire[16:1] raddr1_2;
wire wen_2;
wire[15:1] waddr_2;
wire[15:0] wdata_2;
wire[3:0] pauseResume_2;
wire[18:0] pc_out_2;
reg[1:0] runState_2;
wire awake_2;

wire[15:0] pc_3;
wire[15:0] rdata0_3;
wire[16:1] raddr1_3;
wire wen_3;
wire[15:1] waddr_3;
wire[15:0] wdata_3;
wire[3:0] pauseResume_3;
wire[18:0] pc_out_3;
reg[1:0] runState_3;
wire awake_3;

wire[15:0] pc_4;
wire[15:0] rdata0_4;
wire[16:1] raddr1_4;
wire wen_4;
wire[15:1] waddr_4;
wire[15:0] wdata_4;
wire[3:0] pauseResume_4;
wire[18:0] pc_out_4;
reg[1:0] runState_4;
wire awake_4;

// There is only one load memory output
wire[17:0] rdata1;

mem mem(clk,
	pc_1[15:1], rdata0_1,
	pc_2[15:1], rdata0_2,
	pc_3[15:1], rdata0_3,
	pc_4[15:1], rdata0_4,
	raddr1_1, raddr1_2, raddr1_3, raddr1_4, rdata1,
	{wen_1, waddr_1}, {wen_2, waddr_2}, {wen_3, waddr_3}, {wen_4, waddr_4}, wdata_1, wdata_2, wdata_3, wdata_4);

core core1(2'b00, clk, halt_1, pc_passed_1, stall_num_1,
	pc_1, rdata0_1,
	raddr1_1, rdata1,
	wen_1, waddr_1, wdata_1,
	pauseResume_1, pc_out_1, awake_1);

core core2(2'b01, clk, halt_2, pc_passed_2, stall_num_2,
	pc_2, rdata0_2,
	raddr1_2, rdata1,
	wen_2, waddr_2, wdata_2,
	pauseResume_2, pc_out_2, awake_2);

core core3(2'b10, clk, halt_3, pc_passed_3, stall_num_3,
	pc_3, rdata0_3,
	raddr1_3, rdata1,
	wen_3, waddr_3, wdata_3,
	pauseResume_3, pc_out_3, awake_3);

core core4(2'b11, clk, halt_4, pc_passed_4, stall_num_4,
	pc_4, rdata0_4,
	raddr1_4, rdata1,
	wen_4, waddr_4, wdata_4,
	pauseResume_4, pc_out_4, awake_4);

reg halt = 0;
counter ctr(halt, clk);

always @(posedge clk) begin
	if((halt_1 === 1 | awake_1 !== 1) & (halt_2 === 1 | awake_2 !==1) & (halt_3 === 1 | awake_3 !== 1) & (halt_4 === 1 | awake_4 !==1))
		halt <= 1;
	// Calculate run states for each of the cores based on the idea that
	// pauses and resumes can come in in either order, but multiple pauses
	// could pair to one resume (or vice versa). This is a 3-state sytem,
	// with state 0 meaning the core is paused and state 1 and 2 meaning
	// the core is running. A "resume" increases the state by 1, to
	// a maximum of 2, and a "pause" decreases the state by 1, to
	// a minimum of 0.
	runState_1 <= pauseResume_1[3] === 1 & pauseResume_1[1:0] === 0 ?
	pauseResume_1[2] === 1 & runState_1 !== 2 ? runState_1 + 1 :
	pauseResume_1[2] === 0 & runState_1 !== 0 ? runState_1 - 1 : 
	runState_1 :
	pauseResume_2[3] === 1 & pauseResume_2[1:0] === 0 ?
	pauseResume_2[2] === 1 & runState_1 !== 2 ? runState_1 + 1 :
	pauseResume_2[2] === 0 & runState_1 !== 0 ? runState_1 - 1 :
	runState_1 :
	pauseResume_3[3] === 1 & pauseResume_3[1:0] === 0 ?
	pauseResume_3[2] === 1 & runState_1 !== 2 ? runState_1 + 1 :
	pauseResume_3[2] === 0 & runState_1 !== 0 ? runState_1 - 1 :
	runState_1 :
	pauseResume_4[3] === 1 & pauseResume_4[1:0] === 0 ?
	pauseResume_4[2] === 1 & runState_1 !== 2 ? runState_1 + 1 :
	pauseResume_4[2] === 0 & runState_1 !== 0 ? runState_1 - 1 :
	runState_1 :
	runState_1;
runState_2 <= pauseResume_1[3] === 1 & pauseResume_1[1:0] === 1 ?
	pauseResume_1[2] === 1 & runState_2 !== 2 ? runState_2 + 1 :
	pauseResume_1[2] === 0 & runState_2 !== 0 ? runState_2 - 1 :
	runState_2 :
	pauseResume_2[3] === 1 & pauseResume_2[1:0] === 1 ?
	pauseResume_2[2] === 1 & runState_2 !== 2 ? runState_2 + 1 :
	pauseResume_2[2] === 0 & runState_2 !== 0 ? runState_2 - 1 :
	runState_2 :
	pauseResume_3[3] === 1 & pauseResume_3[1:0] === 1 ?
	pauseResume_3[2] === 1 & runState_2 !== 2 ? runState_2 + 1 :
	pauseResume_3[2] === 0 & runState_2 !== 0 ? runState_2 - 1 :
	runState_2 :
	pauseResume_4[3] === 1 & pauseResume_4[1:0] === 1 ?
	pauseResume_4[2] === 1 & runState_2 !== 2 ? runState_2 + 1 :
	pauseResume_4[2] === 0 & runState_2 !== 0 ? runState_2 - 1 :
	runState_2 :
	runState_2;
runState_3 <= pauseResume_1[3] === 1 & pauseResume_1[1:0] === 2 ?
	pauseResume_1[2] === 1 & runState_3 !== 2 ? runState_3 + 1 :
	pauseResume_1[2] === 0 & runState_3 !== 0 ? runState_3 - 1 :
	runState_3 :
	pauseResume_2[3] === 1 & pauseResume_2[1:0] === 2 ?
	pauseResume_2[2] === 1 & runState_3 !== 2 ? runState_3 + 1 :
	pauseResume_2[2] === 0 & runState_3 !== 0 ? runState_3 - 1 :
	runState_3 :
	pauseResume_3[3] === 1 & pauseResume_3[1:0] === 2 ?
	pauseResume_3[2] === 1 & runState_3 !== 2 ? runState_3 + 1 :
	pauseResume_3[2] === 0 & runState_3 !== 0 ? runState_3 - 1 :
	runState_3 :
	pauseResume_4[3] === 1 & pauseResume_4[1:0] === 2 ?
	pauseResume_4[2] === 1 & runState_3 !== 2 ? runState_3 + 1 :
	pauseResume_4[2] === 0 & runState_3 !== 0 ? runState_3 - 1 :
	runState_3 :
	runState_3;
runState_4 <= pauseResume_1[3] === 1 & pauseResume_1[1:0] === 3 ?
	pauseResume_1[2] === 1 & runState_4 !== 2 ? runState_4 + 1 :
	pauseResume_1[2] === 0 & runState_4 !== 0 ? runState_4 - 1 :
	runState_4 :
	pauseResume_2[3] === 1 & pauseResume_2[1:0] === 3 ?
	pauseResume_2[2] === 1 & runState_4 !== 2 ? runState_4 + 1 :
	pauseResume_2[2] === 0 & runState_4 !== 0 ? runState_4 - 1 :
	runState_4 :
	pauseResume_3[3] === 1 & pauseResume_3[1:0] === 3 ?
	pauseResume_3[2] === 1 & runState_4 !== 2 ? runState_4 + 1 :
	pauseResume_3[2] === 0 & runState_4 !== 0 ? runState_4 - 1 :
	runState_4 :
	pauseResume_4[3] === 1 & pauseResume_4[1:0] === 3 ?
	pauseResume_4[2] === 1 & runState_4 !== 2 ? runState_4 + 1 :
	pauseResume_4[2] === 0 & runState_4 !== 0 ? runState_4 - 1 :
	runState_4 :
	runState_4;
first_cycle <= 0;
end

endmodule
