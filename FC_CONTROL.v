module FC_CONTROL # (parameter IFM_SIZE = 9162, TILING_SIZE = 8, KERNEL_SIZE = 4096) (
	 clk1
	,clk2
	,rst_n
	,start
	,ifm_read
	,wgt_read
	,valid_ifm
	,last_kernel
	,end_compute
	,wr_buff_ifm
	,rd_buff_ifm
	,set_reg
	,wr_ifm_clr
	,rd_ifm_clr
	,counter_ifm
	,set_output
	,current_state
	,counter_tiling
	);

  input  clk1; 
  input  clk2; 
	input  rst_n;
  input  start;
  input  valid_ifm;
	output reg end_compute;
  output reg end_conv;
  output reg ifm_read; 
  output reg wgt_read;
  output reg last_kernel;
  output wire wr_buff_ifm;
  output reg rd_buff_ifm;
	output reg set_reg;
  output reg wr_ifm_clr;
  output reg rd_ifm_clr;
	output reg [15:0] counter_ifm;
	output reg set_output;
	output reg [2:0] current_state;
	output reg [15:0] counter_tiling;

	//reg [15:0] counter_ifm;
	reg [15:0] counter_kernel;

	reg [2:0] next_state   ;
	wire wr_buffer_w;
	reg wr_buff_ifm_o;
	assign wr_buff_w = valid_ifm;
  assign wr_buff_ifm = (wr_buff_ifm_o | wr_buff_w); 
	

	parameter IDLE            = 3'd0;
	parameter WRITE_IFM       = 3'd1;
	parameter COMPUTE         = 3'd2;	
	parameter WAIT            = 3'd3;
	parameter NOP             = 3'd4;
	parameter END             = 3'd5;	


  always @(posedge clk1 or negedge rst_n) begin
  	if(!rst_n) begin
  		current_state <= 0;
  	end
  	else begin
  		current_state <=  next_state;
  	end
  end

  always @(current_state or valid_ifm or counter_ifm or counter_kernel or counter_tiling) begin
		case(current_state)
			IDLE:
				if(valid_ifm & (counter_ifm == 0)) 
					next_state = WRITE_IFM;
				else 
					next_state = IDLE;
			WRITE_IFM:
				if(counter_ifm == IFM_SIZE)
					next_state = WAIT;
				else 
					next_state = WRITE_IFM;
			WAIT: 
				next_state = NOP;
			NOP: 
				next_state = COMPUTE;
			COMPUTE:
				if(counter_ifm == IFM_SIZE)
					next_state = WAIT;
				else if(counter_tiling == KERNEL_SIZE / TILING_SIZE + 1)
					next_state = END;
				else 
					next_state = COMPUTE;
			END: next_state = END;
			default: next_state = IDLE;
			endcase
		end
     wire valid_ifm_w ;
		 assign valid_ifm_w = valid_ifm;
		always @(posedge clk1 or negedge rst_n) begin
			if(!rst_n) begin
	       ifm_read       <=  0;    
	       wgt_read       <=  0;        
	       last_kernel    <=  0;          
	       end_compute    <=  0;         
	       rd_buff_ifm    <=  0;         
	       set_reg        <=  0;        
	       wr_ifm_clr     <=  1;         
	       rd_ifm_clr     <=  1;         
				 set_output     <=  0;
			end
			else begin
				case(next_state)
					IDLE:
            {ifm_read, wgt_read, last_kernel,end_compute,rd_buff_ifm,set_reg,wr_ifm_clr ,rd_ifm_clr} <= 9'b000000000;
					WRITE_IFM:begin
            {ifm_read, wgt_read, last_kernel,end_compute,rd_buff_ifm,set_reg,wr_ifm_clr ,rd_ifm_clr} <= 8'b00000000;
				//		wr_buff_ifm_o <= valid_ifm;
					end
					WAIT: begin
            {ifm_read, wgt_read, last_kernel,end_compute,rd_buff_ifm,set_reg,wr_ifm_clr ,rd_ifm_clr} <= 8'b00000001;
						set_output <= (counter_tiling > 0) ? 1 : 0;
					end
					COMPUTE: begin
            {ifm_read, wgt_read, last_kernel,end_compute,rd_buff_ifm,set_reg,wr_ifm_clr ,rd_ifm_clr,set_output} <= 9'b010011000;
						//set_output <= (counter_ifm == (IFM_SIZE - 1));
					end
					NOP:
            {ifm_read, wgt_read, last_kernel,end_compute,rd_buff_ifm,set_reg,wr_ifm_clr ,rd_ifm_clr, set_output} <= 9'b000010000;

					END:
            {ifm_read, wgt_read, last_kernel,end_compute,rd_buff_ifm,set_reg,wr_ifm_clr ,rd_ifm_clr} <= 8'b00001100;
					default:
            {ifm_read, wgt_read, last_kernel,end_compute,rd_buff_ifm,set_reg,wr_ifm_clr ,rd_ifm_clr} <= 8'b00001100;
				endcase
			end
		end
		always @(posedge clk1 or negedge rst_n) begin
			if(!rst_n) begin
				wr_buff_ifm_o <= 0;
			end
			else begin
				case(next_state)
					IDLE:
				    wr_buff_ifm_o <= 0;
					WRITE_IFM:
				    wr_buff_ifm_o <= valid_ifm;
					WAIT:
				    wr_buff_ifm_o <= 0;
					COMPUTE:
				    wr_buff_ifm_o <= 0;
					NOP:
				    wr_buff_ifm_o <= 0;
					END:
				    wr_buff_ifm_o <= 0;
				endcase
			end
		end

		always @(posedge clk1 or rst_n) begin
			if(~rst_n) begin
				counter_ifm <= 0;
				counter_tiling <= 0;
				counter_kernel <= 0;
			end
			else begin
				case(next_state)
					IDLE: begin
				    counter_ifm    <= 0;
				    counter_tiling <= 0;
				    counter_kernel <= 0;
					end
          WRITE_IFM:
						counter_ifm <= (wr_buff_ifm) ? (counter_ifm == IFM_SIZE) ? 0 : counter_ifm +  1 : counter_ifm;
					COMPUTE: begin
						counter_kernel <= (counter_kernel == KERNEL_SIZE) ? 0 : counter_kernel + 1;
						counter_ifm    <= (counter_ifm == IFM_SIZE) ? 0 : counter_ifm + 1;
						counter_tiling <= counter_tiling;
						end
					WAIT: begin
						counter_tiling <= counter_tiling + 1;
						counter_ifm <= 0;
						end
					END: begin
				    counter_ifm    <= 0;
				    counter_tiling <= 0;
				    counter_kernel <= 0;
					end
					NOP: 
						counter_tiling <= counter_tiling;
					default: begin
				    counter_ifm    <= 0;
				    counter_tiling <= 0;
				    counter_kernel <= 0;
					end
				endcase
			end
		end
						
						
				



							
						
						
						
						




























	endmodule
