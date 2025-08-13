module two_bit_predictor(
    input  wire       clk, rst,
    input  wire [7:0] index,
    input  wire       actual_taken,
    input  wire       update,
    output wire       predict_taken
);
    reg [1:0] table[0:255];
    assign predict_taken = table[index][1];
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0;i<256;i=i+1) table[i] <= 2'b01;
        end else if (update) begin
            case (table[index])
                2'b00: table[index] <= actual_taken ? 2'b01 : 2'b00;
                2'b01: table[index] <= actual_taken ? 2'b10 : 2'b00;
                2'b10: table[index] <= actual_taken ? 2'b11 : 2'b01;
                2'b11: table[index] <= actual_taken ? 2'b11 : 2'b10;
            endcase
        end
    end
endmodule
