module FWRD(
    input wire CLK,
    input wire prev_stall,
    input wire [31:0] ID_INST_F,
    input wire [31:0] ID_INST_L,
    input wire [31:0] EX_INST_F,
    input wire [31:0] EX_INST_L,
    input wire [31:0] MEM_INST_F,
    input wire [31:0] WB_INST_F,
    input wire [1:0] flush,

    output reg [1:0] FDSrc5,
    output reg [1:0] FDSrc6,
    output reg SWFD,
    output reg stall
    );

    initial begin
        FDSrc5 <= 0;
        FDSrc6 <= 0;
        stall <= 0;
    end 

    always @ (posedge CLK) begin
        // 1. ID_F 지점에서 확인 . 만약 flush 중이면 이 단계는 무시.
        if (flush == 0) begin    
            if (stall == 0) begin //이미 stall이 실행된건 아닐 때,
                if (EX_INST_L[5:4] == 2'b00 && ID_INST_L[6:4] != 3'b010) begin //바로 앞이 LW라면
                    if (EX_INST_L[11:7] == ID_INST_L[19:15]) begin //LW의 rd와 지금 rs1이 같다면
                        stall <= 1;
                    end
                    else if ((EX_INST_L[11:7] == ID_INST_L[24:20]) && (ID_INST_L[6:3]==4'b0110 || ID_INST_L[6:3]==4'b1100)) begin 
                        //LW의 rd와 지금 rs2가 같고 지금 rs2가 있다면 (r, b, 단 s는 제외)
                        stall <= 1;
                    end
                    else stall <= 0;
                end 
                else stall <= 0;
            end
            else stall <= 0;
        end
    end

    always @ (*) begin 
        // 2. EX_F 지점에서 확인
        if (prev_stall == 1) begin // stall된 상태라면
                if (WB_INST_F[11:7] == EX_INST_F[19:15]) begin //LW의 rd와 지금 rs1이 같다면
                    FDSrc5 <= 'd2;
                end
                else FDSrc5 <= 0; 
                if ((WB_INST_F[11:7] == EX_INST_F[24:20]) && (EX_INST_F[6:3]==4'b0110 || EX_INST_F[6:3]==4'b1100)) begin 
                    //LW의 rd와 지금 rs2가 같고 지금 rs2가 있다면 (r, b. sw 제외)
                    FDSrc6 <= 'd2;
                end
                else FDSrc6 <= 0;
        end
        else begin
                if ((MEM_INST_F[11:7] == EX_INST_F[19:15]) && (MEM_INST_F[6:4]==3'b001 || MEM_INST_F[6:4]==3'b011)) begin 
                    //바로 전 inst의 rd와 지금 rs1이 같다면 && 바로 전 inst에 rd가 있다면 (당연히 있어야겠죠?)
                    FDSrc5 <= 1;
                end
                else if ((WB_INST_F[11:7] == EX_INST_F[19:15]) && (WB_INST_F[6:4]==3'b001 || WB_INST_F[6:4]==3'b011 || WB_INST_F[6:4]==3'b000)) begin 
                    //전전 inst의 rd와 지금 rs1이 같다면 && 전전 inst에 rd가 있다면 (당연히 있어야겠죠?)
                    FDSrc5 <= 'd3; 
                end
                else FDSrc5 <= 0;

                if ((MEM_INST_F[11:7] == EX_INST_F[24:20]) && (EX_INST_F[6:3]==4'b0110 || EX_INST_F[6:3]==4'b1100)
                   && (MEM_INST_F[6:4]==3'b001 || MEM_INST_F[6:4]==3'b011)) begin 
                    //바로 전 inst의 rd와 지금 rs2가 같고 지금 rs2가 있다면 (r, b, 단 s는 제외) && 바로 전 inst에 rd가 있다면 (당연히 있어야겠죠?)
                    FDSrc6 <= 1;
                end
                else if ((WB_INST_F[11:7] == EX_INST_F[24:20]) && (EX_INST_F[6:3]==4'b0110 || EX_INST_F[6:3]==4'b1100)
                         && (WB_INST_F[6:4]==3'b001 || WB_INST_F[6:4]==3'b011 || WB_INST_F[6:4]==3'b000 )) begin 
                    //전전 inst의 rd와 지금 rs2이 같다면 && 전전 inst에 rd가 있다면 (당연히 있어야겠죠?)
                    FDSrc6 <= 'd3; 
                end            
                else FDSrc6 <= 0; 
        end

        // 3. MEM_F 지점에서 확인 (SW의 rs2)
        if (MEM_INST_F[6:4] == 3'b010 && stall == 0) begin // stall 된 상태라면 아무것도 안함. 안 된 상태라면.. **prev_stall 안쓰는게 맞나?
            if (WB_INST_F[11:7] == MEM_INST_F[24:20]) begin
                SWFD <= 1;
            end
            else SWFD <= 0;
        end
        else SWFD <= 0;

    end
endmodule