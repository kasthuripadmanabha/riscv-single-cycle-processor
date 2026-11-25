// ============================================================
// alu.sv
// Purely combinational ALU for all RV32I integer operations.
// The result must be ready in the same cycle (single-cycle CPU).
// Operand B is either rs2 (R-type) or the immediate (I-type);
// that choice is made by a mux in riscv_top, not here.
// ============================================================

module alu
    import riscv_pkg::*;
(
    input  logic [31:0] operand_a,   // rs1_data
    input  logic [31:0] operand_b,   // rs2_data or immediate
    input  alu_op_t     alu_ctrl,    // operation select
    output logic [31:0] result
);

    always_comb begin
        case (alu_ctrl)
            ALU_ADD:  result = operand_a + operand_b;
            ALU_SUB:  result = operand_a - operand_b;
            ALU_AND:  result = operand_a & operand_b;
            ALU_OR:   result = operand_a | operand_b;
            ALU_XOR:  result = operand_a ^ operand_b;

            // Only the low 5 bits are the shift amount (0-31),
            // exactly as the RISC-V spec defines for RV32.
            ALU_SLL:  result = operand_a << operand_b[4:0];
            ALU_SRL:  result = operand_a >> operand_b[4:0];

            // Arithmetic shift: copies the sign bit into vacated bits.
            ALU_SRA:  result = $signed(operand_a) >>> operand_b[4:0];

            // RISC-V has no flags register; comparisons write 1 or 0.
            ALU_SLT:  result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: result = (operand_a < operand_b) ? 32'd1 : 32'd0;

            default:  result = 32'd0;
        endcase
    end

endmodule
