module BUFFER #(parameter DATA_WIDTH = 16, KERNEL_SIZE = 4, DEPTH_H = 6, DEPTH_W = 6, CO = 8)(
  clk,
  addr_x,
  addr_y,
  addr_c,
  d_in,
  d_out,
  we,
  re
  );
  
  localparam ADDR_W = $clog2(DEPTH_W);
  localparam ADDR_H = $clog2(DEPTH_H);
  localparam ADDR_C = $clog2(CO);

  input                       clk   ;
  input                       re    ;
  input                       we    ;
  input   [ADDR_W+1:0]        addr_x;
  input   [ADDR_H+1:0]        addr_y;
  input   [ADDR_C+1:0]        addr_c;
  input   [DATA_WIDTH-1:0]    d_in  ;
  output  [DATA_WIDTH-1:0]    d_out ;

  reg [DATA_WIDTH-1:0] tmp_data;
  reg [DATA_WIDTH-1:0] mem [CO-1:0][DEPTH_H-1:0][DEPTH_W-1:0];

  always @(posedge clk)
  begin
    if (we)
      mem[addr_c][addr_y-1][addr_x] <= d_in;
    if (re)
      tmp_data <= mem[addr_c][addr_y][addr_x+1-KERNEL_SIZE];
  end

  assign d_out = tmp_data;

endmodule
