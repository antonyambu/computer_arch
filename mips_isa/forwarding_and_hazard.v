module forwarding_unit(
    input  wire       exmem_regwrite,
    input  wire [4:0] exmem_rd,
    input  wire       memwb_regwrite,
    input  wire [4:0] memwb_rd,
    input  wire [4:0] idex_rs, idex_rt,
    output reg  [1:0] forwardA, forwardB
);
    always @* begin
        forwardA = 2'b00; forwardB = 2'b00;
        if (exmem_regwrite && (exmem_rd!=0) && (exmem_rd==idex_rs)) forwardA = 2'b10;
        if (exmem_regwrite && (exmem_rd!=0) && (exmem_rd==idex_rt)) forwardB = 2'b10;
        if (memwb_regwrite && (memwb_rd!=0) && (memwb_rd==idex_rs) && !(exmem_regwrite && (exmem_rd!=0) && (exmem_rd==idex_rs))) forwardA = 2'b01;
        if (memwb_regwrite && (memwb_rd!=0) && (memwb_rd==idex_rt) && !(exmem_regwrite && (exmem_rd!=0) && (exmem_rd==idex_rt))) forwardB = 2'b01;
    end
endmodule

module hazard_unit(
    input  wire       idex_memread,
    input  wire [4:0] idex_rt,
    input  wire [4:0] ifid_rs,
    input  wire [4:0] ifid_rt,
    output reg        stall,
    output reg        flush
);
    always @* begin
        stall = 1'b0; flush = 1'b0;
        // Load-use hazard
        if (idex_memread && ((idex_rt == ifid_rs) || (idex_rt == ifid_rt))) stall = 1'b1;
    end
endmodule
