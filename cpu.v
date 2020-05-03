`timescale 1ps/1ps

module main();

initial begin
	$dumpfile("cpu.vcd");
	$dumpvars(0,main);
end

wire clk;
clock c0(clk);

wire halt1;
wire halt2;

wire[16:0] pc_passed_1 = 17'b0;
wire[16:0] pc_passed_2 = 17'h200;

wire[2:0] stall_num_1;
assign stall_num_1 = pauseResume_1 === 3'b100 | pauseResume_2 === 3'b100 ? 6 :
	pauseResume[1] === 0 & pauseResume_1 !== 3'b110 & pauseResume_2 !== 3'b110 ? 6 :
	0;
wire[2:0] stall_num_2;
assign stall_num_2 = pauseResume_1 === 3'b101 | pauseResume_2 === 3'b101 ? 6 :
	pauseResume[1] === 0 & pauseResume_1 !== 3'b111 & pauseResume_2 !== 3'b111 ? 6 :
	wen_1 ===  1 & wen_2 === 1 ? 6 : 
	raddr1_1[16] === 1 & raddr1_2[16] === 1 ? 3 : 
	0;


wire debug_mem = 0;

wire[15:0] pc_1;
wire[15:0] rdata0_1;
wire[16:1] raddr1_1;
wire wen_1;
wire[15:1] waddr_1;
wire[15:0] wdata_1;
wire[2:0] pauseResume_1;
wire debug_1 = 1;

wire[15:0] pc_2;
wire[15:0] rdata0_2;
wire[16:1] raddr1_2;
wire wen_2;
wire[15:1] waddr_2;
wire[15:0] wdata_2;
wire[2:0] pauseResume_2;
wire debug_2 = 0;

wire[16:0] rdata1;

// The first bit in this reg will denote the current state of core 2 (with
// 1 being running, 0 being paused) and the second bit will denote the current
// state of core 1
reg[1:0] pauseResume;

mem mem(clk,
	pc_1[15:1], rdata0_1,
	pc_2[15:1], rdata0_2,
	raddr1_1, raddr1_2, rdata1,
	{wen_1, waddr_1}, {wen_2, waddr_2}, wdata_1, wdata_2,
	debug_mem);

core core1(clk, halt_1, pc_passed_1, stall_num_1,
	pc_1, rdata0_1,
	raddr1_1, rdata1,
	wen_1, waddr_1, wdata_1,
	pauseResume_1,
	debug_1);

core core2(clk, halt_2, pc_passed_2, stall_num_2,
	pc_2, rdata0_2,
	raddr1_2, rdata1,
	wen_2, waddr_2, wdata_2,
	pauseResume_2,
	debug_2);

reg halt = 0;
counter ctr(halt, clk);

always @(posedge clk) begin
	if(halt_1 === 1 & halt_2 === 1)
		halt <= 1;
	pauseResume[0] <= pauseResume_1[2] === 1 & pauseResume_1[0] === 0 ? pauseResume_1[1] : 
			  pauseResume_2[2] === 1 & pauseResume_2[0] === 0 ? pauseResume_2[1] :
			  pauseResume[0];	
	pauseResume[1] <= pauseResume_1[2] === 1 & pauseResume_1[0] === 1 ? pauseResume_1[1] : 
			  pauseResume_2[2] === 1 & pauseResume_2[0] === 1 ? pauseResume_2[1] :
			  pauseResume[1];	
end

endmodule
