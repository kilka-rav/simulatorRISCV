`include "Ops.v"

module ControlUnit(
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output logic [3:0] ALU_op,
    output logic MemToReg,
    output logic MemWrite,
    output logic ALUSrc1, 
    output logic [1:0] ALUSrc2,
    output logic /*RegDst,*/ RegWrite,
    output logic Branch, InvertBranchTriger,
    output logic Jump,
    output logic [1:0] TypeInstruction,
    output logic Exception, valid
    );

always @(*) begin
    case(opcode)
        `R_TYPE: begin
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
        `I_TYPE: begin
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
        `STORE: begin
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
        `LOAD: begin
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
        `BRANCH: begin
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
        `JALR: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1; // pc
            ALUSrc2 = 2'b11; // 4
            Branch = 0;
            Jump = 1;
            RegWrite = 1;
            // next pc is rs1 + imm
            TypeInstruction = 2'b11;
            Exception = 0;
            valid = 1;
        end
        `JAL: begin
            MemToReg = 0;
            MemWrite = 0;
            ALUSrc1 = 1; // pc
            ALUSrc2 = 2'b11; // 4
            Branch = 0;
            Jump = 1;
            RegWrite = 1;
            // next pc is pc + imm
            TypeInstruction = 2'b01;
            Exception = 0;
            valid = 1;
        end
        `AUIPC: begin
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
        `LUI: begin
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
        `ZERO: begin
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