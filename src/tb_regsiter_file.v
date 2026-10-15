`timescale 1ns/1ps

module tb_register_file;

    // ── Testbench signals ──────────────────────────────────────
    reg         clk;
    reg         reset;
    reg         reg_write;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] write_data;

    wire [31:0] read_data1, read_data2;

    // ── Instantiate the Unit Under Test ─────────────────────────
    register_file uut (
        .clk        (clk),
        .reset      (reset),
        .reg_write  (reg_write),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .write_data (write_data),
        .read_data1 (read_data1),
        .read_data2 (read_data2)
    );

    // ── Clock generator: 10 ns period = 100 MHz ─────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Pass/Fail counters ───────────────────────────────────────
    integer pass_count;
    integer fail_count;

    // ── Check tasks ───────────────────────────────────────────────
    task check1;
        input [31:0] expected;
        input integer test_num;
        begin
            if (read_data1 === expected) begin
                $display("  PASS [T%0d]: read_data1 = 0x%08X", test_num, read_data1);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: read_data1 = 0x%08X  (expected 0x%08X)",
                         test_num, read_data1, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check2;
        input [31:0] expected;
        input integer test_num;
        begin
            if (read_data2 === expected) begin
                $display("  PASS [T%0d]: read_data2 = 0x%08X", test_num, read_data2);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: read_data2 = 0x%08X  (expected 0x%08X)",
                         test_num, read_data2, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Test sequence ────────────────────────────────────────────
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("==================================================");
        $display("       Register File Testbench  —  Stage 7");
        $display("==================================================");

        // Init
        reset      = 1;
        reg_write  = 0;
        rs1 = 0; rs2 = 0; rd = 0; write_data = 0;
        @(posedge clk); #1;

        // ── TEST 1: After reset, all registers read 0 ───────────
        $display("\n[TEST 1] All registers zero after reset");
        reset = 0;
        rs1 = 5'd10; rs2 = 5'd20;
        #1;
        check1(32'h0000_0000, 1);
        check2(32'h0000_0000, 2);

        // ── TEST 2: Write x1 = 5, then read it back ─────────────
        $display("\n[TEST 2] Write x1 = 5, read back");
        reg_write  = 1;
        rd         = 5'd1;
        write_data = 32'h0000_0005;
        @(posedge clk); #1;
        reg_write = 0;
        rs1 = 5'd1;
        #1;
        check1(32'h0000_0005, 3);

        // ── TEST 3: Write x2 = 3, read both x1 and x2 ───────────
        $display("\n[TEST 3] Write x2 = 3, read x1 and x2 together");
        reg_write  = 1;
        rd         = 5'd2;
        write_data = 32'h0000_0003;
        @(posedge clk); #1;
        reg_write = 0;
        rs1 = 5'd1; rs2 = 5'd2;
        #1;
        check1(32'h0000_0005, 4);
        check2(32'h0000_0003, 5);

        // ── TEST 4: x0 cannot be written ─────────────────────────
        $display("\n[TEST 4] x0 is hardwired to 0 — write attempt must fail");
        reg_write  = 1;
        rd         = 5'd0;
        write_data = 32'hFFFF_FFFF;
        @(posedge clk); #1;
        reg_write = 0;
        rs1 = 5'd0; rs2 = 5'd0;
        #1;
        check1(32'h0000_0000, 6);
        check2(32'h0000_0000, 7);

        // ── TEST 5: Simultaneous read/write (forwarding check) ──
        // Write x3 = 0xAAAA_AAAA on this edge while reading x3
        // BEFORE the edge -> should still see OLD value combinationally,
        // then NEW value after the clock edge (no bypass in this module).
        $display("\n[TEST 5] Simultaneous read/write - read address = write address");
        rs1        = 5'd3;
        reg_write  = 1;
        rd         = 5'd3;
        write_data = 32'hAAAA_AAAA;
        #1; // before clock edge: x3 still old (0)
        check1(32'h0000_0000, 8);

        @(posedge clk); #1; // after edge: x3 updated
        reg_write = 0;
        check1(32'hAAAA_AAAA, 9);

        // ── TEST 6: Write to x31 (boundary register) ────────────
        $display("\n[TEST 6] Write and read boundary register x31");
        reg_write  = 1;
        rd         = 5'd31;
        write_data = 32'h1234_5678;
        @(posedge clk); #1;
        reg_write = 0;
        rs2 = 5'd31;
        #1;
        check2(32'h1234_5678, 10);

        // ── TEST 7: reg_write low -> no write happens ───────────
        $display("\n[TEST 7] reg_write = 0 must block writes");
        rd         = 5'd5;
        write_data = 32'hDEAD_BEEF;
        reg_write  = 0;
        @(posedge clk); #1;
        rs1 = 5'd5;
        #1;
        check1(32'h0000_0000, 11);

        // ── Summary ──────────────────────────────────────────────
        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 7 COMPLETE — Register File is working!\n");
        else
            $display("  ✗ Fix the failing tests before moving to Stage 8.\n");

        $finish;
    end

endmodule