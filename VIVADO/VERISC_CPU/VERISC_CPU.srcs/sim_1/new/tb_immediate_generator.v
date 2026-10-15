`timescale 1ns/1ps

module tb_immediate_generator;

    reg  [31:0] instruction;
    wire [31:0] immediate;

    immediate_generator uut (
        .instruction(instruction),
        .immediate  (immediate)
    );

    integer pass_count;
    integer fail_count;

    task check;
        input [31:0] instr;
        input [31:0] expected;
        input integer test_num;
        begin
            instruction = instr;
            #5; // let combinational output settle
            if (immediate === expected) begin
                $display("  PASS [T%0d]: instr=0x%08X  imm=0x%08X",
                         test_num, instruction, immediate);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: instr=0x%08X  got=0x%08X  expected=0x%08X",
                         test_num, instruction, immediate, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("==================================================");
        $display("   Immediate Generator Testbench  -  Stage 9");
        $display("==================================================");

        // ── I-Type ────────────────────────────────────────────
        $display("\n[I-Type]");
        check(32'h00500093, 32'h0000_0005, 1);   // ADDI x1, x0, 5
        check(32'hFFF00093, 32'hFFFF_FFFF, 2);   // ADDI x1, x0, -1  (sign extend)
        check(32'h7FF00093, 32'h0000_07FF, 3);   // ADDI x1, x0, 2047 (max positive)
        check(32'h0080A283, 32'h0000_0008, 4);   // LW   x5, 8(x1)

        // ── S-Type ────────────────────────────────────────────
        $display("\n[S-Type]");
        check(32'h0020A623, 32'h0000_000C, 5);   // SW x2, 12(x1)
        check(32'hFE20AE23, 32'hFFFF_FFFC, 6);   // SW x2, -4(x1)

        // ── B-Type ────────────────────────────────────────────
        $display("\n[B-Type]");
        check(32'h00208463, 32'h0000_0008, 7);   // BEQ x1, x2, +8
        check(32'hFE208CE3, 32'hFFFF_FFF8, 8);   // BEQ x1, x2, -8

        // ── J-Type ────────────────────────────────────────────
        $display("\n[J-Type]");
        check(32'h008000EF, 32'h0000_0008, 9);   // JAL x1, +8
        check(32'hFF9FF06F, 32'hFFFF_FFF8, 10);  // JAL x0, -8

        // ── R-Type / NOP: no immediate ────────────────────────
        $display("\n[R-Type -> 0]");
        check(32'h002081B3, 32'h0000_0000, 11);  // ADD x3, x1, x2
        check(32'h40208233, 32'h0000_0000, 12);  // SUB x4, x1, x2

        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 9 COMPLETE - Immediate Generator is working!\n");
        else
            $display("  ✗ Fix the failing tests before moving to Stage 10.\n");

        $finish;
    end

endmodule