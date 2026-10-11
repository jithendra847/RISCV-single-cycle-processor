// ============================================================================
// File: riscv_processor.v
// Project: Single-Cycle 32-bit RISC-V (RV32I) Unified Core
// Description: Complete RISC-V processor in ONE single, clean, easy-to-understand
//              Verilog file. No complicated multi-file wiring needed!
// ============================================================================

`timescale 1ns / 1ps

module riscv_processor (
    input  wire        clk,            // Clock signal (har clock tick par instruction execute hoti hai)
    input  wire        reset,          // Active-high reset signal (1 karne par processor reset hota hai)
    
    // Outputs for monitoring / presentation
    output wire [31:0] out_pc,         // Current PC address
    output wire [31:0] out_instruction,// Current instruction machine code
    output wire [31:0] out_alu_result, // ALU ka output
    output wire [31:0] out_write_data, // Register me save hone wala final answer
    output wire        out_reg_write   // Register write enable status flag
);

    integer i;

    // ========================================================================
    // 1. STAGE 1: INSTRUCTION FETCH (PC + INSTRUCTION MEMORY)
    // ========================================================================
    reg  [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] pc_plus_4 = pc + 32'd4;

    // 64 words (32-bit each) ki Instruction Memory
    reg [31:0] instr_mem [0:63];

    // Instruction fetch (Word aligned: pc >> 2 ya pc[7:2])
    wire [31:0] instr = instr_mem[pc[7:2]];

    // Program Counter Update logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;
        end else begin
            pc <= next_pc;
        end
    end

    // Default program loaded into instruction memory
    initial begin
        for (i = 0; i < 64; i = i + 1) instr_mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
        
        // Demo Program:
        instr_mem[0]  = 32'h00500093; // [0x00] ADDI x1, x0, 5    (x1 = 5)
        instr_mem[1]  = 32'h00a00113; // [0x04] ADDI x2, x0, 10   (x2 = 10)
        instr_mem[2]  = 32'h002081b3; // [0x08] ADD  x3, x1, x2   (x3 = 15)
        instr_mem[3]  = 32'h40110233; // [0x0C] SUB  x4, x2, x1   (x4 = 5)
        instr_mem[4]  = 32'h0020f2b3; // [0x10] AND  x5, x1, x2   (x5 = 0)
        instr_mem[5]  = 32'h0020e333; // [0x14] OR   x6, x1, x2   (x6 = 15)
        instr_mem[6]  = 32'h0020a3b3; // [0x18] SLT  x7, x1, x2   (x7 = 1)
        instr_mem[7]  = 32'h00302223; // [0x1C] SW   x3, 4(x0)    (Store 15 in RAM[4])
        instr_mem[8]  = 32'h00402403; // [0x20] LW   x8, 4(x0)    (Load from RAM[4] to x8 = 15)
        instr_mem[9]  = 32'h00408463; // [0x24] BEQ  x1, x4, 8    (Equal? Jump to 0x2C!)
        instr_mem[10] = 32'h06300493; // [0x28] ADDI x9, x0, 99   (SKIPPED BY BRANCH)
        instr_mem[11] = 32'h02a00513; // [0x2C] ADDI x10, x0, 42  (x10 = 42)
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

    // Control Unit Logic (Opcode Decode)
    always @(*) begin
        // Default values
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type: ADD, SUB, AND, OR, SLT, XOR
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I-type Arithmetic: ADDI, ANDI, ORI, SLTI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b0000011: begin // Load: LW
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00; // ADD for address calculation
            end
            7'b0100011: begin // Store: SW
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00; // ADD for address calculation
            end
            7'b1100011: begin // Branch: BEQ, BNE
                branch = 1'b1;
                alu_op = 2'b01; // SUB for comparison
            end
            7'b1101111: begin // Jump: JAL
                reg_write = 1'b1;
                jump      = 1'b1;
            end
            default: ;
        endcase
    end

    // Immediate Generator (ImmGen)
    reg [31:0] imm_ext;
    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011: imm_ext = {{20{instr[31]}}, instr[31:20]}; // I-type
            7'b0100011:             imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type
            7'b1100011:             imm_ext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type
            7'b1101111:             imm_ext = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type
            default:                imm_ext = 32'h00000000;
        endcase
    end

    // 32 General-Purpose Registers (x0 to x31)
    reg [31:0] registers [0:31];
    wire [31:0] write_back_data; // Forward declaration

    // Register Read: Asynchronous (Register x0 is ALWAYS 0!)
    wire [31:0] read_data1 = (rs1 == 5'd0) ? 32'h00000000 : registers[rs1];
    wire [31:0] read_data2 = (rs2 == 5'd0) ? 32'h00000000 : registers[rs2];

    // Register Write: Synchronous on clock posedge
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
    // ALU Input B Multiplexer (ALUSrc Mux)
    wire [31:0] alu_operand_b = (alu_src) ? imm_ext : read_data2;

    // ALU Control Logic
    reg [3:0] alu_control;
    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'b0010; // ADD (Load / Store / JAL)
            2'b01: alu_control = 4'b0110; // SUB (Branch comparison)
            2'b10: begin // R-type
                case (funct3)
                    3'b000:  alu_control = (funct7_5) ? 4'b0110 : 4'b0010; // SUB : ADD
                    3'b111:  alu_control = 4'b0000; // AND
                    3'b110:  alu_control = 4'b0001; // OR
                    3'b100:  alu_control = 4'b1000; // XOR
                    3'b010:  alu_control = 4'b0111; // SLT
                    default: alu_control = 4'b0010;
                endcase
            end
            2'b11: begin // I-type
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

    // ALU Calculation
    reg [31:0] alu_result;
    always @(*) begin
        case (alu_control)
            4'b0000: alu_result = read_data1 & alu_operand_b; // AND
            4'b0001: alu_result = read_data1 | alu_operand_b; // OR
            4'b0010: alu_result = read_data1 + alu_operand_b; // ADD
            4'b0110: alu_result = read_data1 - alu_operand_b; // SUB
            4'b0111: alu_result = ($signed(read_data1) < $signed(alu_operand_b)) ? 32'd1 : 32'd0; // SLT
            4'b1000: alu_result = read_data1 ^ alu_operand_b; // XOR
            default: alu_result = 32'h00000000;
        endcase
    end

    wire alu_zero = (alu_result == 32'h00000000);


    // ========================================================================
    // 4. STAGE 4: MEMORY ACCESS (DATA RAM)
    // ========================================================================
    reg [31:0] data_mem [0:63]; // 64 words Data RAM
    wire [5:0] mem_addr = alu_result[7:2];

    // Asynchronous Memory Read
    wire [31:0] mem_read_data = (mem_read) ? data_mem[mem_addr] : 32'h00000000;

    // Synchronous Memory Write
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
    // Writeback Multiplexer (MemToReg & Jump Mux)
    assign write_back_data = (jump)       ? pc_plus_4 :
                             (mem_to_reg) ? mem_read_data :
                                            alu_result;

    // Branch Decision & Next PC
    wire branch_condition = (funct3 == 3'b000) ? alu_zero : (!alu_zero); // BEQ : BNE
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
