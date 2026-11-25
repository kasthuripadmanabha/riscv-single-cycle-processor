// ============================================================
// control_unit.sv
// Two-level decoder:
//   1. Main decoder  (opcode)               -> datapath controls
//   2. ALU decoder   (funct3, funct7 bit 5) -> alu_ctrl
// Purely combinational. Every output gets a default value first,
// so no latches are inferred and any unsupported opcode becomes
// a harmless NOP (no register write, PC simply goes to PC+4).
// ============================================================

module control_unit
    import riscv_pkg::*;
(
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic       reg_write,  // write rd this cycle
    output logic       alu_src,    // 0: operand B = rs2, 1: = imm
    output alu_op_t    alu_ctrl,
    output imm_sel_t   imm_sel,
    output logic       branch,     // conditional branch instruction
    output logic       jal,
    output logic       jalr,
    output wb_sel_t    wb_sel      // what gets written to rd
);

    // ---- ALU decoder ----
    // R-type and I-type ALU instructions share the same funct3
    // meanings. Two special cases:
    //  * funct3=000: SUB exists only for R-type. For ADDI, bits
    //    [31:25] are part of the immediate, NOT funct7, so they
    //    must be ignored.
    //  * funct3=101: SRL/SRA (and SRLI/SRAI) are distinguished by
    //    instruction bit 30 (= funct7[5]) in BOTH formats.
    function automatic alu_op_t decode_alu(input logic [2:0] f3,
                                           input logic       f7_bit5,
                                           input logic       is_rtype);
        alu_op_t op;
        case (f3)
            3'b000: begin
                if (is_rtype && f7_bit5) op = ALU_SUB;
                else                     op = ALU_ADD;
            end
            3'b001: op = ALU_SLL;
            3'b010: op = ALU_SLT;
            3'b011: op = ALU_SLTU;
            3'b100: op = ALU_XOR;
            3'b101: begin
                if (f7_bit5) op = ALU_SRA;
                else         op = ALU_SRL;
            end
            3'b110: op = ALU_OR;
            3'b111: op = ALU_AND;
            default: op = ALU_ADD;
        endcase
        return op;
    endfunction

    // ---- Main decoder ----
    always_comb begin
        // Safe defaults = NOP
        reg_write = 1'b0;
        alu_src   = 1'b0;
        alu_ctrl  = ALU_ADD;
        imm_sel   = IMM_I;
        branch    = 1'b0;
        jal       = 1'b0;
        jalr      = 1'b0;
        wb_sel    = WB_ALU;

        case (opcode)
            OP_RTYPE: begin              // rd = rs1 op rs2
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_ctrl  = decode_alu(funct3, funct7[5], 1'b1);
            end

            OP_ITYPE: begin              // rd = rs1 op imm
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_I;
                alu_ctrl  = decode_alu(funct3, funct7[5], 1'b0);
            end

            OP_BRANCH: begin             // if (cond) PC = PC + imm
                branch    = 1'b1;        // comparison done in pc_logic
                imm_sel   = IMM_B;
            end

            OP_JAL: begin                // rd = PC+4; PC = PC + imm
                reg_write = 1'b1;
                jal       = 1'b1;
                imm_sel   = IMM_J;
                wb_sel    = WB_PC4;
            end

            OP_JALR: begin               // rd = PC+4; PC = (rs1+imm) & ~1
                reg_write = 1'b1;
                jalr      = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_I;
                alu_ctrl  = ALU_ADD;     // ALU computes rs1 + imm
                wb_sel    = WB_PC4;
            end

            default: ;                   // unsupported opcode -> NOP
        endcase
    end

endmodule