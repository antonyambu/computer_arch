module imem #(
    parameter MEMFILE = ""
)(
    input  wire [31:2] a,       // word address
    output wire [31:0] rd
);
    reg [31:0] ROM[0:1023];
    initial begin
        if (MEMFILE != "") $readmemh(MEMFILE, ROM);
    end
    assign rd = ROM[a];
endmodule

module dmem(
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] a,
    input  wire [31:0] wd,
    output wire [31:0] rd
);
    reg [31:0] RAM[0:1023];
    assign rd = RAM[a[31:2]];
    always @(posedge clk) begin
        if (we) RAM[a[31:2]] <= wd;
    end
endmodule
