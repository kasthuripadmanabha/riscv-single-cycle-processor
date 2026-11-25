// ============================================================
// imm_gen.sv
// Immediate generator: extracts the immediate bits from the
// instruction for the selected format and SIGN-EXTENDS them to
// 32 bits. Bit 31 of the instruction is always the sign bit in
// every format - RISC-V's encoding was designed this way so the
// sign-extension wiring is identical for all formats.
//
// B and J immediates are byte offsets that are always even, so
// their bit 0 is not stored in the instruction; it is forced 0.
// ============================================================

module imm_gen
    import riscv_pkg::*;
(
    input  logic [31:0] instruction,
    input  imm_sel_t    imm_sel,
    output logic [31:0] imm
);

    always_comb begin
        case (imm_sel)
            IMM_I: imm = {{20{instruction[31]}}, instruction[31:20]};

            IMM_S: imm = {{20{instruction[31]}}, instruction[31:25],
                          instruction[11:7]};

            IMM_B: imm = {{19{instruction[31]}}, instruction[31],
                          instruction[7], instruction[30:25],
                          instruction[11:8], 1'b0};

            IMM_U: imm = {instruction[31:12], 12'b0};

            IMM_J: imm = {{11{instruction[31]}}, instruction[31],
                          instruction[19:12], instruction[20],
                          instruction[30:21], 1'b0};

            default: imm = 32'd0;
        endcase
    end


endmodule