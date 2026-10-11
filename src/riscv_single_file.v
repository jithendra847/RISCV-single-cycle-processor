// ============================================================================
// File: riscv_single_file.v
// Project: Single-Cycle 32-bit RISC-V (RV32I) Processor
// Description: All hardware modules combined into one file for easy compilation
//              on EDA Playground, ModelSim, Vivado, or Icarus Verilog.
// ============================================================================

`timescale 1ns / 1ps

// ============================================================================
// 1. PROGRAM COUNTER (PC)
// ============================================================================
module Program_Counter (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;
        end else begin
            pc <= next_pc;
        end
    end
endmodule

// ============================================================================
// 2. INSTRUCTION MEMORY
// ============================================================================
module Instruction_Memory (
    input  wire [31:0] pc,
    output wire [31:0] instruction
);
    reg [31:0] memory [0:63];

    // Word-aligned access (pc >> 2)
    assign instruction = memory[pc[7:2]];

    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h00000013; // NOP (addi x0, x0, 0)
        end
        // Default demonstration instructions:
        memory[0]  = 32'h00500093; // ADDI x1, x0, 5    (x1 = 5)
        memory[1]  = 32'h00a00113; // ADDI x2, x0, 10   (x2 = 10)
        memory[2]  = 32'h002081b3; // ADD  x3, x1, x2   (x3 = 15)
        memory[3]  = 32'h40110233; // SUB  x4, x2, x1   (x4 = 5)
        memory[4]  = 32'h0020f2b3; // AND  x5, x1, x2   (x5 = 0)
        memory[5]  = 32'h0020e333; // OR   x6, x1, x2   (x6 = 15)
        memory[6]  = 32'h0020a3b3; // SLT  x7, x1, x2   (x7 = 1)
        memory[7]  = 32'h00302223; // SW   x3, 4(x0)    (Store x3 to mem[4])
        memory[8]  = 32'h00402403; // LW   x8, 4(x0)    (Load mem[4] to x8)
        memory[9]  = 32'h00408463; // BEQ  x1, x4, 8    (Branch to memory[11])
        memory[10] = 32'h06300493; // ADDI x9, x0, 99   (Skipped!)
        memory[11] = 32'h02a00513; // ADDI x10, x0, 42  (x10 = 42)
    end
endmodule

// ============================================================================
// 3. REGISTER FILE (32 General Purpose Registers x0-x31)
// ============================================================================
module Register_File (
    input  wire        clk,
    input  wire        reset,
    input  wire        reg_write,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);
    reg [31:0] registers [0:31];
    integer i;

    // Asynchronous read (Register x0 is hardwired to 0)
    assign read_data1 = (rs1 == 5'd0) ? 32'h00000000 : registers[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'h00000000 : registers[rs2];

    // Synchronous write on clock posedge
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'h00000000;
        end else if (reg_write && (rd != 5'd0)) begin
            registers[rd] <= write_data;
        end
    end
endmodule

// ============================================================================
// 4. IMMEDIATE GENERATOR (Imm_Gen)
// ============================================================================
module Imm_Gen (
    input  wire [31:0] instruction,
    output reg  [31:0] imm_ext
);
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011,
            7'b0000011,
            7'b1100111: imm_ext = {{20{instruction[31]}}, instruction[31:20]}; // I-type
            7'b0100011: imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type
            7'b1100011: imm_ext = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
            7'b1101111: imm_ext = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
            7'b0110111: imm_ext = {instruction[31:12], 12'h000}; // U-type
            default:    imm_ext = 32'h00000000;
        endcase
    end
endmodule

// ============================================================================
// 5. CONTROL UNIT
// ============================================================================
module Control_Unit (
    input  wire [6:0] opcode,
    output reg        branch,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg  [1:0] alu_op,
    output reg        mem_write,
    output reg        alu_src,
    output reg        reg_write,
    output reg        jump
);
    always @(*) begin
        branch     = 1'b0;
        mem_read   = 1'b0;
        mem_to_reg = 1'b0;
        alu_op     = 2'b00;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        reg_write  = 1'b0;
        jump       = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b0000011: begin // LW
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00;
            end
            7'b0100011: begin // SW
                mem_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = 2'b00;
            end
            7'b1100011: begin // Branch (BEQ/BNE)
                branch     = 1'b1;
                alu_op     = 2'b01;
            end
            7'b1101111: begin // JAL
                reg_write  = 1'b1;
                jump       = 1'b1;
            end
            default: ;
        endcase
    end
endmodule

// ============================================================================
// 6. ALU CONTROL UNIT
// ============================================================================
module ALU_Control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,
    output reg  [3:0] alu_control
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'b0010; // ADD (Load / Store)
            2'b01: alu_control = 4'b0110; // SUB (Branch)
            2'b10: begin // R-type
                case (funct3)
                    3'b000:  alu_control = funct7_5 ? 4'b0110 : 4'b0010; // SUB : ADD
                    3'b111:  alu_control = 4'b0000; // AND
                    3'b110:  alu_control = 4'b0001; // OR
                    3'b100:  alu_control = 4'b1000; // XOR
                    3'b010:  alu_control = 4'b0111; // SLT
                    3'b001:  alu_control = 4'b0011; // SLL
                    3'b101:  alu_control = 4'b0101; // SRL
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
                    3'b001:  alu_control = 4'b0011; // SLLI
                    3'b101:  alu_control = 4'b0101; // SRLI
                    default: alu_control = 4'b0010;
                endcase
            end
            default: alu_control = 4'b0010;
        endcase
    end
endmodule

// ============================================================================
// 7. ARITHMETIC LOGIC UNIT (ALU)
// ============================================================================
module ALU (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] result,
    output wire        zero
);
    assign zero = (result == 32'h00000000);

    always @(*) begin
        case (alu_control)
            4'b0000: result = a & b;
            4'b0001: result = a | b;
            4'b0010: result = a + b;
            4'b0110: result = a - b;
            4'b0111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'b1000: result = a ^ b;
            4'b0011: result = a << b[4:0];
            4'b0101: result = a >> b[4:0];
            default: result = 32'h00000000;
        endcase
    end
endmodule

// ============================================================================
// 8. DATA MEMORY
// ============================================================================
module Data_Memory (
    input  wire        clk,
    input  wire        reset,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] memory [0:63];
    integer i;
    wire [5:0] word_addr = addr[7:2];

    assign read_data = (mem_read) ? memory[word_addr] : 32'h00000000;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 64; i = i + 1)
                memory[i] <= 32'h00000000;
        end else if (mem_write) begin
            memory[word_addr] <= write_data;
        end
    end
endmodule

// ============================================================================
// 9. TOP-LEVEL PROCESSOR CORE (riscv_top)
// ============================================================================
module riscv_top (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] out_pc,
    output wire [31:0] out_instruction,
    output wire [31:0] out_alu_result,
    output wire [31:0] out_write_data,
    output wire        out_reg_write
);
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    wire [31:0] branch_target;

    wire [31:0] instr;
    wire [6:0]  opcode   = instr[6:0];
    wire [4:0]  rd       = instr[11:7];
    wire [2:0]  funct3   = instr[14:12];
    wire [4:0]  rs1      = instr[19:15];
    wire [4:0]  rs2      = instr[24:20];
    wire        funct7_5 = instr[30];

    wire        branch;
    wire        mem_read;
    wire        mem_to_reg;
    wire [1:0]  alu_op;
    wire        mem_write;
    wire        alu_src;
    wire        reg_write;
    wire        jump;

    wire [31:0] reg_read_data1;
    wire [31:0] reg_read_data2;
    wire [31:0] reg_write_data;

    wire [31:0] imm_ext;

    wire [3:0]  alu_control_signal;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire        alu_zero;

    wire [31:0] mem_read_data;

    wire branch_condition = (funct3 == 3'b000) ? alu_zero : (!alu_zero);
    wire take_branch = (branch & branch_condition) | jump;

    assign pc_plus_4     = pc_current + 32'd4;
    assign branch_target = pc_current + imm_ext;
    assign pc_next       = (take_branch) ? branch_target : pc_plus_4;
    assign alu_operand_b = (alu_src) ? imm_ext : reg_read_data2;
    assign reg_write_data = (jump)       ? pc_plus_4 :
                            (mem_to_reg) ? mem_read_data :
                                           alu_result;

    Program_Counter pc_inst (
        .clk(clk), .reset(reset), .next_pc(pc_next), .pc(pc_current)
    );

    Instruction_Memory imem_inst (
        .pc(pc_current), .instruction(instr)
    );

    Control_Unit control_inst (
        .opcode(opcode), .branch(branch), .mem_read(mem_read),
        .mem_to_reg(mem_to_reg), .alu_op(alu_op), .mem_write(mem_write),
        .alu_src(alu_src), .reg_write(reg_write), .jump(jump)
    );

    Register_File rf_inst (
        .clk(clk), .reset(reset), .reg_write(reg_write),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .write_data(reg_write_data),
        .read_data1(reg_read_data1), .read_data2(reg_read_data2)
    );

    Imm_Gen imm_gen_inst (
        .instruction(instr), .imm_ext(imm_ext)
    );

    ALU_Control alu_ctrl_inst (
        .alu_op(alu_op), .funct3(funct3), .funct7_5(funct7_5),
        .alu_control(alu_control_signal)
    );

    ALU alu_inst (
        .a(reg_read_data1), .b(alu_operand_b),
        .alu_control(alu_control_signal),
        .result(alu_result), .zero(alu_zero)
    );

    Data_Memory dmem_inst (
        .clk(clk), .reset(reset), .mem_read(mem_read),
        .mem_write(mem_write), .addr(alu_result),
        .write_data(reg_read_data2), .read_data(mem_read_data)
    );

    assign out_pc          = pc_current;
    assign out_instruction = instr;
    assign out_alu_result  = alu_result;
    assign out_write_data  = reg_write_data;
    assign out_reg_write   = reg_write;

endmodule
