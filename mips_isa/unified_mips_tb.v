module unified_mips_tb;
    reg clk=0, rst=1;
    wire [31:0] pc_sc, pc_mc, pc_pl;
    wire [31:0] v0_sc, v0_mc, v0_pl;

    always #5 clk = ~clk;

    mips_single_cycle #(.IMEM_FILE("program.mem")) SC(.clk(clk), .rst(rst), .pc_debug(pc_sc), .reg_v0(v0_sc));
    mips_multicycle  #(.IMEM_FILE("program.mem")) MC(.clk(clk), .rst(rst), .pc_debug(pc_mc), .reg_v0(v0_mc));
    mips_pipeline    #(.IMEM_FILE("program.mem")) PL(.clk(clk), .rst(rst), .pc_debug(pc_pl), .reg_v0(v0_pl));

    initial begin
        #20 rst = 0;
        #1000 $finish;
    end
endmodule
