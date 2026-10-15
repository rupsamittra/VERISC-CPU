// ============================================================
// Testbench : tb_instruction_memory
// Tests     : instruction_memory.v
// Stage     : 6
// Simulator : Vivado 2025.1 (XSIM)
// ============================================================
// What we verify:
//   - PC=0x00 gives the first instruction  (ADDI x1,x0,5)
//   - PC=0x04 gives the second instruction (ADDI x2,x0,3)
//   - PC=0x08 gives the third instruction  (ADD  x3,x1,x2)
//   - PC=0x0C gives the fourth             (SUB  x4,x1,x2)
//   - PC=0x10 gives the fifth              (AND  x5,x1,x2)
//   - PC=0x14 gives the sixth              (OR   x6,x1,x2)
//   - PC=0x18 gives the seventh            (SLT  x7,x2,x1)
//   - PC=0x1C gives NOP (end of program)
//   - Output changes IMMEDIATELY when address changes (combinational)
// ============================================================

`timescale 1ns/1ps

module tb_instruction_memory;

    // ── Signals ───────────────────────────────────────────────
    reg  [31:0] address;
    wire [31:0] instruction;

    // ── Instantiate UUT ───────────────────────────────────────
    instruction_memory uut (
        .address    (address),
        .instruction(instruction)
    );

    // ── Pass/Fail tracking ────────────────────────────────────
    integer pass_count;
    integer fail_count;

    task check;
        input [31:0] expected;
        input integer test_num;
        input [63:0] instr_name; // just for display clarity
        begin
            #5; // small delay so combinational output settles
            if (instruction === expected) begin
                $display("  PASS [T%0d]: address=0x%08X  instruction=0x%08X",
                         test_num, address, instruction);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: address=0x%08X  got=0x%08X  expected=0x%08X",
                         test_num, address, instruction, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("==================================================");
        $display("   Instruction Memory Testbench  —  Stage 6");
        $display("==================================================");
        $display("  Checking: address -> instruction mapping");
        $display("  (No clock needed — this is combinational read)\n");

        // ── Check each instruction fetch ──────────────────────

        address = 32'h00000000;
        check(32'h00500093, 1, 0); // ADDI x1, x0, 5

        address = 32'h00000004;
        check(32'h00300113, 2, 0); // ADDI x2, x0, 3

        address = 32'h00000008;
        check(32'h002081B3, 3, 0); // ADD x3, x1, x2

        address = 32'h0000000C;
        check(32'h40208233, 4, 0); // SUB x4, x1, x2

        address = 32'h00000010;
        check(32'h0020F2B3, 5, 0); // AND x5, x1, x2

        address = 32'h00000014;
        check(32'h0020E333, 6, 0); // OR x6, x1, x2

            address = 32'h00000018;
        check(32'h001123B3, 7, 0); // SLT x7, x2, x1

        address = 32'h0000001C;
        check(32'h00000013, 8, 0); // NOP

        // ── Verify combinational behaviour ────────────────────
        // Change address and check output updates immediately
        $display("\n[TEST 9] Combinational check: jump back to address 0");
        address = 32'h00000000;
        #5;
        if (instruction === 32'h00500093) begin
            $display("  PASS [T9]: Jumping back to addr 0 instantly gives first instruction");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL [T9]: Expected 0x00500093, got 0x%08X", instruction);
            fail_count = fail_count + 1;
        end

        // ── Summary ───────────────────────────────────────────
        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 6 COMPLETE — Instruction Memory working!\n");
        else
            $display("  ✗ Fix failing tests before moving to Stage 7.\n");

        $finish;
    end

endmodule
