`timescale 1ns/1ps

module tb_alu;

    // ── Signals ───────────────────────────────────────────────
    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    reg  [2:0]  alu_control;
    wire [31:0] alu_result;
    wire        zero_flag;

    // ── Instantiate UUT ───────────────────────────────────────
    alu uut (
        .operand_a   (operand_a),
        .operand_b   (operand_b),
        .alu_control (alu_control),
        .alu_result  (alu_result),
        .zero_flag   (zero_flag)
    );

    // ── Pass/Fail tracking ────────────────────────────────────
    integer pass_count;
    integer fail_count;

    task check;
        input [31:0] expected_result;
        input        expected_zero;
        input integer test_num;
        begin
            #5; // let combinational output settle
            if (alu_result === expected_result && zero_flag === expected_zero) begin
                $display("  PASS [T%0d]: a=0x%08X b=0x%08X ctrl=%b -> result=0x%08X zero=%b",
                         test_num, operand_a, operand_b, alu_control, alu_result, zero_flag);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: a=0x%08X b=0x%08X ctrl=%b",
                         test_num, operand_a, operand_b, alu_control);
                $display("              got result=0x%08X zero=%b  (expected 0x%08X, zero=%b)",
                         alu_result, zero_flag, expected_result, expected_zero);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("==================================================");
        $display("            ALU Testbench  -  Stage 8");
        $display("==================================================");

        // ── ADD ───────────────────────────────────────────────
        $display("\n[ADD]");
        alu_control = 3'b000;
        operand_a = 32'd5;          operand_b = 32'd3;
        check(32'd8, 1'b0, 1);
        operand_a = 32'hFFFF_FFFF;  operand_b = 32'd1;     // wraps to 0
        check(32'd0, 1'b1, 2);

        // ── SUB ───────────────────────────────────────────────
        $display("\n[SUB]");
        alu_control = 3'b001;
        operand_a = 32'd5;          operand_b = 32'd3;
        check(32'd2, 1'b0, 3);
        operand_a = 32'd7;          operand_b = 32'd7;     // equal -> zero (BEQ case)
        check(32'd0, 1'b1, 4);
        operand_a = 32'd3;          operand_b = 32'd5;     // negative result
        check(32'hFFFF_FFFE, 1'b0, 5);

        // ── AND ───────────────────────────────────────────────
        $display("\n[AND]");
        alu_control = 3'b010;
        operand_a = 32'd5;          operand_b = 32'd3;     // 101 & 011 = 001
        check(32'd1, 1'b0, 6);
        operand_a = 32'hF0F0_F0F0;  operand_b = 32'h0F0F_0F0F;
        check(32'd0, 1'b1, 7);

        // ── OR ────────────────────────────────────────────────
        $display("\n[OR]");
        alu_control = 3'b011;
        operand_a = 32'd5;          operand_b = 32'd3;     // 101 | 011 = 111
        check(32'd7, 1'b0, 8);
        operand_a = 32'd0;          operand_b = 32'd0;
        check(32'd0, 1'b1, 9);

        // ── SLT (signed) ──────────────────────────────────────
        $display("\n[SLT]");
        alu_control = 3'b100;
        operand_a = 32'd3;          operand_b = 32'd5;     // 3 < 5 -> 1
        check(32'd1, 1'b0, 10);
        operand_a = 32'd5;          operand_b = 32'd3;     // 5 < 3 -> 0
        check(32'd0, 1'b1, 11);
        operand_a = 32'hFFFF_FFFF;  operand_b = 32'd1;     // -1 < 1 -> 1 (signed!)
        check(32'd1, 1'b0, 12);
        operand_a = 32'd1;          operand_b = 32'hFFFF_FFFF; // 1 < -1 -> 0
        check(32'd0, 1'b1, 13);
        operand_a = 32'd4;          operand_b = 32'd4;     // equal -> 0
        check(32'd0, 1'b1, 14);

        // ── Undefined control code ────────────────────────────
        $display("\n[Undefined control code 3'b111 -> 0]");
        alu_control = 3'b111;
        operand_a = 32'd9;          operand_b = 32'd9;
        check(32'd0, 1'b1, 15);

        // ── Summary ───────────────────────────────────────────
        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 8 COMPLETE - ALU is working!\n");
        else
            $display("  ✗ Fix the failing tests before moving to Stage 9.\n");

        $finish;
    end

endmodule