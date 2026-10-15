`timescale 1ns/1ps

module tb_programs;

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
    integer i;

    // ── Helpers ───────────────────────────────────────────────
    // Fill instruction memory with NOPs and zero the data memory
    task clear_memories;
        begin
            for (i = 0; i < 64; i = i + 1) begin
                uut.imem.memory[i] = 32'h0000_0013;   // NOP
                uut.dmem.memory[i] = 32'h0000_0000;
            end
        end
    endtask

    // Reset the CPU, then run 12 clock cycles (every program is shorter;
    // leftover cycles just execute NOPs)
    task run_program;
        integer c;
        begin
            reset = 1;
            @(posedge clk);
            @(posedge clk); #1;
            reset = 0;
            for (c = 0; c < 12; c = c + 1)
                @(posedge clk);
            #1;
        end
    endtask

    task check_reg;
        input integer prog;
        input integer idx;
        input [31:0]  expected;
        begin
            if (uut.rf.regs[idx] === expected) begin
                $display("  PASS [P%0d]: x%0d = %0d", prog, idx, uut.rf.regs[idx]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [P%0d]: x%0d = %0d  (expected %0d)",
                         prog, idx, uut.rf.regs[idx], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_mem;
        input integer prog;
        input integer byte_addr;
        input [31:0]  expected;
        begin
            if (uut.dmem.memory[byte_addr >> 2] === expected) begin
                $display("  PASS [P%0d]: Mem[%0d] = %0d",
                         prog, byte_addr, uut.dmem.memory[byte_addr >> 2]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [P%0d]: Mem[%0d] = %0d  (expected %0d)",
                         prog, byte_addr, uut.dmem.memory[byte_addr >> 2], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Test sequence ─────────────────────────────────────────
    initial begin
        pass_count = 0;
        fail_count = 0;
        reset = 1;
        #1;   // let the memories' own initial blocks finish first

        $display("==================================================");
        $display("       Test Programs Testbench  -  Stage 17");
        $display("==================================================");

        // ── PROGRAM 1: Arithmetic ──────────────────────────────
        $display("\n[PROGRAM 1] Arithmetic");
        clear_memories;
        uut.imem.memory[0] = 32'h00500093; // 0x00: ADDI x1, x0, 5
        uut.imem.memory[1] = 32'h00300113; // 0x04: ADDI x2, x0, 3
        uut.imem.memory[2] = 32'h002081B3; // 0x08: ADD  x3, x1, x2
        uut.imem.memory[3] = 32'h40208233; // 0x0C: SUB  x4, x1, x2
        uut.imem.memory[4] = 32'h0020F2B3; // 0x10: AND  x5, x1, x2
        uut.imem.memory[5] = 32'h0020E333; // 0x14: OR   x6, x1, x2
        uut.imem.memory[6] = 32'h001123B3; // 0x18: SLT  x7, x2, x1
        run_program;
        check_reg(1, 1, 32'd5);
        check_reg(1, 2, 32'd3);
        check_reg(1, 3, 32'd8);
        check_reg(1, 4, 32'd2);
        check_reg(1, 5, 32'd1);
        check_reg(1, 6, 32'd7);
        check_reg(1, 7, 32'd1);

        // ── PROGRAM 2: SW then LW ──────────────────────────────
        $display("\n[PROGRAM 2] Memory: store then load");
        clear_memories;
        uut.imem.memory[0] = 32'h06400093; // 0x00: ADDI x1, x0, 100
        uut.imem.memory[1] = 32'h02A00113; // 0x04: ADDI x2, x0, 42
        uut.imem.memory[2] = 32'h0020A023; // 0x08: SW   x2, 0(x1)
        uut.imem.memory[3] = 32'h0000A183; // 0x0C: LW   x3, 0(x1)
        run_program;
        check_reg(2, 1, 32'd100);
        check_reg(2, 2, 32'd42);
        check_reg(2, 3, 32'd42);     // loaded back from memory
        check_mem(2, 100, 32'd42);

        // ── PROGRAM 2b: load/store offsets ─────────────────────
        $display("\n[PROGRAM 2b] Memory: offsets 4 and 96");
        clear_memories;
        uut.imem.memory[0] = 32'h06400093; // 0x00: ADDI x1, x0, 100
        uut.imem.memory[1] = 32'h02A00113; // 0x04: ADDI x2, x0, 42
        uut.imem.memory[2] = 32'h00700313; // 0x08: ADDI x6, x0, 7
        uut.imem.memory[3] = 32'h0020A223; // 0x0C: SW   x2, 4(x1)    -> Mem[104] = 42
        uut.imem.memory[4] = 32'h06602023; // 0x10: SW   x6, 96(x0)   -> Mem[96]  = 7
        uut.imem.memory[5] = 32'h0040A203; // 0x14: LW   x4, 4(x1)
        uut.imem.memory[6] = 32'h06002283; // 0x18: LW   x5, 96(x0)
        run_program;
        check_reg(22, 4, 32'd42);
        check_reg(22, 5, 32'd7);
        check_mem(22, 104, 32'd42);
        check_mem(22, 96,  32'd7);

        // ── PROGRAM 3: BEQ ─────────────────────────────────────
        $display("\n[PROGRAM 3] Branch");
        clear_memories;
        uut.imem.memory[0] = 32'h00500093; // 0x00: ADDI x1, x0, 5
        uut.imem.memory[1] = 32'h00500113; // 0x04: ADDI x2, x0, 5
        uut.imem.memory[2] = 32'h00208463; // 0x08: BEQ  x1, x2, 8   (-> 0x10)
        uut.imem.memory[3] = 32'h00100193; // 0x0C: ADDI x3, x0, 1   (skipped)
        uut.imem.memory[4] = 32'h00200213; // 0x10: ADDI x4, x0, 2
        run_program;
        check_reg(3, 1, 32'd5);
        check_reg(3, 2, 32'd5);
        check_reg(3, 3, 32'd0);      // would be 1 if the branch failed
        check_reg(3, 4, 32'd2);

        // ── PROGRAM 4: JAL ─────────────────────────────────────
        $display("\n[PROGRAM 4] Jump and link");
        clear_memories;
        uut.imem.memory[0] = 32'h008000EF; // 0x00: JAL  x1, 8       (-> 0x08)
        uut.imem.memory[1] = 32'h06300113; // 0x04: ADDI x2, x0, 99  (skipped)
        uut.imem.memory[2] = 32'h06400193; // 0x08: ADDI x3, x0, 100
        run_program;
        check_reg(4, 1, 32'd4);      // return address = PC + 4
        check_reg(4, 2, 32'd0);      // would be 99 if the jump failed
        check_reg(4, 3, 32'd100);

        // ── Summary ────────────────────────────────────────────
        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 17 COMPLETE - all test programs pass!\n");
        else
            $display("  ✗ Fix the failing programs before moving to Stage 18.\n");

        $finish;
    end

endmodule