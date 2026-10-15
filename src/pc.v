// ============================================================
// Module : pc
// Project: VERISC — 32-bit Single-Cycle RISC-V Processor
// Stage  : 5 — Program Counter
// ============================================================
// What this does:
//   Holds the address of the instruction currently being fetched.
//   On every rising clock edge it moves to pc_next.
//   On reset it goes back to address 0.
//
// Why pc_next comes from outside:
//   This module does NOT decide what the next PC is.
//   The top-level CPU wires up a MUX that picks between
//   PC+4, branch target, or jump target, and feeds the
//   result here as pc_next.  Keeping that logic outside
//   makes each module simple and testable on its own.
// ============================================================

module pc (
    input  wire        clk,        // clock — rising edge triggers update
    input  wire        reset,      // active-high synchronous reset
    input  wire [31:0] pc_next,    // next address (from top-level MUX)
    output reg  [31:0] pc_current  // current address (goes to Instruction Memory)
);

    // On every rising clock edge:
    //   - if reset is high  → go back to address 0
    //   - otherwise         → load pc_next
    always @(posedge clk) begin
        if (reset)
            pc_current <= 32'h0000_0000;  // start execution at address 0
        else
            pc_current <= pc_next;        // advance to next instruction
    end

endmodule
