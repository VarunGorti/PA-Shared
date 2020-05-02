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

wire[2:0] stall_num_1 = 3'b0;
wire[2:0] stall_num_2 = 3'b0;

wire[15:0] pc_1;
wire[15:0] rdata0_1;
wire[15:1] raddr1_1;
wire[15:0] rdata1_1;
wire wen_1;
wire[15:1] waddr_1;
wire[15:0] wdata_1;

wire[15:0] pc_2;
wire[15:0] rdata0_2;
wire[15:1] raddr1_2;
wire[15:0] rdata1_2;
wire wen_2;
wire[15:1] waddr_2;
wire[15:0] wdata_2;

mem mem(clk,
	pc_1[15:1], rdata0_1,
	pc_2[15:1], rdata0_2,
	raddr1_1, rdata1_1,
	wen_1, waddr_1, wdata_1);

core core1(clk, halt_1, pc_passed_1, stall_num_1,
	   pc_1, rdata0_1,
	   raddr1_1, rdata1_1,
	   wen_1, waddr_1, wdata_1);

core core2(clk, halt_2, pc_passed_2, stall_num_2,
	   pc_2, rdata0_2,
	   raddr1_2, rdata1_2,
	   wen_2, waddr_2, wdata_2);

endmodule
