module FWRD(
    input wire [31:0] pres_INST, // for forwardnig to SW source (rs2)
    input wire [31:0] INST2, //for forwarding to SW base (rs1)
    input wire [4:0] RA1,
    input wire [5:0] RA2, // MSB is to check if rs2 existed
    input wire [6:0] prev_RD, // one cycle ago. 5th is to check if rd existed. 6th is to check load
    input wire [6:0] prev2_RD, // two cycles ago. 5th is to check if rd existed. 6th is to check load
    input wire LWPR, //WB_F

    output reg [1:0] FDSrc5,
    output reg [1:0] FDSrc6,
    output reg SWFD
    );

    initial begin
        FDSrc5 <= 0;
        FDSrc6 <= 0;
        SWFD <= 0;
    end 

    always @ (*) begin 
        if (LWPR == 1) begin //previous was load
            if ((prev2_RD[5]==1) && (RA1 == prev2_RD[4:0]) && (prev2_RD[6] == 1)) FDSrc5 <= 'd3;
            else FDSrc5 <= 0;
            SWFD <= 0;
        end 

        else begin //previous was not load
            if (pres_INST[6:0]==7'b0100011) begin //when present instruction is SW. we don't have to care about prev2 when SW appears.
                                                                // but prev2 is used b/c prev2 is actually prev for SW
                if ((prev2_RD[5] == 1) && (prev2_RD[4:0] == pres_INST[24:20])) begin
                    SWFD <= 1;
                end
                else SWFD <= 0;
            end

            if ((prev_RD[5]==1) && (RA1 == prev_RD[4:0]) && (prev_RD[6] == 0)) begin 
                FDSrc5 <= 1;
                //SWFD <= 0;
            end
            else if ((prev2_RD[5]==1) && (RA1 == prev2_RD[4:0]) && (prev2_RD[6] == 0)) begin 
                FDSrc5 <= 'd2;
                //SWFD <= 0;
            end
            else begin 
                FDSrc5 <= 0;
                //SWFD <= 0;
            end

            if (INST2[6:0] != 7'b0100011) begin
                if ((prev_RD[5]==1) && (RA2[4:0] == prev_RD[4:0]) && (RA2[5]==1) && (prev_RD[6] == 0)) begin
                    FDSrc6 <= 1;
                    //SWFD <= 0;
                end
                else if ((prev2_RD[5]==1) && (RA2[4:0] == prev2_RD[4:0]) && (RA2[5]==1) && (prev2_RD[6] == 0)) begin
                    FDSrc6 <= 'd2;
                    //SWFD <= 0;
                end
                else begin 
                    FDSrc6 <= 0;
                    //SWFD <= 0;
                end
            end
        end
/*
        if ((prev2_RD[5]==1) && (RA1 == prev2_RD[4:0]) && (prev2_RD[6] == 1)) FDSrc5 <= 'd3;
        else if ((prev_RD[5]==1) && (RA1 == prev_RD[4:0]) && (prev_RD[6] == 0)) FDSrc5 <= 1;
        else if ((prev2_RD[5]==1) && (RA1 == prev2_RD[4:0]) && (prev2_RD[6] == 0)) FDSrc5 <= 'd2;
        else FDSrc5 <= 0;

        if ((prev2_RD[5]==1) && (RA2[4:0] == prev2_RD[4:0]) && (prev2_RD[6] == 1) && (RA2[5]==1)) FDSrc5 <= 'd3;
        else if ((prev_RD[5]==1) && (RA2[4:0] == prev_RD[4:0]) && (RA2[5]==1) && (prev_RD[6] == 0)) FDSrc6 <= 1;
        else if ((prev2_RD[5]==1) && (RA2[4:0] == prev2_RD[4:0]) && (RA2[5]==1) && (prev2_RD[6] == 0)) FDSrc6 <= 'd2;
        else FDSrc6 <= 0;
        */
    end
endmodule