# RISC-V CPU Project Guide

**Design, Implementation and Functional Verification of a 32-bit Single-Cycle RISC-V Processor in Verilog HDL**

---

## 📋 Project Overview

This guide tracks your implementation of a 32-bit single-cycle RISC-V processor supporting a subset of the RV32I instruction set. Work through the 23 stages sequentially, testing each module before integration.

### RV32I Instruction Subset

| Type | Instructions | Purpose |
|------|-------------|---------|
| **R-Type** | ADD, SUB, AND, OR, SLT | Register-to-register operations |
| **I-Type** | ADDI, LW | Immediate and load operations |
| **S-Type** | SW | Store operations |
| **B-Type** | BEQ | Branch operations |
| **J-Type** | JAL | Jump operations |

---

## ✅ Implementation Progress

Track your progress by marking completed stages:

- [ ] **Stage 1**: Understand the Architecture
- [ ] **Stage 2**: Finalize the ISA
- [ ] **Stage 3**: Design the Datapath
- [ ] **Stage 4**: Define Control Signals
- [ ] **Stage 5**: Implement Program Counter
- [ ] **Stage 6**: Instruction Memory
- [ ] **Stage 7**: Register File
- [ ] **Stage 8**: ALU Implementation
- [ ] **Stage 9**: Immediate Generator
- [ ] **Stage 10**: Control Unit / Decoder
- [ ] **Stage 11**: Build CPU Datapath
- [ ] **Stage 12**: Data Memory
- [ ] **Stage 13**: Implement Branching
- [ ] **Stage 14**: Implement JAL
- [ ] **Stage 15**: Complete Top-Level CPU
- [ ] **Stage 16**: Instruction Encoding
- [ ] **Stage 17**: Create Test Programs
- [ ] **Stage 18**: Self-Checking Testbench
- [ ] **Stage 19**: Simulation & Debugging
- [ ] **Stage 20**: Verification
- [ ] **Stage 21**: Performance Analysis
- [ ] **Stage 22**: Project Report
- [ ] **Stage 23**: Project Presentation

---

## 🏗️ Stage Details

### Stage 1: Understand the Architecture

**Objective**: Learn foundational concepts before coding

**Key Concepts to Master**:
- What a CPU is and what RISC means
- RISC-V and RV32I instruction set architecture (ISA)
- Single-cycle processor architecture
- Datapath components and their roles
- Control unit functionality

**Datapath Flow**:
```
PC → Instruction Memory → Instruction → Decoder/Control Unit 
  → Register File → ALU → Data Memory → Write Back → Register File
```

**Components**:
- **PC (Program Counter)**: Holds address of current instruction
- **Instruction Memory**: Stores program instructions
- **Register File**: 32 general-purpose registers (x0-x31)
- **ALU**: Performs arithmetic and logic operations
- **Data Memory**: Stores data for load/store operations
- **Control Unit**: Generates control signals based on opcode
- **Immediate Generator**: Extracts and sign-extends immediate values

---

### Stage 2: Finalize the ISA

**Objective**: Master instruction encoding and create complete reference tables

---

## RISC-V Register ABI Names

Before we dive into encoding, understand the register naming conventions:

| Register | ABI Name | Description | Saved by |
|----------|----------|-------------|----------|
| x0 | zero | Hard-wired zero | - |
| x1 | ra | Return address | Caller |
| x2 | sp | Stack pointer | Callee |
| x3 | gp | Global pointer | - |
| x4 | tp | Thread pointer | - |
| x5-x7 | t0-t2 | Temporary registers | Caller |
| x8 | s0/fp | Saved register / Frame pointer | Callee |
| x9 | s1 | Saved register | Callee |
| x10-x11 | a0-a1 | Function arguments / Return values | Caller |
| x12-x17 | a2-a7 | Function arguments | Caller |
| x18-x27 | s2-s11 | Saved registers | Callee |
| x28-x31 | t3-t6 | Temporary registers | Caller |

**Note**: You can use either naming convention (x3 or gp), but x0-x31 is more common in basic implementations.

---

## Instruction Formats

**R-Type Format** (Register-Register operations):
```
┌─────────┬──────┬──────┬────────┬──────┬─────────┐
│  31:25  │24:20 │19:15 │ 14:12  │ 11:7 │   6:0   │
├─────────┼──────┼──────┼────────┼──────┼─────────┤
│ funct7  │ rs2  │ rs1  │ funct3 │  rd  │ opcode  │
│ 7 bits  │5 bits│5 bits│ 3 bits │5 bits│ 7 bits  │
└─────────┴──────┴──────┴────────┴──────┴─────────┘
```

**I-Type Format** (Immediate operations):
```
┌──────────────────┬──────┬────────┬──────┬─────────┐
│      31:20       │19:15 │ 14:12  │ 11:7 │   6:0   │
├──────────────────┼──────┼────────┼──────┼─────────┤
│   imm[11:0]      │ rs1  │ funct3 │  rd  │ opcode  │
│    12 bits       │5 bits│ 3 bits │5 bits│ 7 bits  │
└──────────────────┴──────┴────────┴──────┴─────────┘
```

**S-Type Format** (Store operations):
```
┌──────────────┬──────┬──────┬────────┬────────────┬─────────┐
│    31:25     │24:20 │19:15 │ 14:12  │    11:7    │   6:0   │
├──────────────┼──────┼──────┼────────┼────────────┼─────────┤
│  imm[11:5]   │ rs2  │ rs1  │ funct3 │  imm[4:0]  │ opcode  │
│   7 bits     │5 bits│5 bits│ 3 bits │   5 bits   │ 7 bits  │
└──────────────┴──────┴──────┴────────┴────────────┴─────────┘
```

**B-Type Format** (Branch operations):
```
┌────┬───────────┬──────┬──────┬────────┬────────────┬────┬─────────┐
│ 31 │   30:25   │24:20 │19:15 │ 14:12  │    11:8    │  7 │   6:0   │
├────┼───────────┼──────┼──────┼────────┼────────────┼────┼─────────┤
│[12]│ imm[10:5] │ rs2  │ rs1  │ funct3 │  imm[4:1]  │[11]│ opcode  │
│1bit│  6 bits   │5 bits│5 bits│ 3 bits │   4 bits   │1bit│ 7 bits  │
└────┴───────────┴──────┴──────┴────────┴────────────┴────┴─────────┘
Note: imm[0] is implicit 0 (word-aligned)
```

**J-Type Format** (Jump operations):
```
┌────┬───────────┬────┬───────────┬──────┬─────────┐
│ 31 │   30:21   │ 20 │   19:12   │ 11:7 │   6:0   │
├────┼───────────┼────┼───────────┼──────┼─────────┤
│[20]│ imm[10:1] │[11]│ imm[19:12]│  rd  │ opcode  │
│1bit│  10 bits  │1bit│  8 bits   │5 bits│ 7 bits  │
└────┴───────────┴────┴───────────┴──────┴─────────┘
Note: imm[0] is implicit 0 (word-aligned)
```

---

## Complete Instruction Encoding Table

| Instruction | Type | Opcode    | funct3 | funct7   | Operation |
|------------|------|-----------|--------|----------|-----------|
| ADD        | R    | 0110011   | 000    | 0000000  | rd = rs1 + rs2 |
| SUB        | R    | 0110011   | 000    | 0100000  | rd = rs1 - rs2 |
| AND        | R    | 0110011   | 111    | 0000000  | rd = rs1 & rs2 |
| OR         | R    | 0110011   | 110    | 0000000  | rd = rs1 \| rs2 |
| SLT        | R    | 0110011   | 010    | 0000000  | rd = (rs1 < rs2) ? 1 : 0 |
| ADDI       | I    | 0010011   | 000    | -        | rd = rs1 + imm |
| LW         | I    | 0000011   | 010    | -        | rd = Mem[rs1 + imm] |
| SW         | S    | 0100011   | 010    | -        | Mem[rs1 + imm] = rs2 |
| BEQ        | B    | 1100011   | 000    | -        | if (rs1 == rs2) PC += imm |
| JAL        | J    | 1101111   | -      | -        | rd = PC+4; PC += imm |

---

## Manual Encoding Examples

### Example 1: R-Type Instruction - ADD x3, x1, x2

**Step 1**: Identify the fields
- Instruction: ADD
- rd = x3 = 3
- rs1 = x1 = 1  
- rs2 = x2 = 2
- opcode = 0110011 (R-Type)
- funct3 = 000
- funct7 = 0000000

**Step 2**: Convert register numbers to 5-bit binary
- rd = 3 = 00011
- rs1 = 1 = 00001
- rs2 = 2 = 00010

**Step 3**: Assemble the instruction
```
┌─────────┬──────┬──────┬────────┬──────┬─────────┐
│ funct7  │ rs2  │ rs1  │ funct3 │  rd  │ opcode  │
├─────────┼──────┼──────┼────────┼──────┼─────────┤
│ 0000000 │00010 │00001 │  000   │00011 │ 0110011 │
└─────────┴──────┴──────┴────────┴──────┴─────────┘

Binary:  0000000_00010_00001_000_00011_0110011
Compact: 00000000001000001000000110110011

Hexadecimal: 0x002080B3
```

**Step 4**: Verification
- Split into groups: 0000 0000 0010 0000 1000 0001 1011 0011
- Convert to hex: 0x0 0x0 0x2 0x0 0x8 0x0 0xB 0x3
- Result: **0x002080B3** ✓

---

### Example 2: I-Type Instruction - ADDI x5, x1, 10

**Step 1**: Identify the fields
- Instruction: ADDI
- rd = x5 (t0) = 5
- rs1 = x1 (ra) = 1
- immediate = 10 (decimal)
- opcode = 0010011 (I-Type arithmetic)
- funct3 = 000

**Step 2**: Convert to binary
- rd = 5 = 00101
- rs1 = 1 = 00001
- immediate = 10 = 0000 0000 1010 (12 bits)

**Step 3**: Assemble the instruction
```
┌──────────────────┬──────┬────────┬──────┬─────────┐
│   imm[11:0]      │ rs1  │ funct3 │  rd  │ opcode  │
├──────────────────┼──────┼────────┼──────┼─────────┤
│ 000000001010     │00001 │  000   │00101 │ 0010011 │
└──────────────────┴──────┴────────┴──────┴─────────┘

Binary:  000000001010_00001_000_00101_0010011
Compact: 00000000101000001000001010010011

Hexadecimal: 0x00A08293
```

**Step 4**: Verification
- Binary groups: 0000 0000 1010 0000 1000 0010 1001 0011
- Hex: 0x0 0x0 0xA 0x0 0x8 0x2 0x9 0x3
- Result: **0x00A08293** ✓

---

### Example 3: S-Type Instruction - SW x2, 8(x1)

**Assembly**: SW x2, 8(x1) means: Memory[x1 + 8] = x2

**Step 1**: Identify the fields
- Instruction: SW
- rs2 = x2 (sp) = 2 (data to store)
- rs1 = x1 (ra) = 1 (base address)
- immediate = 8 (offset)
- opcode = 0100011 (S-Type)
- funct3 = 010 (word)

**Step 2**: Convert to binary
- rs2 = 2 = 00010
- rs1 = 1 = 00001
- immediate = 8 = 0000 0000 1000 (12 bits total)

**Step 3**: Split immediate for S-Type format
```
Immediate = 000000001000
Split into:
  imm[11:5] = 0000000 (upper 7 bits)
  imm[4:0]  = 01000   (lower 5 bits)
```

**Step 4**: Assemble the instruction
```
┌──────────────┬──────┬──────┬────────┬────────────┬─────────┐
│  imm[11:5]   │ rs2  │ rs1  │ funct3 │  imm[4:0]  │ opcode  │
├──────────────┼──────┼──────┼────────┼────────────┼─────────┤
│   0000000    │00010 │00001 │  010   │   01000    │ 0100011 │
└──────────────┴──────┴──────┴────────┴────────────┴─────────┘

Binary:  0000000_00010_00001_010_01000_0100011
Compact: 00000000001000001010010000100011

Hexadecimal: 0x0020A423
```

**Key Point**: Notice how the immediate is split! This is unique to S-Type.

---

### Example 4: B-Type Instruction - BEQ x1, x2, 12

**Assembly**: BEQ x1, x2, 12 means: if (x1 == x2) PC = PC + 12

**Step 1**: Identify the fields
- Instruction: BEQ
- rs1 = x1 (ra) = 1
- rs2 = x2 (sp) = 2
- immediate = 12 (branch offset in bytes)
- opcode = 1100011 (B-Type)
- funct3 = 000 (BEQ)

**Step 2**: Convert immediate to binary
- immediate = 12 = 0000 0000 1100 (13 bits total, LSB implicit 0)
- Full 13-bit representation: 0_0000_0000_1100

**Step 3**: **B-Type Immediate Bit Scrambling** (IMPORTANT!)

B-Type scatters the immediate bits in a non-intuitive way:

```
Original immediate value: 12 decimal
Binary (13 bits): 0_000000_01100
                  ↓    ↓      ↓
                [12] [10:5] [4:1]  (bit [0] implicit 0)

Bit positions in 13-bit immediate:
  [12] [11] [10] [9] [8] [7] [6] [5] [4] [3] [2] [1] [0]
   0    0    0    0   0   0   0   0   1   1   0   0   0

Now map to instruction format:
  - imm[12]   → bit 31       = 0
  - imm[10:5] → bits 30:25   = 000000
  - imm[4:1]  → bits 11:8    = 1100
  - imm[11]   → bit 7        = 0
```

**Step 4**: Assemble the instruction
```
┌────┬───────────┬──────┬──────┬────────┬────────────┬────┬─────────┐
│ 31 │   30:25   │24:20 │19:15 │ 14:12  │    11:8    │  7 │   6:0   │
├────┼───────────┼──────┼──────┼────────┼────────────┼────┼─────────┤
│ 0  │  000000   │00010 │00001 │  000   │    1100    │ 0  │ 1100011 │
└────┴───────────┴──────┴──────┴────────┴────────────┴────┴─────────┘

Binary:  0_000000_00010_00001_000_1100_0_1100011
Compact: 00000000001000001000110001100011

Hexadecimal: 0x00208663
```

**Bit-by-Bit Breakdown**:
```
Instruction bits: 0000 0000 0010 0000 1000 1100 0110 0011
                  └─┬──┘ └─┬──┘ └─┬──┘ └─┬──┘ └─┬──┘ └─┬──┘
                    0      0      2      0      8      C      6      3

Extracting immediate back:
  bit 31 = 0        → imm[12]
  bits 30:25 = 000000 → imm[10:5]
  bits 11:8 = 1100   → imm[4:1]
  bit 7 = 0         → imm[11]
  
  Reconstruct: imm = {imm[12], imm[11], imm[10:5], imm[4:1], 1'b0}
              = {0, 0, 000000, 1100, 0}
              = 0_000000110_0 = 12 ✓
```

---

### Example 5: J-Type Instruction - JAL x1, 100

**Assembly**: JAL x1, 100 means: x1 = PC + 4; PC = PC + 100

**Step 1**: Identify the fields
- Instruction: JAL
- rd = x1 (ra - return address) = 1
- immediate = 100 (jump offset in bytes)
- opcode = 1101111 (J-Type)

**Step 2**: Convert immediate to binary
- immediate = 100 = 0110 0100 (21 bits total, LSB implicit 0)
- Full 21-bit representation: 0_00000000_0_0110010_0

**Step 3**: **J-Type Immediate Bit Scrambling** (MOST COMPLEX!)

J-Type scatters bits even more than B-Type:

```
Original immediate value: 100 decimal
Binary (21 bits): 0_0000000000_011001_00
                  ↓      ↓       ↓     ↓
                [20]  [10:1]   [11] [19:12]  (bit [0] implicit 0)

Bit positions in 21-bit immediate:
  [20][19][18][17][16][15][14][13][12][11][10][9][8][7][6][5][4][3][2][1][0]
   0   0   0   0   0   0   0   0   0   0   0   1  1  0  0  1  0  0  1  0  0

Now map to instruction format:
  - imm[20]    → bit 31        = 0
  - imm[10:1]  → bits 30:21    = 0000110010
  - imm[11]    → bit 20        = 0
  - imm[19:12] → bits 19:12    = 00000000
```

**Step 4**: Assemble the instruction
```
┌────┬────────────────────┬────┬────────────┬──────┬─────────┐
│ 31 │      30:21         │ 20 │   19:12    │ 11:7 │   6:0   │
├────┼────────────────────┼────┼────────────┼──────┼─────────┤
│ 0  │   0000110010        │ 0  │  00000000  │00001 │ 1101111 │
└────┴────────────────────┴────┴────────────┴──────┴─────────┘

Binary:  0_0000110010_0_00000000_00001_1101111
Compact: 00000110010000000000000011101111

Hexadecimal: 0x064000EF
```

**Bit-by-Bit Breakdown**:
```
Instruction bits: 0000 0110 0100 0000 0000 0000 1110 1111
                  └─┬──┘ └─┬──┘ └─┬──┘ └─┬──┘ └─┬──┘ └─┬──┘
                    0      6      4      0      0      0      E      F

Extracting immediate back:
  bit 31 = 0           → imm[20]
  bits 30:21 = 0000110010 → imm[10:1]
  bit 20 = 0           → imm[11]
  bits 19:12 = 00000000  → imm[19:12]
  
  Reconstruct: imm = {imm[20], imm[19:12], imm[11], imm[10:1], 1'b0}
              = {0, 00000000, 0, 0000110010, 0}
              = 0_00000000_0_0000110010_0 = 100 ✓
```

---

## Complete Verilog Immediate Generator Module

This is a complete, copy-paste ready module for extracting immediates from all instruction types:

```verilog
module immediate_generator (
    input [31:0] instruction,
    input [1:0] imm_type,  // 00=I, 01=S, 10=B, 11=J
    output reg [31:0] immediate
);

    // Instruction type parameters
    localparam I_TYPE = 2'b00;
    localparam S_TYPE = 2'b01;
    localparam B_TYPE = 2'b10;
    localparam J_TYPE = 2'b11;

    always @(*) begin
        case (imm_type)
            I_TYPE: begin
                // I-Type: Sign-extend imm[11:0]
                // Bits [31:20] → immediate[11:0]
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            
            S_TYPE: begin
                // S-Type: Sign-extend {imm[11:5], imm[4:0]}
                // Bits [31:25] → imm[11:5]
                // Bits [11:7]  → imm[4:0]
                immediate = {{20{instruction[31]}}, 
                            instruction[31:25], 
                            instruction[11:7]};
            end
            
            B_TYPE: begin
                // B-Type: Sign-extend {imm[12], imm[10:5], imm[4:1], 0}
                // Bit [31]     → imm[12]
                // Bits [30:25] → imm[10:5]
                // Bits [11:8]  → imm[4:1]
                // Bit [7]      → imm[11]
                // LSB is implicit 0 (word-aligned)
                immediate = {{19{instruction[31]}}, 
                            instruction[31],    // imm[12]
                            instruction[7],     // imm[11]
                            instruction[30:25], // imm[10:5]
                            instruction[11:8],  // imm[4:1]
                            1'b0};              // imm[0] = 0
            end
            
            J_TYPE: begin
                // J-Type: Sign-extend {imm[20], imm[19:12], imm[11], imm[10:1], 0}
                // Bit [31]     → imm[20]
                // Bits [30:21] → imm[10:1]
                // Bit [20]     → imm[11]
                // Bits [19:12] → imm[19:12]
                // LSB is implicit 0 (word-aligned)
                immediate = {{11{instruction[31]}}, 
                            instruction[31],    // imm[20]
                            instruction[19:12], // imm[19:12]
                            instruction[20],    // imm[11]
                            instruction[30:21], // imm[10:1]
                            1'b0};              // imm[0] = 0
            end
            
            default: immediate = 32'b0;
        endcase
    end

endmodule
```

---

## Alternative: Opcode-Based Immediate Generator

This version decodes the instruction type automatically from the opcode:

```verilog
module immediate_generator_auto (
    input [31:0] instruction,
    output reg [31:0] immediate
);

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-Type: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            7'b0010011,
            // I-Type: LW, LH, LB, LHU, LBU
            7'b0000011,
            // I-Type: JALR
            7'b1100111: begin
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            
            // S-Type: SW, SH, SB
            7'b0100011: begin
                immediate = {{20{instruction[31]}}, 
                            instruction[31:25], 
                            instruction[11:7]};
            end
            
            // B-Type: BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011: begin
                immediate = {{19{instruction[31]}}, 
                            instruction[31],
                            instruction[7],
                            instruction[30:25],
                            instruction[11:8],
                            1'b0};
            end
            
            // J-Type: JAL
            7'b1101111: begin
                immediate = {{11{instruction[31]}}, 
                            instruction[31],
                            instruction[19:12],
                            instruction[20],
                            instruction[30:21],
                            1'b0};
            end
            
            // U-Type: LUI, AUIPC (for future extension)
            7'b0110111, 7'b0010111: begin
                immediate = {instruction[31:12], 12'b0};
            end
            
            // R-Type and others: no immediate
            default: begin
                immediate = 32'b0;
            end
        endcase
    end

endmodule
```

---

## Key Takeaways for Stage 2

1. **R-Type is straightforward**: Fields are in logical order
2. **I-Type is simple**: Just sign-extend the 12-bit immediate
3. **S-Type splits immediate**: Upper 7 bits and lower 5 bits are separated
4. **B-Type scrambles bits**: imm[12|11|10:5|4:1|0] scattered across instruction
5. **J-Type is most complex**: imm[20|19:12|11|10:1|0] needs careful reconstruction
6. **LSB is always 0**: Both B-Type and J-Type have implicit 0 LSB (word-aligned jumps/branches)
7. **Sign extension is critical**: Always extend from bit [31] of the instruction

**Pro Tip**: When debugging, always check your immediate generator first if branches or jumps aren't working correctly!

---

### Stage 3: Design the Datapath

**Objective**: Design the complete single-cycle datapath with all components and connections

In a single-cycle processor, each instruction executes completely in one clock cycle. This means all operations (fetch, decode, execute, memory access, write-back) must happen within a single cycle, which determines our clock period.

---

## Complete Datapath Architecture

```
                     ┌─────────────────────────────────────────────────┐
                     │                                                 │
                     │         ┌───────────────────┐                  │
                     │         │   Control Unit    │                  │
                     │         │   (Decoder)       │                  │
                     │         └─────────┬─────────┘                  │
                     │                   │                             │
                     │         Control Signals (RegWrite, ALUSrc, etc) │
                     │                   │                             │
   ┌─────┐    ┌──────▼──────┐    ┌──────▼──────┐         ┌─────────┐│
   │ PC  │───>│ Instruction │───>│  Immediate  │         │  Adder  ││
   │     │    │   Memory    │    │  Generator  │         │  (PC+4) ││
   └──┬──┘    └──────┬──────┘    └──────┬──────┘         └────┬────┘│
      │              │                   │                     │     │
      │              │ rs1,rs2,rd        │                     │     │
      │              │                   │                     │     │
      │         ┌────▼────────────┐      │imm                  │     │
      │         │  Register File  │      │                     │     │
      │         │   (32 x 32-bit) │      │                     │     │
      │         └────┬────┬───────┘      │                     │     │
      │              │    │              │                     │     │
      │         rd1  │    │ rd2          │                     │     │
      │              │    │              │                     │     │
      │              │  ┌─▼──────────────▼─┐                   │     │
      │              │  │   ALU MUX        │                   │     │
      │              │  │ (selects rs2/imm)│                   │     │
      │              │  └─────────┬────────┘                   │     │
      │              │            │                            │     │
      │              │       ┌────▼────┐                       │     │
      │              │       │   ALU   │                       │     │
      │              │       │         │<──ALU Control         │     │
      │              │       └────┬────┘                       │     │
      │              │            │ alu_result                 │     │
      │              │            │                            │     │
      │              │       ┌────▼──────┐                     │     │
      │              │       │   Data    │                     │     │
      │              │       │  Memory   │<──MemRead/MemWrite  │     │
      │              │       └────┬──────┘                     │     │
      │              │            │ mem_data                   │     │
      │              │            │                            │     │
      │              │       ┌────▼──────────┐                 │     │
      │              │       │ Write-back MUX│                 │     │
      │              │       │ (ALU or Mem)  │                 │     │
      │              │       └───────┬───────┘                 │     │
      │              │               │                         │     │
      │              └───────────────┘ write_data              │     │
      │                              RegWrite                  │     │
      │                                                         │     │
      │  ┌──────────────────────────────────────────────────────┘     │
      │  │                                                            │
      │  │  Branch/Jump Target Calculation                           │
      │  │  (PC + immediate)                                         │
      │  │                                                            │
      └──▼───────────────────────────────────────────────────────────┘
         PC MUX (selects PC+4, branch target, or jump target)
```

---

## Detailed Component Descriptions

### 1. Program Counter (PC)
**Purpose**: Holds the address of the current instruction being executed

**Inputs**:
- `clk`: Clock signal
- `reset`: Resets PC to 0
- `pc_next[31:0]`: Next PC value (from PC MUX)

**Outputs**:
- `pc_current[31:0]`: Current PC value (to Instruction Memory)

**Operation**: On each positive clock edge, PC updates to `pc_next`. On reset, PC = 0.

---

### 2. PC+4 Adder
**Purpose**: Calculates the address of the next sequential instruction

**Operation**: `pc_next_sequential = pc_current + 4`

This is a simple combinational adder. Since RISC-V instructions are 4 bytes, incrementing by 4 moves to the next instruction.

---

### 3. Instruction Memory
**Purpose**: Stores the program and provides instructions to execute

**Inputs**:
- `address[31:0]`: Address of instruction to fetch (from PC)

**Outputs**:
- `instruction[31:0]`: 32-bit instruction at that address

**Operation**: Combinational read. The instruction at the given address is immediately available.

**Address Mapping**: 
- PC = 0 → instruction[0]
- PC = 4 → instruction[1]
- PC = 8 → instruction[2]

---

### 4. Control Unit (Instruction Decoder)
**Purpose**: Decodes the instruction and generates all control signals

**Inputs**:
- `opcode[6:0]`: instruction[6:0]
- `funct3[2:0]`: instruction[14:12]
- `funct7[6:0]`: instruction[31:25]

**Outputs** (Control Signals):
- `RegWrite`: 1 = Enable register file write
- `ALUSrc`: 0 = ALU input from rs2, 1 = ALU input from immediate
- `MemRead`: 1 = Read from data memory
- `MemWrite`: 1 = Write to data memory
- `MemtoReg`: 0 = Write-back from ALU, 1 = Write-back from memory
- `Branch`: 1 = This is a branch instruction
- `Jump`: 1 = This is a jump instruction
- `ALUControl[2:0]`: Selects ALU operation (ADD, SUB, AND, OR, SLT)

**Operation**: Pure combinational logic that decodes instruction type and generates appropriate control signals.

---

### 5. Register File
**Purpose**: Contains 32 general-purpose registers (x0-x31)

**Inputs**:
- `clk`: Clock signal
- `reg_write`: Write enable (from Control Unit)
- `rs1[4:0]`: instruction[19:15] - First source register address
- `rs2[4:0]`: instruction[24:20] - Second source register address
- `rd[4:0]`: instruction[11:7] - Destination register address
- `write_data[31:0]`: Data to write to rd (from Write-back MUX)

**Outputs**:
- `read_data1[31:0]`: Contents of register rs1
- `read_data2[31:0]`: Contents of register rs2

**Operation**: 
- **Reads**: Combinational - outputs available immediately
- **Write**: Synchronous on positive clock edge when `reg_write = 1`
- **x0 special case**: Always reads as 0, writes to x0 are ignored

---

### 6. Immediate Generator
**Purpose**: Extracts and sign-extends immediate values from instructions

**Inputs**:
- `instruction[31:0]`: The full instruction

**Outputs**:
- `immediate[31:0]`: Sign-extended immediate value

**Operation**: Based on instruction type (determined from opcode), extracts immediate bits and sign-extends to 32 bits. See Stage 2 for detailed bit extraction logic.

---

### 7. ALU (Arithmetic Logic Unit)
**Purpose**: Performs arithmetic and logical operations

**Inputs**:
- `operand_a[31:0]`: First operand (always from rs1)
- `operand_b[31:0]`: Second operand (from ALU MUX: rs2 or immediate)
- `alu_control[2:0]`: Selects operation

**Outputs**:
- `alu_result[31:0]`: Result of operation
- `zero_flag`: 1 if alu_result == 0 (used for BEQ)

**Operations**:
- `3'b000`: ADD (operand_a + operand_b)
- `3'b001`: SUB (operand_a - operand_b)
- `3'b010`: AND (operand_a & operand_b)
- `3'b011`: OR (operand_a | operand_b)
- `3'b100`: SLT (operand_a < operand_b ? 1 : 0) - signed comparison

---

### 8. Data Memory
**Purpose**: Stores data for load/store operations

**Inputs**:
- `clk`: Clock signal
- `mem_read`: Read enable (from Control Unit)
- `mem_write`: Write enable (from Control Unit)
- `address[31:0]`: Memory address (from ALU result)
- `write_data[31:0]`: Data to write (from rs2 via read_data2)

**Outputs**:
- `read_data[31:0]`: Data read from memory

**Operation**:
- **Read**: Combinational when `mem_read = 1`
- **Write**: Synchronous on positive clock edge when `mem_write = 1`
- **Address**: Byte-addressed but word-aligned (divide by 4 for word index)

---

### 9. Multiplexers (MUXes)

#### a) ALU Input MUX (ALUSrc)
**Purpose**: Selects second ALU operand

**Inputs**:
- `read_data2[31:0]`: Value from rs2 register
- `immediate[31:0]`: Sign-extended immediate
- `ALUSrc`: Control signal (0 = rs2, 1 = immediate)

**Output**:
- `alu_operand_b[31:0]`: Selected value to ALU

**Selection**:
- ALUSrc = 0 → Use rs2 (R-Type instructions like ADD)
- ALUSrc = 1 → Use immediate (I-Type like ADDI, LW, SW)

#### b) Write-back MUX (MemtoReg)
**Purpose**: Selects data to write back to register file

**Inputs**:
- `alu_result[31:0]`: Result from ALU
- `mem_data[31:0]`: Data read from memory
- `MemtoReg`: Control signal (0 = ALU, 1 = memory)

**Output**:
- `write_data[31:0]`: Data to write to register rd

**Selection**:
- MemtoReg = 0 → Use ALU result (arithmetic/logic instructions)
- MemtoReg = 1 → Use memory data (LW instruction)

#### c) PC Source MUX (Branch/Jump)
**Purpose**: Selects next PC value

**Inputs**:
- `pc_plus_4[31:0]`: Sequential next instruction (PC + 4)
- `branch_target[31:0]`: PC + branch_immediate
- `jump_target[31:0]`: PC + jump_immediate
- `Branch`: Branch instruction signal
- `Jump`: Jump instruction signal
- `zero_flag`: ALU zero flag (for branch condition)

**Output**:
- `pc_next[31:0]`: Next PC value

**Selection Logic**:
```
if (Jump == 1)
    pc_next = jump_target
else if (Branch == 1 AND zero_flag == 1)
    pc_next = branch_target
else
    pc_next = pc_plus_4
```

---

## Complete Signal List

### Data Path Signals (32-bit):
1. `pc_current[31:0]` - Current PC value
2. `pc_plus_4[31:0]` - PC + 4
3. `pc_next[31:0]` - Next PC value
4. `instruction[31:0]` - Fetched instruction
5. `read_data1[31:0]` - Register rs1 contents
6. `read_data2[31:0]` - Register rs2 contents
7. `immediate[31:0]` - Sign-extended immediate
8. `alu_operand_b[31:0]` - ALU second operand (after MUX)
9. `alu_result[31:0]` - ALU output
10. `mem_read_data[31:0]` - Data from memory
11. `write_data[31:0]` - Data to write to register (after MUX)
12. `branch_target[31:0]` - PC + branch_immediate
13. `jump_target[31:0]` - PC + jump_immediate

### Control Signals (1-bit unless specified):
1. `RegWrite` - Enable register write
2. `ALUSrc` - Select ALU operand (0=rs2, 1=imm)
3. `MemRead` - Enable memory read
4. `MemWrite` - Enable memory write
5. `MemtoReg` - Select write-back (0=ALU, 1=mem)
6. `Branch` - Branch instruction flag
7. `Jump` - Jump instruction flag
8. `ALUControl[2:0]` - ALU operation select (3-bit)
9. `zero_flag` - ALU zero output

### Instruction Fields (extracted from instruction[31:0]):
1. `opcode[6:0]` = instruction[6:0]
2. `rd[4:0]` = instruction[11:7]
3. `funct3[2:0]` = instruction[14:12]
4. `rs1[4:0]` = instruction[19:15]
5. `rs2[4:0]` = instruction[24:20]
6. `funct7[6:0]` = instruction[31:25]

---

## Detailed Instruction Walkthroughs

### Example 1: ADD x3, x1, x2

**Initial State**:
- PC = 0x0000
- x1 = 5
- x2 = 3
- x3 = 0 (before execution)

**Instruction**: `0x002080B3` (ADD x3, x1, x2)

**Cycle-by-Cycle Execution**:

**Step 1: Instruction Fetch**
- PC outputs address: `pc_current = 0x0000`
- Instruction Memory reads: `instruction = 0x002080B3`
- PC+4 Adder calculates: `pc_plus_4 = 0x0004`

**Step 2: Instruction Decode**
- Extract fields:
  - opcode = 0110011 (R-Type)
  - rd = 00011 = 3 (x3)
  - funct3 = 000
  - rs1 = 00001 = 1 (x1)
  - rs2 = 00010 = 2 (x2)
  - funct7 = 0000000

- Control Unit generates signals:
  - `RegWrite = 1` (will write result)
  - `ALUSrc = 0` (use rs2, not immediate)
  - `MemRead = 0` (no memory read)
  - `MemWrite = 0` (no memory write)
  - `MemtoReg = 0` (write-back from ALU)
  - `Branch = 0` (not a branch)
  - `Jump = 0` (not a jump)
  - `ALUControl = 000` (ADD operation)

**Step 3: Register Read**
- Register File reads:
  - `read_data1 = reg[1] = 5` (value in x1)
  - `read_data2 = reg[2] = 3` (value in x2)

**Step 4: Execute**
- ALU MUX selects: `alu_operand_b = read_data2 = 3` (ALUSrc = 0)
- ALU performs: `alu_result = 5 + 3 = 8`
- ALU zero flag: `zero_flag = 0` (result is not zero)

**Step 5: Memory Access**
- MemRead = 0, MemWrite = 0
- Data Memory: **No operation**

**Step 6: Write Back**
- Write-back MUX selects: `write_data = alu_result = 8` (MemtoReg = 0)
- Register File writes: `reg[3] = 8` (on clock edge, RegWrite = 1)

**Step 7: PC Update**
- PC MUX selects: `pc_next = pc_plus_4 = 0x0004` (Branch = 0, Jump = 0)
- PC updates on clock edge: `PC = 0x0004`

**Final State**:
- PC = 0x0004
- x1 = 5 (unchanged)
- x2 = 3 (unchanged)
- x3 = 8 (updated) ✓

---

### Example 2: ADDI x5, x1, 10

**Initial State**:
- PC = 0x0004
- x1 = 5
- x5 = 0 (before execution)

**Instruction**: `0x00A08293` (ADDI x5, x1, 10)

**Step 1: Instruction Fetch**
- `pc_current = 0x0004`
- `instruction = 0x00A08293`
- `pc_plus_4 = 0x0008`

**Step 2: Instruction Decode**
- Extract fields:
  - opcode = 0010011 (I-Type arithmetic)
  - rd = 00101 = 5 (x5)
  - funct3 = 000 (ADDI)
  - rs1 = 00001 = 1 (x1)
  - imm[11:0] = 000000001010 = 10

- Control signals:
  - `RegWrite = 1`
  - `ALUSrc = 1` (use immediate)
  - `MemRead = 0`
  - `MemWrite = 0`
  - `MemtoReg = 0`
  - `Branch = 0`
  - `Jump = 0`
  - `ALUControl = 000` (ADD)

**Step 3: Register Read & Immediate Generation**
- `read_data1 = reg[1] = 5`
- `read_data2 = reg[?]` (not used)
- Immediate Generator: `immediate = 32'h0000000A` (sign-extended 10)

**Step 4: Execute**
- ALU MUX: `alu_operand_b = immediate = 10` (ALUSrc = 1)
- ALU: `alu_result = 5 + 10 = 15`
- `zero_flag = 0`

**Step 5: Memory Access**
- **No operation**

**Step 6: Write Back**
- `write_data = alu_result = 15`
- `reg[5] = 15` (on clock edge)

**Step 7: PC Update**
- `pc_next = 0x0008`
- `PC = 0x0008`

**Final State**:
- PC = 0x0008
- x1 = 5 (unchanged)
- x5 = 15 (updated) ✓

---

### Example 3: LW x3, 8(x1)

**Initial State**:
- PC = 0x0008
- x1 = 100 (base address)
- x3 = 0 (before execution)
- Memory[108] = 42 (data at address 100 + 8)

**Instruction**: `0x0080A183` (LW x3, 8(x1))

**Step 1: Instruction Fetch**
- `pc_current = 0x0008`
- `instruction = 0x0080A183`
- `pc_plus_4 = 0x000C`

**Step 2: Instruction Decode**
- Extract fields:
  - opcode = 0000011 (I-Type load)
  - rd = 00011 = 3 (x3)
  - funct3 = 010 (LW - load word)
  - rs1 = 00001 = 1 (x1)
  - imm[11:0] = 000000001000 = 8

- Control signals:
  - `RegWrite = 1`
  - `ALUSrc = 1` (use immediate for address calculation)
  - `MemRead = 1` (read from memory)
  - `MemWrite = 0`
  - `MemtoReg = 1` (write-back from memory)
  - `Branch = 0`
  - `Jump = 0`
  - `ALUControl = 000` (ADD for address calculation)

**Step 3: Register Read & Immediate Generation**
- `read_data1 = reg[1] = 100`
- Immediate Generator: `immediate = 32'h00000008` (sign-extended 8)

**Step 4: Execute (Address Calculation)**
- ALU MUX: `alu_operand_b = immediate = 8`
- ALU: `alu_result = 100 + 8 = 108` (memory address)
- `zero_flag = 0`

**Step 5: Memory Access**
- Data Memory reads at address 108:
- `mem_read_data = Memory[108] = 42`

**Step 6: Write Back**
- Write-back MUX: `write_data = mem_read_data = 42` (MemtoReg = 1)
- `reg[3] = 42` (on clock edge)

**Step 7: PC Update**
- `pc_next = 0x000C`
- `PC = 0x000C`

**Final State**:
- PC = 0x000C
- x1 = 100 (unchanged)
- x3 = 42 (loaded from memory) ✓

---

### Example 4: SW x2, 8(x1)

**Initial State**:
- PC = 0x000C
- x1 = 100 (base address)
- x2 = 25 (data to store)
- Memory[108] = 0 (before execution)

**Instruction**: `0x0020A423` (SW x2, 8(x1))

**Step 1: Instruction Fetch**
- `pc_current = 0x000C`
- `instruction = 0x0020A423`
- `pc_plus_4 = 0x0010`

**Step 2: Instruction Decode**
- Extract fields:
  - opcode = 0100011 (S-Type)
  - rs2 = 00010 = 2 (x2 - data to store)
  - funct3 = 010 (SW - store word)
  - rs1 = 00001 = 1 (x1 - base address)
  - imm = 000000001000 = 8 (offset)

- Control signals:
  - `RegWrite = 0` (no register write-back)
  - `ALUSrc = 1` (use immediate)
  - `MemRead = 0`
  - `MemWrite = 1` (write to memory)
  - `MemtoReg = X` (don't care, no write-back)
  - `Branch = 0`
  - `Jump = 0`
  - `ALUControl = 000` (ADD)

**Step 3: Register Read & Immediate Generation**
- `read_data1 = reg[1] = 100` (base address)
- `read_data2 = reg[2] = 25` (data to store)
- Immediate: `immediate = 32'h00000008`

**Step 4: Execute (Address Calculation)**
- ALU MUX: `alu_operand_b = immediate = 8`
- ALU: `alu_result = 100 + 8 = 108` (target address)

**Step 5: Memory Access**
- Data Memory writes at address 108:
- `Memory[108] = read_data2 = 25` (on clock edge)

**Step 6: Write Back**
- **No write-back** (RegWrite = 0)

**Step 7: PC Update**
- `pc_next = 0x0010`
- `PC = 0x0010`

**Final State**:
- PC = 0x0010
- x1 = 100 (unchanged)
- x2 = 25 (unchanged)
- Memory[108] = 25 (updated) ✓

---

### Example 5: BEQ x1, x2, 12

**Initial State**:
- PC = 0x0010
- x1 = 5
- x2 = 5 (equal values - branch will be taken)

**Instruction**: `0x00208663` (BEQ x1, x2, 12)

**Step 1: Instruction Fetch**
- `pc_current = 0x0010`
- `instruction = 0x00208663`
- `pc_plus_4 = 0x0014`

**Step 2: Instruction Decode**
- Extract fields:
  - opcode = 1100011 (B-Type)
  - funct3 = 000 (BEQ)
  - rs1 = 00001 = 1 (x1)
  - rs2 = 00010 = 2 (x2)
  - imm = 12 (branch offset)

- Control signals:
  - `RegWrite = 0`
  - `ALUSrc = 0` (use rs2)
  - `MemRead = 0`
  - `MemWrite = 0`
  - `MemtoReg = X`
  - `Branch = 1` (this is a branch)
  - `Jump = 0`
  - `ALUControl = 001` (SUB for comparison)

**Step 3: Register Read & Immediate Generation**
- `read_data1 = reg[1] = 5`
- `read_data2 = reg[2] = 5`
- Immediate: `immediate = 32'h0000000C` (12, sign-extended)
- Branch target calculation: `branch_target = 0x0010 + 12 = 0x001C`

**Step 4: Execute (Comparison)**
- ALU MUX: `alu_operand_b = read_data2 = 5` (ALUSrc = 0)
- ALU: `alu_result = 5 - 5 = 0`
- `zero_flag = 1` (values are equal!)

**Step 5: Memory Access**
- **No operation**

**Step 6: Write Back**
- **No write-back** (RegWrite = 0)

**Step 7: PC Update**
- PC MUX logic:
  - Branch = 1 AND zero_flag = 1 → **Take branch**
  - `pc_next = branch_target = 0x001C`
- `PC = 0x001C` (branch taken!)

**Final State**:
- PC = 0x001C (jumped to branch target) ✓
- x1 = 5 (unchanged)
- x2 = 5 (unchanged)

**Note**: If x1 ≠ x2, then zero_flag = 0, and `pc_next = pc_plus_4 = 0x0014` (branch not taken)

---

### Example 6: JAL x1, 100

**Initial State**:
- PC = 0x001C
- x1 = 0 (before execution)

**Instruction**: `0x064000EF` (JAL x1, 100)

**Step 1: Instruction Fetch**
- `pc_current = 0x001C`
- `instruction = 0x064000EF`
- `pc_plus_4 = 0x0020`

**Step 2: Instruction Decode**
- Extract fields:
  - opcode = 1101111 (J-Type)
  - rd = 00001 = 1 (x1 - return address register)
  - imm = 100 (jump offset)

- Control signals:
  - `RegWrite = 1` (save return address)
  - `ALUSrc = X` (don't care)
  - `MemRead = 0`
  - `MemWrite = 0`
  - `MemtoReg = 0` (write PC+4 to rd)
  - `Branch = 0`
  - `Jump = 1` (this is a jump)
  - `ALUControl = X`

**Step 3: Register Read & Immediate Generation**
- Immediate: `immediate = 32'h00000064` (100, sign-extended)
- Jump target: `jump_target = 0x001C + 100 = 0x0080`

**Step 4: Execute**
- **No ALU operation needed**
- Return address prepared: `pc_plus_4 = 0x0020`

**Step 5: Memory Access**
- **No operation**

**Step 6: Write Back**
- Write-back: `write_data = pc_plus_4 = 0x0020`
- `reg[1] = 0x0020` (return address saved)

**Step 7: PC Update**
- PC MUX logic:
  - Jump = 1 → **Take jump**
  - `pc_next = jump_target = 0x0080`
- `PC = 0x0080`

**Final State**:
- PC = 0x0080 (jumped to target) ✓
- x1 = 0x0020 (return address saved) ✓

---

## Complete Top-Level Verilog Module

```verilog
module riscv_single_cycle_cpu (
    input clk,
    input reset
);

    // ========== Internal Signals ==========
    
    // PC signals
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    
    // Instruction and fields
    wire [31:0] instruction;
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];
    
    // Control signals
    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire branch;
    wire jump;
    wire [2:0] alu_control;
    
    // Register file signals
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] write_data;
    
    // Immediate
    wire [31:0] immediate;
    
    // ALU signals
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire zero_flag;
    
    // Memory signals
    wire [31:0] mem_read_data;
    
    // Branch/Jump signals
    wire [31:0] branch_target;
    wire [31:0] jump_target;
    wire take_branch;
    
    // ========== PC+4 Adder ==========
    assign pc_plus_4 = pc_current + 4;
    
    // ========== Branch/Jump Target Calculation ==========
    assign branch_target = pc_current + immediate;
    assign jump_target = pc_current + immediate;
    assign take_branch = branch & zero_flag;
    
    // ========== Module Instantiations ==========
    
    // Program Counter
    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc_current(pc_current)
    );
    
    // Instruction Memory
    instruction_memory imem (
        .address(pc_current),
        .instruction(instruction)
    );
    
    // Control Unit
    control_unit ctrl (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_control(alu_control)
    );
    
    // Register File
    register_file regfile (
        .clk(clk),
        .reset(reset),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );
    
    // Immediate Generator
    immediate_generator_auto imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );
    
    // ALU
    alu alu_inst (
        .operand_a(read_data1),
        .operand_b(alu_operand_b),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .zero_flag(zero_flag)
    );
    
    // Data Memory
    data_memory dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(alu_result),
        .write_data(read_data2),
        .read_data(mem_read_data)
    );
    
    // ========== Multiplexers ==========
    
    // ALU Input MUX (ALUSrc)
    assign alu_operand_b = alu_src ? immediate : read_data2;
    
    // Write-back MUX (MemtoReg)
    assign write_data = mem_to_reg ? mem_read_data : alu_result;
    
    // PC Source MUX (Branch/Jump)
    assign pc_next = jump ? jump_target :
                     take_branch ? branch_target :
                     pc_plus_4;

endmodule
```

---

## Verilog MUX Implementations with Detailed Explanations

### 1. ALU Input MUX

```verilog
// ===== MUX 1: ALU Input Source Selection =====
// Selects second operand for ALU
// Control signal: ALUSrc

wire [31:0] alu_operand_b;

assign alu_operand_b = alu_src ? immediate : read_data2;

// Explanation:
// ALUSrc = 0 → Use rs2 (read_data2) for R-Type instructions
// ALUSrc = 1 → Use immediate for I-Type and S-Type instructions
//
// Example Usage:
// - ADD x3, x1, x2  → ALUSrc=0, uses x2 value
// - ADDI x3, x1, 10 → ALUSrc=1, uses immediate 10
// - LW x3, 8(x1)    → ALUSrc=1, uses offset 8
// - SW x2, 8(x1)    → ALUSrc=1, uses offset 8
```

**Alternative 4-to-1 MUX Style** (more explicit):
```verilog
always @(*) begin
    case (alu_src)
        1'b0: alu_operand_b = read_data2;  // R-Type
        1'b1: alu_operand_b = immediate;   // I/S-Type
        default: alu_operand_b = 32'b0;
    endcase
end
```

---

### 2. Write-back MUX

```verilog
// ===== MUX 2: Write-back Data Source Selection =====
// Selects data to write back to register file
// Control signal: MemtoReg

wire [31:0] write_data;

assign write_data = mem_to_reg ? mem_read_data : alu_result;

// Explanation:
// MemtoReg = 0 → Use ALU result (most instructions)
// MemtoReg = 1 → Use memory data (LW instruction)
//
// Example Usage:
// - ADD x3, x1, x2  → MemtoReg=0, writes ALU result
// - ADDI x3, x1, 10 → MemtoReg=0, writes ALU result
// - LW x3, 8(x1)    → MemtoReg=1, writes memory data
// - SW does not write to register (RegWrite=0)
```

**Alternative Case Style**:
```verilog
always @(*) begin
    case (mem_to_reg)
        1'b0: write_data = alu_result;     // Arithmetic/Logic result
        1'b1: write_data = mem_read_data;  // Loaded data from memory
        default: write_data = 32'b0;
    endcase
end
```

---

### 3. PC Source MUX (Most Complex)

```verilog
// ===== MUX 3: Next PC Selection =====
// Selects next program counter value
// Control signals: Branch, Jump, zero_flag

wire [31:0] pc_next;
wire take_branch;

// Branch condition
assign take_branch = branch & zero_flag;

// PC selection (priority: Jump > Branch > Sequential)
assign pc_next = jump ? jump_target :
                 take_branch ? branch_target :
                 pc_plus_4;

// Explanation:
// Jump=1                       → Use jump target (JAL)
// Jump=0, Branch=1, Zero=1     → Use branch target (BEQ taken)
// Jump=0, Branch=1, Zero=0     → Use PC+4 (BEQ not taken)
// Jump=0, Branch=0             → Use PC+4 (normal sequential)
//
// Example Usage:
// - ADD x3, x1, x2    → Jump=0, Branch=0 → PC = PC+4
// - BEQ x1, x2, 12    → Jump=0, Branch=1, Zero=? → PC = branch_target or PC+4
// - JAL x1, 100       → Jump=1 → PC = jump_target
```

**Alternative Nested Ternary Style** (more explicit priority):
```verilog
assign pc_next = (jump == 1'b1) ? jump_target :
                 ((branch == 1'b1 && zero_flag == 1'b1) ? branch_target :
                 pc_plus_4);
```

**Alternative Case/If Style**:
```verilog
always @(*) begin
    if (jump) begin
        pc_next = jump_target;
    end else if (branch && zero_flag) begin
        pc_next = branch_target;
    end else begin
        pc_next = pc_plus_4;
    end
end
```

**Truth Table for PC MUX**:
```
Jump | Branch | Zero | PC Selection
-----|--------|------|---------------
  0  |   0    |  X   | PC + 4 (sequential)
  0  |   1    |  0   | PC + 4 (branch not taken)
  0  |   1    |  1   | branch_target (branch taken)
  1  |   X    |  X   | jump_target (always jump)
```

---

## Complete MUX Module (Optional Parameterized Version)

```verilog
// Generic 2-to-1 MUX (can be reused)
module mux2to1 #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] input0,
    input [WIDTH-1:0] input1,
    input select,
    output [WIDTH-1:0] out
);
    assign out = select ? input1 : input0;
endmodule

// Usage in top-level module:
// ALU Input MUX
mux2to1 #(.WIDTH(32)) alu_mux (
    .input0(read_data2),
    .input1(immediate),
    .select(alu_src),
    .out(alu_operand_b)
);

// Write-back MUX
mux2to1 #(.WIDTH(32)) wb_mux (
    .input0(alu_result),
    .input1(mem_read_data),
    .select(mem_to_reg),
    .out(write_data)
);
```

---

## Critical Path Analysis

The **critical path** is the longest combinational delay in a single cycle. For this datapath, the critical path is typically the **LW instruction**:

```
PC → Instruction Memory → Register File Read → ALU (address calc) 
   → Data Memory Read → Write-back MUX → Register File Write
```

**Critical Path Delays** (approximate):
1. PC → Instruction Memory: ~2ns
2. Instruction Memory access: ~5ns
3. Register File read: ~1ns
4. ALU operation: ~3ns
5. Data Memory access: ~5ns
6. MUX delay: ~0.5ns
7. Register File setup: ~1ns

**Total**: ~17.5ns → **Maximum clock frequency ≈ 57 MHz**

This is why single-cycle processors are slower - the clock must be slow enough for the slowest instruction (LW).

---

## Key Takeaways for Stage 3

1. **Single-cycle means ALL operations in one clock cycle** - fetch, decode, execute, memory, write-back
2. **Clock period is limited by the slowest instruction** (usually LW)
3. **All 10 instructions use the same datapath** - just different control signals
4. **MUXes select paths based on instruction type**
5. **Two separate adders needed**: PC+4 and branch/jump target
6. **Register x0 is hardwired to 0** - implemented in register file
7. **Control signals are pure combinational logic** - based only on opcode/funct fields

**Next**: Move to Stage 4 to design the Control Unit that generates all these signals!

---

### Stage 4: Define Control Signals

**Objective**: Design the control unit that decodes instructions and generates all control signals

The control unit is the "brain" of the processor. It examines the instruction's opcode, funct3, and funct7 fields and generates control signals that orchestrate the datapath.

---

## Control Signal Definitions

### Main Control Signals (from Main Decoder)

1. **RegWrite** (1-bit)
   - **Purpose**: Enable register file write
   - **0**: Do not write to register file (SW, BEQ)
   - **1**: Write result to destination register (ADD, ADDI, LW, JAL)

2. **ALUSrc** (1-bit)
   - **Purpose**: Select second ALU operand
   - **0**: Use rs2 value from register file (R-Type: ADD, SUB, AND, OR, SLT)
   - **1**: Use sign-extended immediate (I-Type: ADDI, LW; S-Type: SW)

3. **MemRead** (1-bit)
   - **Purpose**: Enable data memory read operation
   - **0**: Do not read from memory (all except LW)
   - **1**: Read data from memory (LW)

4. **MemWrite** (1-bit)
   - **Purpose**: Enable data memory write operation
   - **0**: Do not write to memory (all except SW)
   - **1**: Write data to memory (SW)

5. **MemtoReg** (1-bit)
   - **Purpose**: Select write-back data source
   - **0**: Write ALU result to register (ADD, ADDI, JAL)
   - **1**: Write memory data to register (LW)

6. **Branch** (1-bit)
   - **Purpose**: Indicate branch instruction
   - **0**: Not a branch (all except BEQ)
   - **1**: Conditional branch (BEQ) - PC changes if condition met

7. **Jump** (1-bit)
   - **Purpose**: Indicate jump instruction
   - **0**: Not a jump (all except JAL)
   - **1**: Unconditional jump (JAL) - PC always changes

8. **ALUOp** (2-bit)
   - **Purpose**: Specify ALU operation category
   - **00**: ADD (for LW, SW - address calculation)
   - **01**: SUB (for BEQ - comparison)
   - **10**: R-Type operation (determined by funct3/funct7)
   - **11**: I-Type arithmetic (determined by funct3)

---

## Complete Control Signal Table

| Instruction | Opcode  | RegWrite | ALUSrc | MemRead | MemWrite | MemtoReg | Branch | Jump | ALUOp |
|------------|---------|----------|--------|---------|----------|----------|--------|------|-------|
| ADD        | 0110011 | 1        | 0      | 0       | 0        | 0        | 0      | 0    | 10    |
| SUB        | 0110011 | 1        | 0      | 0       | 0        | 0        | 0      | 0    | 10    |
| AND        | 0110011 | 1        | 0      | 0       | 0        | 0        | 0      | 0    | 10    |
| OR         | 0110011 | 1        | 0      | 0       | 0        | 0        | 0      | 0    | 10    |
| SLT        | 0110011 | 1        | 0      | 0       | 0        | 0        | 0      | 0    | 10    |
| ADDI       | 0010011 | 1        | 1      | 0       | 0        | 0        | 0      | 0    | 11    |
| LW         | 0000011 | 1        | 1      | 1       | 0        | 1        | 0      | 0    | 00    |
| SW         | 0100011 | 0        | 1      | 0       | 1        | X        | 0      | 0    | 00    |
| BEQ        | 1100011 | 0        | 0      | 0       | 0        | X        | 1      | 0    | 01    |
| JAL        | 1101111 | 1        | X      | 0       | 0        | 0        | 0      | 1    | XX    |

**Note**: X = Don't Care (value doesn't affect operation)

---

## Two-Level ALU Control Decode

The ALU control uses a **two-level decode** for cleaner logic:

1. **Level 1 - Main Decoder**: Generates `ALUOp[1:0]` based on opcode
2. **Level 2 - ALU Decoder**: Generates `ALUControl[2:0]` based on ALUOp + funct3 + funct7

### Why Two Levels?

- **Simplifies main decoder**: Only needs to distinguish instruction categories
- **Modular design**: ALU control logic is separate and reusable
- **Easier to extend**: Adding new ALU operations only changes ALU decoder

### ALU Control Encoding

```
ALUControl[2:0]:
000 → ADD
001 → SUB
010 → AND
011 → OR
100 → SLT
```

### ALU Decoder Truth Table

| ALUOp | funct7  | funct3 | Instruction | ALUControl | Operation |
|-------|---------|--------|-------------|------------|-----------|
| 00    | xxxxxxx | xxx    | LW/SW       | 000        | ADD       |
| 01    | xxxxxxx | xxx    | BEQ         | 001        | SUB       |
| 10    | 0000000 | 000    | ADD         | 000        | ADD       |
| 10    | 0100000 | 000    | SUB         | 001        | SUB       |
| 10    | 0000000 | 111    | AND         | 010        | AND       |
| 10    | 0000000 | 110    | OR          | 011        | OR        |
| 10    | 0000000 | 010    | SLT         | 100        | SLT       |
| 11    | xxxxxxx | 000    | ADDI        | 000        | ADD       |

---

## Step-by-Step Decode Examples

### Example 1: Decoding ADD x3, x1, x2

**Instruction**: `0x002080B3`

**Step 1**: Extract fields
```
Binary: 0000000_00010_00001_000_00011_0110011
opcode  = 0110011
funct3  = 000
funct7  = 0000000
```

**Step 2**: Main decoder examines opcode
```
opcode = 0110011 → R-Type instruction

Generate main control signals:
RegWrite  = 1  (R-Type writes to register)
ALUSrc    = 0  (R-Type uses rs2, not immediate)
MemRead   = 0  (R-Type doesn't access memory)
MemWrite  = 0  (R-Type doesn't write memory)
MemtoReg  = 0  (Write ALU result, not memory data)
Branch    = 0  (Not a branch)
Jump      = 0  (Not a jump)
ALUOp     = 10 (R-Type operation)
```

**Step 3**: ALU decoder examines ALUOp + funct3 + funct7
```
ALUOp = 10 (R-Type)
funct3 = 000
funct7 = 0000000

→ ALUControl = 000 (ADD operation)
```

**Final Control Signals**:
```
RegWrite = 1, ALUSrc = 0, MemRead = 0, MemWrite = 0,
MemtoReg = 0, Branch = 0, Jump = 0, ALUControl = 000 (ADD)
```

---

### Example 2: Decoding LW x3, 8(x1)

**Instruction**: `0x0080A183`

**Step 1**: Extract fields
```
Binary: 000000001000_00001_010_00011_0000011
opcode  = 0000011
funct3  = 010
imm     = 000000001000 (not used in control decode)
```

**Step 2**: Main decoder examines opcode
```
opcode = 0000011 → I-Type Load

Generate main control signals:
RegWrite  = 1  (LW writes loaded data to register)
ALUSrc    = 1  (Use immediate for address calculation)
MemRead   = 1  (Read from memory)
MemWrite  = 0  (Not a store)
MemtoReg  = 1  (Write memory data, not ALU result)
Branch    = 0  (Not a branch)
Jump      = 0  (Not a jump)
ALUOp     = 00 (Address calculation needs ADD)
```

**Step 3**: ALU decoder examines ALUOp
```
ALUOp = 00 → Always ADD (for address calculation)

→ ALUControl = 000 (ADD)
```

**Final Control Signals**:
```
RegWrite = 1, ALUSrc = 1, MemRead = 1, MemWrite = 0,
MemtoReg = 1, Branch = 0, Jump = 0, ALUControl = 000 (ADD)
```

---

### Example 3: Decoding BEQ x1, x2, 12

**Instruction**: `0x00208663`

**Step 1**: Extract fields
```
Binary: 0_000000_00010_00001_000_1100_0_1100011
opcode  = 1100011
funct3  = 000
```

**Step 2**: Main decoder examines opcode
```
opcode = 1100011 → B-Type Branch

Generate main control signals:
RegWrite  = 0  (Branch doesn't write to register)
ALUSrc    = 0  (Compare two registers, not immediate)
MemRead   = 0  (No memory access)
MemWrite  = 0  (No memory write)
MemtoReg  = X  (Don't care - no write-back)
Branch    = 1  (This IS a branch)
Jump      = 0  (Not a jump)
ALUOp     = 01 (Branch comparison needs SUB)
```

**Step 3**: ALU decoder examines ALUOp
```
ALUOp = 01 → Always SUB (for comparison)

→ ALUControl = 001 (SUB)
```

**Final Control Signals**:
```
RegWrite = 0, ALUSrc = 0, MemRead = 0, MemWrite = 0,
MemtoReg = X, Branch = 1, Jump = 0, ALUControl = 001 (SUB)
```

**Note**: The ALU will compute rs1 - rs2, and set zero_flag if equal.

---

## Complete Control Unit Verilog Module

### Main Control Unit

```verilog
module control_unit (
    // Inputs
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    
    // Main control signals
    output reg reg_write,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg jump,
    
    // ALU control
    output reg [1:0] alu_op,
    output [2:0] alu_control
);

    // ===== Main Decoder =====
    // Generates main control signals based on opcode
    
    always @(*) begin
        // Default values (prevents latches)
        reg_write = 0;
        alu_src = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        branch = 0;
        jump = 0;
        alu_op = 2'b00;
        
        case (opcode)
            // R-Type: ADD, SUB, AND, OR, SLT
            7'b0110011: begin
                reg_write = 1;      // Write to rd
                alu_src = 0;        // ALU operand from rs2
                mem_read = 0;       // No memory read
                mem_write = 0;      // No memory write
                mem_to_reg = 0;     // Write-back from ALU
                branch = 0;         // Not a branch
                jump = 0;           // Not a jump
                alu_op = 2'b10;     // R-Type ALU operation
            end
            
            // I-Type Arithmetic: ADDI
            7'b0010011: begin
                reg_write = 1;      // Write to rd
                alu_src = 1;        // ALU operand from immediate
                mem_read = 0;       // No memory read
                mem_write = 0;      // No memory write
                mem_to_reg = 0;     // Write-back from ALU
                branch = 0;         // Not a branch
                jump = 0;           // Not a jump
                alu_op = 2'b11;     // I-Type arithmetic
            end
            
            // I-Type Load: LW
            7'b0000011: begin
                reg_write = 1;      // Write to rd
                alu_src = 1;        // Address = rs1 + immediate
                mem_read = 1;       // Read from memory
                mem_write = 0;      // No memory write
                mem_to_reg = 1;     // Write-back from memory
                branch = 0;         // Not a branch
                jump = 0;           // Not a jump
                alu_op = 2'b00;     // ADD for address calculation
            end
            
            // S-Type: SW
            7'b0100011: begin
                reg_write = 0;      // No register write
                alu_src = 1;        // Address = rs1 + immediate
                mem_read = 0;       // No memory read
                mem_write = 1;      // Write to memory
                mem_to_reg = 0;     // Don't care (no write-back)
                branch = 0;         // Not a branch
                jump = 0;           // Not a jump
                alu_op = 2'b00;     // ADD for address calculation
            end
            
            // B-Type: BEQ
            7'b1100011: begin
                reg_write = 0;      // No register write
                alu_src = 0;        // Compare rs1 and rs2
                mem_read = 0;       // No memory read
                mem_write = 0;      // No memory write
                mem_to_reg = 0;     // Don't care (no write-back)
                branch = 1;         // This is a branch
                jump = 0;           // Not a jump
                alu_op = 2'b01;     // SUB for comparison
            end
            
            // J-Type: JAL
            7'b1101111: begin
                reg_write = 1;      // Write return address to rd
                alu_src = 0;        // Don't care
                mem_read = 0;       // No memory read
                mem_write = 0;      // No memory write
                mem_to_reg = 0;     // Write PC+4 (handled separately)
                branch = 0;         // Not a branch
                jump = 1;           // This is a jump
                alu_op = 2'b00;     // Don't care
            end
            
            // Default case (shouldn't happen with valid instructions)
            default: begin
                reg_write = 0;
                alu_src = 0;
                mem_read = 0;
                mem_write = 0;
                mem_to_reg = 0;
                branch = 0;
                jump = 0;
                alu_op = 2'b00;
            end
        endcase
    end
    
    // ===== ALU Decoder =====
    // Instantiate ALU control decoder
    alu_decoder alu_dec (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(alu_control)
    );

endmodule
```

---

### ALU Decoder Module

```verilog
module alu_decoder (
    input [1:0] alu_op,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [2:0] alu_control
);

    // ALU Control Encoding:
    // 3'b000 → ADD
    // 3'b001 → SUB
    // 3'b010 → AND
    // 3'b011 → OR
    // 3'b100 → SLT
    
    always @(*) begin
        case (alu_op)
            2'b00: begin
                // LW, SW → Always ADD
                alu_control = 3'b000;  // ADD
            end
            
            2'b01: begin
                // BEQ → Always SUB (for comparison)
                alu_control = 3'b001;  // SUB
            end
            
            2'b10: begin
                // R-Type → Decode based on funct3 and funct7
                case (funct3)
                    3'b000: begin
                        // ADD or SUB (distinguished by funct7[5])
                        if (funct7[5])
                            alu_control = 3'b001;  // SUB
                        else
                            alu_control = 3'b000;  // ADD
                    end
                    
                    3'b111: alu_control = 3'b010;  // AND
                    3'b110: alu_control = 3'b011;  // OR
                    3'b010: alu_control = 3'b100;  // SLT
                    
                    default: alu_control = 3'b000;  // Default to ADD
                endcase
            end
            
            2'b11: begin
                // I-Type arithmetic (ADDI)
                // For this subset, only ADDI (funct3 = 000)
                alu_control = 3'b000;  // ADD
            end
            
            default: alu_control = 3'b000;  // Default to ADD
        endcase
    end

endmodule
```

---

## Alternative: Single-Module Control Unit

If you prefer a single module without separate ALU decoder:

```verilog
module control_unit_single (
    // Inputs
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    
    // Outputs
    output reg reg_write,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg jump,
    output reg [2:0] alu_control
);

    always @(*) begin
        // Default values
        reg_write = 0;
        alu_src = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        branch = 0;
        jump = 0;
        alu_control = 3'b000;
        
        case (opcode)
            7'b0110011: begin  // R-Type
                reg_write = 1;
                alu_src = 0;
                mem_to_reg = 0;
                
                // Decode R-Type ALU operation
                case (funct3)
                    3'b000: alu_control = funct7[5] ? 3'b001 : 3'b000;  // SUB : ADD
                    3'b111: alu_control = 3'b010;  // AND
                    3'b110: alu_control = 3'b011;  // OR
                    3'b010: alu_control = 3'b100;  // SLT
                    default: alu_control = 3'b000;
                endcase
            end
            
            7'b0010011: begin  // I-Type Arithmetic (ADDI)
                reg_write = 1;
                alu_src = 1;
                mem_to_reg = 0;
                alu_control = 3'b000;  // ADD
            end
            
            7'b0000011: begin  // LW
                reg_write = 1;
                alu_src = 1;
                mem_read = 1;
                mem_to_reg = 1;
                alu_control = 3'b000;  // ADD
            end
            
            7'b0100011: begin  // SW
                alu_src = 1;
                mem_write = 1;
                alu_control = 3'b000;  // ADD
            end
            
            7'b1100011: begin  // BEQ
                branch = 1;
                alu_control = 3'b001;  // SUB
            end
            
            7'b1101111: begin  // JAL
                reg_write = 1;
                jump = 1;
            end
        endcase
    end

endmodule
```

---

## Control Unit Testbench

```verilog
module tb_control_unit;
    // Testbench signals
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    
    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire branch;
    wire jump;
    wire [2:0] alu_control;
    
    // Instantiate control unit (choose your implementation)
    control_unit_single uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_control(alu_control)
    );
    
    // Test stimulus
    initial begin
        $display("Testing Control Unit");
        $display("====================\n");
        
        // Test 1: ADD (R-Type)
        $display("Test 1: ADD");
        opcode = 7'b0110011;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #10;
        $display("Opcode=%b, Funct3=%b, Funct7=%b", opcode, funct3, funct7);
        $display("RegWrite=%b, ALUSrc=%b, MemRead=%b, MemWrite=%b", 
                 reg_write, alu_src, mem_read, mem_write);
        $display("MemtoReg=%b, Branch=%b, Jump=%b, ALUControl=%b", 
                 mem_to_reg, branch, jump, alu_control);
        
        if (reg_write==1 && alu_src==0 && mem_read==0 && mem_write==0 &&
            mem_to_reg==0 && branch==0 && jump==0 && alu_control==3'b000)
            $display("PASS: ADD signals correct\n");
        else
            $display("FAIL: ADD signals incorrect\n");
        
        // Test 2: SUB (R-Type)
        $display("Test 2: SUB");
        opcode = 7'b0110011;
        funct3 = 3'b000;
        funct7 = 7'b0100000;  // funct7[5]=1 for SUB
        #10;
        $display("ALUControl=%b (should be 001 for SUB)", alu_control);
        
        if (alu_control == 3'b001)
            $display("PASS: SUB ALU control correct\n");
        else
            $display("FAIL: SUB ALU control incorrect\n");
        
        // Test 3: ADDI (I-Type)
        $display("Test 3: ADDI");
        opcode = 7'b0010011;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #10;
        
        if (reg_write==1 && alu_src==1 && mem_read==0 && mem_write==0 &&
            mem_to_reg==0 && branch==0 && jump==0 && alu_control==3'b000)
            $display("PASS: ADDI signals correct\n");
        else
            $display("FAIL: ADDI signals incorrect\n");
        
        // Test 4: LW (I-Type Load)
        $display("Test 4: LW");
        opcode = 7'b0000011;
        funct3 = 3'b010;
        #10;
        
        if (reg_write==1 && alu_src==1 && mem_read==1 && mem_write==0 &&
            mem_to_reg==1 && branch==0 && jump==0)
            $display("PASS: LW signals correct\n");
        else
            $display("FAIL: LW signals incorrect\n");
        
        // Test 5: SW (S-Type)
        $display("Test 5: SW");
        opcode = 7'b0100011;
        funct3 = 3'b010;
        #10;
        
        if (reg_write==0 && alu_src==1 && mem_read==0 && mem_write==1 &&
            branch==0 && jump==0)
            $display("PASS: SW signals correct\n");
        else
            $display("FAIL: SW signals incorrect\n");
        
        // Test 6: BEQ (B-Type)
        $display("Test 6: BEQ");
        opcode = 7'b1100011;
        funct3 = 3'b000;
        #10;
        
        if (reg_write==0 && alu_src==0 && mem_read==0 && mem_write==0 &&
            branch==1 && jump==0 && alu_control==3'b001)
            $display("PASS: BEQ signals correct\n");
        else
            $display("FAIL: BEQ signals incorrect\n");
        
        // Test 7: JAL (J-Type)
        $display("Test 7: JAL");
        opcode = 7'b1101111;
        #10;
        
        if (reg_write==1 && mem_read==0 && mem_write==0 &&
            branch==0 && jump==1)
            $display("PASS: JAL signals correct\n");
        else
            $display("FAIL: JAL signals incorrect\n");
        
        // Test 8: AND (R-Type)
        $display("Test 8: AND");
        opcode = 7'b0110011;
        funct3 = 3'b111;
        funct7 = 7'b0000000;
        #10;
        
        if (alu_control == 3'b010)
            $display("PASS: AND ALU control correct\n");
        else
            $display("FAIL: AND ALU control incorrect\n");
        
        // Test 9: OR (R-Type)
        $display("Test 9: OR");
        funct3 = 3'b110;
        #10;
        
        if (alu_control == 3'b011)
            $display("PASS: OR ALU control correct\n");
        else
            $display("FAIL: OR ALU control incorrect\n");
        
        // Test 10: SLT (R-Type)
        $display("Test 10: SLT");
        funct3 = 3'b010;
        #10;
        
        if (alu_control == 3'b100)
            $display("PASS: SLT ALU control correct\n");
        else
            $display("FAIL: SLT ALU control incorrect\n");
        
        $display("\n====================");
        $display("All tests completed!");
        $finish;
    end

endmodule
```

---

## Expected Testbench Output

```
Testing Control Unit
====================

Test 1: ADD
Opcode=0110011, Funct3=000, Funct7=0000000
RegWrite=1, ALUSrc=0, MemRead=0, MemWrite=0
MemtoReg=0, Branch=0, Jump=0, ALUControl=000
PASS: ADD signals correct

Test 2: SUB
ALUControl=001 (should be 001 for SUB)
PASS: SUB ALU control correct

Test 3: ADDI
PASS: ADDI signals correct

Test 4: LW
PASS: LW signals correct

Test 5: SW
PASS: SW signals correct

Test 6: BEQ
PASS: BEQ signals correct

Test 7: JAL
PASS: JAL signals correct

Test 8: AND
PASS: AND ALU control correct

Test 9: OR
PASS: OR ALU control correct

Test 10: SLT
PASS: SLT ALU control correct

====================
All tests completed!
```

---

## Key Takeaways for Stage 4

1. **Control unit is pure combinational logic** - no clock, no state
2. **Two-level decode is cleaner** - separates instruction categories from ALU operations
3. **Main decoder focuses on opcode** - generates most control signals
4. **ALU decoder refines operation** - uses ALUOp + funct fields for specific ALU operation
5. **Default values prevent latches** - always initialize signals in always blocks
6. **Testbench verifies every instruction** - catches decode errors early
7. **funct7[5] distinguishes ADD/SUB** - only bit that differs in R-Type arithmetic

**Next**: Move to Stage 5 to start implementing individual modules!

---

### Stage 5: Implement Program Counter

**Objective**: Create PC module with reset and branch/jump support

**Module Interface**:
```verilog
module pc (
    input clk,
    input reset,
    input [31:0] pc_next,
    output reg [31:0] pc_current
);
```

**Key Points**:
- Reset to address 0
- PC normally increments by 4 (word-aligned)
- Support branch target and jump target selection
- Synchronous update on clock edge

**Why increment by 4?**
- RV32I instructions are 32 bits (4 bytes) wide
- Memory is byte-addressable
- Each instruction occupies 4 consecutive bytes

---

### Stage 6: Instruction Memory

**Objective**: Create instruction memory module

**Module Interface**:
```verilog
module instruction_memory (
    input [31:0] address,
    output [31:0] instruction
);
```

**Implementation Notes**:
- Use Verilog memory array: `reg [31:0] memory [0:255]`
- Initialize with `$readmemh` or direct assignment
- Address mapping: PC value directly indexes memory
- Combinational read (no clock required)

**Example Program Storage**:
```
Address  | Instruction
---------|------------
0x0000   | ADD x1, x0, x0
0x0004   | ADDI x2, x1, 10
0x0008   | ADD x3, x1, x2
```

---

### Stage 7: Register File

**Objective**: Create 32-register RV32I register file

**Module Interface**:
```verilog
module register_file (
    input clk,
    input reset,
    input reg_write,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
```

**Requirements**:
- 32 registers (x0-x31)
- **x0 must always be 0** (hardwired)
- 2 read ports (combinational)
- 1 write port (synchronous on positive edge)
- Write only when `reg_write` is high

**Testing**:
- Verify x0 cannot be written
- Test simultaneous read and write
- Test forwarding (read address = write address)

---

### Stage 8: ALU Implementation

**Objective**: Create ALU supporting required operations

**Module Interface**:
```verilog
module alu (
    input [31:0] operand_a,
    input [31:0] operand_b,
    input [2:0] alu_control,
    output reg [31:0] alu_result,
    output zero_flag
);
```

**ALU Operations**:
```verilog
// ALU Control Encoding
3'b000: ADD  (operand_a + operand_b)
3'b001: SUB  (operand_a - operand_b)
3'b010: AND  (operand_a & operand_b)
3'b011: OR   (operand_a | operand_b)
3'b100: SLT  (operand_a < operand_b) signed comparison
```

**Zero Flag**: Set when `alu_result == 0` (used for BEQ)

---

### Stage 9: Immediate Generator

**Objective**: Extract and sign-extend immediates

**Module Interface**:
```verilog
module immediate_generator (
    input [31:0] instruction,
    output reg [31:0] immediate
);
```

**Immediate Extraction**:

**I-Type** (ADDI, LW):
```verilog
immediate = {{20{instruction[31]}}, instruction[31:20]};
```

**S-Type** (SW):
```verilog
immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
```

**B-Type** (BEQ):
```verilog
immediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], 
             instruction[11:8], 1'b0};
```

**J-Type** (JAL):
```verilog
immediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], 
             instruction[30:21], 1'b0};
```

**Note**: B-Type and J-Type immediates have LSB = 0 (word-aligned)

---

### Stage 10: Control Unit / Decoder

**Objective**: Decode instructions and generate control signals

**Module Interface**:
```verilog
module control_unit (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg reg_write,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg jump,
    output reg [2:0] alu_control
);
```

**Decoding Logic**:
1. Inspect opcode to identify instruction type
2. Use funct3 and funct7 to distinguish between similar opcodes
3. Generate all control signals combinationally

**Example**:
- Opcode `0110011` → R-Type
- If funct3 = `000` and funct7 = `0000000` → ADD
- If funct3 = `000` and funct7 = `0100000` → SUB

---

### Stage 11: Build CPU Datapath

**Objective**: Integrate all modules into top-level CPU

**Top-Level Module**:
```verilog
module riscv_single_cycle_cpu (
    input clk,
    input reset
);
```

**Integration Steps**:
1. Instantiate all modules
2. Connect wires according to datapath diagram
3. Implement multiplexers for:
   - ALU input selection
   - Write-back data selection
   - PC next value selection
4. Connect control signals from control unit to datapath

**Verification**:
- Check all module connections
- Ensure no unconnected wires
- Verify control signal routing

---

### Stage 12: Data Memory

**Objective**: Implement memory for LW and SW

**Module Interface**:
```verilog
module data_memory (
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] address,
    input [31:0] write_data,
    output [31:0] read_data
);
```

**Operations**:
- **LW**: `read_data = memory[address >> 2]` (word-aligned)
- **SW**: `memory[address >> 2] = write_data` (on clock edge)

**Notes**:
- Use byte addressing but word-aligned access
- Divide address by 4 to get word index
- Synchronous write, combinational read

---

### Stage 13: Implement Branching

**Objective**: Add BEQ instruction support

**BEQ Operation**:
```
if (rs1 == rs2)
    PC = PC + branch_immediate
else
    PC = PC + 4
```

**Implementation**:
1. ALU subtracts rs1 - rs2
2. Zero flag indicates equality
3. Branch target = PC + sign_extended_immediate
4. PC MUX selects between PC+4 and branch target

**Testing**:
- Test branch taken (equal values)
- Test branch not taken (different values)
- Verify correct target address calculation

---

### Stage 14: Implement JAL

**Objective**: Add jump and link instruction

**JAL Operation**:
```
rd = PC + 4
PC = PC + jump_immediate
```

**Implementation**:
1. Calculate jump target = PC + sign_extended_immediate
2. Store return address (PC+4) in rd
3. Update PC to jump target
4. Add PC source MUX to select jump target

**Key Points**:
- JAL always jumps (unconditional)
- Saves return address for function calls
- Jump offset is sign-extended and added to current PC

---

### Stage 15: Complete Top-Level CPU

**Objective**: Final integration and clean module organization

**File Structure**:
```
project/
├── pc.v
├── instruction_memory.v
├── register_file.v
├── alu.v
├── immediate_generator.v
├── control_unit.v
├── data_memory.v
├── riscv_cpu.v (top-level)
└── tb_riscv_cpu.v (testbench)
```

**Final Checks**:
- All modules properly instantiated
- Clean, commented code
- Consistent naming conventions
- No combinational loops
- Proper reset handling

---

### Stage 16: Instruction Encoding

**Objective**: Learn assembly to machine code conversion

**Encoding Example - ADD x3, x1, x2**:

```
Instruction: ADD x3, x1, x2

Fields:
  funct7 = 0000000 (7 bits)
  rs2    = 00010   (5 bits) = x2
  rs1    = 00001   (5 bits) = x1
  funct3 = 000     (3 bits)
  rd     = 00011   (5 bits) = x3
  opcode = 0110011 (7 bits)

Binary:  0000000 00010 00001 000 00011 0110011
Grouped: 0000000_00010_00001_000_00011_0110011

Hexadecimal: 0x002080B3
```

**Practice encoding each instruction type**!

---

### Stage 17: Create Test Programs

**Objective**: Write programs to verify processor functionality

**Test Program 1 - Arithmetic**:
```assembly
# Test ADD, SUB, AND, OR, SLT
ADDI x1, x0, 5      # x1 = 5
ADDI x2, x0, 3      # x2 = 3
ADD  x3, x1, x2     # x3 = 8
SUB  x4, x1, x2     # x4 = 2
AND  x5, x1, x2     # x5 = 1
OR   x6, x1, x2     # x6 = 7
SLT  x7, x2, x1     # x7 = 1 (3 < 5)
```

**Expected Results**:
- x1 = 5
- x2 = 3
- x3 = 8
- x4 = 2
- x5 = 1
- x6 = 7
- x7 = 1

**Test Program 2 - Memory**:
```assembly
# Test SW and LW
ADDI x1, x0, 100    # x1 = 100 (address)
ADDI x2, x0, 42     # x2 = 42 (data)
SW   x2, 0(x1)      # Mem[100] = 42
LW   x3, 0(x1)      # x3 = Mem[100] = 42
```

**Test Program 3 - Branch**:
```assembly
# Test BEQ
ADDI x1, x0, 5
ADDI x2, x0, 5
BEQ  x1, x2, target  # Should branch
ADDI x3, x0, 1       # Should be skipped
target:
ADDI x4, x0, 2       # Should execute
```

**Test Program 4 - JAL**:
```assembly
# Test JAL
JAL  x1, function    # Jump to function, x1 = PC+4
ADDI x2, x0, 99      # Should be skipped
function:
ADDI x3, x0, 100     # Should execute
```

---

### Stage 18: Self-Checking Testbench

**Objective**: Create automated verification

**Testbench Structure**:
```verilog
module tb_riscv_cpu;
    reg clk;
    reg reset;
    
    // Instantiate CPU
    riscv_single_cycle_cpu cpu (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test sequence
    initial begin
        reset = 1;
        #10 reset = 0;
        
        // Wait for instructions to execute
        #200;
        
        // Check register values
        if (cpu.register_file.registers[3] == 32'd8)
            $display("PASS: x3 = 8");
        else
            $display("FAIL: x3 = %d (expected 8)", 
                     cpu.register_file.registers[3]);
        
        $finish;
    end
endmodule
```

---

### Stage 19: Simulation & Debugging

**Objective**: Learn to simulate and debug with waveforms

**Using Icarus Verilog + GTKWave**:

```bash
# Compile
iverilog -o cpu_sim riscv_cpu.v tb_riscv_cpu.v

# Run simulation
vvp cpu_sim

# View waveforms
gtkwave cpu_waveform.vcd
```

**Waveform Analysis Checklist**:
- [ ] PC increments correctly (0, 4, 8, 12, ...)
- [ ] Instructions fetched match expected program
- [ ] Register read addresses correct
- [ ] ALU operations produce correct results
- [ ] Control signals match instruction type
- [ ] Memory read/write at correct addresses
- [ ] Register write-back occurs correctly
- [ ] Branch/jump target calculation correct

**Common Debugging Issues**:
1. **PC not incrementing**: Check PC+4 adder and MUX
2. **Wrong ALU result**: Verify ALU control signals
3. **Register x0 not zero**: Check register file x0 logic
4. **Memory address errors**: Verify word alignment (divide by 4)
5. **Immediate sign extension**: Check immediate generator

---

### Stage 20: Verification

**Objective**: Complete instruction coverage

**Verification Checklist**:

For each instruction, verify:
- [ ] **Instruction Fetch**: Correct instruction read from memory
- [ ] **Decode**: Control signals generated correctly
- [ ] **Register Read**: Correct registers read (rs1, rs2)
- [ ] **Execute**: ALU/memory operation performs correctly
- [ ] **Memory Access**: (LW/SW only) Data read/written correctly
- [ ] **Write Back**: Result written to correct register
- [ ] **PC Update**: PC advances correctly

**Instruction Coverage Table**:

| Instruction | Fetch | Decode | Execute | Memory | Write-Back | PC Update | Status |
|------------|-------|--------|---------|--------|------------|-----------|--------|
| ADD        | ☐     | ☐      | ☐       | N/A    | ☐          | ☐         | ☐      |
| SUB        | ☐     | ☐      | ☐       | N/A    | ☐          | ☐         | ☐      |
| AND        | ☐     | ☐      | ☐       | N/A    | ☐          | ☐         | ☐      |
| OR         | ☐     | ☐      | ☐       | N/A    | ☐          | ☐         | ☐      |
| SLT        | ☐     | ☐      | ☐       | N/A    | ☐          | ☐         | ☐      |
| ADDI       | ☐     | ☐      | ☐       | N/A    | ☐          | ☐         | ☐      |
| LW         | ☐     | ☐      | ☐       | ☐      | ☐          | ☐         | ☐      |
| SW         | ☐     | ☐      | ☐       | ☐      | N/A        | ☐         | ☐      |
| BEQ        | ☐     | ☐      | ☐       | N/A    | N/A        | ☐         | ☐      |
| JAL        | ☐     | ☐      | ☐       | N/A    | ☐          | ☐         | ☐      |

---

### Stage 21: Performance Analysis

**Objective**: Analyze single-cycle processor limitations

**Key Metrics**:

**Clock Period**:
- Determined by the **critical path** (longest combinational delay)
- Critical path in single-cycle: Instruction fetch → Register read → ALU → Memory access → Write back
- All instructions take the same clock period (slowest instruction)

**CPI (Cycles Per Instruction)**:
- Single-cycle processor: **CPI = 1**
- Every instruction completes in exactly one clock cycle

**Performance Formula**:
```
Execution Time = Instructions × CPI × Clock Period
```

**Limitations**:
1. **Clock period limited by slowest instruction** (usually LW)
2. **Hardware underutilization**: Not all components used every cycle
3. **No instruction overlap**: Fetch waits while previous instruction completes

**Single-Cycle vs Pipelined**:
- Single-cycle: Simple, low CPI=1, but slow clock
- Pipelined: Complex, CPI→1 (with hazards), but fast clock
- Pipelined can achieve 4-5× performance improvement

---

### Stage 22: Project Report

**Objective**: Document complete project

**Report Structure**:

1. **Title Page**
   - Project title
   - Your name
   - Institution and date

2. **Abstract** (150-200 words)
   - Brief project overview
   - Key achievements
   - Results summary

3. **Introduction**
   - Motivation for RISC-V
   - Project objectives
   - Scope definition

4. **Background**
   - RISC architecture principles
   - RISC-V ISA overview
   - RV32I instruction subset

5. **System Architecture**
   - Single-cycle processor explanation
   - Datapath diagram with labels
   - Component descriptions

6. **Control Unit Design**
   - Control signal definitions
   - Control truth table
   - Decoding logic explanation

7. **Module Implementation**
   - PC, instruction memory, register file
   - ALU, immediate generator
   - Data memory
   - Control unit
   - Include code snippets

8. **Instruction Encoding**
   - Format explanations (R, I, S, B, J)
   - Encoding examples

9. **Simulation Results**
   - Test programs
   - Waveform screenshots
   - Verification results

10. **Performance Analysis**
    - Critical path analysis
    - CPI calculation
    - Clock period estimation

11. **Limitations and Challenges**
    - What was difficult
    - What could be improved

12. **Future Scope**
    - Pipelining
    - Additional instructions
    - Cache memory

13. **Conclusion**
    - Summary of achievements
    - Learning outcomes

14. **References**
    - RISC-V specification
    - Textbooks
    - Online resources

---

### Stage 23: Project Presentation

**Objective**: Prepare presentation and viva questions

**Presentation Structure** (12-15 slides):

1. **Title Slide**
2. **Problem Statement** - Why build a processor?
3. **Why RISC-V?** - Open-source, simple, modular
4. **Project Objectives** - Design goals and scope
5. **Architecture Overview** - Datapath diagram
6. **Instruction Set** - 10 instructions table
7. **Key Modules** - PC, Register File, ALU, etc.
8. **Control Unit** - Control signals table
9. **Instruction Examples** - Walk through ADD and LW
10. **Simulation Results** - Waveforms, test outputs
11. **Verification** - Testing methodology
12. **Challenges** - What was difficult
13. **Future Improvements** - Pipelining, more instructions
14. **Conclusion** - Achievements and learnings
15. **Q&A**

**Common Viva Questions & Answers**:

**Q: Why did you choose RISC-V over x86 or ARM?**
A: RISC-V is open-source, has a simpler instruction set, is modular, and is designed for educational purposes. It's free from licensing restrictions.

**Q: Why implement a single-cycle processor instead of pipelined?**
A: Single-cycle is simpler to understand and debug. It has no hazards to handle. It's a foundation before learning pipelining.

**Q: Why does PC increment by 4?**
A: RV32I instructions are 32 bits (4 bytes) wide. Memory is byte-addressable, so we increment by 4 to reach the next instruction.

**Q: What is the difference between opcode, funct3, and funct7?**
A: Opcode (7 bits) identifies the instruction type (R, I, S, B, J). funct3 (3 bits) and funct7 (7 bits) further distinguish instructions with the same opcode (e.g., ADD vs SUB both have opcode 0110011).

**Q: Why is register x0 always zero?**
A: RISC-V specification requires x0 to be hardwired to 0. This provides a constant zero value and makes some operations simpler (e.g., MOV can be done with ADDI x1, x0, value).

**Q: How does BEQ determine if two values are equal?**
A: The ALU subtracts rs1 - rs2. If the result is zero (zero_flag = 1), the values are equal and the branch is taken.

**Q: What does JAL do?**
A: JAL (Jump And Link) does two things: (1) stores the return address (PC+4) in register rd, and (2) jumps to the target address (PC + immediate).

**Q: What is the critical path in your processor?**
A: The critical path is the LW instruction: PC → Instruction Memory → Control Unit → Register File → ALU → Data Memory → Write Back. This determines the minimum clock period.

**Q: Why is single-cycle slower than pipelined in terms of clock frequency?**
A: Single-cycle must complete the entire instruction in one cycle, so the clock period is limited by the slowest instruction (LW). Pipelining breaks execution into stages, allowing a faster clock.

**Q: How would you extend this to support more instructions?**
A: Add decoding logic in the control unit for new opcodes/funct fields. Modify the ALU if new operations are needed. Update the immediate generator for new formats. Add test programs.

**Q: What challenges did you face?**
A: [Personalize: Mention debugging issues, timing, understanding instruction encoding, waveform analysis, etc.]

---

## 📚 Resources

### Official Documentation
- **RISC-V ISA Specification**: Official RV32I instruction set architecture
- **RISC-V Green Card**: Quick reference for encodings

### Simulation Tools
- **Icarus Verilog + GTKWave**: Free, open-source Verilog simulator
- **ModelSim/Questa**: Professional HDL simulation (academic licenses available)
- **Xilinx Vivado**: FPGA development suite with simulation

### Online Resources
- RISC-V Foundation website
- "Computer Organization and Design RISC-V Edition" by Patterson & Hennessy
- Online Verilog tutorials and RISC-V guides

---

## 🎯 Quick Reference

### Control Signal Quick Reference

```
RegWrite: 1 = Write to register file
ALUSrc:   0 = Use rs2, 1 = Use immediate
MemRead:  1 = Read from data memory
MemWrite: 1 = Write to data memory
MemtoReg: 0 = ALU result, 1 = Memory data
Branch:   1 = Branch instruction
Jump:     1 = Jump instruction
```

### ALU Operation Encoding

```
3'b000: ADD
3'b001: SUB
3'b010: AND
3'b011: OR
3'b100: SLT
```

### Register Naming Convention

```
x0  = zero (always 0)
x1  = ra (return address)
x2  = sp (stack pointer)
x3-x31 = general purpose
```

---

## ✅ Final Checklist

Before submitting your project, ensure:

- [ ] All 10 instructions implemented and tested
- [ ] Register x0 hardwired to zero
- [ ] PC increments by 4 correctly
- [ ] Branch and jump work correctly
- [ ] Memory operations (LW/SW) functional
- [ ] Self-checking testbench passes all tests
- [ ] Waveforms captured and analyzed
- [ ] Code well-commented and organized
- [ ] Report completed with all sections
- [ ] Presentation prepared with all slides
- [ ] Viva questions practiced

---

**Good luck with your RISC-V processor project!** 🚀

Remember: Test each module independently before integration, and understand each stage before moving to the next.
