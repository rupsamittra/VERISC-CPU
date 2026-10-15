`timescale 1ns/1ps

module tb_data_memory;

    reg         clk;
    reg         mem_read;
    reg         mem_write;
    reg  [31:0] address;
    reg  [31:0] write_data;
    wire [31:0] read_data;

    data_memory uut (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .address    (address),
        .write_data (write_data),
        .read_data  (read_data)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;

    task check;
        input [31:0] expected;
        input integer test_num;
        begin
            #1;
            if (read_data === expected) begin
                $display("  PASS [T%0d]: addr=0x%08X  read_data=0x%08X",
                         test_num, address, read_data);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d]: addr=0x%08X  read_data=0x%08X  (expected 0x%08X)",
                         test_num, address, read_data, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Store one word on the next clock edge
    task store;
        input [31:0] addr;
        input [31:0] data;
        begin
            address    = addr;
            write_data = data;
            mem_write  = 1;
            mem_read   = 0;
            @(posedge clk); #1;
            mem_write  = 0;
        end
    endtask

    // Load one word (combinational)
    task load;
        input [31:0] addr;
        begin
            address   = addr;
            mem_read  = 1;
            mem_write = 0;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        mem_read = 0; mem_write = 0; address = 0; write_data = 0;

        $display("==================================================");
        $display("         Data Memory Testbench  -  Stage 12");
        $display("==================================================");

        @(posedge clk); #1;

        // ── TEST 1: Memory starts at zero ───────────────────────
        $display("\n[TEST 1] Initial contents are zero");
        load(32'h0000_0000);
        check(32'h0000_0000, 1);

        // ── TEST 2: SW then LW ──────────────────────────────────
        $display("\n[TEST 2] Store then load");
        store(32'h0000_0000, 32'hDEAD_BEEF);
        load(32'h0000_0000);
        check(32'hDEAD_BEEF, 2);

        // ── TEST 3: Word addressing (0x04 is a different word) ──
        $display("\n[TEST 3] Separate words at 0x00 and 0x04");
        store(32'h0000_0004, 32'h1234_5678);
        load(32'h0000_0004);
        check(32'h1234_5678, 3);
        load(32'h0000_0000);
        check(32'hDEAD_BEEF, 4);   // first word untouched

        // ── TEST 4: mem_write = 0 blocks the write ──────────────
        $display("\n[TEST 4] mem_write = 0 must not write");
        address    = 32'h0000_0008;
        write_data = 32'hFFFF_FFFF;
        mem_write  = 0;
        @(posedge clk); #1;
        load(32'h0000_0008);
        check(32'h0000_0000, 5);

        // ── TEST 5: mem_read = 0 returns 0 ──────────────────────
        $display("\n[TEST 5] mem_read = 0 gives 0");
        address  = 32'h0000_0000;  // holds 0xDEADBEEF
        mem_read = 0;
        check(32'h0000_0000, 6);

        // ── TEST 6: Overwrite an existing word ──────────────────
        $display("\n[TEST 6] Overwrite word at 0x00");
        store(32'h0000_0000, 32'hCAFE_BABE);
        load(32'h0000_0000);
        check(32'hCAFE_BABE, 7);

        // ── TEST 7: Last word in memory ─────────────────────────
        $display("\n[TEST 7] Boundary word at 0xFC");
        store(32'h0000_00FC, 32'hA5A5_A5A5);
        load(32'h0000_00FC);
        check(32'hA5A5_A5A5, 8);

        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 12 COMPLETE - Data Memory is working!\n");
        else
            $display("  ✗ Fix the failing tests before moving to Stage 13.\n");

        $finish;
    end

endmodule