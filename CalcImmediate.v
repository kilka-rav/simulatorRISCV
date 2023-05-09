`include "Ops.v"

module CalcImmediate(
    input [31:0] instr,
    output [6:0] opcode,
    output [2:0] funct3,
    output [6:0] funct7,

    output [31:0] i_imm_32, s_imm_32, b_imm_32, u_imm_32, j_imm_32, shamt_32, imm32
);

// opcodes
assign opcode = instr[6:0];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];



//immediates calculations 
//=--------------------------------------------------------
assign i_imm_32 = { {20{instr[31]}}, instr[31:20]}; // I-type
assign s_imm_32 = { {20{instr[31]}}, instr[31:25], instr[11:7]}; // S-Type
assign b_imm_32 = { {20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; //B-type
assign u_imm_32 = { instr[31:12], 12'b000000000000}; // U-type
assign j_imm_32 = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type 

assign shamt_32 = {27'b000000000000000000000000000, instr[24:20]};

assign imm32 =  (opcode == `I_TYPE && funct3 == 3'b001)? shamt_32:  //SLLI
                (opcode == `I_TYPE && funct3 == 3'b101)? shamt_32:  //SRLI
                (opcode == `I_TYPE)? i_imm_32:  //I-type
                (opcode == `LOAD  )? i_imm_32:  //Load
                (opcode == `STORE )? s_imm_32:  //S-type
                (opcode == `BRANCH)? b_imm_32:  //Branches
                (opcode == `JAL   )? j_imm_32:  //JAL
                (opcode == `JALR  )? i_imm_32:  //JALR
                (opcode == `AUIPC )? u_imm_32:  //Auipc
                (opcode == `LUI   )? u_imm_32:  //Lui
                0;  //default 


endmodule