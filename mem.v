`timescale 1ps/1ps

module mem(input clk,
    input [15:1]raddr0_, output [15:0]rdata0_,
    input [15:1]raddr1_, output [15:0]rdata1_,
    inout [16:1]raddr2_a, inout [16:1]raddr2_b, output [16:0]rdata2_,
    inout [16:1]waddr_a, inout [16:1]waddr_b, input [15:0]wdata_a, input [15:0]wdata_b,
    input debug);

    reg [15:0]data[0:16'h7fff];

    /* Simulation -- read initial content from file */
    initial begin
        $readmemh("mem.hex",data);
    end

    reg [15:1]raddr0;
    reg [15:0]rdata0;

    reg [15:1]raddr1;
    reg [15:0]rdata1;

    reg [16:1]raddr2;
    reg [16:0]rdata2;

    assign rdata0_ = rdata0;
    assign rdata1_ = rdata1;
    assign rdata2_ = rdata2;

    wire isReading_coreA = raddr2_a[16] === 1;
    wire isReading_coreB = raddr2_b[16] === 1;

    wire wen = isWriting_coreA | isWriting_coreB;
    wire[15:1] waddr = isWriting_coreA ? waddr_a[15:1] : waddr_b[15:1];
    wire[15:0] wdata = isWriting_coreA ? wdata_a : wdata_b;
    
    wire isWriting_coreA = waddr_a[16] === 1;
    wire isWriting_coreB = waddr_b[16] === 1;

    always @(posedge clk) begin
        raddr0 <= raddr0_;
        raddr1 <= raddr1_;
	raddr2 <= isReading_coreA ? {1'b0, raddr2_a} : {1'b1, raddr2_b};
        rdata0 <= data[raddr0];
        rdata1 <= data[raddr1];
	// At some point this needs to be random
	rdata2 <= {raddr2[16], data[raddr2[15:1]]};

        if (wen) begin
            data[waddr] <= wdata;
        end

	if(debug) begin	
	    $write("isWriting_coreA = %b\n", isWriting_coreA);
	    $write("waddr_a = %x\n", waddr_a[15:1]);
	    $write("wdata_a = %x\n", wdata_a);
	    $write("\n"); 
	    $write("isWriting_coreB = %b\n", isWriting_coreB);
	    $write("waddr_b = %x\n", waddr_b[15:1]);
	    $write("wdata_b = %x\n", wdata_b);
	    $write("\n");
	    $write("waddr = %x\n", waddr);
	    $write("wdata = %x\n", wdata);
	end

    end

endmodule
