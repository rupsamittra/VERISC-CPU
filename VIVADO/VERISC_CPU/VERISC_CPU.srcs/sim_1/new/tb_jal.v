`timescale 1ns/1ps

module tb_jal;

    reg clk;
    reg reset;

    riscv_single_cycle_cpu uut (
        .clk   (clk),
        .reset (reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer cycle;

    task check_reg;
        input integer idx;
        input [31:0] expected;
        input integer test_num;
        begin
            if (uut.rf.regs[idx] === expected) begin
                $display("  PASS [T%0d]: x%0d = 0x%08X", test_num, idx, uut.rf.regs[idx]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: x%0d = 0x%08X  (expected 0x%08X)",
                         test_num, idx, uut.rf.regs[idx], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_pc;
        input [31:0] expected;
        input integer test_num;
        begin
            if (uut.pc_current === expected) begin
                $display("  PASS [T%0d]: PC = 0x%08X", test_num, uut.pc_current);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: PC = 0x%08X  (expected 0x%08X)",
                         test_num, uut.pc_current, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        reset = 1;

        // ── Load the JAL test program (overrides earlier program) ──
        #1;
        uut.imem.memory[0] = 32'h00C000EF; // 0x00: JAL  x1, +12   (x1 = 0x04, -> 0x0C)
        uut.imem.memory[1] = 32'h06300293; // 0x04: ADDI x5, x0, 99  (must be SKIPPED)
        uut.imem.memory[2] = 32'h0100006F; // 0x08: JAL  x0, +16   (no link, -> 0x18)
        uut.imem.memory[3] = 32'h00500113; // 0x0C: ADDI x2, x0, 5
        uut.imem.memory[4] = 32'hFF9FF1EF; // 0x10: JAL  x3, -8    (x3 = 0x14, back -> 0x08)
        uut.imem.memory[5] = 32'h06300313; // 0x14: ADDI x6, x0, 99  (must be SKIPPED)
        uut.imem.memory[6] = 32'h00900213; // 0x18: ADDI x4, x0, 9   (end marker)

        $display("==================================================");
        $display("            JAL Testbench  -  Stage 14");
        $display("==================================================");

        // ── Reset for two clock edges ──────────────────────────
        @(posedge clk);
        @(posedge clk); #1;
        reset = 0;

        // ── Run exactly 5 instructions ─────────────────────────
        $display("\n[Execution trace]");
        for (cycle = 0; cycle < 5; cycle = cycle + 1) begin
            #1;
            $display("  cycle %0d: PC=0x%08X  instr=0x%08X  jump=%b",
                     cycle, uut.pc_current, uut.instruction, uut.jump);
            @(posedge clk);
        end
        #1;

        // ── Checks ─────────────────────────────────────────────
        $display("\n[TEST 1] Link register: PC+4 saved by forward JAL at 0x00");
        check_reg(1, 32'h0000_0004, 1);

        $display("\n[TEST 2] Forward jump landed on target 0x0C");
        check_reg(2, 32'd5, 2);

        $display("\n[TEST 3] Link register for backward JAL at 0x10 (PC+4 = 0x14)");
        check_reg(3, 32'h0000_0014, 3);

        $display("\n[TEST 4] Backward jump landed on 0x08, which jumped to end 0x18");
        check_reg(4, 32'd9, 4);

        $display("\n[TEST 5] Skipped instructions never executed");
        check_reg(5, 32'd0, 5);
        check_reg(6, 32'd0, 6);

        $display("\n[TEST 6] JAL with rd = x0 must not change x0");
        check_reg(0, 32'd0, 7);

        $display("\n[TEST 7] PC after 5 instructions");
        check_pc(32'h0000_001C, 8);

        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 14 COMPLETE - JAL is working!\n");
        else
            $display("  ✗ Fix the failing tests before moving to Stage 15.\n");

        $finish;
    end

endmodule