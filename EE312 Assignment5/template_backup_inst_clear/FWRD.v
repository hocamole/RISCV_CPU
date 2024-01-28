module FWRD(
    input wire [4:0] RA1,
    input wire [5:0] RA2,
    input wire [5:0] prev_RD, // one cycle ago
    input wire [5:0] prev2_RD, // two cycles ago

    output reg [1:0] FDSrc5,
    output reg [1:0] FDSrc6
    );

    initial begin
        FDSrc5 <= 0;
        FDSrc6 <= 0;
    end

    always @ (*) begin
        if ((prev_RD[5]==1) && (RA1 == prev_RD[4:0])) FDSrc5 <= 1;
        else if ((prev2_RD[5]==1) && (RA1 == prev2_RD[4:0])) FDSrc5 <= 'd2;
        else FDSrc5 <= 0;

        if ((prev_RD[5]==1) && (RA2[4:0] == prev_RD[4:0]) && (RA2[5]==1)) FDSrc6 <= 1;
        else if ((prev2_RD[5]==1) && (RA2 == prev2_RD[4:0]) && (RA2[5]==1)) FDSrc6 <= 'd2;
        else FDSrc6 <= 0;
    end
endmodule