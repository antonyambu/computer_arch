module mips_single_cycle #(
    parameter IMEM_FILE=""
)(
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] pc_debug,
    output wire [31:0] reg_v0
);
    wire [31:0] pc, instr, signimm, srca, srcb, aluout, readdata, pcplus4, pcbranch, pcjump;
    wire        memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, zero;
    wire [3:0]  alucontrol;
    wire [4:0]  writereg;
    wire [31:0] result;

    // Control
    controller_single ctrl(
        .op(instr[31:26]), .funct(instr[5:0]),
        .memtoreg(memtoreg), .memwrite(memwrite),
        .branch(branch), .alusrc(alusrc),
        .regdst(regdst), .regwrite(regwrite),
        .jump(jump),
        .alucontrol(alucontrol)
    );

    // PC and memories
    wire [31:0] pcnext;
    pc_reg PC(clk, rst, pcnext, pc);
    assign pc_debug = pc;
    imem #(.MEMFILE(IMEM_FILE)) IM(pc[31:2], instr);
    dmem DM(clk, memwrite, aluout, srcb, readdata);

    // Register file
    wire [31:0] writedata;
    assign writereg = regdst ? instr[15:11] : instr[20:16];
    register_file RF(clk, regwrite, instr[25:21], instr[20:16], writereg, writedata, srca, srcb);

    // Immediate
    signext SE(instr[15:0], signimm);

    // ALU second operand mux
    wire [31:0] srcb_mux = alusrc ? signimm : srcb;

    // ALU
    alu_32bit ALU(srca, srcb_mux, alucontrol, aluout, zero);

    // Result mux
    assign result    = memtoreg ? readdata : aluout;
    assign writedata = result;

    // PC update
    assign pcplus4  = pc + 32'd4;
    assign pcbranch = pcplus4 + ({{14{instr[15]}}, instr[15:0], 2'b00}); // sign-extend and shift
    assign pcjump   = {pcplus4[31:28], instr[25:0], 2'b00};

    wire pcsrc = branch & zero;
    assign pcnext = jump ? pcjump : (pcsrc ? pcbranch : pcplus4);

    // expose $v0 (reg 2)
    assign reg_v0 = RF.rf[2];
endmodule
