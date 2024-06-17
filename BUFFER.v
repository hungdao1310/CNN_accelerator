module BUFFER #(parameter DATA_WIDTH = 16, IFM_SIZE = 9, KERNEL_SIZE = 4, STRIDE = 2, PAD = 2)(
  clk,
  rst_n,
  d_in,
  d_out,
  we,
  re
  );
  
  localparam DEPTH = (IFM_SIZE-KERNEL_SIZE+2*PAD)/STRIDE+1;
  localparam ADDR  = $clog2(DEPTH*DEPTH);

  input                       clk   ;
  input                       rst_n ;
  input                       re    ;
  input                       we    ;
  input   [DATA_WIDTH-1:0]    d_in  ;
  output  [DATA_WIDTH-1:0]    d_out ;

  reg [ADDR-1:0] rd_ptr;
  reg [ADDR-1:0] wr_ptr;
  reg [DATA_WIDTH-1:0] tmp_data;
  reg [DATA_WIDTH-1:0] mem [DEPTH*DEPTH-1:0];

  always @(posedge clk or rst_n)
  begin
    if (!rst_n)
    begin
      rd_ptr  <= 0;
      wr_ptr  <= 0;
    end
    else
    begin
      if (we)
      begin
        mem[wr_ptr] <= d_in;
        wr_ptr      <= (wr_ptr == DEPTH*DEPTH-1) ? 0 : wr_ptr + 1;
      end
      if (re)
      begin
        tmp_data    <= mem[rd_ptr];
        rd_ptr      <= (rd_ptr == DEPTH*DEPTH-1) ? 0 : rd_ptr + 1;
      end
      else
        tmp_data <= 0;
    end
  end

  assign d_out = tmp_data;

endmodule
