// ============================================================
// tb_riscv_top.sv
// Self-checking testbench. The program sets up its own operands
// with ADDI, so no values are forced into the processor. The
// testbench only READS internal state (registers, PC) at the end
// to check results.
//  * Prints a trace of every register write
//  * Waits until the program reaches its halt loop (with timeout)
//  * Checks every destination register, x0, and the final PC
// ============================================================

`timescale 1ns / 1ps

module tb_riscv_top;

    logic        clk = 1'b0;
    logic        rst_n;
    logic [31:0] dbg_pc, dbg_wb_data;

    localparam logic [31:0] HALT_PC = 32'h0000_008C;

    riscv_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .dbg_pc      (dbg_pc),
        .dbg_wb_data (dbg_wb_data)
    );

    always #5 clk = ~clk;   // 100 MHz simulation clock

    int pass_count = 0;
    int fail_count = 0;

    task automatic check_reg(input int idx, input logic [31:0] exp,
                             input string what);
        if (dut.rf.regs[idx] === exp) begin
            pass_count++;
            $display("[PASS] x%0d = 0x%08h  %s", idx, dut.rf.regs[idx], what);
        end
        else begin
            fail_count++;
            $error("[FAIL] x%0d = 0x%08h, expected 0x%08h  %s",
                   idx, dut.rf.regs[idx], exp, what);
        end
    endtask

    // ---- Execution trace ----
    always @(posedge clk) begin
        if (rst_n && dut.reg_write && dut.rd_addr != 5'd0)
            $display("t=%0t  PC=0x%08h  instr=0x%08h  x%0d <= 0x%08h",
                     $time, dut.pc, dut.instruction, dut.rd_addr, dut.wb_data);
    end

    initial begin
        // Reset
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        @(negedge clk) rst_n = 1'b1;   // release away from the clock edge

        // Run until the halt loop, or time out
        fork
            wait (dut.pc == HALT_PC);
            begin
                repeat (200) @(posedge clk);
                $error("TIMEOUT: PC never reached halt address");
            end
        join_any
        disable fork;
        repeat (2) @(posedge clk);
        #1;

        $display("---------------- RESULTS ----------------");
        check_reg(0,  32'h0000_0000, "x0 stays zero");
        check_reg(1,  32'd10,        "ADDI");
        check_reg(2,  32'd3,         "ADDI");
        check_reg(3,  32'd13,        "ADD");
        check_reg(4,  32'd7,         "SUB");
        check_reg(5,  32'd2,         "AND");
        check_reg(6,  32'd11,        "OR");
        check_reg(7,  32'd9,         "XOR");
        check_reg(8,  32'd80,        "SLL");
        check_reg(9,  32'd1,         "SRL");
        check_reg(10, 32'd1,         "SRA");
        check_reg(11, 32'd1,         "SLT");
        check_reg(12, 32'd1,         "SLTU");
        check_reg(13, 32'hFFFF_FFFB, "ADDI negative imm");
        check_reg(14, 32'hFFFF_FFFD, "SRAI");
        check_reg(15, 32'd1,         "SLTI");
        check_reg(16, 32'd1,         "BEQ not taken");
        check_reg(17, 32'd1,         "BGE not taken");
        check_reg(18, 32'd1,         "BLTU not taken");
        check_reg(19, 32'h0000_0070, "JAL return address");
        check_reg(20, 32'h0000_0000, "no skipped instruction ran");
        check_reg(21, 32'h0000_0084, "JALR base");
        check_reg(22, 32'h0000_007C, "JALR return address");
        check_reg(23, 32'd1,         "JALR landed on target");

        if (dut.pc === HALT_PC) begin
            pass_count++;
            $display("[PASS] PC halted at 0x%08h", dut.pc);
        end
        else begin
            fail_count++;
            $error("[FAIL] PC = 0x%08h, expected 0x%08h", dut.pc, HALT_PC);
        end

        $display("========================================");
        $display(" RESULT: PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display("========================================");
        $stop;
    end

endmodule