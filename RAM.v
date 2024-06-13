module RAM #(parameter DATA_WIDTH = 16, DEPTH = 10) (
		clk,
    rst_n,
		wr_en,
		rd_en,
		data_in,
		data_out,
		);

   input clk   ; 
   input rst_n ;
   input wr_en ;
   input rd_en ;
   input  [DATA_WIDTH-1:0] data_in ;
   output [DATA_WIDTH-1:0] data_out;

//=======================================================
//      INTERNAL DECLARATIONS
//=======================================================

  reg [DATA_WIDTH-1:0] ram_data [DEPTH-1:0];
  reg [$clog2(DEPTH)-1: 0] rd_ptr;
  reg [$clog2(DEPTH)-1: 0] wr_ptr;
  reg [DATA_WIDTH-1:0] data_read;

  always @(posedge clk or negedge rst_n) begin
  	if(!rst_n)
  	  rd_ptr <= 0;
    else begin
  	  if(rd_en) begin
	 	  	data_read <= ram_data[rd_ptr];
		  	rd_ptr    <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1'b1;
		  end
		  else 
		    data_read <= 0;
    end
	end
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n)
		  wr_ptr <= 0;
    else begin
		  if(wr_en) begin
		  	ram_data[wr_ptr]  <= data_in;
		  	wr_ptr            <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1'b1;
		  end
    end
	end

	assign data_out = data_read;
endmodule
