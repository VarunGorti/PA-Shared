`timescale 1ps/1ps

module main();

initial begin
	$dumpfile("cpu.vcd");
	$dumpvars(0,main);
end

wire clk;
clock c0(clk);

wire halt;
wire[16:0] pc_passed = 17'b0;
wire[2:0] stall_num = 3'b0;

wire[15:0] pc;
wire[15:0] rdata0;
wire[15:1] raddr1;
wire[15:0] rdata1;
wire wen;
wire[15:1] waddr;
wire[15:0] wdata;


mem mem(clk,
	pc[15:1], rdata0,
	raddr1, rdata1,
	wen, waddr, wdata);

core core1(clk, halt, pc_passed, stall_num,
	   pc, rdata0,
	   raddr1, rdata1,
	   wen, waddr, wdata);

endmodule
