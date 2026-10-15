`timescale 1ns/1ps

module tb_control_unit;

    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    wire       reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, jump;
    wire [2:0] alu_control;

    control_unit uut (
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7      (funct7),
        .reg_write   (reg_write),
        .alu_src     (alu_src),
        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .mem_to_reg  (mem_to_reg),
        .branch      (branch),
        .jump        (jump),
        .alu_control (alu_control)
    );

    integer pass_count;
    integer fail_count;

    // Bit layout of the packed vector:
    // [9]=reg_write [8]=alu_src [7]=mem_read [6]=mem_write
    // [5]=mem_to_reg [4]=branch [3]=jump [2:0]=alu_control
    wire [9:0] got = {reg_write, alu_src, mem_read, mem_write,
                      mem_to_reg, branch, jump, alu_control};

    // 'mask' has 0s on don't-care bits so they are not checked
    task check;
        input [6:0] op;
        input [2:0] f3;
        input [6:0] f7;
        input [9:0] expected;
        input [9:0] mask;
        input integer test_num;
        input [47:0] name;   // 6-char label, display only
        begin
            opcode = op; funct3 = f3; funct7 = f7;
            #5;
            if ((got & mask) === (expected & mask)) begin
                $display("  PASS [T%0d] %0s: signals=%b_%b_%b_%b_%b_%b_%b ctrl=%b",
                         test_num, name,
                         reg_write, alu_src, mem_read, mem_write,
                         mem_to_reg, branch, jump, alu_control);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [T%0d] %0s: got=%b  expected=%b (mask=%b)",
                         test_num, name, got, expected, mask);
                fail_count = fail_count + 1;
            end
        end
    endtask

    localparam [9:0] ALL = 10'b1111111111;

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("==================================================");
        $display("       Control Unit Testbench  -  Stage 10");
        $display("==================================================");

        //            opcode     f3     f7         {RW,AS,MR,MW,M2R,BR,JP, ALUctrl}
        check(7'b0110011, 3'b000, 7'b0000000, 10'b1_0_0_0_0_0_0_000, ALL, 1,  "ADD");
        check(7'b0110011, 3'b000, 7'b0100000, 10'b1_0_0_0_0_0_0_001, ALL, 2,  "SUB");
        check(7'b0110011, 3'b111, 7'b0000000, 10'b1_0_0_0_0_0_0_010, ALL, 3,  "AND");
        check(7'b0110011, 3'b110, 7'b0000000, 10'b1_0_0_0_0_0_0_011, ALL, 4,  "OR");
        check(7'b0110011, 3'b010, 7'b0000000, 10'b1_0_0_0_0_0_0_100, ALL, 5,  "SLT");
        check(7'b0010011, 3'b000, 7'b0000000, 10'b1_1_0_0_0_0_0_000, ALL, 6,  "ADDI");
        check(7'b0000011, 3'b010, 7'b0000000, 10'b1_1_1_0_1_0_0_000, ALL, 7,  "LW");

        // SW: MemtoReg is don't care
        check(7'b0100011, 3'b010, 7'b0000000, 10'b0_1_0_1_0_0_0_000,
              10'b1111011111, 8, "SW");

        // BEQ: MemtoReg is don't care
        check(7'b1100011, 3'b000, 7'b0000000, 10'b0_0_0_0_0_1_0_001,
              10'b1111011111, 9, "BEQ");

        // JAL: ALUSrc and ALU control are don't care
        check(7'b1101111, 3'b000, 7'b0000000, 10'b1_0_0_0_0_0_1_000,
              10'b1011111000, 10, "JAL");

        // Unknown opcode must do nothing (no register/memory writes, no PC change)
        check(7'b0000000, 3'b000, 7'b0000000, 10'b0_0_0_0_0_0_0_000, ALL, 11, "UNKN");

        $display("\n==================================================");
        $display("  Results : %0d PASSED   %0d FAILED", pass_count, fail_count);
        $display("==================================================\n");

        if (fail_count == 0)
            $display("  ✓ Stage 10 COMPLETE - Control Unit is working!\n");
        else
            $display("  ✗ Fix the failing tests before moving to Stage 11.\n");

        $finish;
    end

endmodule