`timescale 1 ns / 10 ps
module tb();

parameter DATA_WIDTH = 32;
parameter WEIGHT_WIDTH = 16;
parameter IFM_WIDTH = 16;
parameter IFM_SIZE = 227;
// Convolution 1
parameter KERNEL_SIZE = 11;
parameter STRIDE = 4;
parameter PAD = 0;
parameter RELU = 1;
parameter CI = 3;
parameter CO = 96;
parameter OFM_SIZE = (IFM_SIZE-KERNEL_SIZE+2*PAD)/STRIDE+1;
// Max pooling_1
parameter KERNEL_POOL = 3;
parameter STRIDE_POOL = 2;
// Convolution 2
parameter KERNEL_SIZE_1 = 5;
parameter STRIDE_1 = 1;
parameter PAD_1 = 2;
parameter RELU_1 = 1;
parameter CI_1 = CO;
parameter CO_1 = 256;
// Max pooling_2
parameter KERNEL_POOL_1 = 3;
parameter STRIDE_POOL_1 = 2;

	reg clk1;
	reg clk2;
	reg rst_n;
	reg start_conv;
	wire [WEIGHT_WIDTH-1:0] wgt;
	wire [IFM_WIDTH-1:0] ifm;
  wire ifm_read;
  wire wgt_read;
	wire [WEIGHT_WIDTH-1:0] wgt_1;
  wire wgt_read_1;
  wire end_pool;
  wire end_op;
  wire pool_out_valid_1;
	wire [DATA_WIDTH-1:0] data_output;
  
	//initial begin
	//	$dumpfile("CONV_POOL_CONV.vcd");
	//	$dumpvars(0,tb);
	//end

  CONV_POOL_CONV #(
    .DATA_WIDTH(DATA_WIDTH), 
    .WEIGHT_WIDTH(WEIGHT_WIDTH), 
    .IFM_WIDTH(IFM_WIDTH), 
    .FIFO_SIZE(OFM_SIZE), 
    .IFM_SIZE(IFM_SIZE), 
    .KERNEL_SIZE(KERNEL_SIZE), 
    .STRIDE(STRIDE),
    .PAD(PAD),
    .RELU(RELU),
    .KERNEL_POOL(KERNEL_POOL),
    .STRIDE_POOL(STRIDE_POOL),
    .CI(CI), 
    .CO(CO),
    .KERNEL_SIZE_1(KERNEL_SIZE_1),
    .STRIDE_1(STRIDE_1),
    .PAD_1(PAD_1),
    .RELU_1(RELU_1),
    .KERNEL_POOL_1(KERNEL_POOL_1),
    .STRIDE_POOL_1(STRIDE_POOL_1),
    .CO_1(CO_1)
  ) top_module(
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)                    	
    ,.start_conv(start_conv)
    ,.ifm(ifm)
		,.wgt(wgt)
    ,.ifm_read(ifm_read)
    ,.wgt_read(wgt_read)
		,.wgt_1(wgt_1)
    ,.wgt_read_1(wgt_read_1)
    ,.end_op(end_op)
    ,.end_pool(end_pool)
    ,.pool_out_valid_1(pool_out_valid_1)
    ,.data_output(data_output)
		);

	always #5 clk1 = ~clk1;
	always @(clk1) begin
		clk2 = ~clk1;
	end

  localparam IFM_POOL = (IFM_SIZE+2*PAD-KERNEL_SIZE)/STRIDE+1;
  localparam IFM_CONV = (IFM_POOL-KERNEL_POOL)/STRIDE_POOL+1;
  localparam IFM_POOL_1 = (IFM_CONV+2*PAD_1-KERNEL_SIZE_1)/STRIDE_1+1;
  localparam OFM = (IFM_POOL_1-KERNEL_POOL_1)/STRIDE_POOL_1+1;

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

  integer ofm_rtl;
  integer oc;
  integer oh;
  integer ow;

  task read_output;
    input [DATA_WIDTH-1:0] data_output;
    input pool_out_valid_1;
    input end_op;
    reg signed [DATA_WIDTH-1:0] ofm [0:CO_1-1][0:OFM-1][0:OFM-1];
    integer toc;
    integer toh;
    integer tow;

    begin
      if (oc < CO_1)
      begin
        if (pool_out_valid_1)
        begin
          ofm[oc][oh][ow] = data_output;
          ow = ow + 1;
          if (ow == OFM)
          begin
            ow = 0;
            oh = oh + 1;
            if (oh == OFM)
            begin
              oh = 0;
              oc = oc + 1;
              //$display("Computing channel: %d", oc);
            end
          end
        end
      end
      if (end_op)
      begin
        for (toc = 0; toc < CO_1; toc = toc + 1)
        begin
          for (toh = 0; toh < OFM; toh = toh + 1)
          begin
            for (tow = 0; tow < OFM; tow = tow + 1)
              $fwrite(ofm_rtl, "%d ", ofm[toc][toh][tow]);
            $fwrite(ofm_rtl, "\n");
          end
          $fwrite(ofm_rtl, "\n");
        end
        $display("Finish writing results to ofm_rtl.txt");
        $fclose(ofm_rtl);
        #10 $finish;
      end
    end
  endtask

  initial begin
    oc = 0;
    oh = 0;
    ow = 0;
    forever begin
      @(posedge clk1);
      read_output(data_output, pool_out_valid_1, end_op);
    end
  end

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
  end

  initial begin
    wait (start_conv == 1);
    $display("Computing layer 1");
    wait (end_pool == 1);
    $display("Computing layer 2");
  end

endmodule
