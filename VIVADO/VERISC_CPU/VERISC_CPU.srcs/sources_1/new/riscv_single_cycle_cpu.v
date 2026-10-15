// ============================================================
//  32-bit Single-Cycle RISC-V CPU (RV32I subset)
//  Instructions: ADD SUB AND OR SLT | ADDI LW | SW | BEQ | JAL
// ============================================================
module riscv_single_cycle_cpu (
    input wire clk,
    input wire reset,
    output wire [31:0] debug_out 
);
    // ── Datapath wires ──────────────────────────────────────
    wire [31:0] pc_current, pc_next, pc_plus4, pc_target;
    wire [31:0] instruction;
    wire [31:0] immediate;
    wire [31:0] read_data1, read_data2;
    wire [31:0] alu_operand_b, alu_result;
    wire [31:0] mem_read_data;
    wire [31:0] write_back_data;
    wire        zero_flag;

    // ── Control signals ─────────────────────────────────────
    wire        reg_write, alu_src, mem_read, mem_write;
    wire        mem_to_reg, branch, jump;
    wire [2:0]  alu_control;

    // ── Instruction fields ──────────────────────────────────
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    // ════════════════════════════════════════════════════════
    //  1. FETCH
    // ════════════════════════════════════════════════════════
    pc pc_reg (
        .clk        (clk),
        .reset      (reset),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    assign pc_plus4 = pc_current + 32'd4;

    instruction_memory imem (
        .address     (pc_current),
        .instruction (instruction)
    );

    // ════════════════════════════════════════════════════════
    //  2. DECODE
    // ════════════════════════════════════════════════════════
    control_unit ctrl (
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

    register_file rf (
        .clk        (clk),
        .reset      (reset),
        .reg_write  (reg_write),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .write_data (write_back_data),
        .read_data1 (read_data1),
        .read_data2 (read_data2)
    );

    immediate_generator imm_gen (
        .instruction (instruction),
        .immediate   (immediate)
    );

    // ════════════════════════════════════════════════════════
    //  3. EXECUTE
    // ════════════════════════════════════════════════════════
    // alu_src: 0 = rs2, 1 = immediate
    assign alu_operand_b = alu_src ? immediate : read_data2;

    alu alu_unit (
        .operand_a   (read_data1),
        .operand_b   (alu_operand_b),
        .alu_control (alu_control),
        .alu_result  (alu_result),
        .zero_flag   (zero_flag)
    );

    // ════════════════════════════════════════════════════════
    //  4. MEMORY
    // ════════════════════════════════════════════════════════
    data_memory dmem (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .address    (alu_result),     // rs1 + immediate
        .write_data (read_data2),     // rs2 (value stored by SW)
        .read_data  (mem_read_data)
    );

    // ════════════════════════════════════════════════════════
    //  5. WRITE-BACK
    // ════════════════════════════════════════════════════════
    // JAL -> PC+4 (return address), LW -> memory data, else ALU result
    assign write_back_data = jump       ? pc_plus4      :
                             mem_to_reg ? mem_read_data :
                                          alu_result;

    // ════════════════════════════════════════════════════════
    //  6. NEXT PC
    // ════════════════════════════════════════════════════════
    // BEQ and JAL both target PC + immediate
    assign pc_target = pc_current + immediate;

    wire branch_taken = branch & zero_flag;   // BEQ with rs1 == rs2

    assign pc_next = (jump | branch_taken) ? pc_target : pc_plus4;
    assign debug_out = pc_current ^ write_back_data;
endmodule