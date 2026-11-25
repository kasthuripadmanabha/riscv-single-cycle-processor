// ============================================================
// riscv_pkg.sv
// Shared definitions for the single-cycle RV32I processor:
// opcodes, branch funct3 codes, ALU operation codes, immediate
// formats and write-back select. Defining these ONCE here means
// the control unit, ALU and other modules can never disagree
// about an encoding.
// ============================================================

package riscv_pkg;

    // ---- Opcodes (instruction[6:0]) ----
    localparam logic [6:0] OP_RTYPE  = 7'b0110011; // ADD, SUB, AND ...
    localparam logic [6:0] OP_ITYPE  = 7'b0010011; // ADDI, ANDI, SLLI ...
    localparam logic [6:0] OP_BRANCH = 7'b1100011; // BEQ, BNE, BLT ...
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;

    // ---- Branch funct3 codes ----
    localparam logic [2:0] F3_BEQ  = 3'b000;
    localparam logic [2:0] F3_BNE  = 3'b001;
    localparam logic [2:0] F3_BLT  = 3'b100;
    localparam logic [2:0] F3_BGE  = 3'b101;
    localparam logic [2:0] F3_BLTU = 3'b110;
    localparam logic [2:0] F3_BGEU = 3'b111;

    // ---- ALU operations ----
    typedef enum logic [3:0] {
        ALU_ADD  = 4'd0,
        ALU_SUB  = 4'd1,
        ALU_AND  = 4'd2,
        ALU_OR   = 4'd3,
        ALU_XOR  = 4'd4,
        ALU_SLL  = 4'd5,
        ALU_SRL  = 4'd6,
        ALU_SRA  = 4'd7,
        ALU_SLT  = 4'd8,
        ALU_SLTU = 4'd9
    } alu_op_t;

    // ---- Immediate formats ----
    typedef enum logic [2:0] {
        IMM_I = 3'd0,   // ADDI, JALR
        IMM_S = 3'd1,   // stores (generated, not yet used)
        IMM_B = 3'd2,   // branches
        IMM_U = 3'd3,   // LUI/AUIPC (generated, not yet used)
        IMM_J = 3'd4    // JAL
    } imm_sel_t;

    // ---- Write-back source ----
    typedef enum logic {
        WB_ALU = 1'b0,  // normal ALU result
        WB_PC4 = 1'b1   // return address for JAL/JALR
    } wb_sel_t;

endpackage