module FIFO_ASYNCH #(parameter DATA_WIDTH = 16, FIFO_SIZE = 10, ADD_WIDTH = 3) (
		clk1  ,
		clk2  ,
		rd_clr,
		wr_clr,
		rd_inc,
		wr_inc,
		wr_en ,
		rd_en ,
		data_in_fifo ,
		data_out_fifo,
		);

   input clk1  ;  
   input clk2  ; 
   input rd_clr;         
   input wr_clr;
   input rd_inc;
   input wr_inc;
   input wr_en ;
   input rd_en ;
   input  [DATA_WIDTH-1:0] data_in_fifo ;
   output [DATA_WIDTH-1:0] data_out_fifo;

//=======================================================
//      INTERNAL DECLARATIONS
//=======================================================

  reg [DATA_WIDTH-1:0] fifo_data [FIFO_SIZE-1:0];
  reg [ADD_WIDTH-1: 0] rd_ptr                  ;
  reg [ADD_WIDTH-1: 0] wr_ptr                  ;
  reg [DATA_WIDTH-1:0] data_read               ;
  reg reg_we;

  always @(posedge clk1) begin
   	reg_we <= wr_en;
  end

  always @(posedge clk2) begin
  	if(rd_clr)
  	  rd_ptr <= 0;
  	else if(rd_en) begin
	 		data_read <= fifo_data[rd_ptr];
			rd_ptr    <= rd_ptr + rd_inc   ;
		end
		else 
		  data_read <= 0;
	end
	always @(posedge clk2) begin
		if(wr_clr)
		  wr_ptr <= 0;
		else if(reg_we) begin
			fifo_data[wr_ptr] <= data_in_fifo   ;
			wr_ptr            <= wr_ptr + wr_inc;
		end
		else
			fifo_data[wr_ptr] <= fifo_data[wr_ptr];
	end

	assign data_out_fifo = data_read;
endmodule
