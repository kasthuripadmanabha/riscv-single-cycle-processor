// ============================================================
// riscv_top.sv
// Single-cycle RV32I processor (R-type, I-type ALU, branches,
// JAL, JALR). Fetch, decode, execute and write-back all finish
// in ONE clock cycle. The only clocked state is the PC and the
// register file; everything else is combinational.
//
// dbg_pc / dbg_wb_data are debug outputs. Without at least one
// output, Vivado synthesis would remove the whole processor as
// logic that drives nothing.
// ============================================================

module riscv_top
    import riscv_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] dbg_pc,
    output logic [31:0] dbg_wb_data
);

    // ---- Signals ----
    logic [31:0] pc, pc_plus4, instruction;
    logic [6:0]  opcode, funct7;
    logic [4:0]  rd_addr, rs1_addr, rs2_addr;
    logic [2:0]  funct3;

    logic        reg_write, alu_src, branch, jal, jalr;
    alu_op_t     alu_ctrl;
    imm_sel_t    imm_sel;
    wb_sel_t     wb_sel;

    logic [31:0] imm, rs1_data, rs2_data;
    logic [31:0] alu_b, alu_result, wb_data;

    // ---- Program counter / next-PC logic ----
    pc_logic pc_unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .branch     (branch),
        .jal        (jal),
        .jalr       (jalr),
        .funct3     (funct3),
        .rs1_data   (rs1_data),
        .rs2_data   (rs2_data),
        .imm        (imm),
        .alu_result (alu_result),
        .pc         (pc),
        .pc_plus4   (pc_plus4)
    );

    // ---- Fetch ----
    instruction_memory imem (
        .pc          (pc),
        .instruction (instruction)
    );

    // ---- Decode: field extraction (pure wiring) ----
    assign opcode   = instruction[6:0];
    assign rd_addr  = instruction[11:7];
    assign funct3   = instruction[14:12];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign funct7   = instruction[31:25];

    control_unit ctrl (
        .opcode    (opcode),
        .funct3    (funct3),
        .funct7    (funct7),
        .reg_write (reg_write),
        .alu_src   (alu_src),
        .alu_ctrl  (alu_ctrl),
        .imm_sel   (imm_sel),
        .branch    (branch),
        .jal       (jal),
        .jalr      (jalr),
        .wb_sel    (wb_sel)
    );

    imm_gen immgen (
        .instruction (instruction),
        .imm_sel     (imm_sel),
        .imm         (imm)
    );

    register_file rf (
        .clk       (clk),
        .rst_n     (rst_n),
        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr),
        .rd_data   (wb_data),
        .reg_write (reg_write),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    // ---- Execute ----
    assign alu_b = alu_src ? imm : rs2_data;   // operand-B mux

    alu alu_inst (
        .operand_a (rs1_data),
        .operand_b (alu_b),
        .alu_ctrl  (alu_ctrl),
        .result    (alu_result)
    );

    // ---- Write-back mux ----
    assign wb_data = (wb_sel == WB_PC4) ? pc_plus4 : alu_result;

    // ---- Debug outputs ----
    assign dbg_pc      = pc;
    assign dbg_wb_data = wb_data;

endmodule
