module RegisterFile(
    input clk,
    input [4:0] A2_registerNumber,
    input [4:0] A3_registerNumber,
    input we,
    input [4:0] wd_writeIndex,
    input [31:0] A1_data,

    output [31:0] rd1,
    output [31:0] rd2
);

reg [31:0] registers [31:0] /*verilator public*/;

assign rd1 = (A2_registerNumber == 0) ? 0 : registers[A2_registerNumber];
assign rd2 = (A3_registerNumber == 0) ? 0 : registers[A3_registerNumber];

// write to register wd_writeIndex
always @(negedge clk) begin
    if(we && wd_writeIndex !=0) begin
        registers[wd_writeIndex] <= A1_data;
    end
end

endmodule
