`timescale 1 ns / 10 ps
module tb();

parameter DATA_WIDTH = 32;
parameter WEIGHT_WIDTH = 8;
parameter IFM_WIDTH = 8;
parameter KERNEL_SIZE  = 13;
parameter FIFO_SIZE = 10;
parameter IFM_SIZE = 28;
parameter CI = 3;
parameter CO = 3;
parameter OFM_SIZE = IFM_SIZE-KERNEL_SIZE+1;

	reg clk1;
	reg clk2;
	reg rst_n;
	reg set_wgt;
	reg set_ifm;
	reg start_conv;
	wire [WEIGHT_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0] wgt;
	wire [IFM_WIDTH-1:0] ifm;
  wire out_valid;
  wire end_conv;
	wire [DATA_WIDTH-1:0] data_out;
  
	initial begin
		$dumpfile("CONV_ACC.vcd");
		$dumpvars(0,tb);
	end

  TOP #(
    .DATA_WIDTH(DATA_WIDTH), 
    .WEIGHT_WIDTH(WEIGHT_WIDTH), 
    .IFM_WIDTH(IFM_WIDTH), 
    .FIFO_SIZE(IFM_SIZE-KERNEL_SIZE+1), 
    .IFM_SIZE(IFM_SIZE), 
    .KERNEL_SIZE(KERNEL_SIZE), 
    .CI(CI), 
    .CO(CO)) top_module(
     .clk1(clk1)
    ,.clk2(clk2)
    ,.rst_n(rst_n)                    	
    ,.set_wgt(set_wgt)
    ,.set_ifm(set_ifm)
    ,.start_conv(start_conv)
    ,.ifm(ifm)
		,.wgt(wgt)
    ,.out_valid(out_valid)
    ,.end_conv(end_conv)
    ,.data_output(data_out)
		);

	always #5 clk1 = ~clk1;
	always @(clk1) begin
		clk2 = ~clk1;
	end

  // Read ifm
  reg [IFM_WIDTH-1:0] ifm_in [0:CI*IFM_SIZE*IFM_SIZE-1];
  reg [17:0] ifm_cnt;
  reg hold_ifm;
  initial begin
    $readmemb("./ifm.txt", ifm_in);
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      ifm_cnt   <= 0;
      hold_ifm  <= 0;
    end
    else
    begin
      if (start_conv || (ifm_cnt == CI*IFM_SIZE*IFM_SIZE && hold_ifm == 1))
      begin
        ifm_cnt   <= 1;
        hold_ifm  <= 0;
      end
      else if (set_ifm && (ifm_cnt%IFM_SIZE != 0 || hold_ifm == 1))
      begin  
        ifm_cnt   <= ifm_cnt + 1;
        hold_ifm  <= 0;
      end
      else if (set_ifm && ifm_cnt%IFM_SIZE == 0 && hold_ifm == 0)
      begin
        ifm_cnt   <= ifm_cnt;
        hold_ifm  <= 1;
      end
      else
        ifm_cnt   <= ifm_cnt;
    end
  end

  assign ifm = ifm_in[ifm_cnt-1];

  // Read weight
  reg [WEIGHT_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0] wgt_in [0:CO*CI-1];
  reg [17:0] wgt_cnt;
  initial begin
    $readmemb("./weight.txt", wgt_in);
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
      wgt_cnt  <= 0;
    else
    begin
      if (start_conv)
        wgt_cnt  <= 1;
      else if (set_wgt && ifm_cnt%(IFM_SIZE*IFM_SIZE) == 0 && hold_ifm == 1)
        wgt_cnt  <= wgt_cnt + 1;
      else
        wgt_cnt  <= wgt_cnt;
    end
  end

  assign wgt = wgt_in[wgt_cnt-1];

  integer ofm_rtl;
  integer oc;
  integer oh;
  integer ow;

  task read_output;
    input [DATA_WIDTH-1:0] data_out;
    input out_valid;
    input end_conv;
    reg signed [DATA_WIDTH-1:0] ofm [0:CO-1][0:OFM_SIZE-1][0:OFM_SIZE-1];
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
          if (ow == OFM_SIZE)
          begin
            ow = 0;
            oh = oh + 1;
            if (oh == OFM_SIZE)
            begin
              oh = 0;
              oc = oc + 1;
              $display("Computing channel: %d", oc);
            end
          end
        end
      end
      else
      begin
        if (end_conv)
        begin
          for (toc = 0; toc < CO; toc = toc + 1)
          begin
            for (toh = 0; toh < OFM_SIZE; toh = toh + 1)
            begin
              for (tow = 0; tow < OFM_SIZE; tow = tow + 1)
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
    end
  endtask

  initial begin
    ofm_rtl = $fopen("ofm_rtl.txt");
    oc = 0;
    oh = 0;
    ow = 0;
    forever begin
      @(posedge clk1);
      read_output(data_out, out_valid, end_conv);
    end
  end

	initial begin
		rst_n = 1;
		clk1 = 1;
		clk2 = 0;
#10 rst_n = 0;
#10 rst_n = 1;
#10 start_conv = 1;
#10 start_conv = 0;
    set_ifm = 1;
    set_wgt = 1;
  end

endmodule