module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN,
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

	//D-Memory Signals
	output wire D_MEM_CSN,
	input wire [31:0] D_MEM_DI,
	output wire [31:0] D_MEM_DOUT,
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN,
	output wire [3:0] D_MEM_BE,

	//RegFile Signals
	output wire RF_WE,
	output wire [4:0] RF_RA1,
	output wire [4:0] RF_RA2,
	output wire [4:0] RF_WA1,
	input wire [31:0] RF_RD1,
	input wire [31:0] RF_RD2,
	output wire [31:0] RF_WD,
	output wire HALT,
	output reg [31:0] NUM_INST,
	output wire [31:0] OUTPUT_PORT
	);

	// TODO: implement multi-cycle CPU
	reg [11:0] PC; // program counter
	wire PCSrc, AUIPC, JUMP, alu_cmp;
	wire [3:0] ALUCode;
	wire [2:0] format_type, WhatToReg;
	wire [1:0] ALUSrc, WhatToOut;
	wire [31:0] immediate, alu_out, ls_fill_out;

	// registers for multi cycle implementation
	wire RF_WE_TEMP, D_MEM_WEN_TEMP;
	reg RF_WE_REAL, D_MEM_WEN_REAL;
	reg [2:0] state; //0:IF, 1:ID, 2:EX, 3:MEM, 4:WB
	reg [11:0] RG_ALU1, RG_ALU2_1, RG_ALU2_2;
	reg [31:0] RG_ID, RG_ALU0_1, RG_ALU0_2, RG_MEM_ADDR, RG_MEM_DOUT, RG_WB;

	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;
	assign D_MEM_DOUT = RG_MEM_DOUT;
	assign D_MEM_ADDR = RG_MEM_ADDR & 'h3FFF;

	assign RF_RA1 = RG_ID[19:15];
	assign RF_RA2 = RG_ID[24:20];
	assign RF_WA1 = RG_ID[11:7];

	wire [31:0] mux1_0, mux1_1, mux1_2;
	wire [31:0] mux2_0, mux2_1, mux2_2, mux2_3;
	wire [31:0] mux3_0, mux3_1, mux3_2, mux3_3, mux3_4;
	reg [31:0] mux1_out, mux2_out, mux3_out;

	assign mux1_0 = RF_RD2;
	assign mux1_1 = immediate;
	assign mux1_2 = RG_ID[24:20];

	assign mux2_0 = RG_ALU1 + 'd4;
	assign mux2_1 = mux1_1;
	assign mux2_2 = RG_ALU2_1 + RG_ALU2_2;
	assign mux2_3 = alu_out;

	assign mux3_0 = mux2_3;
	assign mux3_1 = ls_fill_out;
	assign mux3_2 = mux1_1; 
	assign mux3_3 = mux2_2;
	assign mux3_4 = mux2_0;

	// decide mux1_out
	assign mux1_out = (ALUSrc == 0) ? mux1_0 :
							(ALUSrc == 1) ? mux1_1 : mux1_2;
	// mux3_out
	assign mux3_out = (WhatToReg == 0) ? mux3_0 :
							(WhatToReg == 1) ? mux3_1 :
							(WhatToReg == 'd2) ? mux3_2 :
							(WhatToReg == 'd3) ? mux3_3 : mux3_4;
	// decide mux2_out
	assign mux2_out = (((AUIPC | JUMP | (alu_cmp & RG_ID[6]))==0) && (PCSrc==0)) ? mux2_0 :
							(((AUIPC | JUMP | (alu_cmp & RG_ID[6]))==0) && (PCSrc==1)) ? mux2_1 :
							(((AUIPC | JUMP | (alu_cmp & RG_ID[6]))==1) && (PCSrc==0)) ? mux2_2 : mux2_3;

	assign RF_WD = RG_WB;
	
	assign RF_WE = RF_WE_REAL;
	assign D_MEM_WEN = D_MEM_WEN_REAL;

	assign OUTPUT_PORT = (WhatToOut == 0) ? mux3_out :
									(WhatToOut == 1) ? (alu_cmp & RG_ID[6]) : alu_out;

	// check condition for HALT
	assign HALT = ((I_MEM_DI == 'h00008067) && (RF_RD1 == 'h0000000c)) ? 1 : 0;

	CTRL ctrl1(RG_ID, PCSrc, WhatToReg, D_MEM_BE,
				D_MEM_WEN_TEMP, ALUSrc, RF_WE_TEMP, 
				ALUCode, format_type, AUIPC, JUMP, WhatToOut);
	IMM_GEN imm_gen1(RG_ID, format_type, immediate);
	ALU_RISCV alu_riscv1(RG_ALU0_1, RG_ALU0_2, ALUCode, alu_out, alu_cmp);
	LS_FILL ls_fill1(D_MEM_DI, D_MEM_BE, ls_fill_out);

	initial begin
		NUM_INST <= 0;
		PC <= 'h000;
		mux2_out <= 'h00000000;
		I_MEM_ADDR <= 'h000;
		state <= 'b001;
		RF_WE_REAL <= 0;
		D_MEM_WEN_REAL <= 1;
	end

	always @ (negedge CLK) begin
		if (RSTn) begin
			if (state == 3'b000) begin // IF stage
				state <= 3'b001;
				RF_WE_REAL <= 0;
				D_MEM_WEN_REAL <= 1;
				if (NUM_INST > 0) begin
					PC <= mux2_out & 'hFFF;
					I_MEM_ADDR <= mux2_out & 'hFFF;
				end
			end
// -----------------------------------------------------------------------------------------
			else if (state == 3'b001) begin // ID stage
				state <= 3'b010;
				RG_ID <= I_MEM_DI;
			end
// -----------------------------------------------------------------------------------------
			else if (state == 3'b010) begin // EXE stage
				RG_ALU1 <= PC;
				RG_ALU0_1 <= RF_RD1;
				RG_ALU0_2 <= mux1_out;
				if (RG_ID[6:0]==7'b0000011 || format_type == 'd2) state <= 3'b011; // load or store
				else if (format_type == 'd4) begin // branch
					NUM_INST <= NUM_INST + 1;
					state <= 3'b000;
					RG_ALU2_1 <= PC;
					RG_ALU2_2 <= immediate;
				end
				else if (RG_ID[2:0]==3'b111) begin // JAL or JALR
					state <= 3'b100;
					RG_ALU2_1 <= PC;
					RG_ALU2_2 <= immediate;
				end
				else state <= 3'b100; // rest of instructions (R type + I type except for JALR and load)
			end
// -----------------------------------------------------------------------------------------
			else if (state == 3'b011) begin // MEM stage
				RG_MEM_ADDR <= alu_out;
				RG_MEM_DOUT <= RF_RD2;
				if (RG_ID[6:0]==7'b0000011) state <= 3'b100; // load
				else begin
					state <= 3'b000; // store
					D_MEM_WEN_REAL = D_MEM_WEN_TEMP;
					NUM_INST <= NUM_INST + 1;
				end
			end
// -----------------------------------------------------------------------------------------
			else begin // WB stage (100)
				RF_WE_REAL <= RF_WE_TEMP;
				state <= 3'b000;
				NUM_INST <= NUM_INST + 1;
				RG_WB <= mux3_out;			
			end
		end
	end
endmodule //

module IMM_GEN (  
	input reg [31:0] INST_IMM,
	input reg [2:0] format_type_imm,
	output reg [31:0] imm);

	wire [31:0] imm_wire;
	assign imm_wire = (format_type_imm == 1) ? {{20{INST_IMM[31]}}, INST_IMM[31:20]} :
						(format_type_imm == 'd2) ? {{20{INST_IMM[31]}}, INST_IMM[31:25], INST_IMM[11:7]} :
						(format_type_imm == 'd3) ? {INST_IMM[31:12], {12{1'b0}}} :
						(format_type_imm == 'd4) ? {{19{INST_IMM[31]}}, INST_IMM[31], INST_IMM[7], 
															INST_IMM[30:25], INST_IMM[11:8], 1'b0} : // B type
						(format_type_imm == 'd5) ? {{11{INST_IMM[31]}}, INST_IMM[31], INST_IMM[19:12], 
															INST_IMM[20], INST_IMM[30:21], 1'b0} : 0;
	always @(*) begin
		imm = imm_wire;
	end
endmodule

module LS_FILL (
	input wire [31:0] D_MEM_DI_ls,
	input wire [3:0] D_MEM_BE_ls,
	output wire [31:0] lsfill_out);

	assign lsfill_out = (D_MEM_BE_ls == 4'b0001) ? {{24{D_MEM_DI_ls[7]}}, D_MEM_DI_ls[7:0]} :
							(D_MEM_BE_ls == 4'b0011) ? {{16{D_MEM_DI_ls[15]}}, D_MEM_DI_ls[15:0]} :
							(D_MEM_BE_ls == 4'b1001) ? {{24{1'b0}}, D_MEM_DI_ls[7:0]} :
							(D_MEM_BE_ls == 4'b1011) ? {{16{1'b0}}, D_MEM_DI_ls[15:0]} : D_MEM_DI_ls;
endmodule
