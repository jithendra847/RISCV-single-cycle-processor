// ============================================================================
// File: riscv_processor.v
// Project: Single-Cycle 32-bit RISC-V (RV32I) Unified Core
// Description: Complete RISC-V processor in ONE single, clean, easy-to-understand
//              Verilog file. No complicated multi-file wiring needed!
// ============================================================================

`timescale 1ns / 1ps

module riscv_processor (
    input  wire        clk,            // Clock signal: every rising edge triggers the processor to advance one instruction cycle.
    input  wire        reset,          // Active-high reset signal: when driven high, the processor state is cleared and execution restarts from address 0.
    
    // Outputs for monitoring / presentation
    output wire [31:0] out_pc,         // Current program counter (PC) value, pointing to the next instruction address.
    output wire [31:0] out_instruction,// Current fetched instruction in machine-code form.
    output wire [31:0] out_alu_result, // Result produced by the arithmetic logic unit for the current operation.
    output wire [31:0] out_write_data, // Final data value that will be written back to the destination register or memory path.
    output wire        out_reg_write   // Register write-enable flag indicating whether the destination register should be updated this cycle.
);

    integer i;

    // ========================================================================
    // 1. STAGE 1: INSTRUCTION FETCH (PC + INSTRUCTION MEMORY)
    // ========================================================================
    reg  [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] pc_plus_4 = pc + 32'd4;

    // 64 words of instruction memory, each word is 32 bits wide.
    reg [31:0] instr_mem [0:63];

    // Instruction fetch: memory is word-addressable, so the PC address is effectively divided by 4 using pc[7:2].
    wire [31:0] instr = instr_mem[pc[7:2]];

    // Program Counter Update logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;
        end else begin
            pc <= next_pc;
        end
    end

    // Default program loaded into instruction memory.
    initial begin
        for (i = 0; i < 64; i = i + 1) instr_mem[i] = 32'h00000013; // NOP instruction: addi x0, x0, 0
        
        // Demo program showing basic arithmetic, memory access, and branching instructions:
        instr_mem[0]  = 32'h00500093; // [0x00] ADDI x1, x0, 5      ; x1 = 5
        instr_mem[1]  = 32'h00a00113; // [0x04] ADDI x2, x0, 10     ; x2 = 10
        instr_mem[2]  = 32'h002081b3; // [0x08] ADD  x3, x1, x2     ; x3 = 15
        instr_mem[3]  = 32'h40110233; // [0x0C] SUB  x4, x2, x1     ; x4 = 5
        instr_mem[4]  = 32'h0020f2b3; // [0x10] AND  x5, x1, x2     ; x5 = 0
        instr_mem[5]  = 32'h0020e333; // [0x14] OR   x6, x1, x2     ; x6 = 15
        instr_mem[6]  = 32'h0020a3b3; // [0x18] SLT  x7, x1, x2     ; x7 = 1
        instr_mem[7]  = 32'h00302223; // [0x1C] SW   x3, 4(x0)      ; store 15 into RAM[4]
        instr_mem[8]  = 32'h00402403; // [0x20] LW   x8, 4(x0)      ; load RAM[4] to x8 = 15
        instr_mem[9]  = 32'h00408463; // [0x24] BEQ  x1, x4, 8      ; branch to 0x2C if equal
        instr_mem[10] = 32'h06300493; // [0x28] ADDI x9, x0, 99     ; this instruction is skipped by the branch
        instr_mem[11] = 32'h02a00513; // [0x2C] ADDI x10, x0, 42    ; x10 = 42
    end


    // ========================================================================
    // 2. STAGE 2: INSTRUCTION DECODE & REGISTER FILE
    // ========================================================================
    wire [6:0] opcode   = instr[6:0];
    wire [4:0] rd       = instr[11:7];
    wire [2:0] funct3   = instr[14:12];
    wire [4:0] rs1      = instr[19:15];
    wire [4:0] rs2      = instr[24:20];
    wire       funct7_5 = instr[30];

    // Control Unit Signals
    reg       reg_write;
    reg       alu_src;
    reg       mem_read;
    reg       mem_write;
    reg       mem_to_reg;
    reg       branch;
    reg       jump;
    reg [1:0] alu_op;

    // Control unit logic: decodes the opcode and generates the control signals for each instruction type.
    always @(*) begin
        // Default values for a no-op / safe operation.
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type instructions: ADD, SUB, AND, OR, SLT, XOR
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I-type arithmetic instructions: ADDI, ANDI, ORI, SLTI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b0000011: begin // Load instruction: LW
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00; // ADD is used to compute the memory address.
            end
            7'b0100011: begin // Store instruction: SW
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00; // ADD is used to compute the memory address.
            end
            7'b1100011: begin // Branch instructions: BEQ, BNE
                branch = 1'b1;
                alu_op = 2'b01; // SUB is used for comparison between the operands.
            end
            7'b1101111: begin // Jump instruction: JAL
                reg_write = 1'b1;
                jump      = 1'b1;
            end
            default: ;
        endcase
    end

    // Immediate generator (ImmGen): extracts the sign-extended immediate value according to instruction format.
    reg [31:0] imm_ext;
    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011: imm_ext = {{20{instr[31]}}, instr[31:20]}; // I-type immediate
            7'b0100011:             imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type immediate
            7'b1100011:             imm_ext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type immediate
            7'b1101111:             imm_ext = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type immediate
            default:                imm_ext = 32'h00000000;
        endcase
    end

    // 32 general-purpose registers, numbered x0 to x31.
    reg [31:0] registers [0:31];
    wire [31:0] write_back_data; // Forward declaration for the write-back stage.

    // Register read: asynchronous access; x0 is hardwired to zero to enforce the RISC-V convention.
    wire [31:0] read_data1 = (rs1 == 5'd0) ? 32'h00000000 : registers[rs1];
    wire [31:0] read_data2 = (rs2 == 5'd0) ? 32'h00000000 : registers[rs2];

    // Register write: synchronous update on the clock edge; x0 remains unchanged by ignoring writes to it.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) registers[i] <= 32'h00000000;
        end else if (reg_write && (rd != 5'd0)) begin
            registers[rd] <= write_back_data;
        end
    end


    // ========================================================================
    // 3. STAGE 3: EXECUTE (ALU CONTROL + ALU)
    // ========================================================================
    // ALU input B multiplexer (ALUSrc mux): selects either the immediate value or the second register operand.
    wire [31:0] alu_operand_b = (alu_src) ? imm_ext : read_data2;

    // ALU control logic: chooses the appropriate arithmetic or logical operation based on instruction type and funct fields.
    reg [3:0] alu_control;
    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'b0010; // ADD for load/store address calculations and plain adds
            2'b01: alu_control = 4'b0110; // SUB for branch comparison logic
            2'b10: begin // R-type instructions
                case (funct3)
                    3'b000:  alu_control = (funct7_5) ? 4'b0110 : 4'b0010; // SUB if funct7 bit is set, otherwise ADD
                    3'b111:  alu_control = 4'b0000; // AND
                    3'b110:  alu_control = 4'b0001; // OR
                    3'b100:  alu_control = 4'b1000; // XOR
                    3'b010:  alu_control = 4'b0111; // SLT
                    default: alu_control = 4'b0010;
                endcase
            end
            2'b11: begin // I-type instructions
                case (funct3)
                    3'b000:  alu_control = 4'b0010; // ADDI
                    3'b111:  alu_control = 4'b0000; // ANDI
                    3'b110:  alu_control = 4'b0001; // ORI
                    3'b100:  alu_control = 4'b1000; // XORI
                    3'b010:  alu_control = 4'b0111; // SLTI
                    default: alu_control = 4'b0010;
                endcase
            end
            default: alu_control = 4'b0010;
        endcase
    end

    // ALU calculation: performs the operation selected by alu_control.
    reg [31:0] alu_result;
    always @(*) begin
        case (alu_control)
            4'b0000: alu_result = read_data1 & alu_operand_b; // AND
            4'b0001: alu_result = read_data1 | alu_operand_b; // OR
            4'b0010: alu_result = read_data1 + alu_operand_b; // ADD
            4'b0110: alu_result = read_data1 - alu_operand_b; // SUB
            4'b0111: alu_result = ($signed(read_data1) < $signed(alu_operand_b)) ? 32'd1 : 32'd0; // SLT: set to 1 if signed read_data1 < signed alu_operand_b
            4'b1000: alu_result = read_data1 ^ alu_operand_b; // XOR
            default: alu_result = 32'h00000000;
        endcase
    end

    wire alu_zero = (alu_result == 32'h00000000);


    // ========================================================================
    // 4. STAGE 4: MEMORY ACCESS (DATA RAM)
    // ========================================================================
    reg [31:0] data_mem [0:63]; // 64 words of data memory, each 32 bits wide.
    wire [5:0] mem_addr = alu_result[7:2];

    // Asynchronous memory read: data is returned immediately if mem_read is asserted.
    wire [31:0] mem_read_data = (mem_read) ? data_mem[mem_addr] : 32'h00000000;

    // Synchronous memory write: stores the source register contents into RAM on a clock edge.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 64; i = i + 1) data_mem[i] <= 32'h00000000;
        end else if (mem_write) begin
            data_mem[mem_addr] <= read_data2;
        end
    end


    // ========================================================================
    // 5. STAGE 5: WRITE BACK & NEXT PC LOGIC
    // ========================================================================
    // Write-back multiplexer: selects the value to write into the destination register.
    assign write_back_data = (jump)       ? pc_plus_4 :
                             (mem_to_reg) ? mem_read_data :
                                            alu_result;

    // Branch decision and next PC selection logic.
    wire branch_condition = (funct3 == 3'b000) ? alu_zero : (!alu_zero); // BEQ if zero, BNE otherwise
    wire take_branch      = (branch & branch_condition) | jump;
    wire [31:0] branch_target = pc + imm_ext;

    assign next_pc = (take_branch) ? branch_target : pc_plus_4;


    // ========================================================================
    // OUTPUT MONITOR PORTS
    // ========================================================================
    assign out_pc          = pc;
    assign out_instruction = instr;
    assign out_alu_result  = alu_result;
    assign out_write_data  = write_back_data;
    assign out_reg_write   = reg_write;

endmodule
