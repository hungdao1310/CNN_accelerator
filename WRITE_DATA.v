module WRITE_DATA #(parameter DATA_WIDTH = 16, TILING_SIZE = 8) (
		clk
	 ,rst_n
	 ,state
	 ,counter_tiling
	 ,data_output
	 ,valid_data
	 ,sel_data
	);

input clk;
input rst_n;
input [2:0] state;
input [15:0] counter_tiling;
output reg valid_data;
output reg [DATA_WIDTH-1:0] data_output;
output reg [3:0] sel_data;


	reg [2:0] current_state;
	reg [2:0] next_state   ;

	parameter IDLE           = 3'd0;
	parameter WAIT_WRITE     = 3'd1;
	parameter WRITE_DATA     = 3'd2;

  always @(posedge clk or negedge rst_n) begin
  	if(!rst_n) begin
  		current_state <= 0;
  	end
  	else begin
  		current_state <=  next_state;
  	end
  end

	always @(state or current_state or sel_data or counter_tiling) begin
		case(current_state)
			3'd0: begin 
			  if(state == 3'd4 && counter_tiling > 16'd1)
					next_state = WRITE_DATA;
				else
					next_state = IDLE;
				end
	//		3'd1: next_state = WRITE_DATA;
			3'd2: begin
				if(sel_data == TILING_SIZE )
					next_state = IDLE;
				else 
					next_state = WRITE_DATA;
				end
			default: next_state = IDLE;
		endcase
	end

  always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
		  valid_data <= 0;
			sel_data   <= 0;
		end
		else begin
			case(next_state)
				IDLE: begin
		  		valid_data <= 0;
					sel_data   <= 0;
				end
		//		WAIT_WRITE: begin
		//  		valid_data <= 1;
		//			sel_data   <= 0;
    //    end
				WRITE_DATA: begin
		  		valid_data <= 1;
					sel_data   <= (sel_data == TILING_SIZE +1) ? 0 : sel_data + 1;
				end
				default: begin 
		  		valid_data <= 0;
					sel_data   <= 0;
				end
			endcase
		end
	end
	endmodule
