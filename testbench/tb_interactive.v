// ============================================================================
// Module Name: tb_interactive
// Description: Interactive Testbench for Single-Cycle RISC-V Processor.
//              - Takes user input for Operands A, B and operation choice.
//              - Dynamically generates machine code for the RISC-V processor.
//              - Executes the instructions cycle-by-cycle in the hardware model.
//              - Displays the final register contents and ALU results.
// ============================================================================

`timescale 1ns / 1ps

module tb_interactive;

    reg clk;
    reg reset;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] alu_result;
    wire [31:0] write_data;
    wire        reg_write;

    // Instantiate Processor
    riscv_top uut (
        .clk             (clk),
        .reset           (reset),
        .out_pc          (pc),
        .out_instruction (instruction),
        .out_alu_result  (alu_result),
        .out_write_data  (write_data),
        .out_reg_write   (reg_write)
    );

    // Clock Generation: 10ns period
    always #5 clk = ~clk;

    // Variables for user interaction
    integer numA;
    integer numB;
    integer opChoice;
    integer status;
    integer i;

    reg [31:0] instr0; // ADDI x1, x0, numA
    reg [31:0] instr1; // ADDI x2, x0, numB
    reg [31:0] instr2; // Op x3, x1, x2
    reg [31:0] instr3; // SW x3, 0(x0)
    reg [31:0] instr4; // LW x4, 0(x0)

    reg [8*10:1] opName;

    initial begin
        clk = 0;
        reset = 1;

        $display("\n==================================================================");
        $display("   *** WELCOME TO INTERACTIVE RISC-V PROCESSOR SIMULATION ***     ");
        $display("==================================================================");
        $display("This testbench takes numbers and operation from the user,");
        $display("encodes them into RISC-V RV32I machine instructions,");
        $display("and runs them on the single-cycle Verilog processor hardware!\n");

        // Stdin file descriptor in Verilog: 32'h8000_0000
        $write("Enter Operand A (Integer between -2048 and 2047, e.g. 25): ");
        status = $fscanf(32'h8000_0000, "%d", numA);
        if (status == 0 || status == -1) begin
            $display("\n[Notice] No terminal input detected, using default: A = 25");
            numA = 25;
        end else begin
            $display("-> Input A = %0d received.", numA);
        end

        $write("Enter Operand B (Integer between -2048 and 2047, e.g. 10): ");
        status = $fscanf(32'h8000_0000, "%d", numB);
        if (status == 0 || status == -1) begin
            $display("[Notice] No terminal input detected, using default: B = 10");
            numB = 10;
        end else begin
            $display("-> Input B = %0d received.", numB);
        end

        $display("\nSelect Operation to perform:");
        $display("  1 : ADD (x3 = A + B)");
        $display("  2 : SUB (x3 = A - B)");
        $display("  3 : AND (x3 = A & B)");
        $display("  4 : OR  (x3 = A | B)");
        $display("  5 : SLT (x3 = (A < B) ? 1 : 0)");
        $display("  6 : XOR (x3 = A ^ B)");
        $write("Enter choice (1-6): ");
        status = $fscanf(32'h8000_0000, "%d", opChoice);
        if (status == 0 || status == -1 || opChoice < 1 || opChoice > 6) begin
            $display("\n[Notice] Using default choice: 1 (ADD)");
            opChoice = 1;
        end else begin
            $display("-> Choice %0d selected.", opChoice);
        end

        // -------------------------------------------------------------
        // DYNAMIC INSTRUCTION ENCODING (Assembler logic in Verilog)
        // -------------------------------------------------------------
        // Instruction 0: ADDI x1, x0, numA
        // I-type: imm[11:0] (12-bit) | rs1 (5-bit) | funct3 (3-bit) | rd (5-bit) | opcode (7-bit)
        instr0 = {numA[11:0], 5'd0, 3'b000, 5'd1, 7'b0010011};

        // Instruction 1: ADDI x2, x0, numB
        instr1 = {numB[11:0], 5'd0, 3'b000, 5'd2, 7'b0010011};

        // Instruction 2: Operation on x1 and x2, store in x3 (R-type)
        // R-type: funct7 (7-bit) | rs2 (5-bit) | rs1 (5-bit) | funct3 (3-bit) | rd (5-bit) | opcode (7-bit)
        case (opChoice)
            1: begin // ADD
                instr2 = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
                opName = "ADD";
            end
            2: begin // SUB
                instr2 = {7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
                opName = "SUB";
            end
            3: begin // AND
                instr2 = {7'b0000000, 5'd2, 5'd1, 3'b111, 5'd3, 7'b0110011};
                opName = "AND";
            end
            4: begin // OR
                instr2 = {7'b0000000, 5'd2, 5'd1, 3'b110, 5'd3, 7'b0110011};
                opName = "OR";
            end
            5: begin // SLT
                instr2 = {7'b0000000, 5'd2, 5'd1, 3'b010, 5'd3, 7'b0110011};
                opName = "SLT";
            end
            6: begin // XOR
                instr2 = {7'b0000000, 5'd2, 5'd1, 3'b100, 5'd3, 7'b0110011};
                opName = "XOR";
            end
            default: begin
                instr2 = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
                opName = "ADD";
            end
        endcase

        // Instruction 3: SW x3, 0(x0) - Store result into Data Memory address 0
        // S-type: imm[11:5] | rs2 (x3) | rs1 (x0) | funct3 (010) | imm[4:0] | opcode (0100011)
        instr3 = {7'b0000000, 5'd3, 5'd0, 3'b010, 5'b00000, 7'b0100011};

        // Instruction 4: LW x4, 0(x0) - Read back from Data Memory into register x4
        // I-type: imm (0) | rs1 (x0) | funct3 (010) | rd (x4) | opcode (0000011)
        instr4 = {12'h000, 5'd0, 3'b010, 5'd4, 7'b0000011};

        // Load into instruction memory of processor
        uut.imem_inst.memory[0] = instr0;
        uut.imem_inst.memory[1] = instr1;
        uut.imem_inst.memory[2] = instr2;
        uut.imem_inst.memory[3] = instr3;
        uut.imem_inst.memory[4] = instr4;

        $display("\n[Generated RISC-V Machine Code]");
        $display("PC=0x00: 0x%08h -> ADDI x1, x0, %0d", instr0, numA);
        $display("PC=0x04: 0x%08h -> ADDI x2, x0, %0d", instr1, numB);
        $display("PC=0x08: 0x%08h -> %0s  x3, x1, x2",  instr2, opName);
        $display("PC=0x0C: 0x%08h -> SW   x3, 0(x0)",    instr3);
        $display("PC=0x10: 0x%08h -> LW   x4, 0(x0)",    instr4);

        // Reset the hardware
        #10;
        reset = 0;
        $display("\n>>> EXECUTING ON PROCESSOR HARDWARE CYCLE-BY-CYCLE <<<\n");

        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            #1;
            $display("[Cycle %0d] PC=0x%02h | Instruction=0x%08h | ALU_Out=0x%08h | x1=%0d, x2=%0d, x3=%0d, x4=%0d",
                     i + 1, pc, instruction, alu_result,
                     uut.rf_inst.registers[1],
                     uut.rf_inst.registers[2],
                     uut.rf_inst.registers[3],
                     uut.rf_inst.registers[4]);
        end

        #10;
        $display("\n==================================================================");
        $display("                    FINAL EXECUTION RESULT                        ");
        $display("==================================================================");
        $display("Input Operand A (Register x1)  : %0d", uut.rf_inst.registers[1]);
        $display("Input Operand B (Register x2)  : %0d", uut.rf_inst.registers[2]);
        $display("Operation Performed            : %0s", opName);
        $display("ALU Computation Result (x3)    : %0d", uut.rf_inst.registers[3]);
        $display("Memory Verified Result (x4)    : %0d (Read back via LW)", uut.rf_inst.registers[4]);
        $display("==================================================================");
        $display("Execution completed successfully!\n");

        $finish;
    end

endmodule
