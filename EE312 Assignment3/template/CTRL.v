module CTRL(
    input wire [31:0] INST,

    output reg PCSrc_ctrl, // LSB. 00: normal(+4), 01: JUMP, 10: Branch
    output reg [2:0] WhatToReg_ctrl, // 0: ALU result, 1: Memory out, 2: LUI, 3: AUIPC, 4: JAL&JALR
    output reg [3:0] D_MEM_BE_ctrl,
    output reg D_MEM_WEN_ctrl,
    output reg [1:0] ALUSrc_ctrl, // 0: RF_RD2, 1:immediate, 2:shamt
    output reg RF_WE_ctrl,
    output reg [3:0] ALUCode_ctrl,
    output reg [2:0] format_type_ctrl, // 0:R, 1:I, 2:S, 3:U, 4:B, 5:J  나중에 필요없으면 output에서 빼자
    output reg AUIPC_ctrl,
    output reg JUMP_ctrl,
    output reg [1:0] WhatToOut
    );

    always @(*) begin
        //format type check (refer to riscv-spec pdf p.104)
        if (INST[4:0] == 5'b10111) format_type_ctrl = 'd3; // U type
        if (INST[4:0] == 5'b01111) format_type_ctrl = 'd5; // J type
        else if (INST[6:0] == 7'b1100011) format_type_ctrl = 'd4; // B type
        else if (INST[6:0] == 7'b0100011) format_type_ctrl = 'd2; // S type
        else if ((INST[6:0] == 7'b0000011) || (INST[6:0] == 7'b1100111)) format_type_ctrl = 1; // I type
        else if ((INST[5:0] == 6'b010011) && ((INST[14:12]==3'b000) || (INST[14:12]==3'b010) || 
                                                        (INST[14:12]==3'b011) || (INST[14:12]==3'b100) || 
                                                        (INST[14:12]==3'b110) || (INST[14:12]==3'b111)))
            begin format_type_ctrl = 1; end //also I type
        else format_type_ctrl = 0; // R type
        
        //PCSrc
        if (INST[6:0] == 7'b1100111) PCSrc_ctrl = 1;
        else PCSrc_ctrl = 0;

        //WhatToReg
        if (format_type_ctrl == 'd3) begin
            if (INST[5]==1) WhatToReg_ctrl = 'd2;
            else WhatToReg_ctrl = 'd3;
        end
        else if (format_type_ctrl == 'd5) WhatToReg_ctrl = 'd4;
        else if (INST[6:0] == 7'b0000011) WhatToReg_ctrl = 1;
        else WhatToReg_ctrl = 0;

        //D_MEM_BE
        if (format_type_ctrl == 1) begin
            if (INST[4] == 0) begin
                if (INST[14:12] == 3'b000) D_MEM_BE_ctrl = 4'b0001;
                else if (INST[14:12] == 3'b001) D_MEM_BE_ctrl = 4'b0011;
                else if (INST[14:12] == 3'b010) D_MEM_BE_ctrl = 4'b1111;
                else if (INST[14:12] == 3'b100) D_MEM_BE_ctrl = 4'b1001;
                else if (INST[14:12] == 3'b101) D_MEM_BE_ctrl = 4'b1011;
            end
        end
        else if (format_type_ctrl == 'd2) begin
            if (INST[14:12] == 3'b000) D_MEM_BE_ctrl = 4'b0001;
            else if (INST[14:12] == 3'b001) D_MEM_BE_ctrl = 4'b0011;
            else if (INST[14:12] == 3'b010) D_MEM_BE_ctrl = 4'b1111;
        end
        else D_MEM_BE_ctrl = 4'b1111;

        //D_MEM_WEN
        if (format_type_ctrl == 'd2) D_MEM_WEN_ctrl = 0;
        else D_MEM_WEN_ctrl = 1;

        //ALUSrc
        if (format_type_ctrl == 0) begin
            if (INST[5] == 0) ALUSrc_ctrl = 'd2;
            else ALUSrc_ctrl = 0;
        end
        else if (format_type_ctrl == 'd4) ALUSrc_ctrl = 0;
        else ALUSrc_ctrl = 1;

        // RF_WE
        if ((format_type_ctrl == 'd2) || (format_type_ctrl == 'd4)) RF_WE_ctrl = 0;
        else RF_WE_ctrl = 1;

        // AUIPC
        if (INST[6:0] == 7'b0010111) AUIPC_ctrl = 1;
        else AUIPC_ctrl = 0;

        // JUMP
        if((INST[6:5] == 2'b11) && (INST[2:0] == 3'b111)) JUMP_ctrl = 1;
        else JUMP_ctrl = 0;

        //ALUCode
        if (format_type_ctrl == 'd4) begin
            if (INST[14:12]==3'b000) ALUCode_ctrl = 4'b0100;
            else if (INST[14:12]==3'b001) ALUCode_ctrl = 4'b0101;
            else if (INST[14:12]==3'b100) ALUCode_ctrl = 4'b0110; 
            else if (INST[14:12]==3'b101) ALUCode_ctrl = 4'b0111; 
            else if (INST[14:12]==3'b110) ALUCode_ctrl = 4'b1000; 
            else if (INST[14:12]==3'b111) ALUCode_ctrl = 4'b1001; 
        end
        else if (format_type_ctrl == 'd2) ALUCode_ctrl = 4'b0000;
        else if (format_type_ctrl == 1) begin
            if (INST[4]==0) ALUCode_ctrl = 4'b0000;
            else if (INST[14:12]==3'b000) ALUCode_ctrl = 4'b0000;
            else if (INST[14:12]==3'b010) ALUCode_ctrl = 4'b0110;
            else if (INST[14:12]==3'b011) ALUCode_ctrl = 4'b1000;
            else if (INST[14:12]==3'b100) ALUCode_ctrl = 4'b1111;
            else if (INST[14:12]==3'b110) ALUCode_ctrl = 4'b0011;
            else if (INST[14:12]==3'b111) ALUCode_ctrl = 4'b0010;
        end
        else if (format_type_ctrl == 0) begin
            if (INST[5]==0) begin
                if (INST[14:12]==3'b001) ALUCode_ctrl = 4'b1101;
                if (INST[14:12]==3'b101) begin
                    if (INST[30]==0) ALUCode_ctrl = 4'b1010;
                    else ALUCode_ctrl = 4'b1011;
                end
            end
            else if (INST[5]==1) begin
                if (INST[14:12]==3'b000) begin
                    if (INST[30]==0) ALUCode_ctrl = 4'b0000;
                    else ALUCode_ctrl = 4'b0001;
                end
                else if (INST[14:12]==3'b001) ALUCode_ctrl = 4'b1101;
                else if (INST[14:12]==3'b010) ALUCode_ctrl = 4'b0110;
                else if (INST[14:12]==3'b011) ALUCode_ctrl = 4'b1000;
                else if (INST[14:12]==3'b100) ALUCode_ctrl = 4'b1111;
                else if (INST[14:12]==3'b101) begin
                    if (INST[30]==0) ALUCode_ctrl = 4'b1010;
                    else ALUCode_ctrl = 4'b1011;
                end
                else if (INST[14:12]==3'b110) ALUCode_ctrl = 4'b0011;
                else if (INST[14:12]==3'b111) ALUCode_ctrl = 4'b0010;
            end
        end

        //WhatToOut
        if (format_type_ctrl == 'd2) WhatToOut = 'd2;
        else if (format_type_ctrl == 'd4) WhatToOut = 1;
        else WhatToOut = 0;
    end
endmodule