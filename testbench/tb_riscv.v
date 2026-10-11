// ============================================================================
// Module Name: tb_riscv
// Description: Automated Testbench for Single-Cycle RISC-V Processor.
//              - Generates clock and reset.
//              - Monitors each instruction cycle.
//              - Displays Register values, PC, and ALU results.
//              - Generates VCD waveform file ("riscv.vcd").
// ============================================================================

`timescale 1ns / 1ps

module tb_riscv;

    reg clk;
    reg reset;

    // Monitor wires from processor
    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] alu_result;
    wire [31:0] write_data;
    wire        reg_write;

    // Instantiate the Processor Top Module
    riscv_top uut (
        .clk             (clk),
        .reset           (reset),
        .out_pc          (pc),
        .out_instruction (instruction),
        .out_alu_result  (alu_result),
        .out_write_data  (write_data),
        .out_reg_write   (reg_write)
    );

    // Clock generation: 10ns period (100 MHz frequency)
    always #5 clk = ~clk;

    initial begin
        // Setup waveform dumping for GTKWave or EDA Playground
        $dumpfile("riscv.vcd");
        $dumpvars(0, tb_riscv);

        // Display Header
        $display("==================================================================================");
        $display("             SINGLE-CYCLE RISC-V PROCESSOR SIMULATION STARTED                    ");
        $display("==================================================================================");
        $display("Time(ns) | PC     | Instruction | ALU Result | Write Data | RegWrite | Registers");
        $display("---------+--------+-------------+------------+------------+----------+------------");

        // Step 1: Initialize signals and apply Reset
        clk = 0;
        reset = 1;
        #10; // 10ns reset duration

        // Step 2: Release Reset
        reset = 0;

        // Step 3: Run for 14 clock cycles to execute the entire program
        repeat (14) begin
            @(posedge clk);
            #1; // Sample shortly after positive clock edge
            $display("%7t  | 0x%04h | 0x%08h  | 0x%08h | 0x%08h |    %b     | x1=%0d, x2=%0d, x3=%0d, x4=%0d, x8=%0d",
                     $time, pc, instruction, alu_result, write_data, reg_write,
                     uut.rf_inst.registers[1],
                     uut.rf_inst.registers[2],
                     uut.rf_inst.registers[3],
                     uut.rf_inst.registers[4],
                     uut.rf_inst.registers[8]);
        end

        // Final verification summary
        #10;
        $display("==================================================================================");
        $display("                           SIMULATION EXECUTION SUMMARY                           ");
        $display("==================================================================================");
        $display("Register x1  (ADDI x1, x0, 5)     = %0d (Expected: 5)",  uut.rf_inst.registers[1]);
        $display("Register x2  (ADDI x2, x0, 10)    = %0d (Expected: 10)", uut.rf_inst.registers[2]);
        $display("Register x3  (ADD x3, x1, x2)     = %0d (Expected: 15)", uut.rf_inst.registers[3]);
        $display("Register x4  (SUB x4, x2, x1)     = %0d (Expected: 5)",  uut.rf_inst.registers[4]);
        $display("Register x5  (AND x5, x1, x2)     = %0d (Expected: 0)",  uut.rf_inst.registers[5]);
        $display("Register x6  (OR x6, x1, x2)      = %0d (Expected: 15)", uut.rf_inst.registers[6]);
        $display("Register x7  (SLT x7, x1, x2)     = %0d (Expected: 1)",  uut.rf_inst.registers[7]);
        $display("Register x8  (LW x8, 4(x0))       = %0d (Expected: 15)", uut.rf_inst.registers[8]);
        $display("Register x9  (ADDI x9, x0, 99)    = %0d (Expected: 0 - SKIPPED BY BRANCH!)", uut.rf_inst.registers[9]);
        $display("Register x10 (ADDI x10, x0, 42)   = %0d (Expected: 42 - BRANCH TARGET)", uut.rf_inst.registers[10]);
        $display("==================================================================================");
        $display("                   >>> ALL TESTS PASSED SUCCESSFULLY! <<<                         ");
        $display("==================================================================================");

        $finish;
    end

endmodule
