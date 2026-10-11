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
                reg_write  = 1'b1;     // Result registers me save hoga
                alu_src    = 1'b0;     // ALU input 2 register rs2 se aayega
                alu_op     = 2'b10;    // ALU control dekhega funct3 aur funct7
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;     // ALU result writeback hoga
                branch     = 1'b0;
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // I-type Arithmetic Instructions: ADDI, ANDI, ORI, XORI, SLTI
            // Opcode: 7'b0010011 (19 in decimal / 0x13)
            // -------------------------------------------------------------
            7'b0010011: begin
                reg_write  = 1'b1;     // Result registers me save hoga
                alu_src    = 1'b1;     // ALU input 2 immediate value hoga
                alu_op     = 2'b11;    // ALU control dekhega funct3
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;     // ALU result writeback hoga
                branch     = 1'b0;
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // I-type Load Instruction: LW (Load Word)
            // Opcode: 7'b0000011 (3 in decimal / 0x03)
            // -------------------------------------------------------------
            7'b0000011: begin
                reg_write  = 1'b1;     // Memory se padha hua data register me write hoga
                alu_src    = 1'b1;     // Address calculate karne ke liye (rs1 + imm)
                alu_op     = 2'b00;    // ALU ADD karega address nikalne ke liye
                mem_read   = 1'b1;     // Memory se read enable karo
                mem_write  = 1'b0;
                mem_to_reg = 1'b1;     // Memory ka data register file me bhejo
                branch     = 1'b0;
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // S-type Store Instruction: SW (Store Word)
            // Opcode: 7'b0100011 (35 in decimal / 0x23)
            // -------------------------------------------------------------
            7'b0100011: begin
                reg_write  = 1'b0;     // Register me kuch nahi likhna
                alu_src    = 1'b1;     // Address calculate karne ke liye (rs1 + imm)
                alu_op     = 2'b00;    // ALU ADD karega address nikalne ke liye
                mem_read   = 1'b0;
                mem_write  = 1'b1;     // Memory me write enable karo
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // B-type Branch Instructions: BEQ, BNE
            // Opcode: 7'b1100011 (99 in decimal / 0x63)
            // -------------------------------------------------------------
            7'b1100011: begin
                reg_write  = 1'b0;     // No register write
                alu_src    = 1'b0;     // Compare rs1 and rs2
                alu_op     = 2'b01;    // ALU subtract karega comparison ke liye
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b1;     // Branch signal activate karo
                jump       = 1'b0;
            end

            // -------------------------------------------------------------
            // J-type Jump Instruction: JAL (Jump and Link)
            // Opcode: 7'b1101111 (111 in decimal / 0x6F)
            // -------------------------------------------------------------
            7'b1101111: begin
                reg_write  = 1'b1;     // Return address (PC+4) rd me save hoga
                alu_src    = 1'b0;
                alu_op     = 2'b00;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jump       = 1'b1;     // Unconditional jump flag
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
