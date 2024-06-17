module FC #(parameter DATA_WIDTH = 16, IFM_WIDTH = 8, WGT_WIDTH = 8, IFM_SIZE = 9162, KERNEL_SIZE = 4096, TILING_SIZE = 8) (
	 clk1
	,clk2
	,rst_n
	,ifm          // input fM
	,valid_ifm  // signal when input valid
	,wgt           // weight
	,ofm                
	,valid_data
	,ifm_read
	,wgt_read
);
input  clk1;
input  clk2;
input  rst_n;
input  valid_ifm;
input  [IFM_WIDTH-1:0] ifm;
input  [8*WGT_WIDTH-1 : 0] wgt;
output [DATA_WIDTH-1:0] ofm; 	
output  ifm_read;
output  wgt_read;
output  valid_data;

localparam ADD_WIDTH = $clog2(IFM_SIZE)+1;

wire   [WGT_WIDTH-1:0] wgt1 ;
wire   [WGT_WIDTH-1:0] wgt2 ;
wire   [WGT_WIDTH-1:0] wgt3 ;
wire   [WGT_WIDTH-1:0] wgt4 ;
wire   [WGT_WIDTH-1:0] wgt5 ;
wire   [WGT_WIDTH-1:0] wgt6 ;
wire   [WGT_WIDTH-1:0] wgt7 ;
wire   [WGT_WIDTH-1:0] wgt8 ;

wire   [IFM_WIDTH - 1: 0] ifm_out;

assign wgt1 = {8'b0,wgt[7:0]  };
assign wgt2 = {8'b0,wgt[15:8] };
assign wgt3 = {8'b0,wgt[23:16]};
assign wgt4 = {8'b0,wgt[31:24]};
assign wgt5 = {8'b0,wgt[39:32]};
assign wgt6 = {8'b0,wgt[47:40]};
assign wgt7 = {8'b0,wgt[55:48]};
assign wgt8 = {8'b0,wgt[63:56]};

wire [DATA_WIDTH-1:0] psum_out1;
wire [DATA_WIDTH-1:0] psum_out2;
wire [DATA_WIDTH-1:0] psum_out3;
wire [DATA_WIDTH-1:0] psum_out4;
wire [DATA_WIDTH-1:0] psum_out5;
wire [DATA_WIDTH-1:0] psum_out6;
wire [DATA_WIDTH-1:0] psum_out7;
wire [DATA_WIDTH-1:0] psum_out8;

//assign psum_out1 = (counter_ifm == 0 ) ? 0 :  psum_out1;
wire [15:0] counter_ifm;

wire [DATA_WIDTH-1:0] ifm_v;
wire wr_en;
wire wr_buff_ifm;
wire rd_buff_ifm;
wire set_reg;
wire wr_ifm_clr;
wire rd_ifm_clr;

wire last_channel;
wire end_compute;
wire [15:0] counter_tiling;

wire flag;
assign flag = ((counter_ifm == 0));

wire [31:0] psum_in1;
wire [31:0] psum_in2;
wire [31:0] psum_in3;
wire [31:0] psum_in4;
wire [31:0] psum_in5;
wire [31:0] psum_in6;
wire [31:0] psum_in7;
wire [31:0] psum_in8;
assign psum_in1 = (flag)? 0 : psum_out1;
assign psum_in2 = (flag)? 0 : psum_out2;
assign psum_in3 = (flag)? 0 : psum_out3;
assign psum_in4 = (flag)? 0 : psum_out4;
assign psum_in5 = (flag)? 0 : psum_out5;
assign psum_in6 = (flag)? 0 : psum_out6;
assign psum_in7 = (flag)? 0 : psum_out7;
assign psum_in8 = (flag)? 0 : psum_out8;

reg [DATA_WIDTH - 1:0] reg_1;
reg [DATA_WIDTH - 1:0] reg_2;
reg [DATA_WIDTH - 1:0] reg_3;
reg [DATA_WIDTH - 1:0] reg_4;
reg [DATA_WIDTH - 1:0] reg_5;
reg [DATA_WIDTH - 1:0] reg_6;
reg [DATA_WIDTH - 1:0] reg_7;
reg [DATA_WIDTH - 1:0] reg_8;

wire [3:0] sel_mux;
wire [DATA_WIDTH-1:0] out_mux;
wire set_output;
wire [2:0] current_state;

always @(posedge clk2 or negedge rst_n) begin
	if(!rst_n) begin
    reg_1 <= 0;  
    reg_2 <= 0;
    reg_3 <= 0;
    reg_4 <= 0;
    reg_5 <= 0;
    reg_6 <= 0;
    reg_7 <= 0;
    reg_8 <= 0;
	end
	else begin
	  reg_1 <= (set_output) ? psum_out1 : reg_1 ;  	
    reg_2 <= (set_output) ? psum_out2 : reg_2 ;
    reg_3 <= (set_output) ? psum_out3 : reg_3 ;
    reg_4 <= (set_output) ? psum_out4 : reg_4 ;
    reg_5 <= (set_output) ? psum_out5 : reg_5 ;
    reg_6 <= (set_output) ? psum_out6 : reg_6 ;
    reg_7 <= (set_output) ? psum_out7 : reg_7 ;
    reg_8 <= (set_output) ? psum_out8 : reg_8 ;
	end
end


assign ofm = (out_mux[DATA_WIDTH-1]) ? 0 : out_mux;
WRITE_DATA #(.DATA_WIDTH(DATA_WIDTH), .TILING_SIZE(TILING_SIZE))  write_data(
		.clk(clk2)
	 ,.rst_n(rst_n)
	 ,.counter_tiling(counter_tiling)
	 ,.state(current_state)
	 ,.data_output()
	 ,.valid_data(valid_data)
	 ,.sel_data(sel_mux)
	);


 MUX_8_1 # (.DATA_WIDTH(DATA_WIDTH))  mux(
		 .in1(reg_1)  
		,.in2(reg_2)
		,.in3(reg_3)
		,.in4(reg_4)
		,.in5(reg_5)
		,.in6(reg_6)
		,.in7(reg_7)
		,.in8(reg_8)
		,.sel(sel_mux)
		,.out(out_mux)
);

FC_CONTROL #(.IFM_SIZE(IFM_SIZE), .TILING_SIZE(TILING_SIZE), .KERNEL_SIZE(KERNEL_SIZE))  controller (
   .clk1(clk1)
	,.clk2(clk2)
	,.rst_n(rst_n)
	,.start(1'b0)
	,.ifm_read(ifm_read)
	,.wgt_read(wgt_read)
	,.valid_ifm(valid_ifm)
	,.last_kernel(last_kernel)
	,.end_compute(end_compute)
	,.wr_buff_ifm(wr_buff_ifm)
	,.rd_buff_ifm(rd_buff_ifm)
	,.set_reg(set_reg)
	,.wr_ifm_clr(wr_ifm_clr)
	,.rd_ifm_clr(rd_ifm_clr)
	,.counter_ifm(counter_ifm)
	,.set_output(set_output)
	,.current_state(current_state)
	,.counter_tiling(counter_tiling)
);


FIFO_ASYNCH #(.DATA_WIDTH(DATA_WIDTH), .FIFO_SIZE(IFM_SIZE), .ADD_WIDTH(ADD_WIDTH)) ifm_buffer(
	.clk1(clk1)  ,
  .clk2(clk2)  ,
  .rd_clr(rd_ifm_clr),
  .wr_clr(wr_ifm_clr),
  .rd_inc(1'b1),
  .wr_inc(1'b1),
  .wr_en(wr_buff_ifm) ,
  .rd_en(rd_buff_ifm) ,
  .data_in_fifo(ifm) ,
  .data_out_fifo(ifm_out)
	);

PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WGT_WIDTH), .IFM_WIDTH(DATA_WIDTH), .POOLING(0) ) pe1(
      .clk(clk1)
     ,.rst_n(rst_n)
     ,.set_reg(set_reg)
     ,.ifm(ifm_out)
     ,.wgt(wgt1)
     ,.psum_in(psum_in1)
     ,.psum_out(psum_out1)
);
PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WGT_WIDTH), .IFM_WIDTH(DATA_WIDTH), .POOLING(0) ) pe2(
      .clk(clk1)
     ,.rst_n(rst_n)
     ,.set_reg(set_reg)
     ,.ifm(ifm_out)
     ,.wgt(wgt2)
     ,.psum_in(psum_in2)
     ,.psum_out(psum_out2)
);
PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WGT_WIDTH), .IFM_WIDTH(DATA_WIDTH), .POOLING(0) ) pe3(
      .clk(clk1)
     ,.rst_n(rst_n)
     ,.set_reg(set_reg)
     ,.ifm(ifm_out)
     ,.wgt(wgt3)
     ,.psum_in(psum_in3)
     ,.psum_out(psum_out3)
);
PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WGT_WIDTH), .IFM_WIDTH(DATA_WIDTH), .POOLING(0) ) pe4(
      .clk(clk1)
     ,.rst_n(rst_n)
     ,.set_reg(set_reg)
     ,.ifm(ifm_out)
     ,.wgt(wgt4)
     ,.psum_in(psum_in4)
     ,.psum_out(psum_out4)
);
PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WGT_WIDTH), .IFM_WIDTH(DATA_WIDTH), .POOLING(0) ) pe5(
      .clk(clk1)
     ,.rst_n(rst_n)
     ,.set_reg(set_reg)
     ,.ifm(ifm_out)
     ,.wgt(wgt5)
     ,.psum_in(psum_in5) 
     ,.psum_out(psum_out5)
);
PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WGT_WIDTH), .IFM_WIDTH(DATA_WIDTH), .POOLING(0) ) pe6(
      .clk(clk1)
     ,.rst_n(rst_n)
     ,.set_reg(set_reg)
     ,.ifm(ifm_out)
     ,.wgt(wgt6)
     ,.psum_in(psum_in6)
     ,.psum_out(psum_out6)
);
PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WGT_WIDTH), .IFM_WIDTH(DATA_WIDTH), .POOLING(0) ) pe7(
      .clk(clk1)
     ,.rst_n(rst_n)
     ,.set_reg(set_reg)
     ,.ifm(ifm_out)
     ,.wgt(wgt7)
     ,.psum_in(psum_in7)
     ,.psum_out(psum_out7)
);
PE #(.PSUM_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WGT_WIDTH), .IFM_WIDTH(DATA_WIDTH), .POOLING(0) ) pe8(
      .clk(clk1)
     ,.rst_n(rst_n)
     ,.set_reg(set_reg)
     ,.ifm(ifm_out)
     ,.wgt(wgt8)
     ,.psum_in(psum_in8)
     ,.psum_out(psum_out8)
);

endmodule

