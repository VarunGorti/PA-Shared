`timescale 1ps/1ps

module mem(input clk,
	input [15:1]raddr0_, output [15:0]rdata0_,
	input [15:1]raddr1_, output [15:0]rdata1_,
	input [15:1]raddr2_, output [15:0]rdata2_,
	input [15:1]raddr3_, output [15:0]rdata3_,
	inout [16:1]raddr4_a, inout [16:1]raddr4_b, inout [16:1]raddr4_c, inout [16:1]raddr4_d, output [17:0]rdata4_,
	inout [16:1]waddr_a, inout [16:1]waddr_b, inout [16:1]waddr_c, inout [16:1]waddr_d, input [15:0]wdata_a, input [15:0]wdata_b, input [15:0]wdata_c, input[15:0]wdata_d);

reg [15:0]data[0:16'h7fff];

/* Simulation -- read initial content from file */
initial begin
	$readmemh("mem.hex",data);
end

reg [15:1]raddr0;
reg [15:0]rdata0;

reg [15:1]raddr1;
reg [15:0]rdata1;

reg [15:1]raddr2;
reg [15:0]rdata2;

reg [15:1]raddr3;
reg [15:0]rdata3;

reg [16:1]raddr4;
reg [17:0]rdata4;

assign rdata0_ = rdata0;
assign rdata1_ = rdata1;
assign rdata2_ = rdata2;
assign rdata3_ = rdata3;
assign rdata4_ = rdata4;

// Figure out which cores are reading
wire isReading_coreA = raddr4_a[16] === 1;
wire isReading_coreB = raddr4_b[16] === 1;
wire isReading_coreC = raddr4_c[16] === 1;
wire isReading_coreD = raddr4_d[16] === 1;

// Check which cores are writing to memory
wire isWriting_coreA = waddr_a[16] === 1;
wire isWriting_coreB = waddr_b[16] === 1;
wire isWriting_coreC = waddr_c[16] === 1;
wire isWriting_coreD = waddr_d[16] === 1;

// Check whether any core is trying to write to memory
wire wen = isWriting_coreA | isWriting_coreB | isWriting_coreC | isWriting_coreD;

// Determine the write address based on which core is writing, again
// giving priority to the earlier-lettered cores
wire[15:1] waddr = isWriting_coreA ? waddr_a[15:1] : 
	isWriting_coreB ? waddr_b[15:1] : 
	isWriting_coreC ? waddr_c[15:1] :
	waddr_d[15:1];

// Determine the write data based on which cores is writing again, using
// same priority as before
wire[15:0] wdata = isWriting_coreA ? wdata_a : 
	isWriting_coreB ? wdata_b : 
	isWriting_coreC ? wdata_c :
	wdata_d;

always @(posedge clk) begin
	raddr0 <= raddr0_;
	raddr1 <= raddr1_;
	raddr2 <= raddr2_;
	raddr3 <= raddr3_;
	raddr4 <= isReading_coreA ? {2'b00, raddr4_a} :
		isReading_coreB ? {2'b01, raddr4_b} :
		isReading_coreC ? {2'b10, raddr4_c} :
		{2'b11, raddr4_d};
	rdata0 <= data[raddr0];
	rdata1 <= data[raddr1];
	rdata2 <= data[raddr2];
	rdata3 <= data[raddr3];

	rdata4 <= {raddr4[17:16], data[raddr4[15:1]]};

	if (wen) begin
		data[waddr] <= wdata;
	end
end

endmodule
