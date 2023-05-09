
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

`define R_TYPE 7'b0110011
`define I_TYPE 7'b0010011
`define STORE  7'b0100011
`define LOAD   7'b0000011
`define BRANCH 7'b1100011
`define JALR   7'b1100111
`define JAL    7'b1101111
`define AUIPC  7'b0010111
`define LUI    7'b0110111
`define ZERO   7'b0000000