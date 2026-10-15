// ============================================================
// Module : instruction_memory
// Project: VERISC — 32-bit Single-Cycle RISC-V Processor
// Stage  : 6 — Instruction Memory
// ============================================================
// What this does:
//   Stores the program (list of 32-bit instructions).
//   Given a byte address from the PC, it returns the 32-bit
//   instruction stored at that address.
//
// Why divide address by 4?
//   The PC counts in BYTES (0, 4, 8, 12, ...)
//   But our memory array is indexed in WORDS (0, 1, 2, 3, ...)
//   Each word = 4 bytes, so:
//     PC=0  → memory[0]
//     PC=4  → memory[1]
//     PC=8  → memory[2]
//   Dividing by 4 is the same as right-shifting by 2: addr[31:2]
//
// Why combinational (no clock)?
//   In a single-cycle processor, the instruction must be
//   available the moment the PC value is stable — no waiting.
//   So the read is purely combinational (like a lookup table).
//
// Memory size:
//   64 words × 32 bits = 64 instructions = 256 bytes.
//   More than enough for our test programs.
// ============================================================

module instruction_memory (
    input  wire [31:0] address,      // byte address from PC
    output wire [31:0] instruction   // 32-bit instruction at that address
);

    // 64 words of 32-bit instruction storage
    reg [31:0] memory [0:63];

    // Combinational read — no clock, just a direct lookup
    // address[31:2] drops the bottom 2 bits (divides by 4)
    // to convert byte address → word index
    assign instruction = memory[address[31:2]];

    // ── Load a small test program at startup ──────────────────
    // This program tests basic instructions one by one.
    // We will replace this with real encoded programs in Stage 16/17.
    //
    // For now we use raw hex encodings of these instructions:
    //
    //   Addr 0x00:  ADDI x1, x0, 5      // x1 = 5
    //   Addr 0x04:  ADDI x2, x0, 3      // x2 = 3
    //   Addr 0x08:  ADD  x3, x1, x2     // x3 = 8
    //   Addr 0x0C:  SUB  x4, x1, x2     // x4 = 2
    //   Addr 0x10:  AND  x5, x1, x2     // x5 = 1  (5 & 3 = 001)
    //   Addr 0x14:  OR   x6, x1, x2     // x6 = 7  (5 | 3 = 111)
    //   Addr 0x18:  SLT  x7, x2, x1     // x7 = 1  (3 < 5 = true)
    //   Addr 0x1C:  NOP  (ADDI x0,x0,0) // do nothing, end of program
    //
    // Encodings verified against official RV32I specification.

    initial begin
        // ADDI x1, x0, 5
        // imm=5, rs1=x0(0), funct3=000, rd=x1(1), opcode=0010011
        // 000000000101_00000_000_00001_0010011
        memory[0]  = 32'h00500093;

        // ADDI x2, x0, 3
        // imm=3, rs1=x0(0), funct3=000, rd=x2(2), opcode=0010011
        // 000000000011_00000_000_00010_0010011
        memory[1]  = 32'h00300113;

        // ADD x3, x1, x2
        // funct7=0000000, rs2=x2(2), rs1=x1(1), funct3=000, rd=x3(3), opcode=0110011
        // 0000000_00010_00001_000_00011_0110011
        memory[2]  = 32'h002081B3;

        // SUB x4, x1, x2
        // funct7=0100000, rs2=x2(2), rs1=x1(1), funct3=000, rd=x4(4), opcode=0110011
        // 0100000_00010_00001_000_00100_0110011
        memory[3]  = 32'h40208233;

        // AND x5, x1, x2
        // funct7=0000000, rs2=x2(2), rs1=x1(1), funct3=111, rd=x5(5), opcode=0110011
        // 0000000_00010_00001_111_00101_0110011
        memory[4]  = 32'h0020F2B3;

        // OR x6, x1, x2
        // funct7=0000000, rs2=x2(2), rs1=x1(1), funct3=110, rd=x6(6), opcode=0110011
        // 0000000_00010_00001_110_00110_0110011
        memory[5]  = 32'h0020E333;

         // SLT x7, x2, x1
        // funct7=0000000, rs2=x1(1), rs1=x2(2), funct3=010, rd=x7(7), opcode=0110011
        // 0000000_00001_00010_010_00111_0110011
        memory[6]  = 32'h001123B3;

        // NOP = ADDI x0, x0, 0  (writes to x0 which is always 0 — safe no-op)
        // imm=0, rs1=x0(0), funct3=000, rd=x0(0), opcode=0010011
        memory[7]  = 32'h00000013;

        // Fill rest with NOP so we never fetch garbage
        begin : fill_nop
            integer i;
            for (i = 8; i < 64; i = i + 1)
                memory[i] = 32'h00000013;  // NOP
        end
    end

endmodule
