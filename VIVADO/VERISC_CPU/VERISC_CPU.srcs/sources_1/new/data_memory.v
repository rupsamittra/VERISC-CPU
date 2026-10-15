module data_memory (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] address,      // byte address (from ALU result)
    input  wire [31:0] write_data,   // value to store (rs2 for SW)
    output wire [31:0] read_data
);

    // 64 words x 32 bits = 256 bytes of data memory
    reg [31:0] memory [0:63];

    // Word index: drop the bottom 2 bits (byte -> word address).
    // Only 6 index bits are used, so addresses wrap after 0xFF.
    wire [5:0] word_index = address[7:2];

    // Start with all zeros so reads never return X in simulation
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1)
            memory[i] = 32'b0;
    end

    // Synchronous write (SW)
    always @(posedge clk) begin
        if (mem_write)
            memory[word_index] <= write_data;
    end

    // Combinational read (LW); returns 0 when not reading
    assign read_data = mem_read ? memory[word_index] : 32'b0;

endmodule