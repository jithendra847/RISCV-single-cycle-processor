// ============================================================================
// Module Name: ALU (Arithmetic Logic Unit)
// Description: Performs arithmetic and logical operations on two 32-bit operands.
//              Also outputs a 'zero' flag used by branch instructions.
// ============================================================================

`timescale 1ns / 1ps

module ALU (
    input  wire [31:0] a,             // First 32-bit operand (usually from rs1)
    input  wire [31:0] b,             // Second 32-bit operand (from rs2 or immediate)
    input  wire [3:0]  alu_control,   // 4-bit operation select code from ALU Control
    output reg  [31:0] result,        // 32-bit calculation result
    output wire        zero           // 1 if result is zero (used for BEQ/branch)
);

    // Zero flag: jab result zero hoga to zero flag 1 ho jayega
    assign zero = (result == 32'h00000000);

    always @(*) begin
        case (alu_control)
            4'b0000: result = a & b;                               // Bitwise AND
            4'b0001: result = a | b;                               // Bitwise OR
            4'b0010: result = a + b;                               // Addition
            4'b0110: result = a - b;                               // Subtraction
            4'b0111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT (Set Less Than - signed)
            4'b1000: result = a ^ b;                               // Bitwise XOR
            4'b0011: result = a << b[4:0];                         // SLL (Shift Left Logical)
            4'b0101: result = a >> b[4:0];                         // SRL (Shift Right Logical)
            default: result = 32'h00000000;
        endcase
    end

endmodule
