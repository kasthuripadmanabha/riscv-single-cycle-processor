// ============================================================
// register_file.sv
// 32 x 32-bit registers (RV32). Two combinational read ports,
// one synchronous write port.
//  * Combinational reads: operands are available in the same
//    cycle, which a single-cycle design requires.
//  * Synchronous write: rd is updated on the rising clock edge.
//  * x0 is hardwired to zero: reads return 0 and writes are
//    ignored, as the RISC-V architecture requires.
// Because every register has an asynchronous reset, synthesis
// builds this from flip-flops (~1024 FFs), not distributed RAM.
// ============================================================

module register_file (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    input  logic        reg_write,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] regs [0:31];

    // ---- Reads ----
    always_comb begin
        rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
        rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];
    end

    // ---- Write ----
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 32; i++)
                regs[i] <= 32'd0;
        end
        else if (reg_write && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;   // writes to x0 are ignored
        end
    end

endmodule
