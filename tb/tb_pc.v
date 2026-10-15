// ============================================================
// Testbench : tb_pc
// Tests     : pc.v — Program Counter module
// Stage     : 5
// Simulator : Vivado 2025.1 (XSIM)
// ============================================================
// Tests we run:
//   1. Reset behaviour         — after reset, pc_current must be 0
//   2. Sequential increment    — when pc_next = pc_current+4, PC steps 0,4,8,...
//   3. Branch target           — feed an arbitrary address and verify it loads
//   4. Return to sequential    — after a branch, sequential counting resumes
//   5. Mid-execution reset     — reset mid-run must snap PC back to 0
// ============================================================

`timescale 1ns/1ps

module tb_pc;

    // ── Testbench signals ──────────────────────────────────────
    reg        clk;
    reg        reset;
    reg [31:0] pc_next;

    wire [31:0] pc_current;

    // ── Instantiate the Unit Under Test ────────────────────────
    pc uut (
        .clk       (clk),
        .reset     (reset),
        .pc_next   (pc_next),
        .pc_current(pc_current)
    );

    // ── Clock generator: 10 ns period = 100 MHz ────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Pass/Fail counters ─────────────────────────────────────
    integer pass_count;
    integer fail_count;

    // ── Check task ─────────────────────────────────────────────
    task check;
        input [31:0] expected;
        input integer test_num;
        begin
            if (pc_current === expected) begin
                $display("  PASS [T%0d]: pc_current = 0x%08X", test_num, pc_current);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: pc_current = 0x%08X  (expected 0x%08X)",
                         test_num, pc_current, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Test sequence ──────────────────────────────────────────
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("==================================================");
        $display("         PC Module Testbench  —  Stage 5");
        $display("==================================================");

        // ── TEST 1: Reset forces PC to 0 ──────────────────────
        $display("\n[TEST 1] Reset behaviour");
        reset   = 1;
        pc_next = 32'hDEAD_BEEF;   // garbage value — reset must ignore it
        @(posedge clk); #1;
        check(32'h0000_0000, 1);

        // ── TEST 2: Sequential increment ──────────────────────
        $display("\n[TEST 2] Sequential increment (0 -> 4 -> 8 -> C -> 10)");
        reset = 0;

        pc_next = 32'h0000_0004;
        @(posedge clk); #1;
        check(32'h0000_0004, 2);

        pc_next = 32'h0000_0008;
        @(posedge clk); #1;
        check(32'h0000_0008, 3);

        pc_next = 32'h0000_000C;
        @(posedge clk); #1;
        check(32'h0000_000C, 4);

        pc_next = 32'h0000_0010;
        @(posedge clk); #1;
        check(32'h0000_0010, 5);

        // ── TEST 3: Branch / jump target ──────────────────────
        $display("\n[TEST 3] Jump to branch target 0x0000001C");
        pc_next = 32'h0000_001C;
        @(posedge clk); #1;
        check(32'h0000_001C, 6);

        // ── TEST 4: Resume sequential after branch ─────────────
        $display("\n[TEST 4] Resume sequential from 0x20 after branch");
        pc_next = 32'h0000_0020;
        @(posedge clk); #1;
        check(32'h0000_0020, 7);

        pc_next = 32'h0000_0024;
        @(posedge clk); #1;
        check(32'h0000_0024, 8);

        // ── TEST 5: Mid-execution reset ────────────────────────
        $display("\n[TEST 5] Mid-execution reset snaps PC back to 0");
        reset   = 1;
        pc_next = 32'h0000_0028;   // reset must win over this
        @(posedge clk); #1;
        check(32'h0000_0000, 9);

        // ── Summary ───────────────────────────────────────────
        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 5 COMPLETE — PC module is working!\n");
        else
            $display("  ✗ Fix the failing tests before moving to Stage 6.\n");

        $finish;
    end

endmodule
