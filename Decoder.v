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
    wire input [31:0] instr,
    wire output [4:0] rs1_id,
    wire output [4:0] rs2_id,
    wire output [4:0] rd_id,
    wire output [31:0] imm32,
    wire output [2:0] mem_width,

    // control unit out
    wire output logic [3:0] ALU_op,
    wire output logic MemToReg, MemWrite,
    // ALUSrc1:
    // 0 - rs1
    // 1 - pc
    // ALUSrc2:
    // 00 - rs2
    // 01 - imm
    // 11 - 4
    wire output logic ALUSrc1, 
    wire output logic [1:0] ALUSrc2,
    wire output logic /*RegDst,*/ RegWrite,
    wire output logic Branch, InvertBranchTriger,
    wire output logic Jump,
    // TypeInstruction:
    // 00 - pc + 4
    // 01 - pc + imm
    // 11 - rs1 + imm
    wire output logic [1:0] TypeInstruction,
    wire output logic Exception = 0, valid
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
assign i_imm_32 = { {20{instr[31]}}, instr[31:20]}; // I-type
assign s_imm_32 = { {20{instr[31]}}, instr[31:25], instr[11:7]}; // S-Type
assign b_imm_32 = { {20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; //B-type
assign u_imm_32 = { instr[31:12], 12'b000000000000}; // U-type
assign j_imm_32 = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type 

assign shamt_32 = {27'b000000000000000000000000000, instr[24:20]};

assign imm32 =  (opcode == I_TYPE && funct3 == 3'b001)? shamt_32:  //SLLI
                (opcode == I_TYPE && funct3 == 3'b101)? shamt_32:  //SRLI
                (opcode == I_TYPE)? i_imm_32:  //I-type
                (opcode == LOAD  )? i_imm_32:  //Load
                (opcode == STORE )? s_imm_32:  //S-type
                (opcode == BRANCH)? b_imm_32:  //Branches
                (opcode == JAL   )? j_imm_32:  //JAL
                (opcode == JALR  )? i_imm_32:  //JALR
                (opcode == AUIPC )? u_imm_32:  //Auipc
                (opcode == LUI   )? u_imm_32:  //Lui
                0;  //default 

// control unit
//=--------------------------------------------------------
always @(*) begin
    case(opcode)
        R_TYPE: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b00;
            Branch = 0;
            Jump = 0;
            RegWrite = 1;
            TypeInstruction = 2'b00; // pc + 4
            Exception = 0;
            valid = 1;
            if (funct3 == 3'b000) begin 
                if (funct7 == 7'b0000000) begin 
                    ALU_op = `ALU_ADD;
                end else begin 
                    ALU_op = `ALU_SUB;
                end 
            end else if (funct3 == 3'b010) begin 
                ALU_op = `ALU_SLT;
            end else if (funct3 == 3'b100) begin 
                ALU_op = `ALU_XOR;
            end else if (funct3 == 3'b111) begin 
                ALU_op = `ALU_AND;
            end else if (funct3 == 3'b001) begin
                ALU_op = `ALU_SHL;
            end else if (funct3 == 3'b011) begin
                ALU_op = `ALU_SLTU;
            end else if (funct3 == 3'b110) begin
                ALU_op = `ALU_OR;
            end else if (funct3 == 3'b101) begin
                if (funct7 == 7'b0000000) begin
                    ALU_op = `ALU_SHR;
                end else begin 
                    ALU_op = `ALU_SHA;
                end 
            end 
        end
        I_TYPE: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b01; // imm
            Branch = 0;
            Jump = 0;
            RegWrite = 1;
            TypeInstruction = 2'b00; // pc + 4
            Exception = 0;
            valid = 1;
            if (funct3 == 3'b000) begin
                ALU_op = `ALU_ADD; //addi 
            end else if (funct3 == 3'b001) begin
                ALU_op = `ALU_SHL; //slli
            end else if (funct3 == 3'b010) begin
                ALU_op = `ALU_SLT; //slti
            end else if (funct3 == 3'b011) begin
                ALU_op = `ALU_SLTU; //sltiu
            end else if (funct3 == 3'b100) begin 
                ALU_op = `ALU_XOR; //xori
            end else if (funct3 == 3'b101) begin 
                if (funct7 == 7'b0000000) begin 
                    ALU_op = `ALU_SHR; //srli
                end else begin 
                    ALU_op = `ALU_SHA; //srai
                end
            end else if (funct3 == 3'b110) begin
                ALU_op = `ALU_OR; //ori
            end else if (funct3 == 3'b111) begin 
                ALU_op = `ALU_AND; //andi
            end
        end
        STORE: begin
            MemToReg = 0;
            MemWrite = 1;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b01; // imm
            Branch = 0;
            Jump = 0;
            RegWrite = 0;
            TypeInstruction = 2'b00; // pc + 4
            ALU_op = `ALU_ADD;
            Exception = 0;
            valid = 1;
        end
        LOAD: begin
            MemToReg = 1;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b01; // imm
            Branch = 0;
            Jump = 0;
            RegWrite = 1;
            TypeInstruction = 2'b00; // pc + 4
            ALU_op = `ALU_ADD;
            Exception = 0;
            valid = 1;
        end
        BRANCH: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b00; // rs2
            Branch = 1;
            Jump = 0;
            RegWrite = 0;
            TypeInstruction = 2'b01; // pc + imm
            Exception = 0;
            valid = 1;
            if (funct3 == 3'b000) begin 
                ALU_op = `ALU_SUB; //beq
                InvertBranchTriger = 1;
            end else if (funct3 == 3'b001) begin 
                ALU_op = `ALU_SUB; //bne
                InvertBranchTriger = 0;
            end else if (funct3 == 3'b100) begin 
                ALU_op = `ALU_SLT; //blt
                InvertBranchTriger = 0;
            end else if (funct3 == 3'b101) begin 
                ALU_op = `ALU_SLT; //bge
                InvertBranchTriger = 1;
            end else if (funct3 == 3'b110) begin 
                ALU_op = `ALU_SLTU; //bltu
                InvertBranchTriger = 0;
            end else if (funct3 == 3'b111) begin 
                ALU_op = `ALU_SLTU; //bgeu
                InvertBranchTriger = 1;
            end
        end
        JALR: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1; // pc
            ALUSrc2 = 2'b10; // 4
            Branch = 0;
            Jump = 1;
            RegWrite = 1;
            // next pc is rs1 + imm
            TypeInstruction = 2'b10;
            Exception = 0;
            valid = 1;
        end
        JAL: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1; // pc
            ALUSrc2 = 2'b10; // 4
            Branch = 0;
            Jump = 1;
            RegWrite = 1;
            // next pc is pc + imm
            TypeInstruction = 2'b01;
            Exception = 0;
            valid = 1;
        end
        AUIPC: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1; // pc
            ALUSrc2 = 2'b01; // imm
            ALU_op = `ALU_ADD;
            Branch = 0;
            Jump = 0;
            RegWrite = 1;
            TypeInstruction = 2'b00; // pc + 4
            Exception = 0;
            valid = 1;
        end
        LUI: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 0;
            ALUSrc2 = 2'b01; // imm
            ALU_op = `ALU_B;
            Branch = 0;
            Jump = 0;
            RegWrite = 1;
            TypeInstruction = 2'b00; // pc + 4
            Exception = 0;
            valid = 1;
        end
        ZERO: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1'bx;
            ALUSrc2 = 2'bxx; // imm
            Branch = 0;
            Jump = 0;
            RegWrite = 0;
            TypeInstruction = 2'b00; // pc + 4
            Exception = 0;
            valid = 0;
        end
        default: begin 
            Exception = 1;
            valid = 1; 
        end
    endcase
end

endmodule