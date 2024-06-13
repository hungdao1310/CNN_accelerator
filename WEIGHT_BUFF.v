module WEIGHT_BUFF #(parameter DATA_WIDTH = 8) (
		input clk
	 ,input rst_n
	 ,input set_wgt
	 ,input  [DATA_WIDTH-1:0] wgt_in
	 ,output [DATA_WIDTH-1:0] wgt_out
	 );

	reg [DATA_WIDTH-1:0] weight;
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			weight <= 0;
		end
		else if(set_wgt) begin
			weight <= wgt_in;
		end
		else begin
			weight <= weight;
		end
  end

	assign wgt_out = weight;
endmodule
