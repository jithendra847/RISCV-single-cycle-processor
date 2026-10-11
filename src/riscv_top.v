// ============================================================================
// Module Name: riscv_top
// Description: Top-level single-cycle RISC-V (RV32I) processor core.
//              Interconnects:
//              - Program Counter (PC)
//              - Instruction Memory (IMEM)
//              - Register File (RF)
//              - Immediate Generator (ImmGen)
//              - Control Unit & ALU Control Unit
//              - Arithmetic Logic Unit (ALU)
//              - Data Memory (DMEM)
// ============================================================================

`timescale 1ns / 1ps

module riscv_top (
    input  wire        clk,            // System clock
    input  wire        reset,          // Active-high reset
    
    // Outputs exposed for observation, debugging, and presentation
    output wire [31:0] out_pc,         // Current Program Counter value
    output wire [31:0] out_instruction,// Current fetched 32-bit instruction
    output wire [31:0] out_alu_result, // Output of the ALU
    output wire [31:0] out_write_data, // Data being written back to registers
    output wire        out_reg_write   // Register write enable status flag
);

    // ========================================================================
    // Internal Interconnect Wires
    // ========================================================================
    
    // PC signals
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    wire [31:0] branch_target;

    // Instruction signals
    wire [31:0] instr;
    wire [6:0]  opcode   = instr[6:0];
    wire [4:0]  rd       = instr[11:7];
    wire [2:0]  funct3   = instr[14:12];
    wire [4:0]  rs1      = instr[19:15];
    wire [4:0]  rs2      = instr[24:20];
    wire        funct7_5 = instr[30];

    // Control Unit signals
    wire        branch;
    wire        mem_read;
    wire        mem_to_reg;
    wire [1:0]  alu_op;
    wire        mem_write;
    wire        alu_src;
    wire        reg_write;
    wire        jump;

    // Register File signals
    wire [31:0] reg_read_data1;
    wire [31:0] reg_read_data2;
    wire [31:0] reg_write_data;

    // Immediate Generator signals
    wire [31:0] imm_ext;

    // ALU signals
    wire [3:0]  alu_control_signal;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire        alu_zero;

    // Data Memory signals
    wire [31:0] mem_read_data;

    // Branch condition logic:
    // BEQ: funct3 == 3'b000 aur alu_zero == 1
    // BNE: funct3 == 3'b001 aur alu_zero == 0
    wire branch_condition = (funct3 == 3'b000) ? alu_zero : (!alu_zero);
    wire take_branch = (branch & branch_condition) | jump;

    // ========================================================================
    // Datapath Multiplexers & Adders
    // ========================================================================

    // 1. PC Adder: Sequential next instruction address (PC + 4)
    assign pc_plus_4 = pc_current + 32'd4;

    // 2. Branch Target Adder: Target address for branches and jumps (PC + Immediate)
    assign branch_target = pc_current + imm_ext;

    // 3. Next PC Mux: Agar branch/jump lena hai toh branch_target, warna PC + 4
    assign pc_next = (take_branch) ? branch_target : pc_plus_4;

    // 4. ALU Operand B Mux: If ALUSrc = 1, use Immediate; else use Register Data 2
    assign alu_operand_b = (alu_src) ? imm_ext : reg_read_data2;

    // 5. Writeback Mux:
    //    If Jump (JAL) -> write PC + 4 (return address)
    //    Else If MemToReg = 1 (LW) -> write Memory Data
    //    Else -> write ALU Result
    assign reg_write_data = (jump)       ? pc_plus_4 :
                            (mem_to_reg) ? mem_read_data :
                                           alu_result;

    // ========================================================================
    // Module Instantiations
    // ========================================================================

    // 1. Program Counter
    Program_Counter pc_inst (
        .clk     (clk),
        .reset   (reset),
        .next_pc (pc_next),
        .pc      (pc_current)
    );

    // 2. Instruction Memory
    Instruction_Memory imem_inst (
        .pc          (pc_current),
        .instruction (instr)
    );

    // 3. Control Unit
    Control_Unit control_inst (
        .opcode     (opcode),
        .branch     (branch),
        .mem_read   (mem_read),
        .mem_to_reg (mem_to_reg),
        .alu_op     (alu_op),
        .mem_write  (mem_write),
        .alu_src    (alu_src),
        .reg_write  (reg_write),
        .jump       (jump)
    );

    // 4. Register File
    Register_File rf_inst (
        .clk        (clk),
        .reset      (reset),
        .reg_write  (reg_write),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .write_data (reg_write_data),
        .read_data1 (reg_read_data1),
        .read_data2 (reg_read_data2)
    );

    // 5. Immediate Generator
    Imm_Gen imm_gen_inst (
        .instruction (instr),
        .imm_ext     (imm_ext)
    );

    // 6. ALU Control Unit
    ALU_Control alu_ctrl_inst (
        .alu_op      (alu_op),
        .funct3      (funct3),
        .funct7_5    (funct7_5),
        .alu_control (alu_control_signal)
    );

    // 7. Arithmetic Logic Unit (ALU)
    ALU alu_inst (
        .a           (reg_read_data1),
        .b           (alu_operand_b),
        .alu_control (alu_control_signal),
        .result      (alu_result),
        .zero        (alu_zero)
    );

    // 8. Data Memory
    Data_Memory dmem_inst (
        .clk        (clk),
        .reset      (reset),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (alu_result),
        .write_data (reg_read_data2),
        .read_data  (mem_read_data)
    );

    // ========================================================================
    // Assign Debug/Observation Outputs
    // ========================================================================
    assign out_pc          = pc_current;
    assign out_instruction = instr;
    assign out_alu_result  = alu_result;
    assign out_write_data  = reg_write_data;
    assign out_reg_write   = reg_write;

endmodule
