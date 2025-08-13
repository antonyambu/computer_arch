module mips_multicycle #(
    parameter IMEM_FILE=""
)(
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] pc_debug,
    output wire [31:0] reg_v0
);
    // State machine
    localparam IF=0, ID=1, EX_R=2, EX_MEMADR=3, MEM_RD=4, MEM_WB=5,
               MEM_WR=6, EX_BRANCH=7, EX_JUMP=8, EX_ADDI=9, WB_R=10, WB_ADDI=11;

    reg [3:0] state, next;

    // Datapath registers
    reg [31:0] pc, ir, mdr, a, b, aluout;
    wire [31:0] instr = ir;
    wire [31:0] signimm;
    wire [31:0] srca = a;
    wire [31:0] srcb = b;
    wire [31:0] readdata, imem_data, alu_y;
    wire [3:0]  alucontrol;
    wire        zero;

    // Memories
    imem #(.MEMFILE(IMEM_FILE)) IM(pc[31:2], imem_data);
    dmem DM(clk, (state==MEM_WR), aluout, b, readdata);

    // Register file
    wire we3;
    wire [4:0] a1 = instr[25:21];
    wire [4:0] a2 = instr[20:16];
    wire [4:0] a3 = (state==WB_R) ? instr[15:11] : ((state==MEM_WB || state==WB_ADDI) ? instr[20:16] : 5'd0);
    wire [31:0] wd3 = (state==MEM_WB) ? mdr : ((state==WB_R || state==WB_ADDI) ? aluout : 32'd0);
    register_file RF(clk, we3, a1, a2, a3, wd3, /*rd1*/ , /*rd2*/ );

    wire [31:0] rd1 = (a1==0)?32'b0:RF.rf[a1];
    wire [31:0] rd2 = (a2==0)?32'b0:RF.rf[a2];

    assign we3 = (state==MEM_WB) || (state==WB_R) || (state==WB_ADDI);
    signext SE(instr[15:0], signimm);

    // ALU
    alu_32bit ALU(srca, srcb, alucontrol, alu_y, zero);

    // ALU control (simple)
    function [3:0] alu_ctl(input [5:0] op, input [5:0] funct, input [3:0] st);
        begin
            case (st)
                EX_R   : case (funct)
                            6'b100000: alu_ctl = 4'b0010; // add
                            6'b100010: alu_ctl = 4'b0110; // sub
                            6'b100100: alu_ctl = 4'b0000; // and
                            6'b100101: alu_ctl = 4'b0001; // or
                            6'b101010: alu_ctl = 4'b0111; // slt
                            default  : alu_ctl = 4'b0010;
                         endcase
                EX_MEMADR, EX_ADDI: alu_ctl = 4'b0010; // add
                EX_BRANCH: alu_ctl = 4'b0110; // sub
                default: alu_ctl = 4'b0010;
            endcase
        end
    endfunction
    assign alucontrol = alu_ctl(instr[31:26], instr[5:0], state[3:0]);

    // Next state logic
    always @* begin
        next = state;
        case (state)
            IF:       next = ID;
            ID: begin
                case (instr[31:26])
                    6'b000000: next = EX_R;       // R-type
                    6'b100011: next = EX_MEMADR;  // LW
                    6'b101011: next = EX_MEMADR;  // SW
                    6'b000100: next = EX_BRANCH;  // BEQ
                    6'b001000: next = EX_ADDI;    // ADDI
                    6'b000010: next = EX_JUMP;    // J
                    default:   next = IF;
                endcase
            end
            EX_R:       next = WB_R;
            EX_MEMADR:  next = (instr[31:26]==6'b100011) ? MEM_RD : MEM_WR;
            MEM_RD:     next = MEM_WB;
            MEM_WB:     next = IF;
            MEM_WR:     next = IF;
            EX_BRANCH:  next = IF;
            EX_JUMP:    next = IF;
            EX_ADDI:    next = WB_ADDI;
            WB_R:       next = IF;
            WB_ADDI:    next = IF;
            default:    next = IF;
        endcase
    end

    // Sequential state/data updates
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IF;
            pc    <= 32'b0;
        end else begin
            state <= next;
            case (state)
                IF: begin
                    ir <= imem_data;
                    pc <= pc + 32'd4;
                end
                ID: begin
                    a <= rd1; b <= rd2;
                end
                EX_R: begin
                    aluout <= alu_y;
                end
                EX_MEMADR: begin
                    aluout <= a + signimm;
                end
                MEM_RD: begin
                    mdr <= readdata;
                end
                MEM_WR: begin end
                EX_BRANCH: begin
                    if (a == b) pc <= pc + {{14{instr[15]}}, instr[15:0], 2'b00};
                end
                EX_JUMP: begin
                    pc <= {pc[31:28], instr[25:0], 2'b00};
                end
                EX_ADDI: begin
                    aluout <= a + signimm;
                end
                default: begin end
            endcase
        end
    end

    assign pc_debug = pc;
    assign reg_v0   = RF.rf[2];
endmodule
