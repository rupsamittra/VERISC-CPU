I am a beginner working on a Verilog HDL processor project.

My project is:

**“Design, Implementation and Functional Verification of a 32-bit Single-Cycle RISC-V Processor in Verilog HDL”**

I want to implement a small, functional subset of **RISC-V RV32I** rather than creating a completely custom instruction set.

### Instructions I want to implement

Use exactly this initial instruction subset:

**R-type**
- ADD
- SUB
- AND
- OR
- SLT

**I-type**
- ADDI
- LW

**S-type**
- SW

**B-type**
- BEQ

**J-type**
- JAL

Use the **standard RV32I instruction encodings**. Do not invent opcodes, funct3, funct7 values, or instruction formats.

---

# HOW I WANT YOU TO GUIDE ME

Treat me as a beginner.

Do NOT assume I already understand processor architecture, Verilog, RISC-V encoding, datapaths, or control units.

Guide me through the project **from absolute beginning to final simulation**, one stage at a time.

Do not dump the entire implementation at once.

For every stage:

1. Explain what we are building.
2. Explain why we need it.
3. Explain the concept in simple language.
4. Show the required inputs and outputs.
5. Give the design/logic.
6. Then give the Verilog code.
7. Explain the code line by line.
8. Give a small example.
9. Give a testbench if that module needs testing.
10. Tell me exactly what output/waveform I should expect.
11. Help me debug errors before moving to the next stage.

Only move to the next stage after the current stage is understood and working.

---

# PROJECT STAGES

Follow this overall order.

## STAGE 1 — Understand the architecture

Explain:

- What a CPU is
- What RISC means
- What RISC-V is
- What RV32I means
- What an ISA is
- What an instruction is
- What a single-cycle processor means
- What a datapath is
- What a control unit does
- What registers are
- What the ALU does
- What the Program Counter (PC) does
- What instruction memory does
- What data memory does
- What an immediate is
- What a multiplexer does

Then explain the overall processor architecture.

The basic flow should be:

**PC → Instruction Memory → Instruction → Decoder/Control Unit → Register File → ALU → Data Memory → Write Back → Register File**

Also include:

- Immediate Generator
- Branch logic
- Jump logic
- PC selection logic
- Required multiplexers

Explain how all blocks connect.

---

# STAGE 2 — Finalize the ISA

Create a complete table for:

ADD, SUB, AND, OR, SLT, ADDI, LW, SW, BEQ, JAL.

For each instruction provide:

- Instruction name
- Format
- Operation
- Opcode
- funct3
- funct7 if applicable
- rs1
- rs2
- rd
- immediate
- instruction length

Use the **official RV32I encoding**.

Explain R-type, I-type, S-type, B-type and J-type formats visually.

For example, explain the R-type fields:

31:25 | 24:20 | 19:15 | 14:12 | 11:7 | 6:0  
funct7 | rs2 | rs1 | funct3 | rd | opcode

Do the same for the other formats.

---

# STAGE 3 — Design the datapath

Create a complete single-cycle datapath for these instructions.

Show:

- PC
- Instruction Memory
- Instruction
- Control Unit
- Register File
- Immediate Generator
- ALU
- Data Memory
- Write-back MUX
- PC+4 logic
- Branch target logic
- Jump target logic
- MUXes
- Control signals

Explain exactly where every wire goes.

Then explain the datapath separately for:

1. ADD
2. ADDI
3. LW
4. SW
5. BEQ
6. JAL

Use simple examples such as:

ADD x3, x1, x2

Explain exactly what happens from fetching the instruction until the next PC value.

---

# STAGE 4 — Define control signals

Create the control unit design.

Use signals such as:

- RegWrite
- ALUSrc
- MemRead
- MemWrite
- MemtoReg
- Branch
- Jump
- ALUControl

Create a complete control table for all 10 instructions.

Explain every control signal in simple terms.

Then explain how the opcode and funct fields are decoded.

---

# STAGE 5 — Implement the Program Counter

Now start coding.

Create a PC module.

Requirements:

- Reset support
- Initial PC = 0
- PC normally increments by 4
- Ability to select branch target
- Ability to select jump target

Explain why RV32I normally increments by 4.

Give:

- PC Verilog module
- Testbench
- Expected waveform
- Simulation instructions
- Debugging steps

Do not integrate everything yet.

---

# STAGE 6 — Instruction Memory

Create an instruction memory module.

Explain:

- What instruction memory is
- How addresses work
- How instructions are stored
- How the PC accesses an instruction

Use a simple synthesizable Verilog implementation.

Initially allow instructions to be loaded from a Verilog memory array or suitable initialization method.

Show an example program.

Explain how:

PC = 0 → instruction 0  
PC = 4 → instruction 1  
PC = 8 → instruction 2

etc.

Test it independently.

---

# STAGE 7 — Register File

Create a 32-register RV32I register file.

Requirements:

- x0–x31
- x0 must always contain zero
- Two read ports
- One write port
- Synchronous write
- Combinational reads if appropriate for the single-cycle design

Explain:

- rs1
- rs2
- rd

Use an example such as:

ADD x3, x1, x2

Show exactly which registers are read and written.

Create a testbench.

Verify that x0 cannot be changed.

---

# STAGE 8 — ALU

Create an ALU supporting:

- ADD
- SUB
- AND
- OR
- SLT

Include appropriate control codes.

Explain each operation.

For SLT, explain signed comparison correctly.

Create an ALU testbench covering every operation.

Show expected outputs.

---

# STAGE 9 — Immediate Generator

Create an immediate-generation module for:

- I-type
- S-type
- B-type
- J-type

Explain how immediate bits are arranged differently in each format.

Pay particular attention to:

- Sign extension
- B-type immediate reconstruction
- J-type immediate reconstruction

Show examples for:

ADDI  
LW  
SW  
BEQ  
JAL

Then provide Verilog code and testbench.

---

# STAGE 10 — Control Unit / Instruction Decoder

Create the instruction decoder.

It should inspect:

- opcode
- funct3
- funct7

and generate the required control signals.

Support exactly:

ADD
SUB
AND
OR
SLT
ADDI
LW
SW
BEQ
JAL

Explain how the decoder distinguishes instructions that have the same opcode but different funct fields.

Test every instruction.

---

# STAGE 11 — Build the CPU Datapath

Now integrate:

- PC
- Instruction Memory
- Control Unit
- Register File
- Immediate Generator
- ALU
- Data Memory
- Write-back logic
- Branch logic
- Jump logic

Create a top-level module such as:

`riscv_single_cycle_cpu`

Explain every connection.

Do not add unnecessary features.

Keep the architecture simple and understandable.

---

# STAGE 12 — Implement Data Memory

Create data memory supporting:

- LW
- SW

Explain:

LW:
`rd = Memory[rs1 + immediate]`

SW:
`Memory[rs1 + immediate] = rs2`

Use word-aligned addresses.

Explain the difference between instruction memory and data memory.

Test both load and store.

---

# STAGE 13 — Implement Branching

Implement:

**BEQ**

Explain:

`if (rs1 == rs2)`

then:

`PC = PC + branch_immediate`

otherwise:

`PC = PC + 4`

Explain why the branch immediate is encoded in unusual positions.

Test both:

- branch taken
- branch not taken

Show expected PC values.

---

# STAGE 14 — Implement JAL

Implement:

**JAL rd, immediate**

Explain that JAL does two things:

1. Stores PC+4 into rd.
2. Changes PC to the jump target.

Verify both behaviors.

Create a test program specifically for JAL.

---

# STAGE 15 — Create the Complete Top-Level CPU

Combine everything into one working processor.

Show the complete architecture again.

Provide clean Verilog modules such as:

- `pc.v`
- `instruction_memory.v`
- `register_file.v`
- `alu.v`
- `immediate_generator.v`
- `control_unit.v`
- `data_memory.v`
- `riscv_cpu.v`
- `tb_riscv_cpu.v`

Keep the modules beginner-friendly.

Avoid unnecessarily complicated SystemVerilog features unless absolutely required.

---

# STAGE 16 — Instruction Encoding / Machine Code

Teach me how assembly instructions become 32-bit machine instructions.

For example:

`ADD x3, x1, x2`

Show:

- opcode
- funct3
- funct7
- rd
- rs1
- rs2

Then construct the complete 32-bit binary instruction.

Do this for representative instructions from every format.

Explain hexadecimal representation too.

---

# STAGE 17 — Create Test Programs

Create small programs to verify the processor.

At minimum include:

### Program 1 — Arithmetic

Test:

ADD  
SUB  
AND  
OR  
SLT

### Program 2 — Immediate

Test:

ADDI

### Program 3 — Memory

Test:

SW  
LW

### Program 4 — Branch

Test:

BEQ

### Program 5 — Jump

Test:

JAL

### Program 6 — Combined program

Use several instructions together to perform a meaningful computation.

For every program provide:

- Assembly
- Machine code
- Expected register values
- Expected memory values
- Expected PC behavior

---

# STAGE 18 — Self-Checking Testbench

Create a proper testbench that automatically checks results.

Do not rely only on looking at waveforms.

The testbench should report things such as:

PASS
FAIL

For example:

`PASS: x3 = 15`

`PASS: Memory[100] = 25`

Explain how a self-checking testbench works.

---

# STAGE 19 — Simulation and Debugging

Teach me how to simulate the complete CPU using a simulator such as:

- Icarus Verilog + GTKWave
or
- ModelSim/Questa
or
- Vivado if appropriate.

Explain:

- Compilation
- Running simulation
- Adding signals
- Reading waveforms
- Checking PC
- Checking instruction
- Checking register values
- Checking ALU output
- Checking memory
- Checking control signals

Give a debugging checklist for common errors.

---

# STAGE 20 — Verification

Create a verification checklist for every instruction.

For each instruction verify:

- Instruction fetch
- Decode
- Register read
- ALU operation
- Memory operation if applicable
- Register write
- PC update

Create a final instruction coverage table.

---

# STAGE 21 — Performance / Design Analysis

Explain the limitations of a single-cycle processor.

Discuss:

- Clock period
- Critical path
- CPI
- Why every instruction takes one clock cycle
- Why memory access can determine the clock period
- Difference between single-cycle and pipelined processors

Keep this appropriate for a student project.

---

# STAGE 22 — Project Report

After the processor is working, help me prepare the report.

Include:

1. Title
2. Abstract
3. Introduction
4. Problem Statement
5. Objectives
6. RISC-V Architecture
7. RV32I Instruction Subset
8. System Architecture
9. Datapath
10. Control Unit
11. Individual Modules
12. Instruction Encoding
13. Verilog Implementation
14. Simulation Results
15. Verification
16. Results and Discussion
17. Limitations
18. Future Scope
19. Conclusion
20. References

Explain what should go into each section.

---

# STAGE 23 — Project Presentation

Create a presentation structure explaining:

- Problem
- Why RISC-V
- Architecture
- Instruction subset
- Datapath
- Control unit
- Verilog implementation
- Simulation
- Results
- Limitations
- Future improvements

Also prepare likely viva questions and simple answers.

Include questions such as:

- Why RISC-V?
- Why RV32I?
- Why single-cycle?
- Why does PC increment by 4?
- What is an opcode?
- What is funct3?
- What is funct7?
- What is the difference between LW and SW?
- How does BEQ work?
- What does JAL do?
- Why is x0 always zero?
- What is the critical path?
- Why is a single-cycle processor slower than a pipelined processor in clock frequency?

---

# IMPORTANT RULES

1. Use **standard RV32I encoding**.
2. Do not invent instruction encodings.
3. Keep the implementation beginner-friendly.
4. Do not add instructions outside the selected subset unless I specifically ask.
5. Do not introduce pipelining unless I ask about future scope.
6. Do not skip explanations just because the code is simple.
7. Explain Verilog syntax when introducing it.
8. Keep each implementation modular.
9. Test each module before integrating it.
10. After integration, test the processor instruction-by-instruction.
11. Give expected outputs so I can compare them with my simulation.
12. If my code produces an error, debug my code rather than immediately replacing the entire project.
13. Preserve working portions of the project when fixing bugs.
14. Clearly identify exactly what file needs to be changed.
15. Tell me exactly where to place each piece of code.
16. Never assume a signal or module exists unless we have already created it.
17. When giving code, make sure all modules are compatible with each other.
18. Keep naming consistent throughout the entire project.
19. Do not move to a later stage until the current stage is working.
20. If something is optional, clearly label it as OPTIONAL.

### Most important:

I am a beginner, so **teach me while building the processor**.

Do not simply give me a huge block of code and say it is complete.

Build the processor incrementally and help me understand how:

**Assembly instruction → Machine code → Instruction memory → Decoder → Register File → ALU/Data Memory → Write Back → PC update**

works inside the processor.

At the end, I should have:

- A working RV32I subset processor
- Modular Verilog source files
- Testbenches
- Test programs
- Simulation waveforms
- Verification results
- A report
- A presentation
- A clear understanding of how my processor works.