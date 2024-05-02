module PE #(parameter WEIGHT_WIDTH = 8, DATA_OUT_WIDTH = 16, IFM_WIDTH = 8, PSUM_WIDTH = 16)(
    clk,
    rst_n,
    set_reg,
		ifm,
		wgt,
		psum_in,
		psum_out
		);

	input clk    ;  
	input rst_n  ;
	input set_reg;
	input  signed [IFM_WIDTH-1:0   ]          ifm      ;
	input  signed [WEIGHT_WIDTH-1:0]          wgt      ;
	input  signed [PSUM_WIDTH-1:0    ]          psum_in  ;
	output signed [PSUM_WIDTH-1:0    ]          psum_out ;
	
	reg signed  [PSUM_WIDTH-1:0] psum;
	wire signed [PSUM_WIDTH-1:0] psum_in_wire ;
	wire signed [PSUM_WIDTH-1:0] psum_out_wire;
  
	REGG #(.DATA_WIDTH(PSUM_WIDTH)) psum_reg (
			.clk     (clk          ),
		  .rst_n   (rst_n        ),
		  .set_reg (set_reg      ),
		  .reg_in  (psum),
		  .reg_out (psum_out_wire)
	);

	always @(ifm or wgt or psum_in) begin
		psum = wgt*ifm + psum_in;
	end

	assign psum_out = psum_out_wire;
endmodule
