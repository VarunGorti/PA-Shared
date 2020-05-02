`timescale 1ps/1ps

module mem(input clk,
    input [15:1]raddr0_, output [15:0]rdata0_,
    input [15:1]raddr1_, output [15:0]rdata1_,
    input [15:1]raddr2_, output [15:0]rdata2_,
    input wen, input [15:1]waddr, input [15:0]wdata);

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

    assign rdata0_ = rdata0;
    assign rdata1_ = rdata1;
    assign rdata2_ = rdata2;

    always @(posedge clk) begin
        raddr0 <= raddr0_;
        raddr1 <= raddr1_;
	raddr2 <= raddr2_;
        rdata0 <= data[raddr0];
        rdata1 <= data[raddr1];
	rdata2 <= data[raddr2];
        if (wen) begin
            data[waddr] <= wdata;
        end
    end

endmodule
