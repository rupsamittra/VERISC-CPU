`timescale 1ns/1ps

module tb_branch;

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
                $display("  PASS [T%0d]: x%0d = %0d", test_num, idx, uut.rf.regs[idx]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: x%0d = %0d  (expected %0d)",
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

        // ── Load the branch test program (overrides Stage 6 program) ──
        // Runs at #1, after instruction_memory's own initial block (time 0)
        #1;
        uut.imem.memory[0]  = 32'h00500093; // 0x00: ADDI x1, x0, 5
        uut.imem.memory[1]  = 32'h00500113; // 0x04: ADDI x2, x0, 5
        uut.imem.memory[2]  = 32'h00208463; // 0x08: BEQ  x1, x2, +8   (taken -> 0x10)
        uut.imem.memory[3]  = 32'h06300193; // 0x0C: ADDI x3, x0, 99   (must be SKIPPED)
        uut.imem.memory[4]  = 32'h00100213; // 0x10: ADDI x4, x0, 1    (branch target)
        uut.imem.memory[5]  = 32'h00700293; // 0x14: ADDI x5, x0, 7
        uut.imem.memory[6]  = 32'h00508463; // 0x18: BEQ  x1, x5, +8   (5 != 7, NOT taken)
        uut.imem.memory[7]  = 32'h00200313; // 0x1C: ADDI x6, x0, 2    (must execute)
        uut.imem.memory[8]  = 32'h00000393; // 0x20: ADDI x7, x0, 0    (counter = 0)
        uut.imem.memory[9]  = 32'h00138393; // 0x24: ADDI x7, x7, 1    (loop start)
        uut.imem.memory[10] = 32'h00300413; // 0x28: ADDI x8, x0, 3
        uut.imem.memory[11] = 32'h00838463; // 0x2C: BEQ  x7, x8, +8   (exit when x7 == 3)
        uut.imem.memory[12] = 32'hFE000AE3; // 0x30: BEQ  x0, x0, -12  (backward -> 0x24)
        uut.imem.memory[13] = 32'h02A00493; // 0x34: ADDI x9, x0, 42   (loop-exit marker)

        $display("==================================================");
        $display("         Branch (BEQ) Testbench  -  Stage 13");
        $display("==================================================");

        // ── Reset for two clock edges ──────────────────────────
        @(posedge clk);
        @(posedge clk); #1;
        reset = 0;

        // ── Run exactly 20 instructions ────────────────────────
        $display("\n[Execution trace]");
        for (cycle = 0; cycle < 20; cycle = cycle + 1) begin
            #1;
            $display("  cycle %2d: PC=0x%08X  instr=0x%08X  branch_taken=%b",
                     cycle, uut.pc_current, uut.instruction,
                     uut.branch & uut.zero_flag);
            @(posedge clk);
        end
        #1;

        // ── Checks ─────────────────────────────────────────────
        $display("\n[TEST 1] Branch TAKEN (equal): instruction at 0x0C skipped");
        check_reg(3, 32'd0, 1);       // would be 99 if the branch failed

        $display("\n[TEST 2] Branch target reached");
        check_reg(4, 32'd1, 2);

        $display("\n[TEST 3] Branch NOT taken (different): falls through");
        check_reg(5, 32'd7, 3);
        check_reg(6, 32'd2, 4);       // 0x1C ran

        $display("\n[TEST 4] Backward branch loop ran 3 times");
        check_reg(7, 32'd3, 5);
        check_reg(8, 32'd3, 6);

        $display("\n[TEST 5] Loop exited to correct target");
        check_reg(9, 32'd42, 7);

        $display("\n[TEST 6] PC after 20 instructions");
        check_pc(32'h0000_0038, 8);

        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 13 COMPLETE - Branching is working!\n");
        else
            $display("  ✗ Fix the failing tests before moving to Stage 14.\n");

        $finish;
    end

endmodule