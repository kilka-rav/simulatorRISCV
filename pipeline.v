module Pipeline #(parameter Width = 32) 
(
    input clk,
    input rst,
    input en,
    input [Width-1:0] InputData,
    output [Width-1:0] OutputData
);
reg [Width-1:0] Data;
assign OutputData = Data;

always @(posedge clk) begin
    if (en && !rst)
        Data <= InputData;
    else if (rst)
        Data <= 0;
end
endmodule
