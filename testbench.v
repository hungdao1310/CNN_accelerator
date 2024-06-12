`timescale 1 ns / 10 ps
module tb();

parameter DATA_WIDTH = 32;
parameter WEIGHT_WIDTH = 8;
parameter IFM_WIDTH = 16;
parameter IFM_SIZE = 227;
// Convolution 1
parameter KERNEL_SIZE = 11;
parameter STRIDE = 4;
parameter PAD = 0;
parameter RELU = 1;
parameter CI = 1;
parameter CO = 2;
// Max pooling_1
parameter KERNEL_POOL = 3;
parameter STRIDE_POOL = 2;
// Convolution 2
parameter KERNEL_SIZE_1 = 5;
parameter STRIDE_1 = 1;
parameter PAD_1 = 2;
parameter RELU_1 = 1;
parameter CO_1 = 4;
// Max pooling_2
parameter KERNEL_POOL_1 = 3;
parameter STRIDE_POOL_1 = 2;
// Convolution 3
parameter KERNEL_SIZE_2 = 3;
parameter STRIDE_2 = 1;
parameter PAD_2 = 1;
parameter RELU_2 = 1;
parameter CO_2 = 6;
// Convolution 4
parameter KERNEL_SIZE_3 = 3;
parameter STRIDE_3 = 1;
parameter PAD_3 = 1;
parameter RELU_3 = 1;
parameter CO_3 = 8;
// Convolution 5
parameter KERNEL_SIZE_4 = 3;
parameter STRIDE_4 = 1;
parameter PAD_4 = 1;
parameter RELU_4 = 1;
parameter CO_4 = 10;
// Max pooling_2
parameter KERNEL_POOL_2 = 3;
parameter STRIDE_POOL_2 = 2;
// FC 1
parameter IN_FEATURE_1  = 360;
parameter OUT_FEATURE_1 = 160;
// FC 2
parameter OUT_FEATURE_2 = 80;
// FC 3
parameter OUT_FEATURE_3 = 40;

  // Local param
  localparam FIFO_SIZE = (IFM_SIZE-KERNEL_SIZE+2*PAD)/STRIDE+1;
  localparam FIFO_SIZE_1 = (FIFO_SIZE-KERNEL_POOL)/STRIDE_POOL+1;
  localparam FIFO_SIZE_2 = (FIFO_SIZE_1-KERNEL_SIZE_1+2*PAD_1)/STRIDE_1+1;
  localparam FIFO_SIZE_3 = (FIFO_SIZE_2-KERNEL_POOL_1)/STRIDE_POOL_1+1;
  localparam FIFO_SIZE_4 = (FIFO_SIZE_3-KERNEL_SIZE_2+2*PAD_2)/STRIDE_2+1;
  localparam FIFO_SIZE_5 = (FIFO_SIZE_4-KERNEL_SIZE_3+2*PAD_3)/STRIDE_3+1;
  localparam FIFO_SIZE_6 = (FIFO_SIZE_5-KERNEL_SIZE_4+2*PAD_4)/STRIDE_4+1;
  localparam FIFO_SIZE_7 = (FIFO_SIZE_6-KERNEL_POOL_2)/STRIDE_POOL_2+1;
  localparam OFM = FIFO_SIZE_7;

	reg clk1;
	reg clk2;
	reg rst_n;
	reg start_conv;
	wire [IFM_WIDTH-1:0] ifm;
	wire [WEIGHT_WIDTH-1:0] wgt;
	wire [WEIGHT_WIDTH-1:0] wgt_1;
	wire [WEIGHT_WIDTH-1:0] wgt_2;
	wire [WEIGHT_WIDTH-1:0] wgt_3;
	wire [WEIGHT_WIDTH-1:0] wgt_4;
	wire [8*WEIGHT_WIDTH-1:0] wgt_fc1;
	wire [8*WEIGHT_WIDTH-1:0] wgt_fc2;
	wire [8*WEIGHT_WIDTH-1:0] wgt_fc3;
  wire ifm_read;
  wire wgt_read;
  wire wgt_read_1;
  wire wgt_read_2;
  wire wgt_read_3;
  wire wgt_read_4;
  wire wgt_read_fc_1;
  wire wgt_read_fc_2;
  wire wgt_read_fc_3;
  wire end_pool;
  wire end_pool_1;
  wire end_conv_2;
  wire end_conv_3;
  wire end_op;
  wire out_valid;
	wire [DATA_WIDTH-1:0] data_output;
  
	//initial begin
	//	$dumpfile("CONV_POOL_CONV.vcd");
	//	$dumpvars(0,tb);
	//end

  TOP #(
    .DATA_WIDTH(DATA_WIDTH), 
    .WEIGHT_WIDTH(WEIGHT_WIDTH), 
    .IFM_WIDTH(IFM_WIDTH), 
    .IFM_SIZE(IFM_SIZE),
    // Convolution 1 
    .KERNEL_SIZE(KERNEL_SIZE), 
    .STRIDE(STRIDE),
    .PAD(PAD),
    .RELU(RELU),
    .CI(CI), 
    .CO(CO),
    // Pooling 1
    .KERNEL_POOL(KERNEL_POOL),
    .STRIDE_POOL(STRIDE_POOL),
    // Convolution 2
    .KERNEL_SIZE_1(KERNEL_SIZE_1),
    .STRIDE_1(STRIDE_1),
    .PAD_1(PAD_1),
    .RELU_1(RELU_1),
    .CO_1(CO_1),
    // Pooling 2
    .KERNEL_POOL_1(KERNEL_POOL_1),
    .STRIDE_POOL_1(STRIDE_POOL_1),
    // Convolution 3
    .KERNEL_SIZE_2(KERNEL_SIZE_2),
    .STRIDE_2(STRIDE_2),
    .PAD_2(PAD_2),
    .RELU_2(RELU_2),
    .CO_2(CO_2),
    // Convolution 4
    .KERNEL_SIZE_3(KERNEL_SIZE_3),
    .STRIDE_3(STRIDE_3),
    .PAD_3(PAD_3),
    .RELU_3(RELU_3),
    .CO_3(CO_3),
    // Convolution 5
    .KERNEL_SIZE_4(KERNEL_SIZE_4),
    .STRIDE_4(STRIDE_4),
    .PAD_4(PAD_4),
    .RELU_4(RELU_4),
    .CO_4(CO_4),
    // Pooling 3
    .KERNEL_POOL_2(KERNEL_POOL_2),
    .STRIDE_POOL_2(STRIDE_POOL_2),
    // FC1
    .IN_FEATURE_1(IN_FEATURE_1),
    .OUT_FEATURE_1(OUT_FEATURE_1),
    // FC2
    .IN_FEATURE_2(OUT_FEATURE_1),
    .OUT_FEATURE_2(OUT_FEATURE_2),
    // FC3
    .IN_FEATURE_3(OUT_FEATURE_2),
    .OUT_FEATURE_3(OUT_FEATURE_3)
  ) top_module(
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)                    	
    ,.start_conv(start_conv)
    ,.ifm(ifm)
		,.wgt(wgt)
		,.wgt_1(wgt_1)
		,.wgt_2(wgt_2)
		,.wgt_3(wgt_3)
		,.wgt_4(wgt_4)
    ,.wgt_fc1(wgt_fc1)
    ,.wgt_fc2(wgt_fc2)
    ,.wgt_fc3(wgt_fc3)
    ,.ifm_read(ifm_read)
    ,.wgt_read(wgt_read)
    ,.wgt_read_1(wgt_read_1)
    ,.wgt_read_2(wgt_read_2)
    ,.wgt_read_3(wgt_read_3)
    ,.wgt_read_4(wgt_read_4)
    ,.wgt_read_fc_1(wgt_read_fc_1)
    ,.wgt_read_fc_2(wgt_read_fc_2)
    ,.wgt_read_fc_3(wgt_read_fc_3)
    ,.end_pool(end_pool)
    ,.end_pool_1(end_pool_1)
    ,.end_conv_2(end_conv_2)
    ,.end_conv_3(end_conv_3)
    ,.end_op(end_op)
    ,.out_valid(out_valid)
    ,.data_output(data_output)
		);

	always #5 clk1 = ~clk1;
	always @(clk1) begin
		clk2 = ~clk1;
	end

  // Read ifm
  reg [IFM_WIDTH-1:0] ifm_in [0:CI*IFM_SIZE*IFM_SIZE-1];
  reg [17:0] ifm_cnt;
  reg ifm_read_reg;
  initial begin
    $readmemb("./ifm.txt", ifm_in);
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      ifm_cnt       <= 0;
      ifm_read_reg  <= 0;
    end
    else
    begin
      ifm_read_reg <= ifm_read;
      if ((start_conv && !ifm_read) || ifm_cnt == CI*IFM_SIZE*IFM_SIZE)
        ifm_cnt   <= 0;
      else if (ifm_read)
        ifm_cnt   <= ifm_cnt + 1;
      else
        ifm_cnt   <= ifm_cnt;
    end
  end

  assign ifm = (ifm_read_reg == 1) ? ifm_in[ifm_cnt-1] : 0;

  // Read weight
  reg [WEIGHT_WIDTH-1:0] wgt_in [0:CO*CI*KERNEL_SIZE*KERNEL_SIZE-1];
  reg [17:0] wgt_cnt;
  reg wgt_read_reg;
  initial begin
    $readmemb("./weight.txt", wgt_in);
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      wgt_cnt       <= 0;
      wgt_read_reg  <= 0;
    end
    else
    begin
      wgt_read_reg <= wgt_read;
      if (wgt_cnt == CO*CI*KERNEL_SIZE*KERNEL_SIZE)
        wgt_cnt   <= 0;
      else if (wgt_read || start_conv)
        wgt_cnt   <= wgt_cnt + 1;
      else
        wgt_cnt   <= wgt_cnt;
    end
  end

  assign wgt = (wgt_read_reg == 1) ? wgt_in[wgt_cnt-1] : 0;

  // Read weight_1
  reg [WEIGHT_WIDTH-1:0] wgt_in_1 [0:CO_1*CO*KERNEL_SIZE_1*KERNEL_SIZE_1-1];
  reg [17:0] wgt_cnt_1;
  reg wgt_read_reg_1;
  initial begin
    $readmemb("./weight1.txt", wgt_in_1);
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      wgt_cnt_1       <= 0;
      wgt_read_reg_1  <= 0;
    end
    else
    begin
      wgt_read_reg_1 <= wgt_read_1;
      if (wgt_cnt_1 == CO_1*CO*KERNEL_SIZE_1*KERNEL_SIZE_1)
        wgt_cnt_1   <= 0;
      else if (wgt_read_1 || end_pool)
        wgt_cnt_1   <= wgt_cnt_1 + 1;
      else
        wgt_cnt_1   <= wgt_cnt_1;
    end
  end

  assign wgt_1 = (wgt_read_reg_1 == 1) ? wgt_in_1[wgt_cnt_1-1] : 0;

  // Read weight_2
  reg [WEIGHT_WIDTH-1:0] wgt_in_2 [0:CO_2*CO_1*KERNEL_SIZE_2*KERNEL_SIZE_2-1];
  reg [17:0] wgt_cnt_2;
  reg wgt_read_reg_2;
  initial begin
    $readmemb("./weight2.txt", wgt_in_2);
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      wgt_cnt_2       <= 0;
      wgt_read_reg_2  <= 0;
    end
    else
    begin
      wgt_read_reg_2 <= wgt_read_2;
      if (wgt_cnt_2 == CO_2*CO_1*KERNEL_SIZE_2*KERNEL_SIZE_2)
        wgt_cnt_2   <= 0;
      else if (wgt_read_2 || end_pool_1)
        wgt_cnt_2   <= wgt_cnt_2 + 1;
      else
        wgt_cnt_2   <= wgt_cnt_2;
    end
  end

  assign wgt_2 = (wgt_read_reg_2 == 1) ? wgt_in_2[wgt_cnt_2-1] : 0;

  // Read weight_3
  reg [WEIGHT_WIDTH-1:0] wgt_in_3 [0:CO_3*CO_2*KERNEL_SIZE_3*KERNEL_SIZE_3-1];
  reg [17:0] wgt_cnt_3;
  reg wgt_read_reg_3;
  initial begin
    $readmemb("./weight3.txt", wgt_in_3);
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      wgt_cnt_3       <= 0;
      wgt_read_reg_3  <= 0;
    end
    else
    begin
      wgt_read_reg_3 <= wgt_read_3;
      if (wgt_cnt_3 == CO_3*CO_2*KERNEL_SIZE_3*KERNEL_SIZE_3)
        wgt_cnt_3   <= 0;
      else if (wgt_read_3 || end_conv_2)
        wgt_cnt_3   <= wgt_cnt_3 + 1;
      else
        wgt_cnt_3   <= wgt_cnt_3;
    end
  end

  assign wgt_3 = (wgt_read_reg_3 == 1) ? wgt_in_3[wgt_cnt_3-1] : 0;

  // Read weight_4
  reg [WEIGHT_WIDTH-1:0] wgt_in_4 [0:CO_4*CO_3*KERNEL_SIZE_4*KERNEL_SIZE_4-1];
  reg [17:0] wgt_cnt_4;
  reg wgt_read_reg_4;
  initial begin
    $readmemb("./weight4.txt", wgt_in_4);
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      wgt_cnt_4       <= 0;
      wgt_read_reg_4  <= 0;
    end
    else
    begin
      wgt_read_reg_4 <= wgt_read_4;
      if (wgt_cnt_4 == CO_4*CO_3*KERNEL_SIZE_4*KERNEL_SIZE_4)
        wgt_cnt_4   <= 0;
      else if (wgt_read_4 || end_conv_3)
        wgt_cnt_4   <= wgt_cnt_4 + 1;
      else
        wgt_cnt_4   <= wgt_cnt_4;
    end
  end

  assign wgt_4 = (wgt_read_reg_4 == 1) ? wgt_in_4[wgt_cnt_4-1] : 0;

  reg [WEIGHT_WIDTH-1:0] wgt_in_fc1 [0:360*160-1];
  reg [WEIGHT_WIDTH-1:0] wgt_in_fc2 [0:160*80-1];
  reg [WEIGHT_WIDTH-1:0] wgt_in_fc3 [0:80*40-1];
  reg [31:0] wgt_cnt_fc1;
  reg [31:0] wgt_cnt_fc2;
  reg [31:0] wgt_cnt_fc3;
  reg [63:0] wgt_r1;
  reg [63:0] wgt_r2;
  reg [63:0] wgt_r3;
  initial begin
      $readmemb("./weight_fc1.txt", wgt_in_fc1);
  end 
  initial begin
      $readmemb("./weight_fc2.txt", wgt_in_fc2);
  end 
  initial begin
      $readmemb("./weight_fc3.txt", wgt_in_fc3);
  end 

  always @(*) begin
      if (!rst_n) begin
          wgt_r1 = 0;
      end else if (wgt_read_fc_1) begin
          wgt_r1[7:0]   = wgt_in_fc1[wgt_cnt_fc1+0];
          wgt_r1[15:8]  = wgt_in_fc1[wgt_cnt_fc1+1];
          wgt_r1[23:16] = wgt_in_fc1[wgt_cnt_fc1+2];
          wgt_r1[31:24] = wgt_in_fc1[wgt_cnt_fc1+3];
          wgt_r1[39:32] = wgt_in_fc1[wgt_cnt_fc1+4];
          wgt_r1[47:40] = wgt_in_fc1[wgt_cnt_fc1+5];
          wgt_r1[55:48] = wgt_in_fc1[wgt_cnt_fc1+6];
          wgt_r1[63:56] = wgt_in_fc1[wgt_cnt_fc1+7];
      end else
          wgt_r1 = 0;
  end 

  always @(posedge clk1 or negedge rst_n) begin
      if (!rst_n)
          wgt_cnt_fc1 <= 0;
      else if (wgt_cnt_fc1 == 360*160 && !wgt_read_fc_1)
          wgt_cnt_fc1 <= 0;
      else if (wgt_read_fc_1)
          wgt_cnt_fc1 <= wgt_cnt_fc1 + 8;
      else
          wgt_cnt_fc1 <= wgt_cnt_fc1;
  end
  assign wgt_fc1 = wgt_r1;

  always @(*) begin
      if (!rst_n) begin
          wgt_r2 = 0;
      end else if (wgt_read_fc_2) begin
          wgt_r2[7:0]   = wgt_in_fc2[wgt_cnt_fc2+0];
          wgt_r2[15:8]  = wgt_in_fc2[wgt_cnt_fc2+1];
          wgt_r2[23:16] = wgt_in_fc2[wgt_cnt_fc2+2];
          wgt_r2[31:24] = wgt_in_fc2[wgt_cnt_fc2+3];
          wgt_r2[39:32] = wgt_in_fc2[wgt_cnt_fc2+4];
          wgt_r2[47:40] = wgt_in_fc2[wgt_cnt_fc2+5];
          wgt_r2[55:48] = wgt_in_fc2[wgt_cnt_fc2+6];
          wgt_r2[63:56] = wgt_in_fc2[wgt_cnt_fc2+7];
      end else
          wgt_r1 = 0;
  end 
  always @(posedge clk1 or negedge rst_n) begin
      if (!rst_n)
          wgt_cnt_fc2 <= 0;
      else if (wgt_cnt_fc2 == 160*80 && !wgt_read_fc_2)
          wgt_cnt_fc2 <= 0;
      else if (wgt_read_fc_2)
          wgt_cnt_fc2 <= wgt_cnt_fc2 + 8;
      else
          wgt_cnt_fc2 <= wgt_cnt_fc2;
  end
  assign wgt_fc2 = wgt_r2;

  always @(*) begin
      if (!rst_n) begin
          wgt_r3 = 0;
      end else if (wgt_read_fc_3) begin
          wgt_r3[7:0]   = wgt_in_fc3[wgt_cnt_fc3+0];
          wgt_r3[15:8]  = wgt_in_fc3[wgt_cnt_fc3+1];
          wgt_r3[23:16] = wgt_in_fc3[wgt_cnt_fc3+2];
          wgt_r3[31:24] = wgt_in_fc3[wgt_cnt_fc3+3];
          wgt_r3[39:32] = wgt_in_fc3[wgt_cnt_fc3+4];
          wgt_r3[47:40] = wgt_in_fc3[wgt_cnt_fc3+5];
          wgt_r3[55:48] = wgt_in_fc3[wgt_cnt_fc3+6];
          wgt_r3[63:56] = wgt_in_fc3[wgt_cnt_fc3+7];
      end else
          wgt_r3 = 0;
  end 
  always @(posedge clk1 or negedge rst_n) begin
      if (!rst_n)
          wgt_cnt_fc3 <= 0;
      else if (wgt_cnt_fc3 == 800*40 && !wgt_read_fc_3)
          wgt_cnt_fc3 <= 0;
      else if (wgt_read_fc_3)
          wgt_cnt_fc3 <= wgt_cnt_fc3 + 8;
      else
          wgt_cnt_fc3 <= wgt_cnt_fc3;
  end
  assign wgt_fc3 = wgt_r3;


  integer ofm_rtl;
  integer ow;

  task read_output;
    input [DATA_WIDTH-1:0] data_output;
    input out_valid;
    reg signed [DATA_WIDTH-1:0] ofm [0:OUT_FEATURE_3-1];
    integer tow;

    begin
      if (ow < OUT_FEATURE_3)
      begin
        if (out_valid)
        begin
          ofm[ow] = data_output;
          ow = ow + 1;
        end
      end
      else
      begin
        for (tow = 0; tow < OUT_FEATURE_3; tow = tow + 1)
          $fwrite(ofm_rtl, "%d \n", ofm[tow]);
        $fclose(ofm_rtl);
        #10 $finish;
      end
    end
  endtask

  //task read_output;
  //  input [DATA_WIDTH-1:0] data_output;
  //  input out_valid;
  //  input end_op;
  //  reg signed [DATA_WIDTH-1:0] ofm [0:CO_4-1][0:OFM-1][0:OFM-1];
  //  integer toc;
  //  integer toh;
  //  integer tow;

  //  begin
  //    if (oc < CO_4)
  //    begin
  //      if (out_valid)
  //      begin
  //        ofm[oc][oh][ow] = data_output;
  //        ow = ow + 1;
  //        if (ow == OFM)
  //        begin
  //          ow = 0;
  //          oh = oh + 1;
  //          if (oh == OFM)
  //          begin
  //            oh = 0;
  //            oc = oc + 1;
  //          end
  //        end
  //      end
  //    end
  //    if (end_op)
  //    begin
  //      for (toc = 0; toc < CO_4; toc = toc + 1)
  //      begin
  //        for (toh = 0; toh < OFM; toh = toh + 1)
  //        begin
  //          for (tow = 0; tow < OFM; tow = tow + 1)
  //            $fwrite(ofm_rtl, "%d ", ofm[toc][toh][tow]);
  //          $fwrite(ofm_rtl, "\n");
  //        end
  //        $fwrite(ofm_rtl, "\n");
  //      end
  //      $display("Finish writing results to ofm_rtl.txt");
  //      $fclose(ofm_rtl);
  //      #10 $finish;
  //    end
  //  end
  //endtask

  initial begin
    ow = 0;
    forever begin
      @(posedge clk1);
      read_output(data_output, out_valid);
    end
  end

  realtime time_start;

	initial begin
    ofm_rtl = $fopen("ofm_rtl.txt");
		rst_n = 1;
		clk1 = 1;
		clk2 = 0;
    start_conv = 0;
#10 rst_n = 0;
#10 rst_n = 1;
#7  start_conv = 1;
#10 start_conv = 0;
    time_start = $time;
    //wait (end_op == 1);
    //$display("Computing time = %t", $time-time_start);
  end

  //initial begin
  //  wait (start_conv == 1);
  //  $display("Computing layer 1");
  //  wait (end_pool == 1);
  //  $display("Computing layer 2");
  //  wait (end_pool_1 == 1);
  //  $display("Computing layer 3");
  //  wait (end_conv_2 == 1);
  //  $display("Computing layer 4");
  //  wait (end_conv_3 == 1);
  //  $display("Computing layer 5");
  //end

endmodule
