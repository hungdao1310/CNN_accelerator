module CONV #(
  parameter 
    DATA_WIDTH = 32, 
    WEIGHT_WIDTH = 16, 
    IFM_WIDTH = 16,  
    IFM_SIZE = 27, 
    KERNEL_SIZE = 5,
    STRIDE = 1,
    PAD = 2,
    RELU = 1,
    FIFO_SIZE = (IFM_SIZE-KERNEL_SIZE+2*PAD)/STRIDE+1,
    CI = 3, 
    CO = 8
)(
	input clk1,
	input clk2,
	input rst_n,
  input start_conv,
  input in_valid,
	input [IFM_WIDTH-1:0] ifm,
	input [WEIGHT_WIDTH-1:0] wgt,
  output ifm_read,
  output wgt_read,
  output out_valid,
  output end_conv,
	output[DATA_WIDTH-1:0] data_output
	);

  localparam ADD_WIDTH = $clog2(IFM_SIZE-KERNEL_SIZE+2*PAD+1)+1;

	wire [DATA_WIDTH-1:0] psum [KERNEL_SIZE-1:0][KERNEL_SIZE:0];
	wire [WEIGHT_WIDTH-1:0] wgt_wire [KERNEL_SIZE*KERNEL_SIZE-1:0];
	wire [IFM_WIDTH-1:0] ifm_wire;
  wire [KERNEL_SIZE*KERNEL_SIZE-1:0] set_wgt;

  assign psum[0][0] = 0;

  wire rd_clr;
  wire wr_clr;
  wire re_buffer;
  wire set_ifm;
  wire set_reg;
  wire [DATA_WIDTH-1:0] psum_buffer;
  wire [KERNEL_SIZE-1:0] wr_en;
  wire [KERNEL_SIZE-1:0] rd_en;
  wire [ADD_WIDTH:0] addr_x;
  wire [ADD_WIDTH:0] addr_y;
  wire [DATA_WIDTH-1:0] data_output_temp;

  CONTROL #(.KERNEL_SIZE(KERNEL_SIZE), .IFM_SIZE(IFM_SIZE+2*PAD), .PAD(PAD), .STRIDE(STRIDE), .CI(CI), .CO(CO)) control (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.start_conv(start_conv)
    ,.in_valid(in_valid)
    ,.ifm_read(ifm_read)
    ,.wgt_read(wgt_read)
    ,.rd_clr(rd_clr)
    ,.wr_clr(wr_clr)
    ,.out_valid(out_valid)
    ,.set_ifm(set_ifm)
    ,.set_wgt(set_wgt)
    ,.set_reg(set_reg)
    ,.end_conv(end_conv)
    ,.re_buffer(re_buffer)
    ,.rd_en(rd_en)
    ,.wr_en(wr_en)
    ,.addr_x(addr_x)
    ,.addr_y(addr_y)
  );

  genvar arr_i;
  genvar arr_j;
  generate
    for (arr_j = 0; arr_j < KERNEL_SIZE; arr_j = arr_j + 1)
      for (arr_i = 0; arr_i < KERNEL_SIZE; arr_i = arr_i + 1)
      begin
	      PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WEIGHT_WIDTH), .IFM_WIDTH(IFM_WIDTH), .POOLING(0)) pe (
	      		.clk(clk1)
	      	 ,.rst_n(rst_n)
	      	 ,.set_reg(set_reg)
	      	 ,.ifm(ifm_wire)
	      	 ,.wgt(wgt_wire[arr_i*KERNEL_SIZE+arr_j])
	      	 ,.psum_in(psum[arr_i][arr_j])
	      	 ,.psum_out(psum[arr_i][arr_j+1])
	      	 );
      end
  endgenerate
  
  genvar fifo_i;
  generate
    for (fifo_i = 0; fifo_i < KERNEL_SIZE-1; fifo_i = fifo_i + 1)
    begin
      FIFO_ASYNCH #(.DATA_WIDTH(DATA_WIDTH), .FIFO_SIZE(FIFO_SIZE), .ADD_WIDTH(ADD_WIDTH)) fifo(
	    	 .clk1  (clk1)
	    	,.clk2  (clk2)
	    	,.rd_clr(rd_clr)
	    	,.wr_clr(wr_clr)
	    	,.rd_inc(1'b1)
	    	,.wr_inc(1'b1)
	    	,.wr_en (wr_en[fifo_i])
	    	,.rd_en (rd_en[fifo_i])
	    	,.data_in_fifo (psum[fifo_i][KERNEL_SIZE])
	    	,.data_out_fifo(psum[fifo_i+1][0])
	    	);
    end
  endgenerate

  FIFO_ASYNCH_END #(.DATA_WIDTH(DATA_WIDTH), .FIFO_SIZE(FIFO_SIZE), .ADD_WIDTH(ADD_WIDTH)) fifo_end(
		 .clk1  (clk1)
		,.clk2  (clk2)
		,.rd_clr(rd_clr)
		,.wr_clr(wr_clr)
		,.rd_inc(1'b1)
		,.wr_inc(1'b1)
		,.wr_en (wr_en[KERNEL_SIZE-1])
		,.rd_en (rd_en[KERNEL_SIZE-1])
    ,.re_buffer(re_buffer)
    ,.psum_buffer(psum_buffer)
		,.data_in_fifo (psum[KERNEL_SIZE-1][KERNEL_SIZE])
		,.data_out_fifo(data_output_temp)
		);
  
  BUFFER #(.DATA_WIDTH(DATA_WIDTH), .IFM_SIZE(IFM_SIZE), .KERNEL_SIZE(KERNEL_SIZE), .STRIDE(STRIDE), .PAD(PAD)) buffer_psum(
     .clk(clk1)
    ,.addr_x(addr_x)
    ,.addr_y(addr_y)
    ,.d_in(data_output_temp)
    ,.d_out(psum_buffer)
    ,.we(rd_en[KERNEL_SIZE-1])
    ,.re(re_buffer)
  );

  genvar wgt_i;
  generate
    for (wgt_i = 0; wgt_i < KERNEL_SIZE*KERNEL_SIZE; wgt_i = wgt_i + 1)
    begin
	    WEIGHT_BUFF #(.DATA_WIDTH(WEIGHT_WIDTH)) wgt_buf (
          .clk(clk1)
         ,.rst_n(rst_n)
         ,.set_wgt(set_wgt[wgt_i])
         ,.wgt_in(wgt)
         ,.wgt_out(wgt_wire[wgt_i])
	    	 );
    end
  endgenerate

  IFM_BUFF #(.DATA_WIDTH(IFM_WIDTH)) ifm_buf (
       .clk(clk1)
      ,.rst_n(rst_n)
      ,.set_ifm(set_ifm)
      ,.ifm_in(ifm)
      ,.ifm_out(ifm_wire)
			);

  assign data_output = (RELU) ? ((data_output_temp[DATA_WIDTH-1]) ? 0 : data_output_temp) : data_output_temp; 

endmodule

