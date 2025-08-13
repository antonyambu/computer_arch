module alu_32bit(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] y,
    output wire        zero
);
    // ALU control encoding:
    // 0000: AND, 0001: OR, 0010: ADD, 0110: SUB, 0111: SLT, 1100: NOR
    assign zero = (y == 32'b0);
    always @* begin
        case (alu_ctrl)
            4'b0000: y = a & b;
            4'b0001: y = a | b;
            4'b0010: y = a + b;
            4'b0110: y = a - b;
            4'b0111: y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'b1100: y = ~(a | b);
            default: y = 32'b0;
        endcase
    end
endmodule
