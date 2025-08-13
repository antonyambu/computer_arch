module maindec(
    input  wire [5:0] op,
    output reg        memtoreg, memwrite,
    output reg        branch, alusrc,
    output reg        regdst, regwrite,
    output reg        jump,
    output reg  [1:0] aluop
);
    // defaults
    always @* begin
        memtoreg=0; memwrite=0; branch=0; alusrc=0;
        regdst=0; regwrite=0; jump=0; aluop=2'b00;
        case(op)
            6'b000000: begin regdst=1; regwrite=1; aluop=2'b10; end // R-type
            6'b100011: begin memtoreg=1; regwrite=1; alusrc=1; aluop=2'b00; end // LW
            6'b101011: begin memwrite=1; alusrc=1; aluop=2'b00; end // SW
            6'b000100: begin branch=1; aluop=2'b01; end // BEQ
            6'b001000: begin regwrite=1; alusrc=1; aluop=2'b00; end // ADDI
            6'b000010: begin jump=1; end // J
        endcase
    end
endmodule

module aludec(
    input  wire [5:0] funct,
    input  wire [1:0] aluop,
    output reg  [3:0] alucontrol
);
    always @* begin
        case (aluop)
            2'b00: alucontrol = 4'b0010; // add (lw/sw/addi)
            2'b01: alucontrol = 4'b0110; // sub (beq)
            default: begin // R-type
                case (funct)
                    6'b100000: alucontrol = 4'b0012[3:0]; // add (0010)
                    6'b100010: alucontrol = 4'b0110;      // sub
                    6'b100100: alucontrol = 4'b0000;      // and
                    6'b100101: alucontrol = 4'b0001;      // or
                    6'b101010: alucontrol = 4'b0111;      // slt
                    default:   alucontrol = 4'b0000;
                endcase
            end
        endcase
    end
endmodule

module controller_single(
    input  wire [5:0] op, funct,
    output wire       memtoreg, memwrite,
    output wire       branch, alusrc,
    output wire       regdst, regwrite,
    output wire       jump,
    output wire [3:0] alucontrol
);
    wire [1:0] aluop;
    maindec md(op, memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, aluop);
    aludec  ad(funct, aluop, alucontrol);
endmodule
