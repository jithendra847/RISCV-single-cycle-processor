// ============================================================================
// Module Name: Control_Unit
// Description: Main Control Unit of the RISC-V processor.
//              Decodes the 7-bit opcode and generates all main control signals
//              for the datapath (multiplexers, register writes, memory read/write).
// ============================================================================

`timescale 1ns / 1ps

module Control_Unit (
    input  wire [6:0] opcode,        // Instruction opcode (instruction[6:0])
    output reg        branch,        // 1 = Branch instruction (BEQ/BNE)
    output reg        mem_read,      // 1 = Read from Data Memory (LW)
    output reg        mem_to_reg,    // 1 = Write Data Memory output to Register File
    output reg  [1:0] alu_op,        // 2-bit signal to ALU Control unit
    output reg        mem_write,     // 1 = Write to Data Memory (SW)
    output reg        alu_src,       // 0 = Second ALU operand is rs2, 1 = Immediate
    output reg        reg_write,     // 1 = Write to Register File
    output reg        jump           // 1 = Unconditional Jump (JAL)
);

    always @(*) begin
        // Default values to prevent latches
        branch     = 1'b0;
        mem_read   = 1'b0;
        mem_to_reg = 1'b0;
        alu_op     = 2'b00;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        reg_write  = 1'b0;
        jump       = 1'b0;

        case (opcode)
            // -------------------------------------------------------------
            // R-type Instructions: ADD, SUB, AND, OR, XOR, SLT, SLL, SRL
            // Opcode: 7'b0110011 (51 in decimal / 0x33)
            // -------------------------------------------------------------
            7'b0110011: begin
                reg_write  = 1'b1;     // Write the arithmetic/logical result back to the destination register.
                alu_src    = 1'b0;     // The ALU's second operand comes from register rs2.
                alu_op     = 2'b10;    // ALU control will inspect funct3 and funct7 to choose the operation.
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;     // The ALU result is passed directly to the write-back path.
                branch     = 1'b0;
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // I-type Arithmetic Instructions: ADDI, ANDI, ORI, XORI, SLTI
            // Opcode: 7'b0010011 (19 in decimal / 0x13)
            // -------------------------------------------------------------
            7'b0010011: begin
                reg_write  = 1'b1;     // Store the computed result in the destination register.
                alu_src    = 1'b1;     // Use the immediate value as the ALU's second operand.
                alu_op     = 2'b11;    // ALU control will decode the funct3 field for the operation.
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;     // The ALU output is written back directly.
                branch     = 1'b0;
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // I-type Load Instruction: LW (Load Word)
            // Opcode: 7'b0000011 (3 in decimal / 0x03)
            // -------------------------------------------------------------
            7'b0000011: begin
                reg_write  = 1'b1;     // Load the value read from memory into the destination register.
                alu_src    = 1'b1;     // Compute the effective memory address as rs1 + immediate.
                alu_op     = 2'b00;    // ALU does an addition to calculate the address.
                mem_read   = 1'b1;     // Enable the data memory read port.
                mem_write  = 1'b0;
                mem_to_reg = 1'b1;     // Select memory data for the register write-back path.
                branch     = 1'b0;
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // S-type Store Instruction: SW (Store Word)
            // Opcode: 7'b0100011 (35 in decimal / 0x23)
            // -------------------------------------------------------------
            7'b0100011: begin
                reg_write  = 1'b0;     // No destination register is updated for a store instruction.
                alu_src    = 1'b1;     // Compute the memory address as rs1 + immediate.
                alu_op     = 2'b00;    // ALU performs address calculation using addition.
                mem_read   = 1'b0;
                mem_write  = 1'b1;     // Enable the data memory write port.
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // B-type Branch Instructions: BEQ, BNE
            // Opcode: 7'b1100011 (99 in decimal / 0x63)
            // -------------------------------------------------------------
            7'b1100011: begin
                reg_write  = 1'b0;     // Branch instructions do not write a normal register result.
                alu_src    = 1'b0;     // Compare rs1 and rs2 as operands.
                alu_op     = 2'b01;    // ALU performs subtraction to determine equality/inequality.
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b1;     // Activate the branch control signal.
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // J-type Jump Instruction: JAL (Jump and Link)
            // Opcode: 7'b1101111 (111 in decimal / 0x6F)
            // -------------------------------------------------------------
            7'b1101111: begin
                reg_write  = 1'b1;     // Save the return address (PC + 4) into the destination register.
                alu_src    = 1'b0;
                alu_op     = 2'b00;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jump       = 1'b1;     // Set the unconditional jump flag.
            end

            default: begin
                // Invalid or unsupported instruction
                branch     = 1'b0;
                mem_read   = 1'b0;
                mem_to_reg = 1'b0;
                alu_op     = 2'b00;
                mem_write  = 1'b0;
                alu_src    = 1'b0;
                reg_write  = 1'b0;
                jump       = 1'b0;
            end
        endcase
    end

endmodule
