module Pipeline #(parameter Width = 32) 
(
    wire input clk,
    wire input rst,
    wire input en,
    wire input [Width-1:0] InputData,
    wire output [Width-1:0] OutputData
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
