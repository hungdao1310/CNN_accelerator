`timescale 1 ns / 10 ps
module tb();

parameter DATA_WIDTH = 32;
parameter WEIGHT_WIDTH = 16;
parameter IFM_WIDTH = 16;
parameter IFM_SIZE = 13;
// Convolution
parameter KERNEL_SIZE = 3;
parameter STRIDE = 1;
parameter PAD = 1;
parameter RELU = 1;
// Max pooling
parameter KERNEL_POOL = 3;
parameter STRIDE_POOL = 2;
parameter CI = 3;
parameter CO = 16;
parameter OFM_SIZE = (IFM_SIZE-KERNEL_SIZE+2*PAD)/STRIDE+1;
parameter FINAL_SIZE = (OFM_SIZE-KERNEL_POOL)/STRIDE_POOL+1;


	reg clk1;
	reg clk2;
	reg rst_n;
	reg start_conv;
	wire [WEIGHT_WIDTH-1:0] wgt;
	wire [IFM_WIDTH-1:0] ifm;
  wire ifm_read;
  wire wgt_read;
  wire out_valid;
  wire end_pool;
	wire [DATA_WIDTH-1:0] data_out;
  
	//initial begin
	//	$dumpfile("CONV_POOL.vcd");
	//	$dumpvars(0,tb);
	//end

  CONV_POOL #(
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
    .CO(CO)) top_module(
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)                    	
    ,.start_conv(start_conv)
    ,.ifm(ifm)
		,.wgt(wgt)
    ,.ifm_read(ifm_read)
    ,.wgt_read(wgt_read)
    ,.out_valid(out_valid)
    ,.end_pool(end_pool)
    ,.data_output(data_out)
		);

	always #5 clk1 = ~clk1;
	always @(clk1) begin
		clk2 = ~clk1;
	end

  localparam IFM_PAD = IFM_SIZE+2*PAD;
  localparam IFM_PAD_SQR = IFM_PAD*IFM_PAD;
  localparam IFM_SQR = IFM_SIZE*IFM_SIZE;

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

  integer ofm_rtl;
  integer oc;
  integer oh;
  integer ow;

  task read_output;
    input [DATA_WIDTH-1:0] data_out;
    input out_valid;
    input end_pool;
    reg signed [DATA_WIDTH-1:0] ofm [0:CO-1][0:FINAL_SIZE-1][0:FINAL_SIZE-1];
    integer toc;
    integer toh;
    integer tow;

    begin
      if (oc < CO)
      begin
        if (out_valid)
        begin
          ofm[oc][oh][ow] = data_out;
          ow = ow + 1;
          if (ow == FINAL_SIZE)
          begin
            ow = 0;
            oh = oh + 1;
            if (oh == FINAL_SIZE)
            begin
              oh = 0;
              oc = oc + 1;
              $display("Computing channel: %d", oc);
            end
          end
        end
      end
        if (end_pool)
        begin
          for (toc = 0; toc < CO; toc = toc + 1)
          begin
            for (toh = 0; toh < FINAL_SIZE; toh = toh + 1)
            begin
              for (tow = 0; tow < FINAL_SIZE; tow = tow + 1)
                $fwrite(ofm_rtl, "%d ", ofm[toc][toh][tow]);
              $fwrite(ofm_rtl, "\n");
            end
            $fwrite(ofm_rtl, "\n");
          end
          $display("Finish writing results to ofm_rtl.txt");
          $fclose(ofm_rtl);
          # 10;
          $finish;
        end
    end
  endtask

  initial begin
    ofm_rtl = $fopen("ofm_rtl.txt");
    oc = 0;
    oh = 0;
    ow = 0;
    forever begin
      @(posedge clk1);
      read_output(data_out, out_valid, end_pool);
    end
  end

	initial begin
		rst_n = 1;
		clk1 = 1;
		clk2 = 0;
    start_conv = 0;
#10 rst_n = 0;
#10 rst_n = 1;
#7  start_conv = 1;
#10 start_conv = 0;
  end

endmodule
