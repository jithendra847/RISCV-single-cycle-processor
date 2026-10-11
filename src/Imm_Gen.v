// ============================================================================
// Module Name: Imm_Gen (Immediate Generator)
// Description: Extracts immediate bits from the instruction and sign-extends
//              them to a 32-bit value based on the instruction opcode/format.
//              Supports:
//              - I-type (ADDI, LW, ANDI, ORI, etc.)
//              - S-type (SW)
//              - B-type (BEQ, BNE)
//              - J-type (JAL)
//              - U-type (LUI)
// ============================================================================

`timescale 1ns / 1ps

module Imm_Gen (
    input  wire [31:0] instruction,   // 32-bit RISC-V instruction
    output reg  [31:0] imm_ext        // Sign-extended 32-bit immediate
);

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-type Instructions: ADDI, LW, SLTI, ANDI, ORI (Opcode: 7'b0010011 or 7'b0000011)
            7'b0010011,
            7'b0000011,
            7'b1100111: begin // JALR
                // Sign extend bit 31 across the top 20 bits
                imm_ext = {{20{instruction[31]}}, instruction[31:20]};
            end

            // S-type Instructions: SW (Store Word) (Opcode: 7'b0100011)
            7'b0100011: begin
                imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            // B-type Instructions: BEQ, BNE (Branch) (Opcode: 7'b1100011)
            // Notice: RISC-V branch addresses are multiples of 2, so bit 0 is 0
            7'b1100011: begin
                imm_ext = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end

            // J-type Instructions: JAL (Jump and Link) (Opcode: 7'b1101111)
            7'b1101111: begin
                imm_ext = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end

            // U-type Instructions: LUI (Load Upper Immediate) (Opcode: 7'b0110111)
            7'b0110111: begin
                imm_ext = {instruction[31:12], 12'h000};
            end

            // Default case (R-type ya unknown instructions ke liye 0)
            default: begin
                imm_ext = 32'h00000000;
            end
        endcase
    end

endmodule
