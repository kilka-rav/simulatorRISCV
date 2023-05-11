module Simulator(
    input clk,
    input rst,
    output bit_exit, valid_out,
    output logic [31:0] pc_out, imm_out,
    output logic [4:0] rs1n_out, rs2n_out, rdn_out,
    output RegWrite_out,
    output [31:0] opcode_out
);

//Wires
//----------------------------------------------
wire RegWrite_MEM, RegWrite_WB;
wire [4:0] rs1n_exec, rs2n_exec, rdn_MEM, rdn_WB;
wire [1:0] ForwardSrc1_exec, ForwardSrc2_exec;
wire MemToReg_exec;
wire [4:0] rs1n_instrDecode, rs2n_instrDecode, rdn_exec;
wire Flush_exec, Stall_instrDecode, Stall_instrFetch;
// Branch control hazard
wire BranchIsTaken_exec;
// exception command (ecall, pipeReg ...)
wire bit_exit_WB;
wire [31:0] pc_instrFetch;
wire [31:0] pc_exec;
// signals from execution
wire [31:0] imm32_exec, rs1_val_exec;
wire [1:0] NextPC_exec;
wire [31:0] pc_instrDecode, instr_instrDecode;
// signal from WB
wire[31:0] Result_WB;
// decoded info
wire [31:0] instr_instrFetch;
wire [4:0] rdn_instrDecode;
wire [31:0] rs1_val_instrDecode, rs2_val_instrDecode, imm32_instrDecode;
wire [3:0] alu_op_instrDecode;
wire [2:0] mem_width_instrDecode;
wire MemToReg_instrDecode, MemWrite_instrDecode, ALUSrc1_instrDecode, RegWrite_instrDecode, Branch_instrDecode, InvertBranchTriger_instrDecode, Jump_instrDecode, bit_exit_instrDecode, valid_instrDecode;
wire[1:0] ALUSrc2_instrDecode, NextPC_instrDecode;
// pipe register
wire [2:0] mem_width_exec;
wire [3:0] alu_op_exec;
wire [31:0] rs2_val_exec;
wire MemWrite_exec, ALUSrc1_exec, RegWrite_exec, Branch_exec, InvertBranchTriger_exec
, Jump_exec, bit_exit_exec, valid_exec;
wire [1:0] ALUSrc2_exec;
wire[31:0] ALUOut_exec;
wire ALUZero_exec;
// EX to MEM pipe register
wire [31:0] pc_MEM, ALUOut_MEM, MemWriteData_MEM;
wire [2:0] mem_width_MEM;
wire MemToReg_MEM, MemWrite_MEM, bit_exit_MEM, valid_MEM;
wire[31:0] imm32_MEM;
wire [4:0] rs1n_MEM, rs2n_MEM;
// MEM to WB pipe register
wire[31:0] ReadData_WB, ALUOut_WB;
wire MemToReg_WB, valid_WB;
// debug info pipe
wire[31:0] imm32_WB, pc_WB;
wire [4:0] rs1n_WB, rs2n_WB;
//END Wires
//-------------------------------


// hazard unit
// RAW 

assign bit_exit = bit_exit_WB;
assign RegWrite_out = RegWrite_WB;
Hazard hazard(
RegWrite_MEM, RegWrite_WB, rs1n_exec, rs2n_exec, rdn_MEM, rdn_WB, 
ForwardSrc1_exec, ForwardSrc2_exec,

MemToReg_exec, rs1n_instrDecode, rs2n_instrDecode, rdn_exec,
Flush_exec, Stall_instrDecode, Stall_instrFetch,

Jump_exec, Branch_exec, InvertBranchTriger_exec, ALUOut_exec, BranchIsTaken_exec
);

// Fetch

wire [1:0] TakenNextPC_exec = (BranchIsTaken_exec) ? NextPC_exec : 2'b00;
wire PCEn = !Stall_instrFetch & !bit_exit_WB;
PCCounter pc_module(clk, PCEn, TakenNextPC_exec, pc_exec, imm32_exec, rs1_val_exec, pc_instrFetch);

MemoryInstruction #(.N(17), .DW(32)) imem(clk, pc_instrFetch >> 2, 3'b010 /*32w*/, 0/*we*/, 0, instr_instrFetch);


wire Enable_instrDecode = !Stall_instrDecode & !bit_exit_WB;
wire Flush_instrDecode = rst | BranchIsTaken_exec;
Pipeline #(.Width(64)) pipeReg_instrDecode(clk, Flush_instrDecode, Enable_instrDecode, 
{pc_instrFetch, instr_instrFetch}, 
{pc_instrDecode, instr_instrDecode}
);

// instruction decode
//=--------------------------------------------------------

Decoder decoder(instr_instrDecode, 
    rs1n_instrDecode, rs2n_instrDecode, rdn_instrDecode, imm32_instrDecode, // decoded instruction
    mem_width_instrDecode ,alu_op_instrDecode, 
    MemToReg_instrDecode, MemWrite_instrDecode, ALUSrc1_instrDecode, ALUSrc2_instrDecode, RegWrite_instrDecode, Branch_instrDecode, InvertBranchTriger_instrDecode, Jump_instrDecode, NextPC_instrDecode,
    bit_exit_instrDecode, valid_instrDecode
);
RegisterFile reg_file(clk, rs1n_instrDecode, rs2n_instrDecode, RegWrite_WB, rdn_WB, Result_WB, //input
    rs1_val_instrDecode, rs2_val_instrDecode // out
);


wire PipeRegRst_exec = rst | Flush_exec | BranchIsTaken_exec;
wire PipeRegEn_exec = !bit_exit_WB;
Pipeline #(.Width(150)) pipeReg_ex_vals(clk, PipeRegRst_exec, PipeRegEn_exec, 
    {pc_instrDecode, rs1_val_instrDecode, rs2_val_instrDecode, imm32_instrDecode, rs1n_instrDecode, rs2n_instrDecode, rdn_instrDecode, alu_op_instrDecode, mem_width_instrDecode}, 
    {pc_exec, rs1_val_exec, rs2_val_exec, imm32_exec, rs1n_exec, rs2n_exec, rdn_exec, alu_op_exec, mem_width_exec}
);
Pipeline #(.Width(13)) pipeReg_ex_flags(clk, PipeRegRst_exec, PipeRegEn_exec,
    {MemToReg_instrDecode, MemWrite_instrDecode, ALUSrc1_instrDecode, ALUSrc2_instrDecode, RegWrite_instrDecode, Branch_instrDecode, InvertBranchTriger_instrDecode, Jump_instrDecode, NextPC_instrDecode, bit_exit_instrDecode, valid_instrDecode},
    {MemToReg_exec, MemWrite_exec, ALUSrc1_exec, ALUSrc2_exec, RegWrite_exec, Branch_exec, InvertBranchTriger_exec, Jump_exec, NextPC_exec, bit_exit_exec, valid_exec}
);

// execution
//=--------------------------------------------------------
// forwarding registers
wire [31:0] rs1_val_forwarded_exec = (ForwardSrc1_exec[1:1]) ? ALUOut_MEM : ((ForwardSrc1_exec[0:0]) ? Result_WB : rs1_val_exec);
wire [31:0] rs2_val_forwarded_exec = (ForwardSrc2_exec[1:1]) ? ALUOut_MEM : ((ForwardSrc2_exec[0:0]) ? Result_WB : rs2_val_exec);

wire[31:0] ALUSrc1_val_exec = (ALUSrc1_exec) ? pc_exec : rs1_val_forwarded_exec;
wire[31:0] ALUSrc2_val_exec = (ALUSrc2_exec == 2'b00) ? rs2_val_forwarded_exec : ((ALUSrc2_exec == 2'b01) ? imm32_exec : 4); 

ALU alu(ALUSrc1_val_exec, ALUSrc2_val_exec, alu_op_exec, ALUOut_exec, ALUZero_exec);

// branch logic
//assign BranchIsTaken_exec = (Jump_exec) || (Branch_exec && (InvertBranchTriger_exec ^ (ALUOut_exec != 0)));

wire PipeRegRst_MEM = rst;
wire PipeRegEn_MEM = !bit_exit_WB;
Pipeline #(.Width(96)) pipeReg_mem_values(clk, PipeRegRst_MEM, PipeRegEn_MEM, 
{pc_exec , ALUOut_exec , rs2_val_forwarded_exec}, 
{pc_MEM, ALUOut_MEM, MemWriteData_MEM    }
);
Pipeline #(.Width(13)) pipeReg_mem_flags(clk, PipeRegRst_MEM, PipeRegEn_MEM,
{mem_width_exec , MemToReg_exec , MemWrite_exec , RegWrite_exec , rdn_exec , bit_exit_exec , valid_exec },
{mem_width_MEM, MemToReg_MEM, MemWrite_MEM, RegWrite_MEM, rdn_MEM, bit_exit_MEM, valid_MEM}
);

Pipeline #(.Width(42)) debug_pipe_MEM(clk, PipeRegRst_MEM, PipeRegEn_MEM,
{imm32_exec , rs1n_exec , rs2n_exec },
{imm32_MEM, rs1n_MEM, rs2n_MEM}
);

// memory
//=--------------------------------------------------------
wire[31:0] ReadData_MEM;
MemoryData #(.N(17), .DW(32)) dmem(clk, ALUOut_MEM >> 2 , mem_width_MEM, MemWrite_MEM, MemWriteData_MEM, ReadData_MEM);


// MEM to WB pipe register
wire[31:0] ReadData_WB, ALUOut_WB;
wire MemToReg_WB, valid_WB;
wire PipeRegRst_WB = rst;
wire PipeRegEn_WB = !bit_exit_WB;
Pipeline #(.Width(64)) pipeReg_wb_vals(clk, PipeRegRst_WB, PipeRegEn_WB, 
{ReadData_MEM, ALUOut_MEM}, 
{ReadData_WB , ALUOut_WB });
Pipeline #(.Width(9)) pipeReg_wb_flags(clk, PipeRegRst_WB, PipeRegEn_WB, 
{RegWrite_MEM, MemToReg_MEM, rdn_MEM, bit_exit_MEM, valid_MEM}, 
{RegWrite_WB , MemToReg_WB , rdn_WB , bit_exit_WB , valid_WB });

Pipeline #(.Width(74)) debug_pipe_WB(clk, PipeRegRst_WB, PipeRegEn_WB,
{pc_MEM, imm32_MEM, rs1n_MEM, rs2n_MEM},
{pc_WB , imm32_WB , rs1n_WB , rs2n_WB}
);

assign pc_out = pc_WB;
assign rs1n_out = rs1n_WB;
assign rs2n_out = rs2n_WB;
assign rdn_out = rdn_WB;
assign imm_out = imm32_WB;
assign opcode_out = instr_instrDecode[31:0];
assign valid_out = valid_WB;

// write back
//=--------------------------------------------------------
assign Result_WB = (MemToReg_WB) ? ReadData_WB : ALUOut_WB;


endmodule
