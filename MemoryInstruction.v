module MemoryInstruction #(parameter N = 12, DW = 32) (
    input clk, 
    input [31:0] /* verilator lint_off UNUSED */ addr_A, 
    input [2:0] width, 
    input we,
    input [31:0] WD,
    output [31:0] RD
);
//assert property(addr_A >> N == 0);

reg	[(DW-1):0]	mem_buff 	[0:((1<<N)-1)] /*verilator public*/;

wire to_extend = ~width[2:2];

wire [31:0]read_w = mem_buff[addr_A];
wire [31:0]read_b = { {24{to_extend && read_w[7:7]}}, read_w[7:0] };
wire [31:0]read_h = { {16{to_extend && read_w[15:15]}}, read_w[15:0] };

assign RD = (width[0:0]) ? read_h : ((width[1:1]) ? read_w : read_b); 

endmodule