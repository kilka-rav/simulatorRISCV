// ALU operations
//=--------------------------------------------------------
`define ALU_ADD 4'b00_00
`define ALU_SUB 4'b00_01
`define ALU_AND 4'b01_00
`define ALU_OR  4'b01_01
`define ALU_XOR 4'b01_10
`define ALU_SHL 4'b10_00
`define ALU_SHR 4'b10_10
`define ALU_SHA 4'b10_11
`define ALU_SLT 4'b11_00
`define ALU_SLTU 4'b11_01
`define ALU_A   4'b01_11
`define ALU_B   4'b11_11

module Decoder (
    input [31:0] instr,
    output [4:0] rs1_id,
    output [4:0] rs2_id,
    output [4:0] rd_id,
    output [31:0] imm32,
    output [2:0] mem_width,

    // control unit out
    output logic [3:0] ALU_op,
    output logic MemToReg, MemWrite,
    // ALUSrc1:
    // 0 - rs1
    // 1 - pc
    // ALUSrc2:
    // 00 - rs2
    // 01 - imm
    // 11 - 4
    output logic ALUSrc1, 
    output logic [1:0] ALUSrc2,
    output logic /*RegDst,*/ RegWrite,
    output logic Branch, InvertBranchTriger,
    output logic Jump,
    // TypeInstruction:
    // 00 - pc + 4
    // 01 - pc + imm
    // 11 - rs1 + imm
    output logic [1:0] TypeInstruction,
    output logic Exception = 0, valid
);

localparam [6:0]R_TYPE  = 7'b0110011,
                I_TYPE  = 7'b0010011,
                STORE   = 7'b0100011,
                LOAD    = 7'b0000011,
                BRANCH  = 7'b1100011,
                JALR    = 7'b1100111,
                JAL     = 7'b1101111,
                AUIPC   = 7'b0010111,
                LUI     = 7'b0110111,
                ZERO    = 7'b0000000; // empty state (after rst)

wire [6:0] opcode;
wire [6:0] funct7;
wire [2:0] funct3;

// Read registers
assign rs1_id  = instr[19:15];
assign rs2_id  = instr[24:20];
assign rd_id = instr[11:7];
assign mem_width = funct3;

// opcodes
assign opcode = instr[6:0];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];

//immediates calculations 
//=--------------------------------------------------------
wire [31:0] i_imm_32, s_imm_32, b_imm_32, u_imm_32, j_imm_32, shamt_32;
CalcImmediate immediateCount(instr, opcode, funct3, funct7, i_imm_32, s_imm_32, b_imm_32, u_imm_32, j_imm_32, shamt_32, imm32);

// control unit
//=--------------------------------------------------------
ControlUnit control(opcode, funct3, funct7, ALU_op, MemToReg, MemWrite, ALUSrc1, ALUSrc2, RegWrite, Branch, InvertBranchTriger, Jump, TypeInstruction, Exception, valid);

endmodule