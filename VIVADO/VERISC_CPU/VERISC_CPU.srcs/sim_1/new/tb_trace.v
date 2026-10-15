`timescale 1ns/1ps
module tb_trace;
    reg clk = 0, reset = 1;
    riscv_single_cycle_cpu uut (.clk(clk), .reset(reset));
    always #5 clk = ~clk;
    integer i;
    initial begin
        #1;
        for (i = 0; i < 64; i = i + 1) begin uut.imem.memory[i] = 32'h13; uut.dmem.memory[i] = 0; end
        uut.imem.memory[0] = 32'h06400093; // ADDI x1,x0,100
        uut.imem.memory[1] = 32'h02A00113; // ADDI x2,x0,42
        uut.imem.memory[2] = 32'h002081B3; // ADD  x3,x1,x2
        uut.imem.memory[3] = 32'h0020A023; // SW   x2,0(x1)
        uut.imem.memory[4] = 32'h0000A203; // LW   x4,0(x1)
        uut.imem.memory[5] = 32'h00220463; // BEQ  x4,x2,+8
        uut.imem.memory[6] = 32'h06300293; // ADDI x5,x0,99 (skipped)
        uut.imem.memory[7] = 32'h008003EF; // JAL  x7,+8
        uut.imem.memory[8] = 32'h06300313; // ADDI x6,x0,99 (skipped)
        uut.imem.memory[9] = 32'h00100413; // ADDI x8,x0,1
        @(posedge clk); @(posedge clk); #1 reset = 0;
        $display("cyc  PC   instr     alu_ctl alu_res  RegW MemR MemW M2R Br Jmp wb_data  taken");
        for (i = 0; i < 8; i = i + 1) begin
            #3;
            $display("%2d   0x%02X  %08X  %03b   %08X   %b    %b    %b    %b   %b  %b   %08X  %b",
              i, uut.pc_current, uut.instruction, uut.alu_control, uut.alu_result,
              uut.reg_write, uut.mem_read, uut.mem_write, uut.mem_to_reg, uut.branch, uut.jump,
              uut.write_back_data, uut.branch & uut.zero_flag);
            @(posedge clk); #1;
        end
        $finish;
    end
endmodule