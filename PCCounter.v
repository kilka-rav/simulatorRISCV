module PCCounter(
    input clk,
    input en,
    input[1:0] TypeInstruction,
    //0b00 -> pc + 4 (Common)
    //0b01 -> pc _exec + imm (Branch)
    //0b11 -> pc + imm + rs1 (Call function)
    input[31:0] pc_exec,
    input[31:0] imm,
    input[31:0] rs1,

    output[31:0] PCOutput
);
reg [31:0] pc /*verilator public*/;
assign PCOutput = pc;

always @(posedge clk) begin
    if (en) begin
        case (TypeInstruction)
            2'b00: pc <= pc + 4;
            2'b01: pc <= pc_exec + imm;
            2'b11: pc <= imm + rs1;
            default: ;
        endcase
    end
end

endmodule
