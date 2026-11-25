// ============================================================
// instruction_memory.sv
// 64-word ROM holding the test program. Word-addressed with
// pc[7:2]: instructions are 4-byte aligned, so pc[1:0] is always
// 00 and is not used.
//
// Test program (byte address: instruction -> expected effect)
//  -- set up operands with I-type --
//  00: addi x1,  x0, 10      x1  = 10
//  04: addi x2,  x0, 3       x2  = 3
//  -- R-type ALU --
//  08: add  x3,  x1, x2      x3  = 13
//  0C: sub  x4,  x1, x2      x4  = 7
//  10: and  x5,  x1, x2      x5  = 2
//  14: or   x6,  x1, x2      x6  = 11
//  18: xor  x7,  x1, x2      x7  = 9
//  1C: sll  x8,  x1, x2      x8  = 80
//  20: srl  x9,  x1, x2      x9  = 1
//  24: sra  x10, x1, x2      x10 = 1
//  28: slt  x11, x2, x1      x11 = 1
//  2C: sltu x12, x2, x1      x12 = 1
//  -- I-type, negative immediate (tests sign extension) --
//  30: addi x13, x0, -5      x13 = 0xFFFFFFFB
//  34: srai x14, x13, 1      x14 = 0xFFFFFFFD (-3)
//  38: slti x15, x13, 0      x15 = 1
//  -- branches (x20 must stay 0: it is only written by
//     instructions that should be SKIPPED) --
//  3C: beq  x1, x2, +8       not taken
//  40: addi x16, x0, 1       x16 = 1
//  44: bne  x1, x2, +8       taken -> 4C
//  48: addi x20, x0, 99      (skipped)
//  4C: blt  x13, x0, +8      taken (-5 < 0) -> 54
//  50: addi x20, x0, 99      (skipped)
//  54: bgeu x13, x1, +8      taken (0xFFFFFFFB >= 10 unsigned) -> 5C
//  58: addi x20, x0, 99      (skipped)
//  5C: bge  x13, x0, +8      not taken (-5 < 0)
//  60: addi x17, x0, 1       x17 = 1
//  64: bltu x1, x2, +8       not taken (10 > 3)
//  68: addi x18, x0, 1       x18 = 1
//  -- jumps --
//  6C: jal  x19, +8          x19 = 0x70, -> 74
//  70: addi x20, x0, 99      (skipped)
//  74: addi x21, x0, 0x84    x21 = 0x84
//  78: jalr x22, 0(x21)      x22 = 0x7C, -> 84
//  7C: addi x20, x0, 99      (skipped)
//  80: addi x20, x0, 99      (skipped)
//  84: addi x23, x0, 1       x23 = 1
//  -- x0 must stay zero --
//  88: addi x0,  x0, 5       ignored
//  8C: jal  x0, 0            halt (jumps to itself forever)
// ============================================================

module instruction_memory (
    input  logic [31:0] pc,
    output logic [31:0] instruction
);

    localparam int MEM_DEPTH = 64;

    logic [31:0] mem [0:MEM_DEPTH-1];

    initial begin
        for (int i = 0; i < MEM_DEPTH; i++)
            mem[i] = 32'h0000_0000;     // opcode 0 = NOP in this design

        mem[0]  = 32'h00A00093; // addi x1,  x0, 10
        mem[1]  = 32'h00300113; // addi x2,  x0, 3
        mem[2]  = 32'h002081B3; // add  x3,  x1, x2
        mem[3]  = 32'h40208233; // sub  x4,  x1, x2
        mem[4]  = 32'h0020F2B3; // and  x5,  x1, x2
        mem[5]  = 32'h0020E333; // or   x6,  x1, x2
        mem[6]  = 32'h0020C3B3; // xor  x7,  x1, x2
        mem[7]  = 32'h00209433; // sll  x8,  x1, x2
        mem[8]  = 32'h0020D4B3; // srl  x9,  x1, x2
        mem[9]  = 32'h4020D533; // sra  x10, x1, x2
        mem[10] = 32'h001125B3; // slt  x11, x2, x1
        mem[11] = 32'h00113633; // sltu x12, x2, x1
        mem[12] = 32'hFFB00693; // addi x13, x0, -5
        mem[13] = 32'h4016D713; // srai x14, x13, 1
        mem[14] = 32'h0006A793; // slti x15, x13, 0
        mem[15] = 32'h00208463; // beq  x1,  x2, +8
        mem[16] = 32'h00100813; // addi x16, x0, 1
        mem[17] = 32'h00209463; // bne  x1,  x2, +8
        mem[18] = 32'h06300A13; // addi x20, x0, 99   (skipped)
        mem[19] = 32'h0006C463; // blt  x13, x0, +8
        mem[20] = 32'h06300A13; // addi x20, x0, 99   (skipped)
        mem[21] = 32'h0016F463; // bgeu x13, x1, +8
        mem[22] = 32'h06300A13; // addi x20, x0, 99   (skipped)
        mem[23] = 32'h0006D463; // bge  x13, x0, +8
        mem[24] = 32'h00100893; // addi x17, x0, 1
        mem[25] = 32'h0020E463; // bltu x1,  x2, +8
        mem[26] = 32'h00100913; // addi x18, x0, 1
        mem[27] = 32'h008009EF; // jal  x19, +8
        mem[28] = 32'h06300A13; // addi x20, x0, 99   (skipped)
        mem[29] = 32'h08400A93; // addi x21, x0, 0x84
        mem[30] = 32'h000A8B67; // jalr x22, 0(x21)
        mem[31] = 32'h06300A13; // addi x20, x0, 99   (skipped)
        mem[32] = 32'h06300A13; // addi x20, x0, 99   (skipped)
        mem[33] = 32'h00100B93; // addi x23, x0, 1
        mem[34] = 32'h00500013; // addi x0,  x0, 5    (must be ignored)
        mem[35] = 32'h0000006F; // jal  x0,  0        (halt loop)
    end

    // Combinational read: the instruction for the current PC is
    // available in the same cycle (required for single-cycle).
    always_comb begin
        instruction = mem[pc[7:2]];
    end

endmodule
