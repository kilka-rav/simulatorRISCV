module PCCounter(
    wire input clk,
    wire input en,
    wire input[1:0] TypeInstruction
    //0b00 -> pc + 4 (Common)
    //0b01 -> pc _EX + imm (Branch)
    //0b10 -> pc + imm + rs1 (Call function)
    wire input[31:0] pc_EX,
    wire input[31:0] imm,
    wire input[31:0] rs1,

    wire output[31:0] PCOutput
);
reg [31:0] pc;
assign PCOutput = pc;

always @(posedge clk) begin
    if (en) begin
        if (TypeInstruction == 2'b00)
            pc <= pc + 4
        else if (TypeInstruction == 2'b01)
            pc <= pc_EX + imm
        else if (TypeInstruction == 2'b10)
            pc <= imm + rs1
    end
end

endmodule
