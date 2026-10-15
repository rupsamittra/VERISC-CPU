`timescale 1ns/1ps

// ============================================================
//  Final self-checking testbench - single-cycle RISC-V CPU
//    * 7 test programs, loaded straight into instruction memory
//    * checks registers, data memory and final PC
//    * monitors invariants every cycle (no X, x0 == 0, PC aligned)
//    * watchdog ends a hung simulation
// ============================================================
module tb_riscv_cpu;

    reg clk;
    reg reset;

    riscv_single_cycle_cpu uut (
        .clk   (clk),
        .reset (reset)
    );

    // 10 ns clock = 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Bookkeeping ───────────────────────────────────────────
    integer pass_count;
    integer fail_count;
    integer monitor_errors;
    integer current_prog;
    integer i;
    reg     monitoring;

    // ── Watchdog: stop a hung simulation ──────────────────────
    initial begin
        #200000;
        $display("  FAIL: TIMEOUT - testbench did not finish");
        $finish;
    end

    // ── Invariant monitor: runs every cycle at the falling edge ─
    always @(negedge clk) begin
        if (monitoring) begin
            if ((^uut.pc_current) === 1'bx) begin
                monitor_errors = monitor_errors + 1;
                $display("  MONITOR [P%0d @%0d ns]: PC contains X/Z", current_prog, $time);
            end
            if ((^uut.instruction) === 1'bx) begin
                monitor_errors = monitor_errors + 1;
                $display("  MONITOR [P%0d @%0d ns]: instruction contains X/Z", current_prog, $time);
            end
            if ((^uut.write_back_data) === 1'bx) begin
                monitor_errors = monitor_errors + 1;
                $display("  MONITOR [P%0d @%0d ns]: write-back data contains X/Z (multiple drivers?)",
                         current_prog, $time);
            end
            if (uut.rf.regs[0] !== 32'd0) begin
                monitor_errors = monitor_errors + 1;
                $display("  MONITOR [P%0d @%0d ns]: x0 is not zero (= 0x%08X)",
                         current_prog, $time, uut.rf.regs[0]);
            end
            if (uut.pc_current[1:0] !== 2'b00) begin
                monitor_errors = monitor_errors + 1;
                $display("  MONITOR [P%0d @%0d ns]: PC not word-aligned (= 0x%08X)",
                         current_prog, $time, uut.pc_current);
            end
        end
    end

    // ── Helper tasks ──────────────────────────────────────────
    // Fill instruction memory with NOPs and zero the data memory
    task clear_memories;
        begin
            for (i = 0; i < 64; i = i + 1) begin
                uut.imem.memory[i] = 32'h0000_0013;   // NOP
                uut.dmem.memory[i] = 32'h0000_0000;
            end
        end
    endtask

    // Reset the CPU, then run 'cycles' clock cycles (one instruction each)
    task run_program;
        input integer cycles;
        integer c;
        begin
            monitoring = 0;
            reset = 1;
            @(posedge clk);
            @(posedge clk); #1;
            reset = 0;
            monitoring = 1;
            for (c = 0; c < cycles; c = c + 1)
                @(posedge clk);
            monitoring = 0;
            #1;
        end
    endtask

    task check_reg;
        input integer idx;
        input [31:0]  expected;
        begin
            if (uut.rf.regs[idx] === expected) begin
                $display("  PASS [P%0d]: x%0d = 0x%08X", current_prog, idx, uut.rf.regs[idx]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [P%0d]: x%0d = 0x%08X  (expected 0x%08X)",
                         current_prog, idx, uut.rf.regs[idx], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_mem;
        input integer byte_addr;
        input [31:0]  expected;
        begin
            if (uut.dmem.memory[byte_addr >> 2] === expected) begin
                $display("  PASS [P%0d]: Mem[%0d] = 0x%08X",
                         current_prog, byte_addr, uut.dmem.memory[byte_addr >> 2]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [P%0d]: Mem[%0d] = 0x%08X  (expected 0x%08X)",
                         current_prog, byte_addr, uut.dmem.memory[byte_addr >> 2], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_pc;
        input [31:0] expected;
        begin
            if (uut.pc_current === expected) begin
                $display("  PASS [P%0d]: PC = 0x%08X", current_prog, uut.pc_current);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [P%0d]: PC = 0x%08X  (expected 0x%08X)",
                         current_prog, uut.pc_current, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Test sequence ─────────────────────────────────────────
    initial begin
        pass_count     = 0;
        fail_count     = 0;
        monitor_errors = 0;
        current_prog   = 0;
        monitoring     = 0;
        reset          = 1;
        #1;   // let the memories' own initial blocks finish first

        $display("==================================================");
        $display("   Single-Cycle RISC-V CPU  -  Final Testbench");
        $display("==================================================");

        // ── PROGRAM 1: Arithmetic (ADD SUB AND OR SLT) ─────────
        current_prog = 1;
        $display("\n[PROGRAM 1] Arithmetic");
        clear_memories;
        uut.imem.memory[0] = 32'h00500093; // 0x00: ADDI x1, x0, 5
        uut.imem.memory[1] = 32'h00300113; // 0x04: ADDI x2, x0, 3
        uut.imem.memory[2] = 32'h002081B3; // 0x08: ADD  x3, x1, x2
        uut.imem.memory[3] = 32'h40208233; // 0x0C: SUB  x4, x1, x2
        uut.imem.memory[4] = 32'h0020F2B3; // 0x10: AND  x5, x1, x2
        uut.imem.memory[5] = 32'h0020E333; // 0x14: OR   x6, x1, x2
        uut.imem.memory[6] = 32'h001123B3; // 0x18: SLT  x7, x2, x1
        run_program(12);
        check_reg(1, 32'd5);
        check_reg(2, 32'd3);
        check_reg(3, 32'd8);
        check_reg(4, 32'd2);
        check_reg(5, 32'd1);
        check_reg(6, 32'd7);
        check_reg(7, 32'd1);

        // ── PROGRAM 2: Memory (SW then LW) ─────────────────────
        current_prog = 2;
        $display("\n[PROGRAM 2] Memory: store then load");
        clear_memories;
        uut.imem.memory[0] = 32'h06400093; // 0x00: ADDI x1, x0, 100
        uut.imem.memory[1] = 32'h02A00113; // 0x04: ADDI x2, x0, 42
        uut.imem.memory[2] = 32'h0020A023; // 0x08: SW   x2, 0(x1)
        uut.imem.memory[3] = 32'h0000A183; // 0x0C: LW   x3, 0(x1)
        run_program(12);
        check_reg(1, 32'd100);
        check_reg(2, 32'd42);
        check_reg(3, 32'd42);        // loaded back from memory
        check_mem(100, 32'd42);

        // ── PROGRAM 3: Memory offsets ──────────────────────────
        current_prog = 3;
        $display("\n[PROGRAM 3] Memory: offsets 4 and 96");
        clear_memories;
        uut.imem.memory[0] = 32'h06400093; // 0x00: ADDI x1, x0, 100
        uut.imem.memory[1] = 32'h02A00113; // 0x04: ADDI x2, x0, 42
        uut.imem.memory[2] = 32'h00700313; // 0x08: ADDI x6, x0, 7
        uut.imem.memory[3] = 32'h0020A223; // 0x0C: SW   x2, 4(x1)    -> Mem[104] = 42
        uut.imem.memory[4] = 32'h06602023; // 0x10: SW   x6, 96(x0)   -> Mem[96]  = 7
        uut.imem.memory[5] = 32'h0040A203; // 0x14: LW   x4, 4(x1)
        uut.imem.memory[6] = 32'h06002283; // 0x18: LW   x5, 96(x0)
        run_program(12);
        check_reg(4, 32'd42);
        check_reg(5, 32'd7);
        check_mem(104, 32'd42);
        check_mem(96,  32'd7);

        // ── PROGRAM 4: BEQ taken ───────────────────────────────
        current_prog = 4;
        $display("\n[PROGRAM 4] Branch");
        clear_memories;
        uut.imem.memory[0] = 32'h00500093; // 0x00: ADDI x1, x0, 5
        uut.imem.memory[1] = 32'h00500113; // 0x04: ADDI x2, x0, 5
        uut.imem.memory[2] = 32'h00208463; // 0x08: BEQ  x1, x2, 8   (-> 0x10)
        uut.imem.memory[3] = 32'h00100193; // 0x0C: ADDI x3, x0, 1   (skipped)
        uut.imem.memory[4] = 32'h00200213; // 0x10: ADDI x4, x0, 2
        run_program(12);
        check_reg(1, 32'd5);
        check_reg(2, 32'd5);
        check_reg(3, 32'd0);         // would be 1 if the branch failed
        check_reg(4, 32'd2);

        // ── PROGRAM 5: JAL ─────────────────────────────────────
        current_prog = 5;
        $display("\n[PROGRAM 5] Jump and link");
        clear_memories;
        uut.imem.memory[0] = 32'h008000EF; // 0x00: JAL  x1, 8       (-> 0x08)
        uut.imem.memory[1] = 32'h06300113; // 0x04: ADDI x2, x0, 99  (skipped)
        uut.imem.memory[2] = 32'h06400193; // 0x08: ADDI x3, x0, 100
        run_program(12);
        check_reg(1, 32'd4);         // return address = PC + 4
        check_reg(2, 32'd0);         // would be 99 if the jump failed
        check_reg(3, 32'd100);

        // ── PROGRAM 6: Branch taken/not taken + backward loop ──
        current_prog = 6;
        $display("\n[PROGRAM 6] Branch: not taken, and a backward loop");
        clear_memories;
        uut.imem.memory[0]  = 32'h00500093; // 0x00: ADDI x1, x0, 5
        uut.imem.memory[1]  = 32'h00500113; // 0x04: ADDI x2, x0, 5
        uut.imem.memory[2]  = 32'h00208463; // 0x08: BEQ  x1, x2, +8   (taken -> 0x10)
        uut.imem.memory[3]  = 32'h06300193; // 0x0C: ADDI x3, x0, 99   (skipped)
        uut.imem.memory[4]  = 32'h00100213; // 0x10: ADDI x4, x0, 1
        uut.imem.memory[5]  = 32'h00700293; // 0x14: ADDI x5, x0, 7
        uut.imem.memory[6]  = 32'h00508463; // 0x18: BEQ  x1, x5, +8   (5 != 7, NOT taken)
        uut.imem.memory[7]  = 32'h00200313; // 0x1C: ADDI x6, x0, 2
        uut.imem.memory[8]  = 32'h00000393; // 0x20: ADDI x7, x0, 0    (counter)
        uut.imem.memory[9]  = 32'h00138393; // 0x24: ADDI x7, x7, 1    (loop start)
        uut.imem.memory[10] = 32'h00300413; // 0x28: ADDI x8, x0, 3
        uut.imem.memory[11] = 32'h00838463; // 0x2C: BEQ  x7, x8, +8   (exit when x7 == 3)
        uut.imem.memory[12] = 32'hFE000AE3; // 0x30: BEQ  x0, x0, -12  (back -> 0x24)
        uut.imem.memory[13] = 32'h02A00493; // 0x34: ADDI x9, x0, 42   (loop-exit marker)
        run_program(20);             // exactly 20 instructions execute
        check_reg(1, 32'd5);
        check_reg(2, 32'd5);
        check_reg(3, 32'd0);
        check_reg(4, 32'd1);
        check_reg(5, 32'd7);
        check_reg(6, 32'd2);
        check_reg(7, 32'd3);         // loop ran 3 times
        check_reg(8, 32'd3);
        check_reg(9, 32'd42);
        check_pc(32'h0000_0038);

        // ── PROGRAM 7: JAL forward + backward chain ────────────
        current_prog = 7;
        $display("\n[PROGRAM 7] JAL: forward jump, backward jump, rd = x0");
        clear_memories;
        uut.imem.memory[0] = 32'h00C000EF; // 0x00: JAL  x1, +12   (x1 = 0x04, -> 0x0C)
        uut.imem.memory[1] = 32'h06300293; // 0x04: ADDI x5, x0, 99  (skipped)
        uut.imem.memory[2] = 32'h0100006F; // 0x08: JAL  x0, +16   (no link, -> 0x18)
        uut.imem.memory[3] = 32'h00500113; // 0x0C: ADDI x2, x0, 5
        uut.imem.memory[4] = 32'hFF9FF1EF; // 0x10: JAL  x3, -8    (x3 = 0x14, back -> 0x08)
        uut.imem.memory[5] = 32'h06300313; // 0x14: ADDI x6, x0, 99  (skipped)
        uut.imem.memory[6] = 32'h00900213; // 0x18: ADDI x4, x0, 9
        run_program(5);              // exactly 5 instructions execute
        check_reg(1, 32'h0000_0004);
        check_reg(2, 32'd5);
        check_reg(3, 32'h0000_0014);
        check_reg(4, 32'd9);
        check_reg(5, 32'd0);
        check_reg(6, 32'd0);
        check_pc(32'h0000_001C);

        // ── Summary ────────────────────────────────────────────
        $display("\n==================================================");
        $display("  Checks     : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("  Monitors   : %0d invariant violations", monitor_errors);
        $display("==================================================");

        if (fail_count == 0 && monitor_errors == 0)
            $display("  *** ALL TESTS PASSED - CPU verified ***\n");
        else
            $display("  *** TESTS FAILED - see FAIL/MONITOR lines above ***\n");

        $finish;
    end

endmodule