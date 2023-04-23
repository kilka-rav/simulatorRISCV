module RegisterFile(
    wire input clk,
    wire input [4:0] registerNumber1,
    wire input [4:0] registerNumber2,
    wire input we,
    wire input [4:0] writeIndex,
    wire input [31:0] data,

    wire output [31:0] val1,
    wire output [31:0] val2
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
