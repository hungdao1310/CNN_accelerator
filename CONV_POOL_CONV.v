module CONV_POOL_CONV #(
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
    CO = 8,
    KERNEL_SIZE_1 = 3,
    STRIDE_1 = 1,
    PAD_1 = 2,
    RELU_1 = 1,
    KERNEL_POOL_1 = 3,
    STRIDE_POOL_1 = 2,
    CO_1 = 16
)(
	input clk1,
	input clk2,
	input rst_n,
  input start_conv,
	input [IFM_WIDTH-1:0] ifm,
	input [WEIGHT_WIDTH-1:0] wgt,
	input [WEIGHT_WIDTH-1:0] wgt_1,
  output ifm_read,
  output wgt_read,
  output wgt_read_1,
  output reg end_pool,
  output end_op,
  output pool_out_valid_1,
	output[DATA_WIDTH-1:0] data_output
	);

	wire [DATA_WIDTH-1:0] ifm_1;
  wire ifm_read_1;
  wire conv_out_valid;
  wire end_conv;
  wire end_conv_1;
  wire out_valid;
  wire [DATA_WIDTH-1:0] conv_out;
  wire [DATA_WIDTH-1:0] conv_out_1;
  wire [DATA_WIDTH-1:0] data_output_temp;
  wire end_pool_temp;

  localparam FIFO_SIZE_1 = (FIFO_SIZE-KERNEL_POOL)/STRIDE_POOL+1;
  localparam FIFO_SIZE_2 = (FIFO_SIZE_1-KERNEL_SIZE_1+2*PAD_1)/STRIDE_1+1;
  localparam FIFO_SIZE_3 = (FIFO_SIZE_2-KERNEL_POOL_1)/STRIDE_POOL_1+1;

  // Convolution 1
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

  // Pooling 1
  POOL
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.IFM_SIZE(FIFO_SIZE)
    ,.KERNEL_POOL(KERNEL_POOL)
    ,.STRIDE_POOL(STRIDE_POOL)
    ,.FIFO_SIZE(FIFO_SIZE_1)
    ,.CI(CO)
  ) pooling
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.in_valid(conv_out_valid)
    ,.ifm(conv_out)
    ,.out_valid(pool_out_valid)
    ,.end_pool(end_pool_temp)
    ,.data_output(data_output_temp)
  );

  RAM
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.DEPTH(CO*FIFO_SIZE_1*FIFO_SIZE_1)
  ) ram_1
  (
     .clk(clk2)
    ,.rst_n(rst_n)
    ,.wr_en(pool_out_valid)
    ,.rd_en(ifm_read_1)
    ,.data_in(data_output_temp)
    ,.data_out(ifm_1)
  );

  always @(posedge clk2)
  begin
    end_pool <= end_pool_temp;
  end

  // Convolution 2
  CONV 
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.WEIGHT_WIDTH(WEIGHT_WIDTH)
    ,.IFM_WIDTH(DATA_WIDTH)
    ,.IFM_SIZE(FIFO_SIZE_1)
    ,.KERNEL_SIZE(KERNEL_SIZE_1)
    ,.STRIDE(STRIDE_1)
    ,.PAD(PAD_1)
    ,.RELU(RELU_1)
    ,.FIFO_SIZE(FIFO_SIZE_2)
    ,.CI(CO)
    ,.CO(CO_1)
  ) convolution_1
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.start_conv(end_pool)
    ,.ifm(ifm_1)
    ,.wgt(wgt_1)
    ,.ifm_read(ifm_read_1)
    ,.wgt_read(wgt_read_1)
    ,.out_valid(conv_out_valid_1)
    ,.end_conv(end_conv_1)
    ,.data_output(conv_out_1)
  );

  // Pooling 2
  POOL
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.IFM_SIZE(FIFO_SIZE_2)
    ,.KERNEL_POOL(KERNEL_POOL_1)
    ,.STRIDE_POOL(STRIDE_POOL_1)
    ,.FIFO_SIZE(FIFO_SIZE_3)
    ,.CI(CO_1)
  ) pooling_1
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.in_valid(conv_out_valid_1)
    ,.ifm(conv_out_1)
    ,.out_valid(pool_out_valid_1)
    ,.end_pool(end_op)
    ,.data_output(data_output)
  );

endmodule
