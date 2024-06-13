module POOL_CONTROL #(parameter KERNEL_POOL = 4, IFM_SIZE = 9, STRIDE_POOL = 2, CI = 3)(
  input clk1,
  input clk2,
  input rst_n,
  input full,
  output reg set_ifm,
  output reg ifm_read,
  output reg rd_clr,
  output reg wr_clr,
  output reg out_valid,
  output reg set_reg,
  output reg end_pool,
  output reg [KERNEL_POOL-1:0] rd_en,
  output reg [KERNEL_POOL-1:0] wr_en
);

  reg [7:0] cnt_index;
  reg [7:0] cnt_line;
  reg [8:0] cnt_channel;

  reg [2:0] curr_state;
  reg [2:0] next_state;

  reg end_reg;

  parameter [2:0] 
    IDLE        = 3'b000,
    COMPUTE     = 3'b001,
    END_ROW     = 3'b010,
    END_CHANNEL = 3'b011,
    END_FILTER  = 3'b100,
    END_POOL    = 3'b101;

  always @(posedge clk1 or negedge rst_n)
  begin
    if (!rst_n)
      curr_state <= IDLE;
    else
      curr_state <= next_state;
  end

  always @(full or cnt_index or cnt_line or cnt_channel)
  begin
    case (curr_state)
      IDLE:
      begin
        if (full)
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
      begin
        if (full)
          next_state = COMPUTE;
        else
          next_state = END_ROW;
      end
      END_CHANNEL:
      begin
        if (full)
          next_state = COMPUTE;
        else
          next_state = END_CHANNEL;
      end
      END_FILTER:
        next_state = END_POOL;
      END_POOL:
        if (cnt_index > IFM_SIZE-KERNEL_POOL+2)
          next_state = IDLE;
        else
          next_state = END_POOL;
      default:
        next_state = IDLE;
    endcase
  end

  genvar ii;
  generate
    for (ii = 0; ii < KERNEL_POOL; ii = ii + 1) begin
      always @(posedge clk1) begin
        rd_en[ii] <= (((cnt_line >= (ii+2) && cnt_line <= (IFM_SIZE-KERNEL_POOL+ii+2) && ((cnt_line-ii-2)%STRIDE_POOL == 0)) || (ii == KERNEL_POOL-1 && cnt_line == 1 && cnt_channel != 1)) && (|cnt_index && cnt_index <= IFM_SIZE-KERNEL_POOL+1 && ((cnt_index-1)%STRIDE_POOL == 0))) ? 1 : 0;
        wr_en[ii] <= ((next_state != END_POOL) && (cnt_line >= (ii+1) && cnt_line <= (IFM_SIZE-KERNEL_POOL+ii+1) && ((cnt_line-ii-1)%STRIDE_POOL == 0)) && (cnt_index >= KERNEL_POOL && ((cnt_index-KERNEL_POOL)%STRIDE_POOL == 0)))? 1 : 0;
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
      set_reg     <= 0;
      end_reg     <= 0;
      rd_clr      <= 0;
      wr_clr      <= 0;
      set_ifm     <= 0;
      ifm_read    <= 0;
    end 
    else
    begin
      case (next_state)
        IDLE:
        begin
          cnt_index   <= 0;
          cnt_line    <= 0;
          cnt_channel <= 0;
          set_reg     <= 0;
          rd_clr      <= 0;
          wr_clr      <= 0;
          set_ifm     <= 0;
          ifm_read    <= 0;
          end_reg     <= (cnt_index == IFM_SIZE-KERNEL_POOL+3) ? 1 : 0;
        end
        COMPUTE:
        begin
          cnt_index   <= cnt_index + 1;
          cnt_line    <= (|cnt_index == 1'b0)? cnt_line + 1:cnt_line;
          cnt_channel <= (|cnt_index == 1'b0 && |cnt_line == 1'b0)? cnt_channel + 1:cnt_channel;
          set_reg     <= 1;
          rd_clr      <= 0;
          wr_clr      <= (cnt_index == KERNEL_POOL)? 1 : 0;
          set_ifm     <= 1;
          ifm_read    <= 1;
        end
        END_ROW:
        begin
          cnt_index   <= 0;
          rd_clr      <= 1;
          set_ifm     <= 0;
          ifm_read    <= 0;
        end
        END_CHANNEL:
        begin
          cnt_index   <= 0;
          cnt_line    <= 0;
          rd_clr      <= 1;
          set_ifm     <= 0;
          ifm_read    <= 0;
        end
        END_FILTER:
        begin
          cnt_index   <= 0;
          cnt_line    <= 0;
          cnt_channel <= 0;
          rd_clr      <= 1;
          set_ifm     <= 0;
          ifm_read    <= 0;
        end
        END_POOL:
        begin
          cnt_index   <= cnt_index + 1;
          cnt_line    <= 1;
          cnt_channel <= CI + 1;
          set_reg     <= 0;
          set_ifm     <= 0;
          rd_clr      <= 0;
          ifm_read    <= 0;
        end
        default:
        begin
          cnt_index   <= cnt_index;
          cnt_line    <= cnt_line;
          cnt_channel <= cnt_channel;
          set_reg     <= set_reg;
          set_ifm     <= set_ifm;
          end_reg     <= end_reg;
          wr_clr      <= wr_clr;
          rd_clr      <= rd_clr;
          ifm_read    <= ifm_read;
        end
      endcase
    end
  end

  always @(posedge clk2 or negedge rst_n)
  begin
    if (!rst_n) begin
      out_valid <= 0;
      end_pool  <= 0;
    end
    else begin
      out_valid <= rd_en[KERNEL_POOL-1];
      end_pool  <= end_reg;
    end
  end

endmodule
