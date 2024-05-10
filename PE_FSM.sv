module PE_FSM #(parameter KERNEL_SIZE = 4, IFM_SIZE = 9, CI = 3, CO = 4)(
  input clk1,
  input clk2,
  input rst_n,
  input start_conv,
  output [KERNEL_SIZE-1:0] rd_en,
  output [KERNEL_SIZE-1:0] wr_en,
  output rd_clr,
  output wr_clr,
  output []
);

  reg [7:0] cnt_index;
  reg [7:0] cnt_line;
  reg [7:0] cnt_channel;
  reg [7:0] cnt_filter;

  reg [1:0] curr_state;
  reg [1:0] next_state;

  parameter [3:0] 
    IDLE        = 3'b000;
    COMPUTE     = 3'b001;
    END_ROW     = 3'b010;
    END_CHANNEL = 3'b011;
    END_FILTER  = 3'b100;
    END         = 3'b101;

  always @(posedge clk1 or negedge rst_n)
  begin
    if (!rst_n)
      curr_state <= IDLE;
    else
      curr_state <= next_state;
  end

  always @(curr_state or cnt_index or cnt_line or cnt_channel or cnt_filter)
  begin
    case (curr_state) 
      IDLE:
        if (start_conv)
          next_state = COMPUTE;
        else
          next_state = IDLE;
      COMPUTE:
        if (cnt_index == )
      END_ROW:

      END_CHANNEL:

      END_FILTER:

      END:
  end 

  always @(posedge clk1) begin
    rd_clr <= (cnt_index == IFM_SIZE - KERNEL_SIZE + 3)? 1 : 0;
    wr_clr <= (cnt_index == KERNEL_SIZE)? 1 : 0;
  end

  genvar i;
  generate
    for (i = 0; i < KERNEL_SIZE; i = i + 1) begin
      always @(posedge clk1) begin
        rd_en[i] <= ((cnt_line >= (i+2)) && (cnt_index > 0 && cnt_index <= IFM_SIZE-KERNEL_SIZE+1))? 1 : 0;
        wr_en[i] <= ((cnt_line >= (i+1)) && (cnt_index > KERNEL_SIZE || cnt_index == 0))? 1 : 0;
      end
    end
  endgenerate

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_index   <= 0;
      cnt_line    <= 0;
      cnt_channel <= 0;
      cnt_filter  <= 0;
    end 
    else
    begin
      // cnt_index
      if (cnt_index < IFM_SIZE)
        cnt_index <= cnt_index + 1;
      else
        cnt_index <= 0;
      // cnt_line
      if (cnt_index == 0)
        cnt_line <= cnt_line + 1;
      else if (cnt_index == IFM_SIZE & cnt_line == IFM_SIZE)
        cnt_line <= 0;
      // cnt_channel
      if (cnt_index == 0 & cnt_line == 0)
        cnt_channel <= cnt_channel + 1;
      else if (cnt_index == IFM_SIZE & cnt_line == IFM_SIZE & cnt_channel == CI)
        cnt_channel <= 0;
      // cnt_filter
      if (cnt_index == 0 & cnt_line == 0 & cnt_channel == 0 & cnt_filter < CO)
        cnt_filter <= cnt_filter + 1;
      else 
        cnt_filter <= cnt_filter;
    end
  end
