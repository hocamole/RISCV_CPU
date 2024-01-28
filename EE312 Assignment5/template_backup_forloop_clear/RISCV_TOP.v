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
	output wire HALT,                   // if set, terminate program
	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT      // equal RF_WD this port is used for test
	);

	// TODO: implement pipelined CPU
	wire PCSrc, JUMP, alu_cmp, Branch, RF_WE_TEMP, SWFD;
	wire [3:0] ALUCode;
	wire [2:0] format_type, WhatToReg;
	wire [1:0] ALUSrc, WhatToOut, FDSrc5, FDSrc6;
	wire [31:0] immediate, alu_out, ls_fill_out;
	wire [3:0] D_MEM_BE_TEMP;
	wire D_MEM_WEN_TEMP;

	// registers that deliever data (address, value, etc. black line)
	reg [11:0] PC_F, PC_L; // program counter
	reg [11:0] RG_ID_PC_F, RG_ID_PC_L;
	reg [31:0] RG_ID_F, RG_ID_L;
	reg [31:0] RG_EX_ALU_1_F, RG_EX_ALU_2_F, 
				 RG_EX_ALU_1_L, RG_EX_ALU_2_L;
	reg [31:0] RG_EX_ADD2_1_F, RG_EX_ADD2_2_F, 
				 RG_EX_ADD2_1_L, RG_EX_ADD2_2_L;
	reg [31:0] RG_EX_RD2_F, RG_EX_RD2_L;
	reg RG_EX_LWPR_F, RG_EX_LWPR_L,   // if LW instruction appear, we need 'pause and remain'
		 RG_MEM_LWPR_F, RG_MEM_LWPR_L,
		 RG_WB_LWPR_F, RG_WB_LWPR_L;
	reg [14:0] RG_MEM_ADDR_F, RG_MEM_ADDR_L,
				 RG_WB_ADDR_F, RG_WB_ADDR_L;
	reg [31:0] RG_MEM_DOUT_F, RG_MEM_DOUT_L; 
	reg [31:0] RG_WB_F, RG_WB_L;
	reg [31:0] RG_WB_DO_F;
	reg [4:0] RG_EX_RA1_F, RG_EX_RA1_L, RG_MEM_RA1_F, RG_MEM_RA1_L, RG_WB_RA1_F;
	reg [5:0] RG_EX_RA2_F, RG_EX_RA2_L, RG_MEM_RA2_F, RG_MEM_RA2_L, RG_WB_RA2_F;
	reg [6:0] RG_EX_WA_F, RG_EX_WA_L, RG_MEM_WA_F, RG_MEM_WA_L, RG_WB_WA_F;
	reg RG_MEM_BTaken_F, RG_MEM_BTaken_L, RG_WB_BTaken_F, RG_WB_BTaken_L;

	// registers that deliever control signals to next stage (blue line)
	reg [2:0] RG_ID_FMTYPE_F, RG_ID_FMTYPE_L;
	reg [1:0] RG_ID_ALUSrc_F, RG_ID_ALUSrc_L;
	reg RG_ID_PCSrc_F, RG_ID_PCSrc_L,
		 RG_EX_PCSrc_F, RG_EX_PCSrc_L;
	reg RG_ID_JUMP_F, RG_ID_JUMP_L,
		 RG_EX_JUMP_F, RG_EX_JUMP_L;
	reg RG_ID_Branch_F, RG_ID_Branch_L,
		 RG_EX_Branch_F, RG_EX_Branch_L;
	reg [3:0] RG_ID_ALUCode_F, RG_ID_ALUCode_L,
				RG_EX_ALUCode_F, RG_EX_ALUCode_L;
	reg RG_ID_DMEMWEN_F, RG_ID_DMEMWEN_L,
		 RG_EX_DMEMWEN_F, RG_EX_DMEMWEN_L,
		 RG_MEM_DMEMWEN_F, RG_MEM_DMEMWEN_L;
	reg [3:0] RG_ID_DMEMBE_F, RG_ID_DMEMBE_L,
				RG_EX_DMEMBE_F, RG_EX_DMEMBE_L,
				RG_MEM_DMEMBE_F, RG_MEM_DMEMBE_L;
	reg [2:0] RG_ID_WhatToReg_F, RG_ID_WhatToReg_L,
				RG_EX_WhatToReg_F, RG_EX_WhatToReg_L,
				RG_MEM_WhatToReg_F, RG_MEM_WhatToReg_L;
	reg [1:0] RG_ID_WhatToOut_F, RG_ID_WhatToOut_L,
				RG_EX_WhatToOut_F, RG_EX_WhatToOut_L,
				RG_MEM_WhatToOut_F, RG_MEM_WhatToOut_L,
				RG_WB_WhatToOut_F, RG_WB_WhatToOut_L;
	reg RG_ID_RFWE_F, RG_ID_RFWE_L,
		 RG_EX_RFWE_F, RG_EX_RFWE_L,
		 RG_MEM_RFWE_F, RG_MEM_RFWE_L,
		 RG_WB_RFWE_F, RG_WB_RFWE_L;

	// other registers
	reg [31:0] NUM_INST_initial,  // for NUM_INST
				NUM_INST_ID_F, NUM_INST_ID_L, 
				NUM_INST_EX_F, NUM_INST_EX_L,
				NUM_INST_MEM_F, NUM_INST_MEM_L,
				NUM_INST_WB_F;
	reg [31:0] RG_EX_INST_F, RG_EX_INST_L, RG_MEM_INST_F, RG_MEM_INST_L, RG_WB_INST_F; //for HALT
	reg [1:0] flush;

	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;
	assign D_MEM_DOUT = RG_MEM_DOUT_L;
	assign D_MEM_ADDR = RG_MEM_ADDR_L & 'h3FFF;
	assign D_MEM_BE = RG_MEM_DMEMBE_L;
	assign D_MEM_WEN = RG_MEM_DMEMWEN_L;

	assign RF_RA1 = RG_ID_L[19:15];
	assign RF_RA2 = RG_ID_L[24:20];
	assign RF_WA1 = RG_WB_WA_F[4:0];
	assign RF_WE = RG_WB_RFWE_F;
	assign RF_WD = RG_WB_F;

	wire [31:0] mux1_0, mux1_1, mux1_2;
	wire [31:0] mux2_0, mux2_2, mux2_3; // deleted mux2_1. can't remember why I made 2_1...;;;
	wire [31:0] mux3_0, mux3_1, mux3_2, mux3_3, mux3_4;
	wire [31:0] mux5_0, mux5_1, mux5_2, mux5_3; // mux for forwarding
	wire [31:0] mux6_0, mux6_1, mux6_2, mux6_3; // mux for forwarding
	wire [31:0] mux7_0, mux7_1;
	reg [31:0] mux1_out, mux2_out, mux3_out, mux5_out, mux6_out, mux7_out; // mux4 is output port

	assign mux1_0 = RF_RD2;
	assign mux1_1 = immediate;
	assign mux1_2 = RG_ID_L[24:20];

	assign mux2_0 = PC_L + 'd4;
	//assign mux2_1 = mux1_1;
	assign mux2_2 = RG_EX_ADD2_1_L + RG_EX_ADD2_2_L;
	assign mux2_3 = alu_out;

	assign mux3_0 = RG_MEM_ADDR_L;
	assign mux3_1 = ls_fill_out;
	assign mux3_2 = mux1_1; 
	assign mux3_3 = mux2_2;
	assign mux3_4 = mux2_0;

	assign mux5_0 = RG_EX_ALU_1_F;
	assign mux5_1 = RG_MEM_ADDR_F;
	assign mux5_2 =	RG_WB_ADDR_F;
	assign mux5_3 = RG_WB_DO_F;

	assign mux6_0 = RG_EX_ALU_2_F;
	assign mux6_1 = RG_MEM_ADDR_F;
	assign mux6_2 =	RG_WB_ADDR_F;
	assign mux6_3 = RG_WB_DO_F;

	assign mux7_0 = RG_MEM_DOUT_F;
	assign mux7_1 = RG_WB_F; //forwarding
	
	// decide mux1_out
	assign mux1_out = (RG_ID_ALUSrc_L == 0) ? mux1_0 :
							(RG_ID_ALUSrc_L == 1) ? mux1_1 : mux1_2;
	
	// decide mux2_out
	assign mux2_out = (((RG_EX_JUMP_L | (alu_cmp & RG_EX_Branch_L))==0) && (RG_EX_PCSrc_L==0)) ? mux2_0 :
							(((RG_EX_JUMP_L | (alu_cmp & RG_EX_Branch_L))==1) && (RG_EX_PCSrc_L==0)) ? mux2_2 : mux2_3;

	// decide mux3_out
	assign mux3_out = (RG_MEM_WhatToReg_L == 0) ? mux3_0 :
							(RG_MEM_WhatToReg_L == 1) ? mux3_1 :
							(RG_MEM_WhatToReg_L == 'd2) ? mux3_2 :
							(RG_MEM_WhatToReg_L == 'd3) ? mux3_3 : mux3_4;

	// decide mux5_out, mux6_out
	assign mux5_out = (FDSrc5 == 0) ? mux5_0 :
							(FDSrc5 == 1) ? mux5_1 :
							(FDSrc5 == 'd2) ? mux5_2 : mux5_3;
	assign mux6_out = (FDSrc6 == 0) ? mux6_0 :
							(FDSrc6 == 1) ? mux6_1 :
							(FDSrc6 == 'd2) ? mux6_2 : mux6_3;

	assign mux7_out = (SWFD == 0) ? mux7_0 : mux7_1;
	//assign mux5_out = mux5_0;
	//assign mux6_out = mux6_0;

	// decide mux4_out (output port)
	assign OUTPUT_PORT = (RG_WB_WhatToOut_L == 0) ? RG_WB_L :
									(RG_WB_WhatToOut_L == 1) ? RG_WB_BTaken_L : RG_WB_ADDR_L;

	// check condition for HALT
	assign HALT = ((RG_EX_INST_L== 'h00008067) && (RG_MEM_INST_L == 'h00c00093)) ? 1 : 0;

	CTRL ctrl1(I_MEM_DI, PCSrc, WhatToReg, D_MEM_BE_TEMP,
				D_MEM_WEN_TEMP, ALUSrc, RF_WE_TEMP, 
				ALUCode, format_type, Branch, JUMP, WhatToOut);
	IMM_GEN imm_gen1(RG_ID_L, RG_ID_FMTYPE_L, immediate);
	FWRD fwrd1(RG_MEM_INST_F, RG_EX_INST_F, RG_EX_RA1_F, RG_EX_RA2_F, 
					RG_MEM_WA_F, RG_WB_WA_F, 
					RG_WB_LWPR_F, FDSrc5, FDSrc6, SWFD);
	ALU_RISCV alu_riscv1(RG_EX_ALU_1_L, RG_EX_ALU_2_L, RG_EX_ALUCode_L, alu_out, alu_cmp);
	LS_FILL ls_fill1(D_MEM_DI, RG_MEM_DMEMBE_L, ls_fill_out);

	initial begin
		NUM_INST <= 0;
		PC_F <= 'h000;
		PC_L <= 'h000;
		I_MEM_ADDR <= 'h000;
		NUM_INST_initial <= 0;
		NUM_INST_ID_F <= 0;
		NUM_INST_ID_L <= 0;
		NUM_INST_EX_F <= 0;
		NUM_INST_EX_L <= 0;
		NUM_INST_MEM_F <= 0;
		NUM_INST_MEM_L <= 0;
		NUM_INST_WB_F <= 0;
		RG_ID_JUMP_F <= 0;
		RG_ID_JUMP_L <= 0;
		RG_EX_JUMP_F <= 0;
		RG_EX_JUMP_L <= 0;
		RG_ID_PCSrc_F <= 0;
		RG_ID_PCSrc_L <= 0;
		RG_EX_PCSrc_F <= 0;
		RG_EX_PCSrc_L <= 0;
		RG_ID_Branch_F <= 0;
		RG_ID_Branch_L <= 0;
		RG_EX_Branch_F <= 0;
		RG_EX_Branch_L <= 0;
		RG_EX_LWPR_F <= 0;
		RG_EX_LWPR_L <= 0;
		RG_MEM_LWPR_F <= 0;
		RG_MEM_LWPR_F <= 0;
		flush <= 0;
	end

	always @ (negedge CLK) begin
		if (RSTn) begin
			if (NUM_INST_initial == 0) NUM_INST_initial <= 1;
			if ((RG_MEM_LWPR_F == 1 || RG_ID_F[5:4] != 2'b00) && flush != 1) begin
				NUM_INST_initial = NUM_INST_initial + 1;
			end
			if (flush == 1) begin
				if (~RG_EX_LWPR_F) NUM_INST_initial = NUM_INST_initial - 1; 
			end

			if (~RG_MEM_LWPR_F) begin
				PC_L <= PC_F;
				RG_ID_L <= RG_ID_F;
				RG_ID_PC_L <= RG_ID_PC_F;
				RG_ID_FMTYPE_L <= RG_ID_FMTYPE_F;
				RG_ID_ALUSrc_L <= RG_ID_ALUSrc_F;
				RG_ID_ALUCode_L <= RG_ID_ALUCode_F;
				RG_ID_Branch_L <= RG_ID_Branch_F;
				RG_ID_DMEMBE_L <= RG_ID_DMEMBE_F;
				RG_ID_DMEMWEN_L <= RG_ID_DMEMWEN_F;
				RG_ID_JUMP_L <= RG_ID_JUMP_F;
				RG_ID_PCSrc_L <= RG_ID_PCSrc_F;
				RG_ID_RFWE_L <= RG_ID_RFWE_F;
				RG_ID_WhatToOut_L <= RG_ID_WhatToOut_F;
				RG_ID_WhatToReg_L <= RG_ID_WhatToReg_F;
			end

			if (flush == 0) begin
				RG_EX_ADD2_1_L <= RG_EX_ADD2_1_F;
				RG_EX_ADD2_2_L <= RG_EX_ADD2_2_F;
				RG_EX_ALU_1_L <= mux5_out;
				RG_EX_ALU_2_L <= mux6_out;
				RG_EX_RA1_L <= RG_EX_RA1_F;
				RG_EX_RA2_L <= RG_EX_RA2_F;
				RG_EX_RFWE_L <= RG_EX_RFWE_F;
				RG_EX_ALUCode_L <= RG_EX_ALUCode_F;
				
				RG_EX_WA_L <= RG_EX_WA_F;
				RG_EX_WhatToOut_L <= RG_EX_WhatToOut_F;
				RG_EX_WhatToReg_L <= RG_EX_WhatToReg_F;
				RG_EX_RD2_L <= RG_EX_RD2_F;
				
				RG_EX_DMEMBE_L <= RG_EX_DMEMBE_F;
				RG_EX_DMEMWEN_L <= RG_EX_DMEMWEN_F;
				RG_EX_PCSrc_L <= RG_EX_PCSrc_F;
				RG_EX_LWPR_L <= RG_EX_LWPR_F;
				RG_EX_INST_L <= RG_EX_INST_F;
				NUM_INST_EX_L <= NUM_INST_EX_F;
			end
			RG_EX_Branch_L <= RG_EX_Branch_F;
			RG_EX_JUMP_L <= RG_EX_JUMP_F;

			RG_MEM_ADDR_L <= RG_MEM_ADDR_F;
			RG_WB_ADDR_L <= RG_WB_ADDR_F;
			RG_MEM_DMEMBE_L <= RG_MEM_DMEMBE_F;
			RG_MEM_DMEMWEN_L <= RG_MEM_DMEMWEN_F;
			RG_MEM_DOUT_L <= mux7_out;
			RG_MEM_RFWE_L <= RG_MEM_RFWE_F;
			RG_MEM_WhatToOut_L <= RG_MEM_WhatToOut_F;
			RG_MEM_RA1_L <= RG_MEM_RA1_F;
			RG_MEM_RA2_L <= RG_MEM_RA2_F;
			RG_MEM_WA_L <= RG_MEM_WA_F;
			RG_MEM_WhatToReg_L <= RG_MEM_WhatToReg_F;
			RG_MEM_LWPR_L <= RG_MEM_LWPR_F;
			RG_MEM_INST_L <= RG_MEM_INST_F;
			RG_MEM_BTaken_L <= RG_MEM_BTaken_F;

			RG_WB_L <= RG_WB_F;
			RG_WB_RFWE_L <= RG_WB_RFWE_F;
			RG_WB_WhatToOut_L <= RG_WB_WhatToOut_F;
			RG_WB_BTaken_L <= RG_WB_BTaken_F;
			RG_WB_LWPR_L <= RG_WB_LWPR_F;

			NUM_INST_ID_L <= NUM_INST_ID_F;
			//NUM_INST_EX_L <= NUM_INST_EX_F;
			NUM_INST_MEM_L <= NUM_INST_MEM_F;
			NUM_INST <= NUM_INST_WB_F;
		end
	end

	always @ (posedge CLK) begin
		if (RSTn) begin
			PC_F <= mux2_out;
			RG_ID_F <= I_MEM_DI;
			RG_ID_PC_F <= PC_L;
			RG_ID_FMTYPE_F <= format_type;
			RG_ID_ALUSrc_F <= ALUSrc;
			RG_ID_ALUCode_F <= ALUCode;
			RG_ID_Branch_F <= Branch;
			RG_ID_DMEMBE_F <= D_MEM_BE_TEMP;
			RG_ID_DMEMWEN_F <= D_MEM_WEN_TEMP;
			RG_ID_JUMP_F <= JUMP;
			RG_ID_PCSrc_F <= PCSrc;
			RG_ID_RFWE_F <= RF_WE_TEMP;
			RG_ID_WhatToOut_F <= WhatToOut;
			RG_ID_WhatToReg_F <= WhatToReg;

			RG_EX_ADD2_1_F <= RG_ID_PC_L;
			RG_EX_ADD2_2_F <= immediate;
			RG_EX_ALU_1_F <= RF_RD1;
			RG_EX_ALU_2_F <= mux1_out;
			RG_EX_RA1_F <= RF_RA1;
			RG_EX_RA2_F[4:0] <= RF_RA2;
			if ((RG_ID_L[6:0] == 7'b1100011) || (RG_ID_L[6:0] == 7'b0100011) || (RG_ID_L[6:0] == 7'b0110011)) RG_EX_RA2_F[5] <= 1;
			else RG_EX_RA2_F[5] <= 0;
			RG_EX_RFWE_F <= RG_ID_RFWE_L;
			RG_EX_ALUCode_F <= RG_ID_ALUCode_L;
			RG_EX_Branch_F <= RG_ID_Branch_L;
			if (RG_ID_L[6:4]==3'b000) RG_EX_WA_F[6] <= 1; //Load. So FDSrc will be 3 if condition is satisfied
			else RG_EX_WA_F[6] <= 0;
			if ((RG_ID_L[6:4]==3'b000) || (RG_ID_L[6:4]==3'b001) || (RG_ID_L[6:4]==3'b011)) begin
				RG_EX_WA_F[5] <= 1; // Forwarding available
			end
			else RG_EX_WA_F[5] <= 0;
			RG_EX_WA_F[4:0] <= RG_ID_L[11:7];
			RG_EX_WhatToOut_F <= RG_ID_WhatToOut_L;
			RG_EX_WhatToReg_F <= RG_ID_WhatToReg_L;
			RG_EX_RD2_F = RF_RD2;
			RG_EX_JUMP_F <= RG_ID_JUMP_L;
			RG_EX_DMEMBE_F <= RG_ID_DMEMBE_L;
			RG_EX_DMEMWEN_F <= RG_ID_DMEMWEN_L;
			RG_EX_PCSrc_F <= RG_ID_PCSrc_L;
			if (RG_ID_L[5:4] == 2'b00) RG_EX_LWPR_F <= 1;
			else RG_EX_LWPR_F <= 0;
			RG_EX_INST_F <= RG_ID_L;

			RG_MEM_ADDR_F <= alu_out;
			RG_WB_ADDR_F <= RG_MEM_ADDR_L;
			RG_MEM_DMEMBE_F <= RG_EX_DMEMBE_L;
			RG_MEM_DMEMWEN_F <= RG_EX_DMEMWEN_L;
			RG_MEM_DOUT_F <= RG_EX_RD2_L;
			RG_MEM_RFWE_F <= RG_EX_RFWE_L;
			RG_MEM_WhatToOut_F <= RG_EX_WhatToOut_L;
			RG_MEM_RA1_F <= RG_EX_RA1_L;
			RG_MEM_RA2_F <= RG_EX_RA2_L;
			RG_MEM_WA_F <= RG_EX_WA_L;
			RG_MEM_WhatToReg_F <= RG_EX_WhatToReg_L;
			RG_MEM_LWPR_F <= RG_EX_LWPR_L;
			RG_MEM_INST_F <= RG_EX_INST_L;
			RG_MEM_BTaken_F <= alu_cmp & RG_EX_Branch_L;

			RG_WB_F <= mux3_out;
			RG_WB_RFWE_F <= RG_MEM_RFWE_L;
			RG_WB_WhatToOut_F <= RG_MEM_WhatToOut_L;
			RG_WB_WA_F <= RG_MEM_WA_L;
			RG_WB_RA1_F <= RG_MEM_RA1_L;
			RG_WB_RA2_F <= RG_MEM_RA2_L;
			RG_WB_INST_F <= RG_MEM_INST_L;
			RG_WB_BTaken_F <= RG_MEM_BTaken_L;
			RG_WB_LWPR_F <= RG_MEM_LWPR_L;
			RG_WB_DO_F <= D_MEM_DI;

			NUM_INST_ID_F <= NUM_INST_initial;
			NUM_INST_EX_F <= NUM_INST_ID_L;
			NUM_INST_MEM_F <= NUM_INST_EX_L;
			NUM_INST_WB_F <= NUM_INST_MEM_L;
			
			if (flush == 0) begin
				if ((RG_EX_JUMP_L | (alu_cmp & RG_EX_Branch_L))==1) flush <= 1;
			end
			else if (flush == 1) flush = flush + 1;
			else if (flush == 'd2) flush <= 0;
 		end
	end

	always @ (*) begin
		I_MEM_ADDR <= PC_L;
	end

endmodule

//-------------------------------------------------------------------------------------------------------------

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

//-------------------------------------------------------------------------------------------------------------

module LS_FILL (
	input wire [31:0] D_MEM_DI_ls,
	input wire [3:0] D_MEM_BE_ls,
	output wire [31:0] lsfill_out);

	assign lsfill_out = (D_MEM_BE_ls == 4'b0001) ? {{24{D_MEM_DI_ls[7]}}, D_MEM_DI_ls[7:0]} :
							(D_MEM_BE_ls == 4'b0011) ? {{16{D_MEM_DI_ls[15]}}, D_MEM_DI_ls[15:0]} :
							(D_MEM_BE_ls == 4'b1001) ? {{24{1'b0}}, D_MEM_DI_ls[7:0]} :
							(D_MEM_BE_ls == 4'b1011) ? {{16{1'b0}}, D_MEM_DI_ls[15:0]} : D_MEM_DI_ls;
endmodule