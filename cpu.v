`timescale 1ps/1ps

module main();

initial begin
	$dumpfile("cpu.vcd");
	$dumpvars(0,main);
end

wire clk;
clock c0(clk);

wire[16:0] pc_passed_1 = first_cycle === 1 ? {1'b1, 16'h0} :
			 pc_out_1[18:16] === 3'b100 ? {1'b1, pc_out_1[15:0]} :
			 pc_out_2[18:16] === 3'b100 ? {1'b1, pc_out_2[15:0]} :
			 pc_out_3[18:16] === 3'b100 ? {1'b1, pc_out_3[15:0]} : 
			 pc_out_4[18:16] === 3'b100 ? {1'b1, pc_out_2[15:0]} :
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

wire[2:0] stall_num_1;
assign stall_num_1 = pauseResume_1 === 4'b1000 | pauseResume_2 === 4'b1000 | pauseResume_3 === 4'b1000 | pauseResume_4 === 4'b1000 ? 6 :
	pauseResume[0] === 0 & pauseResume_1 !== 4'b1100 & pauseResume_2 !== 4'b1100 & pauseResume_3 !== 4'b1100 & pauseResume_4 !== 4'b1100 ? 6 :
	0;
wire[2:0] stall_num_2;
assign stall_num_2 = pauseResume_1 === 4'b1001 | pauseResume_2 === 4'b1001 | pauseResume_3 === 4'b1001 | pauseResume_4 !== 4'b1001 ? 6 :
	pauseResume[1] === 0 & pauseResume_1 !== 4'b1101 & pauseResume_2 !== 4'b1101 & pauseResume_3 !== 4'b1101 & pauseResume_4 !== 4'b1101 ? 6 :
	(wen_1 & wen_2) === 1 ? 6 : 
	(raddr1_1[16] & raddr1_2[16]) === 1 ? 3 : 
	0;
wire[2:0] stall_num_3;
assign stall_num_3 = pauseResume_1 === 4'b1010 | pauseResume_2 === 4'b1010 | pauseResume_3 === 4'b1010 | pauseResume_4 !== 4'b1010 ? 6 :
	pauseResume[2] === 0 & pauseResume_1 !== 4'b1110 & pauseResume_2 !== 4'b1110 & pauseResume_3 !== 4'b1110 & pauseResume_4 !== 4'b1110 ? 6 :
	((wen_1 | wen_2) & wen_3) === 1 ? 6 : 
	((raddr1_1[16] | raddr1_2[16]) & raddr1_3[16]) === 1 ? 3 : 
	0;
wire[2:0] stall_num_4;
assign stall_num_4 = pauseResume_1 === 4'b1011 | pauseResume_2 === 4'b1011 | pauseResume_3 === 4'b1011 | pauseResume_4 !== 4'b1011 ? 6 :
	pauseResume[3] === 0 & pauseResume_1 !== 4'b1111 & pauseResume_2 !== 4'b1111 & pauseResume_3 !== 4'b1111 & pauseResume_4 !== 4'b1111 ? 6 :
	((wen_1 | wen_2 | wen_3) & wen_4) === 1 ? 6 : 
	((raddr1_1[16] | raddr1_2[16] | raddr1_3[16]) & raddr1_4[16]) === 1 ? 3 : 
	0;
wire debug_mem = 0;

wire[15:0] pc_1;
wire[15:0] rdata0_1;
wire[16:1] raddr1_1;
wire wen_1;
wire[15:1] waddr_1;
wire[15:0] wdata_1;
wire[3:0] pauseResume_1;
wire[18:0] pc_out_1;
wire awake_1;
wire debug_1 = 0;

wire[15:0] pc_2;
wire[15:0] rdata0_2;
wire[16:1] raddr1_2;
wire wen_2;
wire[15:1] waddr_2;
wire[15:0] wdata_2;
wire[3:0] pauseResume_2;
wire[18:0] pc_out_2;
wire awake_2;
wire debug_2 = 0;

wire[15:0] pc_3;
wire[15:0] rdata0_3;
wire[16:1] raddr1_3;
wire wen_3;
wire[15:1] waddr_3;
wire[15:0] wdata_3;
wire[3:0] pauseResume_3;
wire[18:0] pc_out_3;
wire awake_3;
wire debug_3 = 0;

wire[15:0] pc_4;
wire[15:0] rdata0_4;
wire[16:1] raddr1_4;
wire wen_4;
wire[15:1] waddr_4;
wire[15:0] wdata_4;
wire[3:0] pauseResume_4;
wire[18:0] pc_out_4;
wire awake_4;
wire debug_4 = 0;

wire[17:0] rdata1;

// The first bit in this reg will denote the current state of core 2 (with
// 1 being running, 0 being paused) and the second bit will denote the current
// state of core 1
reg[3:0] pauseResume;

mem mem(clk,
	pc_1[15:1], rdata0_1,
	pc_2[15:1], rdata0_2,
	pc_3[15:1], rdata0_3,
	pc_4[15:1], rdata0_4,
	raddr1_1, raddr1_2, raddr1_3, raddr1_4, rdata1,
	{wen_1, waddr_1}, {wen_2, waddr_2}, {wen_3, waddr_3}, {wen_4, waddr_4}, wdata_1, wdata_2, wdata_3, wdata_4,
	debug_mem);

core core1(clk, halt_1, pc_passed_1, stall_num_1,
	pc_1, rdata0_1,
	raddr1_1, rdata1,
	wen_1, waddr_1, wdata_1,
	pauseResume_1, pc_out_1, awake_1,
	debug_1);

core core2(clk, halt_2, pc_passed_2, stall_num_2,
	pc_2, rdata0_2,
	raddr1_2, rdata1,
	wen_2, waddr_2, wdata_2,
	pauseResume_2, pc_out_2, awake_2,
	debug_2);

core core3(clk, halt_3, pc_passed_3, stall_num_3,
	pc_3, rdata0_3,
	raddr1_3, rdata1,
	wen_3, waddr_3, wdata_3,
	pauseResume_3, pc_out_3, awake_3,
	debug_3);

core core4(clk, halt_4, pc_passed_4, stall_num_4,
	pc_4, rdata0_4,
	raddr1_4, rdata1,
	wen_4, waddr_4, wdata_4,
	pauseResume_4, pc_out_4, awake_4,
	debug_4);

reg halt = 0;
counter ctr(halt, clk);

always @(posedge clk) begin
	if((halt_1 === 1 | awake_1 !== 1) & (halt_2 === 1 | awake_2 !==1) & (halt_3 === 1 | awake_3 !== 1) & (halt_4 === 1 | awake_4 !==1))
		halt <= 1;
	pauseResume[0] <= pauseResume_1[3] === 1 & pauseResume_1[1:0] === 0 ? pauseResume_1[2] : 
			  pauseResume_2[3] === 1 & pauseResume_2[1:0] === 0 ? pauseResume_2[2] :
			  pauseResume[0];	
	pauseResume[1] <= pauseResume_1[3] === 1 & pauseResume_1[1:0] === 1 ? pauseResume_1[2] : 
			  pauseResume_2[3] === 1 & pauseResume_2[1:0] === 1 ? pauseResume_2[2] :
			  pauseResume[1];	
	pauseResume[2] <= pauseResume_1[3] === 1 & pauseResume_1[1:0] === 2 ? pauseResume_1[2] : 
			  pauseResume_2[3] === 1 & pauseResume_2[1:0] === 2 ? pauseResume_2[2] :
			  pauseResume[2];	
	pauseResume[3] <= pauseResume_1[3] === 1 & pauseResume_1[1:0] === 3 ? pauseResume_1[2] : 
			  pauseResume_2[3] === 1 & pauseResume_2[1:0] === 3 ? pauseResume_2[2] :
			  pauseResume[3];	
	first_cycle <= 0;
end

endmodule
