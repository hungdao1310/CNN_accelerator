module IFM_BUFF #(parameter DATA_WIDTH = 8) (
		input clk
	 ,input rst_n
	 ,input set_ifm
	 ,input  [DATA_WIDTH-1:0] ifm_in
	 ,output [DATA_WIDTH-1:0] ifm_out
	 );

	reg [DATA_WIDTH-1:0] ifm;
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			ifm <= 0;
		end
		else if(set_ifm) begin
			ifm <= ifm_in;
		end
		else begin
			ifm <= ifm;
		end
  end
	assign ifm_out = ifm;
endmodule
