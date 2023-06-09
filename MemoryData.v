module MemoryData #(parameter N = 12, DW = 32) (
    input clk, 
    input [31:0] /* verilator lint_off UNUSED */ addr_A, 
    input [2:0] width, 
    input we,
    input [31:0] WD,
    output [31:0] RD
);

reg	[(DW-1):0]	mem_buff 	[0:((1<<N)-1)] /*verilator public*/;

wire to_extend = ~width[2:2];

wire [31:0]read_b = { {24{to_extend && mem_buff[addr_A][7:7]}}, mem_buff[addr_A][7:0] };
wire [31:0]read_h = { {16{to_extend && mem_buff[addr_A][15:15]}}, mem_buff[addr_A][15:0] };
wire [31:0]read_w = mem_buff[addr_A];

assign RD = (width[0:0]) ? read_h : ((width[1:1]) ? read_w : read_b); 

always @(posedge clk)
begin
    if (we) begin
        mem_buff[addr_A][7:0] <= WD[7:0];
        if (width[0:0]) begin
            mem_buff[addr_A][15:8] <= WD[15:8];
        end else if (width[1:1]) begin
            mem_buff[addr_A][31:8] <= WD[31:8];
        end
    end
end

endmodule