// ============================================================================
// Module Name: ALU_Control
// Description: Decodes ALUOp from Control Unit along with funct3 and funct7[5]
//              from the instruction to generate a 4-bit ALU control code.
// ============================================================================

`timescale 1ns / 1ps

module ALU_Control (
    input  wire [1:0] alu_op,        // 2-bit ALU operation signal from Control Unit
    input  wire [2:0] funct3,        // instruction[14:12]
    input  wire       funct7_5,      // instruction[30] (used to differentiate ADD/SUB and SRL/SRA)
    output reg  [3:0] alu_control    // 4-bit operation code fed into ALU
);

    // ALU Operation Codes:
    // 4'b0000: AND
    // 4'b0001: OR
    // 4'b0010: ADD
    // 4'b0110: SUB
    // 4'b0111: SLT (Set Less Than)
    // 4'b1000: XOR
    // 4'b0011: SLL (Shift Left Logical)
    // 4'b0101: SRL (Shift Right Logical)

    always @(*) begin
        case (alu_op)
            // Case 00: Load and Store instructions (always ADD for memory offset)
            2'b00: alu_control = 4'b0010; // ADD

            // Case 01: Branch instructions (always SUB to compare A and B)
            2'b01: alu_control = 4'b0110; // SUB

            // Case 10: R-type instructions (depends on funct3 and funct7_5)
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        // funct7_5 == 1 means SUB, funct7_5 == 0 means ADD
                        if (funct7_5)
                            alu_control = 4'b0110; // SUB
                        else
                            alu_control = 4'b0010; // ADD
                    end
                    3'b111: alu_control = 4'b0000; // AND
                    3'b110: alu_control = 4'b0001; // OR
                    3'b100: alu_control = 4'b1000; // XOR
                    3'b010: alu_control = 4'b0111; // SLT (Set Less Than)
                    3'b001: alu_control = 4'b0011; // SLL (Shift Left Logical)
                    3'b101: alu_control = 4'b0101; // SRL (Shift Right Logical)
                    default: alu_control = 4'b0010; // Default ADD
                endcase
            end

            // Case 11: I-type arithmetic instructions (e.g. ADDI, ANDI, ORI)
            2'b11: begin
                case (funct3)
                    3'b000:  alu_control = 4'b0010; // ADDI
                    3'b111:  alu_control = 4'b0000; // ANDI
                    3'b110:  alu_control = 4'b0001; // ORI
                    3'b100:  alu_control = 4'b1000; // XORI
                    3'b010:  alu_control = 4'b0111; // SLTI
                    3'b001:  alu_control = 4'b0011; // SLLI
                    3'b101:  alu_control = 4'b0101; // SRLI
                    default: alu_control = 4'b0010; // Default ADD
                endcase
            end

            default: alu_control = 4'b0010;
        endcase
    end

endmodule
