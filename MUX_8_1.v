module MUX_8_1 # (parameter DATA_WIDTH = 16) (
		in1,
		in2,
		in3,
		in4,
		in5,
		in6,
		in7,
		in8,
		sel,
		out
);
    input [DATA_WIDTH-1:0] in1 ;
    input [DATA_WIDTH-1:0] in2 ;
    input [DATA_WIDTH-1:0] in3 ;
    input [DATA_WIDTH-1:0] in4 ;
    input [DATA_WIDTH-1:0] in5 ;
    input [DATA_WIDTH-1:0] in6 ;
    input [DATA_WIDTH-1:0] in7 ;
    input [DATA_WIDTH-1:0] in8 ;
    input [3:0] sel ;
    output reg [DATA_WIDTH-1:0] out ; 

    always @(*) begin
        case (sel)
            4'b0001: out = in1;
            4'b0010: out = in2;
            4'b0011: out = in3;
            4'b0100: out = in4;
            4'b0101: out = in5;
            4'b0110: out = in6;
            4'b0111: out = in7;
						4'b1000: out = in8;
            default: out = 1'b0; // Default case to handle unexpected values of sel
        endcase
    end

endmodule

