module mips_pipeline #(
    parameter IMEM_FILE=""
)(
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] pc_debug,
    output wire [31:0] reg_v0
);
    // IF stage
    reg  [31:0] pc;
    wire [31:0] instrF, pcplus4F, pcnextF;
    assign pcplus4F = pc + 32'd4;
    imem #(.MEMFILE(IMEM_FILE)) IM(pc[31:2], instrF);

    // Predictor
    wire predict_takenF;
    wire [31:0] pc_pred_targetF = {pcplus4F[31:28], instrF[25:0], 2'b00};
    two_bit_predictor BP(
        .clk(clk), .rst(rst),
        .index(pc[9:2]),
        .actual_taken(/* from EX */ 1'b0),
        .update(1'b0),
        .predict_taken(predict_takenF)
    );
    assign pcnextF = predict_takenF ? pc_pred_targetF : pcplus4F;

    // IF/ID
    reg [31:0] pcplus4D, instrD;
    reg        stallD, flushD;
    wire       stall, flush;
    // ID stage
    wire [4:0] rsD = instrD[25:21];
    wire [4:0] rtD = instrD[20:16];
    wire [4:0] rdD = instrD[15:11];
    wire [31:0] signimmD; signext SE_D(instrD[15:0], signimmD);
    wire        jumpD  = (instrD[31:26]==6'b000010);
    wire        branchD= (instrD[31:26]==6'b000100);
    wire        memtoregD = (instrD[31:26]==6'b100011);
    wire        memwriteD = (instrD[31:26]==6'b101011);
    wire        alusrcD   = (instrD[31:26]==6'b100011)||(instrD[31:26]==6'b101011)||(instrD[31:26]==6'b001000);
    wire        regdstD   = (instrD[31:26]==6'b000000)?1'b1:1'b0;
    wire        regwriteD = (instrD[31:26]==6'b000000)||(instrD[31:26]==6'b100011)||(instrD[31:26]==6'b001000);
    wire [3:0]  alucontrolD;
    aludec AD_D(instrD[5:0], (instrD[31:26]==6'b000000)?2'b10:((instrD[31:26]==6'b000100)?2'b01:2'b00), alucontrolD);

    // Register file
    wire [31:0] rd1D, rd2D;
    wire [31:0] resultW;
    wire [4:0]  writeregW;
    wire        regwriteW;
    register_file RF(clk, regwriteW, rsD, rtD, writeregW, resultW, rd1D, rd2D);

    // Hazard unit
    wire idex_memread; wire [4:0] idex_rt;
    hazard_unit HU(idex_memread, idex_rt, rsD, rtD, stall, flush);

    // ID/EX
    reg [31:0] rd1E, rd2E, signimmE, pcplus4E;
    reg [4:0]  rsE, rtE, rdE;
    reg        memtoregE, memwriteE, alusrcE, regdstE, regwriteE, branchE;
    reg [3:0]  alucontrolE;

    // EX stage
    wire [1:0] forwardAE, forwardBE;
    wire [31:0] srcaE, srcbE, aluoutE;
    wire zeroE;
    forwarding_unit FU(
        .exmem_regwrite(regwriteM), .exmem_rd(writeregM),
        .memwb_regwrite(regwriteW), .memwb_rd(writeregW),
        .idex_rs(rsE), .idex_rt(rtE),
        .forwardA(forwardAE), .forwardB(forwardBE)
    );

    wire [31:0] forwardA_src = (forwardAE==2'b10)? aluoutM : (forwardAE==2'b01? resultW : rd1E);
    wire [31:0] forwardB_src = (forwardBE==2'b10)? aluoutM : (forwardBE==2'b01? resultW : rd2E);
    wire [31:0] srcbE_mux = alusrcE ? signimmE : forwardB_src;

    alu_32bit ALU_E(forwardA_src, srcbE_mux, alucontrolE, aluoutE, zeroE);

    wire [4:0] writeregE = regdstE ? rdE : rtE;

    // EX/MEM
    reg        memtoregM, memwriteM, regwriteM, branchM;
    reg [31:0] aluoutM, writedataM;
    reg [4:0]  writeregM;
    reg        zeroM;
    // Branch target
    wire [31:0] pcbranchE = pcplus4E + {signimmE[29:0],2'b00};

    // MEM stage
    wire [31:0] readdataM;
    dmem DM(clk, memwriteM, aluoutM, writedataM, readdataM);

    // MEM/WB
    reg        memtoregW;
    reg [31:0] readdataW, aluoutW;

    // WB stage
    assign resultW   = memtoregW ? readdataW : aluoutW;
    assign writeregW = writeregM;
    assign regwriteW = regwriteM;

    // Pipeline registers and control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 0;
            instrD <= 0; pcplus4D <= 0;
            // clear ID/EX
            memtoregE<=0; memwriteE<=0; alusrcE<=0; regdstE<=0; regwriteE<=0; branchE<=0; alucontrolE<=0;
        end else begin
            // IF
            if (!stall) pc <= pcnextF;
            // IF/ID
            if (!stall) begin instrD <= instrF; pcplus4D <= pcplus4F; end
            if (flush)  begin instrD <= 32'b0; end
            // ID/EX
            rd1E<=rd1D; rd2E<=rd2D; signimmE<=signimmD; pcplus4E<=pcplus4D;
            rsE<=rsD; rtE<=rtD; rdE<=rdD;
            memtoregE<=memtoregD; memwriteE<=memwriteD; alusrcE<=alusrcD; regdstE<=regdstD; regwriteE<=regwriteD; branchE<=branchD;
            alucontrolE<=alucontrolD;
            // EX/MEM
            memtoregM<=memtoregE; memwriteM<=memwriteE; regwriteM<=regwriteE; branchM<=branchE;
            aluoutM<=aluoutE; writedataM<=forwardB_src; zeroM<=zeroE; writeregM<=writeregE;
            // MEM/WB
            memtoregW<=memtoregM; readdataW<=readdataM; aluoutW<=aluoutM;
        end
    end

    assign pc_debug = pc;
    assign reg_v0   = RF.rf[2];

    // Expose for hazard unit
    assign idex_memread = memtoregE;
    assign idex_rt      = rtE;
endmodule
