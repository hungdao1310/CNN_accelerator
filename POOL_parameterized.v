module POOL #(
  parameter 
    DATA_WIDTH = 32, 
    IFM_SIZE = 27, 
    KERNEL_POOL = 5,
    STRIDE_POOL = 1,
    FIFO_SIZE = (IFM_SIZE-KERNEL_POOL)/STRIDE_POOL+1,
    CI = 3 
)(
	input clk1,
	input clk2,
	input rst_n,
  input in_valid,
	input [DATA_WIDTH-1:0] ifm,
  output end_pool,
  output out_valid,
	output[DATA_WIDTH-1:0] data_output
	);

  localparam ADD_WIDTH = $clog2(IFM_SIZE-KERNEL_POOL+1)+1;

  reg [DATA_WIDTH-1:0] ifm_temp;
	wire [DATA_WIDTH-1:0] psum [KERNEL_POOL-1:0][KERNEL_POOL:0];
	wire [DATA_WIDTH-1:0] ifm_wire;

  assign psum[0][0] = 0;

  wire rd_clr;
  wire wr_clr;
  wire set_ifm;
  wire set_reg;
  wire [KERNEL_POOL-1:0] wr_en;
  wire [KERNEL_POOL-1:0] rd_en;

  POOL_CONTROL #(.KERNEL_POOL(KERNEL_POOL), .IFM_SIZE(IFM_SIZE), .STRIDE_POOL(STRIDE_POOL), .CI(CI)) control (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.in_valid(in_valid)
    ,.rd_clr(rd_clr)
    ,.wr_clr(wr_clr)
    ,.out_valid(out_valid)
    ,.set_ifm(set_ifm)
    ,.set_reg(set_reg)
    ,.end_pool(end_pool)
    ,.rd_en(rd_en)
    ,.wr_en(wr_en)
  );

  genvar arr_i;
  genvar arr_j;
  generate
    for (arr_j = 0; arr_j < KERNEL_POOL; arr_j = arr_j + 1)
      for (arr_i = 0; arr_i < KERNEL_POOL; arr_i = arr_i + 1)
      begin
	      PE #(.IFM_WIDTH(DATA_WIDTH), .PSUM_WIDTH(DATA_WIDTH), .POOLING(1)) pe (
	      		.clk(clk1)
	      	 ,.rst_n(rst_n)
	      	 ,.set_reg(set_reg)
	      	 ,.ifm(ifm_wire)
           ,.wgt({8{1'b0}})
	      	 ,.psum_in(psum[arr_i][arr_j])
	      	 ,.psum_out(psum[arr_i][arr_j+1])
	      	 );
      end
  endgenerate
  
  genvar fifo_i;
  generate
    for (fifo_i = 0; fifo_i < KERNEL_POOL-1; fifo_i = fifo_i + 1)
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
	    	,.data_in_fifo (psum[fifo_i][KERNEL_POOL])
	    	,.data_out_fifo(psum[fifo_i+1][0])
	    	);
    end
  endgenerate

  // Fifo end
  FIFO_ASYNCH #(.DATA_WIDTH(DATA_WIDTH), .FIFO_SIZE(FIFO_SIZE), .ADD_WIDTH(ADD_WIDTH)) fifo(
		 .clk1  (clk1)
		,.clk2  (clk2)
		,.rd_clr(rd_clr)
		,.wr_clr(wr_clr)
		,.rd_inc(1'b1)
		,.wr_inc(1'b1)
		,.wr_en (wr_en[KERNEL_POOL-1])
		,.rd_en (rd_en[KERNEL_POOL-1])
		,.data_in_fifo (psum[KERNEL_POOL-1][KERNEL_POOL])
		,.data_out_fifo(data_output)
		);

  always @(posedge clk2)
  begin
    ifm_temp <= ifm;
  end

  IFM_BUFF #(.DATA_WIDTH(DATA_WIDTH)) ifm_buf (
       .clk(clk1)
      ,.rst_n(rst_n)
      ,.set_ifm(set_ifm)
      ,.ifm_in(ifm_temp)
      ,.ifm_out(ifm_wire)
			);

endmodule
