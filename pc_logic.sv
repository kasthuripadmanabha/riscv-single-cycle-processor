// ============================================================
// pc_logic.sv
// Program-counter logic: the PC register, the branch comparator
// and the next-PC selection.
//
// Next-PC priority:
//   JALR                -> (rs1 + imm) & ~1   (target from ALU)
//   JAL or taken branch -> PC + imm
//   otherwise           -> PC + 4
//
// The branch target uses its OWN adder (PC + imm) so the ALU is
// free; JALR reuses the ALU result (rs1 + imm). Bit 0 of the
// JALR target is cleared, as the RISC-V spec requires.
// ============================================================

module pc_logic
    import riscv_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic [2:0]  funct3,
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [31:0] imm,
    input  logic [31:0] alu_result,
    output logic [31:0] pc,
    output logic [31:0] pc_plus4
);

    logic        branch_taken;
    logic [31:0] pc_target;
    logic [31:0] pc_next;

    assign pc_plus4  = pc + 32'd4;
    assign pc_target = pc + imm;

    // ---- Branch comparator ----
    always_comb begin
        case (funct3)
            F3_BEQ:  branch_taken = (rs1_data == rs2_data);
            F3_BNE:  branch_taken = (rs1_data != rs2_data);
            F3_BLT:  branch_taken = ($signed(rs1_data) <  $signed(rs2_data));
            F3_BGE:  branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
            F3_BLTU: branch_taken = (rs1_data <  rs2_data);
            F3_BGEU: branch_taken = (rs1_data >= rs2_data);
            default: branch_taken = 1'b0;   // 010/011 are not branches
        endcase
    end

    // ---- Next-PC mux ----
    always_comb begin
        if (jalr)
            pc_next = {alu_result[31:1], 1'b0};
        else if (jal || (branch && branch_taken))
            pc_next = pc_target;
        else
            pc_next = pc_plus4;
    end

    // ---- PC register ----
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'h0000_0000;
        else
            pc <= pc_next;
    end

endmodule