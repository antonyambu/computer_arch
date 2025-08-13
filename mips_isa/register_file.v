module register_file(
    input  wire        clk,
    input  wire        we3,
    input  wire [4:0]  a1, a2, a3,
    input  wire [31:0] wd3,
    output wire [31:0] rd1, rd2
);
    reg [31:0] rf[31:0];
    // x0 is hardwired to zero
    assign rd1 = (a1 == 0) ? 32'b0 : rf[a1];
    assign rd2 = (a2 == 0) ? 32'b0 : rf[a2];
    always @(posedge clk) begin
        if (we3 && (a3 != 0)) rf[a3] <= wd3;
    end
endmodule
