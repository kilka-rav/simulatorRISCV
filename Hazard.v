module Hazard(
    // RAW register hazard
    input RegWrite_MEM,
    input RegWrite_WB,
    input[4:0] registerNumber1_exec,
    input[4:0] registerNumber2_exec,
    input[4:0] rdn_MEM,
    input[4:0] rdn_WB,
    //   10 - forward from MEM
    //   01 - forward from WB
    output logic[1:0] ForwardSrc1_exec, ForwardSrc2_exec,

    // Data hazard with stall
    input MemToReg_exec,
    input [4:0] rs1n_instrDecode, rs2n_instrDecode, rdn_exec,
    output Flush_exec, Stall_instrDecode, Stall_instrFetch,

    // Branch control hazard
    input Jump_exec,
    input Branch_exec,
    input InvertBranchTriger_exec,
    input [31:0] ALUOut_exec,
    output BranchIsTaken_exec
);
// RAW register hazard
//=--------------------------------------------------------
assign ForwardSrc1_exec = {2{(registerNumber1_exec != 0)}} & ((RegWrite_MEM & (rdn_MEM == registerNumber1_exec)) ? 2'b10 
    : ((RegWrite_WB & (rdn_WB == registerNumber1_exec)) ?  2'b01 : 2'b00 ));
assign ForwardSrc2_exec = {2{(registerNumber2_exec != 0)}} & ((RegWrite_MEM & (rdn_MEM == registerNumber2_exec)) ? 2'b10 
    : ((RegWrite_WB & (rdn_WB == registerNumber2_exec)) ?  2'b01 : 2'b00 ));

// Data hazard with stall
//=--------------------------------------------------------
wire load_stall = MemToReg_exec & ((rs1n_instrDecode == rdn_exec) || (rs2n_instrDecode == rdn_exec));
assign Flush_exec = load_stall, Stall_instrDecode = load_stall, Stall_instrFetch = load_stall;

//Branch Control Hazard

assign BranchIsTaken_exec = (Jump_exec) || (Branch_exec && (InvertBranchTriger_exec ^ (ALUOut_exec != 0)));
endmodule