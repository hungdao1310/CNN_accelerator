module POOL_BUFFER #(parameter DATA_WIDTH = 16, FIFO_SIZE = 10, ADD_WIDTH = 3) (
		clk   ,
    rst_n ,
		wr_en ,
		rd_en ,
		data_in_fifo ,
		data_out_fifo,
    full
		);

   input clk   ;  
   input rst_n ;
   input wr_en ;
   input rd_en ;
   input  [DATA_WIDTH-1:0] data_in_fifo ;
   output [DATA_WIDTH-1:0] data_out_fifo;
   output full;

//=======================================================
//      INTERNAL DECLARATIONS
//=======================================================

  reg [DATA_WIDTH-1:0] fifo_data [FIFO_SIZE-1:0];
  reg [ADD_WIDTH-1: 0] rd_ptr                  ;
  reg [ADD_WIDTH-1: 0] wr_ptr                  ;
  reg [DATA_WIDTH-1:0] data_read               ;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rd_ptr    <= 0;
    else
    begin
  	  if(rd_en) begin
	 	  	data_read <= fifo_data[rd_ptr];
		  	rd_ptr    <= rd_ptr + 1       ;
		  end
		  else 
		    data_read <= 0;
      if (rd_ptr == FIFO_SIZE)
        rd_ptr    <= 0;
    end
	end
	always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      wr_ptr    <= 0;
    else
    begin
		  if(wr_en) begin
		  	fifo_data[wr_ptr] <= data_in_fifo   ;
		  	wr_ptr            <= wr_ptr + 1     ;
		  end
		  else
		  	fifo_data[wr_ptr] <= fifo_data[wr_ptr];
      if (wr_ptr == FIFO_SIZE)
        wr_ptr    <= 0;
    end
	end

  assign full = (wr_ptr == FIFO_SIZE) ? 1 : 0; 
	assign data_out_fifo = data_read;
endmodule
