//file: qmult.v
`timescale 1ns / 1ps
module qmult_feed #(
	//Parameterized values
	parameter Q_a = 8,
	parameter N_a = 16,
	parameter Q_b = 10,
	parameter N_b = 16,
	parameter Q_q = 12,
	parameter N_q = 16
	)
	(
	 input			[N_a-1:0]	a,
	 input			[N_b-1:0]	b,
	 output         [N_q-1:0] q_result,    //output quantized to same number of bits as the input
     output			overflow             //signal to indicate output greater than the range of our format
	 );
	
	wire [N_a+N_b-1:0]	f_result;		//	Multiplication by 2 values of N bits requires a 
									//	register that is N+N = 2N deep
	wire [N_a-1:0]   multiplicand; // represent for input a
	wire [N_b-1:0]	multiplier;  // represent for input b
	wire [N_a-1:0]    a_2cmp;  // inverse of a,b
	wire [N_b-1:0] b_2cmp;   // inverse of a,b
	wire [N_q-2:0]    quantized_result,quantized_result_2cmp;
	
	assign a_2cmp = {a[N_a-1],{(N_a-1){1'b1}} - a[N_a-2:0]+ 1'b1};  //2's complement of a
	assign b_2cmp = {b[N_b-1],{(N_b-1){1'b1}} - b[N_b-2:0]+ 1'b1};  //2's complement of b
	
    assign multiplicand = (a[N_a-1]) ? a_2cmp : a;              
    assign multiplier   = (b[N_b-1]) ? b_2cmp : b;
    
    assign q_result[N_q-1] = a[N_a-1]^b[N_b-1];                      //Sign bit of output would be XOR or input sign bits
    assign f_result = multiplicand[N_a-2:0] * multiplier[N_b-2:0]; //We remove the sign bit for multiplication
    assign quantized_result = f_result[N_q-2+Q:Q];               //Quantization of output to required number of bits
    assign quantized_result_2cmp = {(N_q-1){1'b1}} - quantized_result[N_q-2:0] + 1'b1;  //2's complement of quantized_result
    assign q_result[N_q-2:0] = (q_result[N_q-1]) ? quantized_result_2cmp : quantized_result; //If the result is negative, we return a 2's complement representation 
    																					 //of the output value
    assign overflow = (f_result[2*N_q-2:N_q-1+Q_q] > 0) ? 1'b1 : 1'b0;

endmodule