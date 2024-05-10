module TOP #(
  parameter 
    DATA_WIDTH = 16, 
    WEIGHT_WIDTH = 8, 
    IFM_WIDTH = 8, 
    FIFO_SIZE = 10, 
    IFM_SIZE = 9, 
    KERNEL_SIZE = 3, 
    CI = 3, 
    CO = 4
)(
	input clk1,
	input clk2,
	input rst_n,
	input set_wgt,
	input set_ifm,
  input start_conv,
	input [IFM_WIDTH-1:0] ifm,
	input [KERNEL_SIZE*KERNEL_SIZE*WEIGHT_WIDTH-1:0] wgt,
  output out_valid,
  output end_conv,
	output[DATA_WIDTH-1:0] data_output
	);

  localparam ADD_WIDTH = $clog2(IFM_SIZE-KERNEL_SIZE+1)+1;

	wire [DATA_WIDTH-1:0] psum [KERNEL_SIZE-1:0][KERNEL_SIZE:0];
	reg  [WEIGHT_WIDTH-1:0] weight [KERNEL_SIZE*KERNEL_SIZE-1:0];
	wire [WEIGHT_WIDTH-1:0] wgt_wire [KERNEL_SIZE*KERNEL_SIZE-1:0];
	wire [IFM_WIDTH-1:0] ifm_wire;

  genvar i;
  generate 
    for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1)
    begin
	    always @(*) begin
        weight[i] = wgt[WEIGHT_WIDTH*(KERNEL_SIZE*KERNEL_SIZE-i)-1:WEIGHT_WIDTH*(KERNEL_SIZE*KERNEL_SIZE-i-1)];
	    end
    end
  endgenerate

  assign psum[0][0] = 0;

  wire rd_clr;
  wire wr_clr;
  wire re_buffer;
  wire set_reg;
  wire [DATA_WIDTH-1:0] psum_buffer;
  wire [KERNEL_SIZE-1:0] wr_en;
  wire [KERNEL_SIZE-1:0] rd_en;
  wire [ADD_WIDTH:0] addr_x;
  wire [ADD_WIDTH:0] addr_y;
  wire [$clog2(CO)+1:0] addr_c;

  CONTROL #(.KERNEL_SIZE(KERNEL_SIZE), .IFM_SIZE(IFM_SIZE), .CI(CI), .CO(CO)) control (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.start_conv(start_conv)
    ,.rd_clr(rd_clr)
    ,.wr_clr(wr_clr)
    ,.out_valid(out_valid)
    ,.set_reg(set_reg)
    ,.end_conv(end_conv)
    ,.re_buffer(re_buffer)
    ,.rd_en(rd_en)
    ,.wr_en(wr_en)
    ,.addr_x(addr_x)
    ,.addr_y(addr_y)
    ,.addr_c(addr_c)
  );

  genvar arr_i;
  genvar arr_j;
  generate
    for (arr_i = 0; arr_i < KERNEL_SIZE; arr_i = arr_i + 1)
      for (arr_j = 0; arr_j < KERNEL_SIZE; arr_j = arr_j + 1)
      begin
	      PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WEIGHT_WIDTH), .DATA_OUT_WIDTH(DATA_WIDTH), .IFM_WIDTH(IFM_WIDTH)) pe (
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
		,.data_out_fifo(data_output)
		);
  
  BUFFER #(.DATA_WIDTH(DATA_WIDTH), .KERNEL_SIZE(KERNEL_SIZE), .DEPTH_H(IFM_SIZE-KERNEL_SIZE+1), .DEPTH_W(IFM_SIZE-KERNEL_SIZE+1), .CO(CO)) buffer_psum(
     .clk(clk1)
    ,.addr_x(addr_x)
    ,.addr_y(addr_y)
    ,.addr_c(addr_c)
    ,.d_in(data_output)
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
         ,.set_wgt(set_wgt)
         ,.wgt_in(weight[wgt_i])
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
endmodule

