`include "Ops.v"

module ALU(
  input [31:0] SrcA,
  input [31:0] SrcB,
  input [3:0] ALUControl,
  output reg[31:0] ALUResult,
  output reg zero
);
always @(*) begin 
  case (ALUControl)
    `ALU_ADD: ALUResult = SrcA + SrcB;
    `ALU_SUB: ALUResult = SrcA - SrcB;
    `ALU_AND: ALUResult = SrcA & SrcB;
    `ALU_OR: ALUResult = SrcA | SrcB;
    `ALU_XOR: ALUResult = SrcA ^ SrcB;
    //left shift logical
    `ALU_SHL: ALUResult= SrcA << SrcB[4:0];
    //right shift logical
    `ALU_SHR: ALUResult= SrcA >> SrcB[4:0];
    //arithmetic right shift
    `ALU_SHA: ALUResult=$signed(SrcA)>>>$signed(SrcB[4:0]);
    //set less than
    `ALU_SLT: ALUResult=$signed(SrcA) < $signed(SrcB)? 32'b1:32'b0;
    //set less than unsigned
    `ALU_SLTU: ALUResult = SrcA < SrcB ? 32'b1:32'b0;
    `ALU_A: ALUResult = SrcA;
    `ALU_B: ALUResult = SrcB;
    //by default do nothing
    default: ;
   endcase 
   zero = (ALUResult == 0);
   //over<=0;
end
endmodule
