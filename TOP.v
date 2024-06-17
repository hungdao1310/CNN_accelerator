module TOP #(
  parameter 
    DATA_WIDTH = 32, 
    WEIGHT_WIDTH = 8, 
    IFM_WIDTH = 16,  
    IFM_SIZE = 27, 
    // Convolution 1
    KERNEL_SIZE = 5,
    STRIDE = 1,
    PAD = 2,
    RELU = 1,
    CI = 3, 
    CO = 8,
    // Pooling 1
    KERNEL_POOL = 3,
    STRIDE_POOL = 2,
    // Convolution 2
    KERNEL_SIZE_1 = 3,
    STRIDE_1 = 1,
    PAD_1 = 2,
    RELU_1 = 1,
    CO_1 = 16,
    // Pooling 2
    KERNEL_POOL_1 = 3,
    STRIDE_POOL_1 = 2,
    // Convolution 3
    KERNEL_SIZE_2 = 3,
    STRIDE_2 = 1,
    PAD_2 = 2,
    RELU_2 = 1,
    CO_2 = 64,
    // Convolution 4
    KERNEL_SIZE_3 = 3,
    STRIDE_3 = 1,
    PAD_3 = 2,
    RELU_3 = 1,
    CO_3 = 64,
    // Convolution 5
    KERNEL_SIZE_4 = 3,
    STRIDE_4 = 1,
    PAD_4 = 2,
    RELU_4 = 1,
    CO_4 = 64,
    // Pooling 3
    KERNEL_POOL_2 = 3,
    STRIDE_POOL_2 = 2,
    // FC1
    IN_FEATURE_1 = 360,
    OUT_FEATURE_1 = 160,
    // FC2
    IN_FEATURE_2 = 160,
    OUT_FEATURE_2 = 80,
    // FC3
    IN_FEATURE_3 = 80,
    OUT_FEATURE_3 = 40
)(
	input clk1,
	input clk2,
	input rst_n,
  input start_conv,
	input [IFM_WIDTH-1:0] ifm,
	input [WEIGHT_WIDTH-1:0] wgt,
	input [WEIGHT_WIDTH-1:0] wgt_1,
	input [WEIGHT_WIDTH-1:0] wgt_2,
	input [WEIGHT_WIDTH-1:0] wgt_3,
	input [WEIGHT_WIDTH-1:0] wgt_4,
	input [8*WEIGHT_WIDTH-1:0] wgt_fc1,
	input [8*WEIGHT_WIDTH-1:0] wgt_fc2,
	input [8*WEIGHT_WIDTH-1:0] wgt_fc3,
  output ifm_read,
  output wgt_read,
  output wgt_read_1,
  output wgt_read_2,
  output wgt_read_3,
  output wgt_read_4,
  output wgt_read_fc_1,
  output wgt_read_fc_2,
  output wgt_read_fc_3,
  output end_pool,
  output end_pool_1,
  output end_pool_2,
  output end_conv_2,
  output end_conv_3,
  output end_op,
  output out_valid,
	output[DATA_WIDTH-1:0] data_output
	);

	wire [DATA_WIDTH-1:0] ifm_1;
	wire [DATA_WIDTH-1:0] ifm_2;
	wire [DATA_WIDTH-1:0] ifm_3;
	wire [DATA_WIDTH-1:0] ifm_4;
  wire ifm_read_1;
  wire ifm_read_2;
  wire ifm_read_3;
  wire ifm_read_4;
  wire conv_out_valid;
  wire conv_out_valid_1;
  wire conv_out_valid_2;
  wire conv_out_valid_3;
  wire conv_out_valid_4;
  wire fc_out_valid_1;
  wire fc_out_valid_2;
  wire fc_out_valid_3;
  wire end_conv;
  wire end_conv_1;
  wire end_conv_2;
  wire end_conv_3;
  wire end_conv_4;
  wire end_pool;
  wire end_pool_1;
  wire end_pool_2;
  wire [DATA_WIDTH-1:0] conv_out;
  wire [DATA_WIDTH-1:0] conv_out_1;
  wire [DATA_WIDTH-1:0] conv_out_2;
  wire [DATA_WIDTH-1:0] conv_out_3;
  wire [DATA_WIDTH-1:0] conv_out_4;
  wire [DATA_WIDTH-1:0] pool_out;
  wire [DATA_WIDTH-1:0] pool_out_1;
  wire [DATA_WIDTH-1:0] pool_out_2;
  wire [DATA_WIDTH-1:0] out_fc1;
  wire [DATA_WIDTH-1:0] out_fc2;
  wire [DATA_WIDTH-1:0] out_fc3;

  localparam FIFO_SIZE = (IFM_SIZE-KERNEL_SIZE+2*PAD)/STRIDE+1;
  localparam FIFO_SIZE_1 = (FIFO_SIZE-KERNEL_POOL)/STRIDE_POOL+1;
  localparam FIFO_SIZE_2 = (FIFO_SIZE_1-KERNEL_SIZE_1+2*PAD_1)/STRIDE_1+1;
  localparam FIFO_SIZE_3 = (FIFO_SIZE_2-KERNEL_POOL_1)/STRIDE_POOL_1+1;
  localparam FIFO_SIZE_4 = (FIFO_SIZE_3-KERNEL_SIZE_2+2*PAD_2)/STRIDE_2+1;
  localparam FIFO_SIZE_5 = (FIFO_SIZE_4-KERNEL_SIZE_3+2*PAD_3)/STRIDE_3+1;
  localparam FIFO_SIZE_6 = (FIFO_SIZE_5-KERNEL_SIZE_4+2*PAD_4)/STRIDE_4+1;
  localparam FIFO_SIZE_7 = (FIFO_SIZE_6-KERNEL_POOL_2)/STRIDE_POOL_2+1;

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
    ,.end_pool(end_pool)
    ,.data_output(pool_out)
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
    ,.data_in(pool_out)
    ,.data_out(ifm_1)
  );

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
    ,.end_pool(end_pool_1)
    ,.data_output(pool_out_1)
  );

  RAM
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.DEPTH(CO_1*FIFO_SIZE_3*FIFO_SIZE_3)
  ) ram_2
  (
     .clk(clk2)
    ,.rst_n(rst_n)
    ,.wr_en(pool_out_valid_1)
    ,.rd_en(ifm_read_2)
    ,.data_in(pool_out_1)
    ,.data_out(ifm_2)
  );

  // Convolution 3
  CONV 
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.WEIGHT_WIDTH(WEIGHT_WIDTH)
    ,.IFM_WIDTH(DATA_WIDTH)
    ,.IFM_SIZE(FIFO_SIZE_3)
    ,.KERNEL_SIZE(KERNEL_SIZE_2)
    ,.STRIDE(STRIDE_2)
    ,.PAD(PAD_2)
    ,.RELU(RELU_2)
    ,.FIFO_SIZE(FIFO_SIZE_4)
    ,.CI(CO_1)
    ,.CO(CO_2)
  ) convolution_2
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.start_conv(end_pool_1)
    ,.ifm(ifm_2)
    ,.wgt(wgt_2)
    ,.ifm_read(ifm_read_2)
    ,.wgt_read(wgt_read_2)
    ,.out_valid(conv_out_valid_2)
    ,.end_conv(end_conv_2)
    ,.data_output(conv_out_2)
  );

  RAM
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.DEPTH(CO_2*FIFO_SIZE_4*FIFO_SIZE_4)
  ) ram_3
  (
     .clk(clk2)
    ,.rst_n(rst_n)
    ,.wr_en(conv_out_valid_2)
    ,.rd_en(ifm_read_3)
    ,.data_in(conv_out_2)
    ,.data_out(ifm_3)
  );

  // Convolution 4
  CONV 
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.WEIGHT_WIDTH(WEIGHT_WIDTH)
    ,.IFM_WIDTH(DATA_WIDTH)
    ,.IFM_SIZE(FIFO_SIZE_4)
    ,.KERNEL_SIZE(KERNEL_SIZE_3)
    ,.STRIDE(STRIDE_3)
    ,.PAD(PAD_3)
    ,.RELU(RELU_3)
    ,.FIFO_SIZE(FIFO_SIZE_5)
    ,.CI(CO_2)
    ,.CO(CO_3)
  ) convolution_3
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.start_conv(end_conv_2)
    ,.ifm(ifm_3)
    ,.wgt(wgt_3)
    ,.ifm_read(ifm_read_3)
    ,.wgt_read(wgt_read_3)
    ,.out_valid(conv_out_valid_3)
    ,.end_conv(end_conv_3)
    ,.data_output(conv_out_3)
  );

  RAM
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.DEPTH(CO_3*FIFO_SIZE_5*FIFO_SIZE_5)
  ) ram_4
  (
     .clk(clk2)
    ,.rst_n(rst_n)
    ,.wr_en(conv_out_valid_3)
    ,.rd_en(ifm_read_4)
    ,.data_in(conv_out_3)
    ,.data_out(ifm_4)
  );

  // Convolution 5
  CONV 
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.WEIGHT_WIDTH(WEIGHT_WIDTH)
    ,.IFM_WIDTH(DATA_WIDTH)
    ,.IFM_SIZE(FIFO_SIZE_5)
    ,.KERNEL_SIZE(KERNEL_SIZE_4)
    ,.STRIDE(STRIDE_4)
    ,.PAD(PAD_4)
    ,.RELU(RELU_4)
    ,.FIFO_SIZE(FIFO_SIZE_6)
    ,.CI(CO_3)
    ,.CO(CO_4)
  ) convolution_4
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.start_conv(end_conv_3)
    ,.ifm(ifm_4)
    ,.wgt(wgt_4)
    ,.ifm_read(ifm_read_4)
    ,.wgt_read(wgt_read_4)
    ,.out_valid(conv_out_valid_4)
    ,.end_conv(end_conv_4)
    ,.data_output(conv_out_4)
  );

  // Pooling 3
  POOL
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.IFM_SIZE(FIFO_SIZE_6)
    ,.KERNEL_POOL(KERNEL_POOL_2)
    ,.STRIDE_POOL(STRIDE_POOL_2)
    ,.FIFO_SIZE(FIFO_SIZE_7)
    ,.CI(CO_4)
  ) pooling_2
  (
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)
    ,.in_valid(conv_out_valid_4)
    ,.ifm(conv_out_4)
    ,.out_valid(pool_out_valid_2)
    ,.end_pool(end_pool_2)
    ,.data_output(pool_out_2)
  );

  // FC1
  FC 
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.IFM_WIDTH(DATA_WIDTH)
    ,.WGT_WIDTH(8)
    ,.IFM_SIZE(360)
    ,.TILING_SIZE(8)
    ,.KERNEL_SIZE(160)
  ) fully_1 (
		 .clk1(clk1)        
    ,.clk2(clk2)
    ,.rst_n(rst_n)   
    ,.ifm(pool_out_2)
    ,.valid_ifm(pool_out_valid_2)
    ,.wgt_read(wgt_read_fc_1)
    ,.wgt(wgt_fc1)
    ,.ofm(out_fc1)  
		,.valid_data(fc_out_valid_1)
	);

  // FC2
  FC 
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.IFM_WIDTH(DATA_WIDTH)
    ,.WGT_WIDTH(8)
    ,.IFM_SIZE(160)
    ,.TILING_SIZE(8)
    ,.KERNEL_SIZE(80)
  ) fully_2 (
		 .clk1(clk1)        
    ,.clk2(clk2)
    ,.rst_n(rst_n)   
    ,.ifm(out_fc1)
    ,.valid_ifm(fc_out_valid_1)
    ,.wgt_read(wgt_read_fc_2)
    ,.wgt(wgt_fc2)
    ,.ofm(out_fc2)  
		,.valid_data(fc_out_valid_2)
	);

  // FC3
  FC 
  #(
     .DATA_WIDTH(DATA_WIDTH)
    ,.IFM_WIDTH(DATA_WIDTH)
    ,.WGT_WIDTH(8)
    ,.IFM_SIZE(80)
    ,.TILING_SIZE(8)
    ,.KERNEL_SIZE(40)
  ) fully_3 (
		 .clk1(clk1)        
    ,.clk2(clk2)
    ,.rst_n(rst_n)   
    ,.ifm(out_fc2)
    ,.valid_ifm(fc_out_valid_2)
    ,.wgt_read(wgt_read_fc_3)
    ,.wgt(wgt_fc3)
    ,.ofm(out_fc3)  
		,.valid_data(fc_out_valid_3)
	);

  assign data_output = out_fc3;
  assign out_valid = fc_out_valid_3;
  assign end_op = 1;

endmodule
