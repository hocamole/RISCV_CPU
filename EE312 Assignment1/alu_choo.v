`timescale 1ns / 100ps

module ALU(A,B,OP,C,Cout);

	input [15:0]A;
	input [15:0]B;
	input [3:0]OP;
	output [15:0]C;
	output Cout;

	//TODO BEGINING
	reg [15:0]C;
	reg Cout;

	always @(*) begin
		if (OP == 4'b0000) begin //16-bit Addition
			C = A + B;
			if ((A[15]) == B[15]) begin //overflow check step 1
				if (C[15] != B[15]) //overflow check step 2
					Cout = 1;
				else
					Cout = 0;
			end
			else
				Cout = 0;
		end
		if (OP == 4'b0001) begin //16bit-Subtraction
			C = A - B;
			if (A[15] != B[15]) begin //overflow check step 1
				if (C[15] == B[15]) //overflow check step 2
					Cout = 1;
				else
					Cout = 0;
			end
			else
				Cout = 0;
		end
		if (OP == 4'b1010) begin //Logical right shift
			C = A>>1;
			Cout = 0;
		end
		if (OP == 4'b1011) begin //Arithmetic right shift
			C = A>>>1;
			Cout = 0;
			if (A[15] == 1)
				C[15] = 1;
		end
		if (OP == 4'b1100) begin //Rotate right
			C = A>>1;
			C[15] = A[0];
			Cout = 0;
		end
		if (OP == 4'b1101) begin //Logical left shift
			C = A<<1;
			Cout = 0;
		end
		if (OP == 4'b1110) begin //Arithmetic left shift
			C = A<<<1;
			Cout = 0;
		end
		if (OP == 4'b1111) begin //Rotate left
			C = A<<1;
			C[0] = A[15];
			Cout = 0;
		end
	end
	//TODO END

endmodule