`timescale 1ns / 10ps

module ALU_RISCV(A, B, OP, C, cmp);

	input wire [31:0]A;
	input wire [31:0]B;
	input wire [3:0]OP;
	output reg [31:0]C;
	output reg cmp;

	//TODO BEGINING
	integer i;

	always @(*) begin
		if (OP == 4'b0000) begin //32-bit Addition
			C = A + B;
			cmp = 0;
		end
		if (OP == 4'b0001) begin //32-bit Subtraction
			C = A - B;
			cmp = 0;
		end
		//
		if (OP == 4'b0010) begin // 32-bit and
			C = A & B;
			cmp = 0;
		end
		if (OP == 4'b0011) begin // 32-bit or
			C = A | B;
			cmp = 0;
		end
		if (OP == 4'b0100) begin // Equal to
			if (A == B) begin
				cmp = 1;
				C = 1;
			end
			else begin
				cmp = 0;
				C = 0;
			end
		end
		if (OP == 4'b0101) begin // not equal to
			if (A != B) begin
				cmp = 1;
				C = 1;
			end
			else begin
				cmp = 0;
				C = 0;
			end
		end
		if (OP == 4'b0110) begin // lower than
			if ($signed(A) < $signed(B)) begin
				cmp = 1;
				C = 1;
			end
			else begin
				cmp = 0;
				C = 0;
			end
		end
		if (OP == 4'b0111) begin // Greater than or equal to
			if ($signed(A) >= $signed(B)) begin
				cmp = 1;
				C = 1;
			end
			else begin
				cmp = 0;
				C = 0;
			end
		end
		if (OP == 4'b1000) begin // lower than (unsigned)
			if (A < B) begin
				cmp = 1;
				C = 1;
			end
			else begin
				cmp = 0;
				C = 0;
			end
		end
		if (OP == 4'b1001) begin // Greater than or equal to (unsigned)
			if (A >= B) begin
				cmp = 1;
				C = 1;
			end
			else begin
				cmp = 0;
				C = 0;
			end
		end
		// 
		if (OP == 4'b1010) begin //Logical right shift
			C = A>>B;
			cmp = 0;
		end
		if (OP == 4'b1011) begin //Arithmetic right shift
			for (i=0; i<B; i=i+1) begin
				C = A>>>1;
				if (A[31] == 1) C[31] = 1;			
			end
			cmp = 0;
		end
		if (OP == 4'b1100) begin //Rotate right
			C = A>>1;
			C[15] = A[0];
			cmp = 0;
		end
		if (OP == 4'b1101) begin //Logical left shift
			C = A<<B;
			cmp = 0;
		end
		if (OP == 4'b1110) begin //Arithmetic left shift
			C = A<<<B;
			cmp = 0;
		end
		if (OP == 4'b1111) begin //32 bit xor
			C = A ^ B;
			cmp = 0;
		end
	end
	//TODO END

endmodule