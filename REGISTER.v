module REGG #(parameter DATA_WIDTH = 16)  (
		clk,
		rst_n,
		set_reg,
		reg_in,
		reg_out,
		);

  input clk     ;
	input rst_n   ;
	input set_reg ;

  input signed  [DATA_WIDTH-1:0] reg_in         ;  
  output signed [DATA_WIDTH-1:0] reg_out        ; 
	reg signed    [DATA_WIDTH-1:0] internal_data  ;
	reg signed    [DATA_WIDTH-1:0] internal_signal;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			internal_data <= 0;
		end
		else begin
			internal_data <= internal_signal;
		end
	end

	always @(*) begin
		if(set_reg) begin
		  internal_signal = reg_in;
		end
		else begin
			internal_signal = internal_data;
		end
	end

	assign reg_out = internal_data;
endmodule
