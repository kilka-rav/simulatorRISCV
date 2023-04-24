module RegisterFile(
    input clk,
    input [4:0] registerNumber1,
    input [4:0] registerNumber2,
    input we,
    input [4:0] writeIndex,
    input [31:0] data,

    output [31:0] val1,
    output [31:0] val2
);

reg [31:0] registers [31:0] /*verilator public*/;

assign val1 = (registerNumber1 == 0) ? 0 : registers[registerNumber1];
assign val2 = (registerNumber2 == 0) ? 0 : registers[registerNumber2];

// write to register writeIndex
always @(negedge clk) begin
    if(we && writeIndex !=0) begin
        registers[writeIndex] <= data;
    end
end

endmodule
