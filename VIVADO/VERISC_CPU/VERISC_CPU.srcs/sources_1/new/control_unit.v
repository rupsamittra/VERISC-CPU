module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg        alu_src,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        branch,
    output reg        jump,
    output reg [2:0]  alu_control
);

    // Internal ALUOp (level 1 output)
    //   00 = ADD (LW/SW)   01 = SUB (BEQ)
    //   10 = R-type        11 = I-type arithmetic (ADDI)
    reg [1:0] alu_op;

    // ── Level 1: Main decoder (opcode -> control signals + ALUOp) ──
    always @(*) begin
        // Safe defaults: do nothing
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)
            7'b0110011: begin               // R-type: ADD SUB AND OR SLT
                reg_write = 1'b1;
                alu_op    = 2'b10;
            end
            7'b0010011: begin               // ADDI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b0000011: begin               // LW
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00;
            end
            7'b0100011: begin               // SW
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00;
            end
            7'b1100011: begin               // BEQ
                branch = 1'b1;
                alu_op = 2'b01;
            end
            7'b1101111: begin               // JAL
                reg_write = 1'b1;
                jump      = 1'b1;
            end
            default: ;                      // unknown opcode -> all zeros
        endcase
    end

    // ── Level 2: ALU decoder (ALUOp + funct3 + funct7 -> alu_control) ──
    always @(*) begin
        case (alu_op)
            2'b00:   alu_control = 3'b000;              // ADD
            2'b01:   alu_control = 3'b001;              // SUB
            2'b10: begin                                // R-type
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_control = 3'b000;  // ADD
                    {7'b0100000, 3'b000}: alu_control = 3'b001;  // SUB
                    {7'b0000000, 3'b111}: alu_control = 3'b010;  // AND
                    {7'b0000000, 3'b110}: alu_control = 3'b011;  // OR
                    {7'b0000000, 3'b010}: alu_control = 3'b100;  // SLT
                    default:              alu_control = 3'b000;
                endcase
            end
            2'b11:   alu_control = 3'b000;              // ADDI -> ADD
            default: alu_control = 3'b000;
        endcase
    end

endmodule