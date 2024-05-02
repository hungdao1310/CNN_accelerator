`timescale 1 ns / 10 ps
module tb();

parameter DATA_WIDTH = 20;
parameter WEIGHT_WIDTH = 8;
parameter IFM_WIDTH = 8;
parameter KERNEL_SIZE  = 3;
parameter FIFO_SIZE = 10;
parameter ADD_WIDTH = 4;

	reg clk1;
	reg clk2;
	reg rst_n;
	reg set_reg_pe;
	reg set_wgt;
	reg set_ifm;
	reg wr_en;
	reg rd_en;
	reg [WEIGHT_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0] wgt;
	reg [IFM_WIDTH-1:0] ifm;
	wire [DATA_WIDTH-1:0] data_out;
	reg [2:0] set_reg;

	initial begin
		$dumpfile("CONV_ACC.vcd");
		$dumpvars(0,tb);
	end

  TOP #(.DATA_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WEIGHT_WIDTH), .IFM_WIDTH(IFM_WIDTH), .FIFO_SIZE(FIFO_SIZE), .INDEX_WIDTH(ADD_WIDTH), .KERNEL_SIZE(KERNEL_SIZE)) top_module(
      .clk1(clk1)
     ,.clk2(clk2)
     ,.rst_n(rst_n)                    	
     ,.set_reg(set_reg_pe)
     ,.set_wgt(set_wgt)
     ,.set_ifm(set_ifm)
     ,.wr_en(wr_en)                        		
     ,.rd_en(rd_en)
     ,.ifm(ifm)
		 ,.wgt(wgt)
     ,.data_output(data_out)
		 );
	always #5 clk1 = ~clk1;
	always @(clk1) begin
		clk2 = ~clk1;
	end
	always @(posedge clk2 or negedge rst_n) begin
		if(!rst_n) begin
			set_reg_pe = 0;
		end
		else begin
			set_reg_pe = 1'b1;
		end
	end
			
	initial begin
		rst_n = 1;
		clk1 = 1;
		clk2 = 0;
#10 rst_n = 0;
#10 rst_n = 1;

#10 ifm = 1;
		wgt = 72'hABCDEF010101;
		set_wgt =1;
		set_ifm = 1;
#5 ifm = 2;
		wgt = 72'hABCDEF020102;
		set_wgt =1;
		set_ifm = 1;
#5 ifm = 2;
		wgt = 72'hABCDEF030401;
		set_wgt =1;
		set_ifm = 1;
#5 ifm = 2;
		wgt = 72'hABCDEF030102;
		set_wgt =1;
		set_ifm = 1;
#5 ifm = 2;
		wgt = 72'hABCDEF020103;
		set_wgt =1;
		set_ifm = 1;
#5 ifm = 2;
		wgt = 72'hABCDEF020202;
		set_wgt =1;
		set_ifm = 1;
#5 ifm = 2;
		wgt = 72'hABCDEF010102;
		set_wgt =1;
		set_ifm = 1;
		
#1000 $finish; 
		end
endmodule
