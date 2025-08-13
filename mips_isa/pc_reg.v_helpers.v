module pc_reg(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc
);
    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 32'b0;
        else     pc <= pc_next;
    end
endmodule

module signext(input wire [15:0] a, output wire [31:0] y);
    assign y = {{16{a[15]}}, a};
endmodule

module sl2(input wire [31:0] a, output wire [31:0] y);
    assign y = {a[29:0], 2'b00};
endmodule

module mux2 #(parameter W=32) (
    input  wire [W-1:0] d0, d1,
    input  wire         s,
    output wire [W-1:0] y
);
    assign y = s ? d1 : d0;
endmodule

module mux3 #(parameter W=32) (
    input  wire [W-1:0] d0, d1, d2,
    input  wire [1:0]   s,
    output reg  [W-1:0] y
);
    always @* begin
        case (s)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            default: y = d0;
        endcase
    end
endmodule
