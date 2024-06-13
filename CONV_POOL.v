module CONV_POOL #(
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
    KERNEL_POOL = 3,
    STRIDE_POOL = 2,
    CI = 3, 
    CO = 8
)(
	input clk1,
	input clk2,
	input rst_n,
  input start_conv,
	input [IFM_WIDTH-1:0] ifm,
	input [WEIGHT_WIDTH-1:0] wgt,
  output ifm_read,
  output wgt_read,
  output end_pool,
  output out_valid,
	output[DATA_WIDTH-1:0] data_output
	);

  wire conv_out_valid;
  wire [DATA_WIDTH-1:0] conv_out;

  CONV 
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.WEIGHT_WIDTH(WEIGHT_WIDTH)
    ,.IFM_WIDTH(IFM_WIDTH)
    ,.IFM_SIZE(IFM_SIZE)
    ,.KERNEL_SIZE(KERNEL_SIZE)
    ,.STRIDE(STRIDE)
    ,.PAD(PAD)
    ,.RELU(RELU)
    ,.FIFO_SIZE(FIFO_SIZE)
    ,.CI(CI)
    ,.CO(CO)
  ) convolution
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.start_conv(start_conv)
    ,.ifm(ifm)
    ,.wgt(wgt)
    ,.ifm_read(ifm_read)
    ,.wgt_read(wgt_read)
    ,.out_valid(conv_out_valid)
    ,.end_conv(end_conv)
    ,.data_output(conv_out)
  );

  POOL
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.IFM_SIZE(FIFO_SIZE)
    ,.KERNEL_POOL(KERNEL_POOL)
    ,.STRIDE_POOL(STRIDE_POOL)
    ,.FIFO_SIZE((FIFO_SIZE-KERNEL_POOL)/STRIDE_POOL+1)
    ,.CI(CO)
  ) pooling
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.in_valid(conv_out_valid)
    ,.ifm(conv_out)
    ,.out_valid(out_valid)
    ,.end_pool(end_pool)
    ,.data_output(data_output)
  );

endmodule
