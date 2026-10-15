module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [2:0]  alu_control,
    output reg  [31:0] alu_result,
    output wire        zero_flag
);

    // Combinational ALU: result depends only on the inputs
    always @(*) begin
        case (alu_control)
            3'b000:  alu_result = operand_a + operand_b;   // ADD
            3'b001:  alu_result = operand_a - operand_b;   // SUB
            3'b010:  alu_result = operand_a & operand_b;   // AND
            3'b011:  alu_result = operand_a | operand_b;   // OR
            3'b100:  alu_result = ($signed(operand_a) < $signed(operand_b))
                                  ? 32'd1 : 32'd0;         // SLT (signed)
            default: alu_result = 32'd0;                   // undefined codes -> 0
        endcase
    end

    // Zero flag: high when result is 0 (used by BEQ)
    assign zero_flag = (alu_result == 32'd0);

endmodule