module register_file (
    input  wire        clk,
    input  wire        reset,
    input  wire        reg_write,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    // 32 general-purpose registers, x0-x31
    reg [31:0] regs [0:31];

    // ── Combinational reads ─────────────────────────────────────
    // x0 is hardwired to 0 no matter what is stored in regs[0]
    assign read_data1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];

    // ── Synchronous write ────────────────────────────────────────
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end
        else if (reg_write && rd != 5'd0) begin
            // never actually write to x0, even if rd = 0 and reg_write = 1
            regs[rd] <= write_data;
        end
    end

endmodule