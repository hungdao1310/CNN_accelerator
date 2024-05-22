module CONTROL #(parameter KERNEL_SIZE = 4, IFM_SIZE = 9, PAD = 2, STRIDE = 2, CI = 3, CO = 4)(
  input clk1,
  input clk2,
  input rst_n,
  input start_conv,
  output wgt_read,
  output ifm_read,
  output reg set_ifm,
  output reg rd_clr,
  output reg wr_clr,
  output reg re_buffer,
  output reg out_valid,
  output reg set_reg,
  output reg end_conv,
  output reg [KERNEL_SIZE-1:0] rd_en,
  output reg [KERNEL_SIZE-1:0] wr_en,
  output reg [KERNEL_SIZE*KERNEL_SIZE-1:0] set_wgt,
  output [$clog2(IFM_SIZE-KERNEL_SIZE+1)+1:0] addr_x,
  output [$clog2(IFM_SIZE-KERNEL_SIZE+1)+1:0] addr_y,
  output [$clog2(CO)+1:0] addr_c
);

  reg [7:0] cnt_index;
  reg [7:0] cnt_line;
  reg [7:0] cnt_channel;
  reg [7:0] cnt_filter;

  reg [2:0] curr_state;
  reg [2:0] next_state;

  parameter [2:0] 
    IDLE        = 3'b000,
    COMPUTE     = 3'b001,
    END_ROW     = 3'b010,
    END_CHANNEL = 3'b011,
    END_FILTER  = 3'b100,
    END_CONV    = 3'b101;

  always @(posedge clk1 or negedge rst_n)
  begin
    if (!rst_n)
      curr_state <= IDLE;
    else
      curr_state <= next_state;
  end

  always @(start_conv or cnt_index or cnt_line or cnt_channel)
  begin
    case (curr_state)
      IDLE:
      begin
        if (start_conv)
          next_state = COMPUTE;
        else
          next_state = IDLE;
      end
      COMPUTE:
      begin
        if (cnt_index == IFM_SIZE)
        begin
          if (cnt_line < IFM_SIZE)
            next_state = END_ROW;
          else
          begin
            if (cnt_channel < CI)
              next_state = END_CHANNEL;
            else
              next_state = END_FILTER;
          end
        end
        else
          next_state = COMPUTE;
      end
      END_ROW:
        next_state = COMPUTE;
      END_CHANNEL:
        next_state = COMPUTE;
      END_FILTER:
      begin
        if (cnt_filter < CO)
          next_state = COMPUTE;
        else
          next_state = END_CONV;
      end
      END_CONV:
        if (cnt_index > IFM_SIZE-KERNEL_SIZE+2)
          next_state = IDLE;
        else
          next_state = END_CONV;
      default:
        next_state = IDLE;
    endcase
  end

  always @(posedge clk1) begin
    re_buffer <= ((cnt_channel > 1) && (cnt_line >= KERNEL_SIZE) && (cnt_index >= KERNEL_SIZE && cnt_index <= IFM_SIZE))? ((STRIDE == 1) ? 1 : (((cnt_index+1-KERNEL_SIZE)%STRIDE == 1 || cnt_index == IFM_SIZE) ? 1 : 0)) : 0;
  end

  genvar i;
  generate
    for (i = 0; i < KERNEL_SIZE; i = i + 1) begin
      always @(posedge clk1) begin
        rd_en[i] <= ((cnt_filter > 0) && ((cnt_line >= (i+2) && cnt_line <= (IFM_SIZE-KERNEL_SIZE+i+2)) || (i == KERNEL_SIZE-1 && cnt_line == 1)) && (cnt_index > 0 && cnt_index <= IFM_SIZE-KERNEL_SIZE+1))? ((cnt_filter == 1 && cnt_channel == 1 && cnt_line == 1) ? 0 : ((STRIDE == 1) ? 1 : ((((cnt_line-i-1)%STRIDE == 1 || cnt_line == 1) && (cnt_index%STRIDE == 1)) ? 1 : 0))) : 0;
        wr_en[i] <= ((cnt_filter > 0) && ((cnt_line >= (i+1) && cnt_line <= (IFM_SIZE-KERNEL_SIZE+i+1)) && (cnt_index > KERNEL_SIZE || cnt_index == 0)) || (i == KERNEL_SIZE-1 && cnt_line == 0 && cnt_index == 0))? ((cnt_filter == 0 || curr_state == END_CONV || curr_state == IDLE) ? 0 : ((STRIDE == 1) ? 1 : (((((cnt_line-i)%STRIDE == 1 || cnt_line == 1) && ((cnt_index-KERNEL_SIZE)%STRIDE == 1 || cnt_index == 0)) || (cnt_line == 0 || cnt_channel == 0)) ? 1 : 0))) : 0;
      end
    end
  endgenerate

  always @(posedge clk1 or negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_index   <= 0;
      cnt_line    <= 0;
      cnt_channel <= 0;
      cnt_filter  <= 0;
      set_reg     <= 0;
      set_wgt     <= 0;
      end_conv    <= 0;
      rd_clr      <= 0;
      wr_clr      <= 0;
      set_ifm     <= 0;
    end 
    else
    begin
      case (next_state)
        IDLE:
        begin
          cnt_index   <= 0;
          cnt_line    <= 0;
          cnt_channel <= 0;
          cnt_filter  <= 0;
          set_reg     <= 0;
          set_wgt     <= 0;
          end_conv    <= 0;
          rd_clr      <= 0;
          wr_clr      <= 0;
          set_ifm     <= 0;
        end
        COMPUTE:
        begin
          cnt_index   <= cnt_index + 1;
          cnt_line    <= (cnt_index == 0)? cnt_line + 1:cnt_line;
          cnt_channel <= (cnt_index == 0 & cnt_line == 0)? cnt_channel + 1:cnt_channel;
          cnt_filter  <= (cnt_index == 0 & cnt_line == 0 & cnt_channel == 0)? cnt_filter + 1:cnt_filter;
          set_reg     <= 1;
          set_wgt     <= (cnt_index == 0 && cnt_line == 0)? 1 : (set_wgt << 1);
          rd_clr      <= (cnt_index == IFM_SIZE - KERNEL_SIZE + 2)? 1 : 0;
          wr_clr      <= (cnt_index == KERNEL_SIZE)? 1 : 0;
          set_ifm     <= 1;
        end
        END_ROW:
        begin
          cnt_index   <= 0;
          set_reg     <= 1;
          set_wgt     <= set_wgt << 1;
          set_ifm     <= 0;
        end
        END_CHANNEL:
        begin
          cnt_index   <= 0;
          cnt_line    <= 0;
          set_reg     <= 1;
          set_wgt     <= set_wgt << 1;
          set_ifm     <= 0;
        end
        END_FILTER:
        begin
          cnt_index   <= 0;
          cnt_line    <= 0;
          cnt_channel <= 0;
          set_reg     <= 1;
          set_wgt     <= set_wgt << 1;
          set_ifm     <= 0;
        end
        END_CONV:
        begin
          cnt_index   <= cnt_index + 1;
          cnt_line    <= 1;
          cnt_channel <= 1;
          set_reg     <= 0;
          set_wgt     <= 0;
          end_conv    <= (cnt_index == IFM_SIZE-KERNEL_SIZE+2) ? 1 : 0;
          set_ifm     <= 0;
          rd_clr      <= (cnt_index == IFM_SIZE - KERNEL_SIZE + 2)? 1 : 0;
        end
        default:
        begin
          cnt_index   <= cnt_index;
          cnt_line    <= cnt_line;
          cnt_channel <= cnt_channel;
          cnt_filter  <= cnt_filter;
          set_reg     <= set_reg;
          set_wgt     <= set_wgt;
          end_conv    <= end_conv;
          wr_clr      <= wr_clr;
          rd_clr      <= rd_clr;
          set_ifm     <= set_ifm;
        end
      endcase

    end
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n)
      out_valid <= 0;
    else begin
      if ((cnt_channel == CI && cnt_line > KERNEL_SIZE) || (cnt_channel == 1 && cnt_line == 1))
        out_valid <= rd_en[KERNEL_SIZE-1];
      else
        out_valid <= 0;
    end
  end

  assign ifm_read = ((cnt_line > PAD && cnt_line <= IFM_SIZE-PAD) && (cnt_index > PAD && cnt_index <= IFM_SIZE-PAD)) ? 1 : 0;
  assign wgt_read = (|set_wgt) ? 1 : 0;

  assign addr_x = (cnt_index >= 2) ? cnt_index - 2 : cnt_index + IFM_SIZE - 1;
  assign addr_y = (cnt_line >= KERNEL_SIZE) ? cnt_line - KERNEL_SIZE : cnt_line + IFM_SIZE - KERNEL_SIZE;
  assign addr_c = cnt_filter - 1;
endmodule
