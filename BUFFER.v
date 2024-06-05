module BUFFER #(parameter DATA_WIDTH = 16, IFM_SIZE = 9, KERNEL_SIZE = 4, STRIDE = 2, PAD = 2)(
  clk,
  addr_x,
  addr_y,
  d_in,
  d_out,
  we,
  re
  );
  
  localparam ADDR = $clog2(IFM_SIZE-KERNEL_SIZE+2*PAD+1);

  input                       clk   ;
  input                       re    ;
  input                       we    ;
  input   [ADDR+1:0]          addr_x;
  input   [ADDR+1:0]          addr_y;
  input   [DATA_WIDTH-1:0]    d_in  ;
  output  [DATA_WIDTH-1:0]    d_out ;

  reg [DATA_WIDTH-1:0] tmp_data;
  reg [DATA_WIDTH-1:0] mem [(IFM_SIZE-KERNEL_SIZE+2*PAD)/STRIDE:0][(IFM_SIZE-KERNEL_SIZE+2*PAD)/STRIDE:0];

  always @(posedge clk)
  begin
    if (we)
      mem[(addr_y-1)/STRIDE][addr_x/STRIDE] <= d_in;
    if (re)
      tmp_data <= mem[(addr_y)/STRIDE][(addr_x+1-KERNEL_SIZE)/STRIDE];
    else
      tmp_data <= 0;
  end

  assign d_out = tmp_data;

endmodule
