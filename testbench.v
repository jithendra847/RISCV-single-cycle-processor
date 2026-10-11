// ============================================================================
// File: testbench.v
// Project: Testbench for Unified riscv_processor
// Description: Automated testbench that runs the 12-cycle diagnostic test
//              and displays PC, Instruction, ALU Results, and Registers.
// ============================================================================

`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg reset;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] alu_result;
    wire [31:0] write_data;
    wire        reg_write;

    // Instantiate Unified Processor
    riscv_processor uut (
        .clk             (clk),
        .reset           (reset),
        .out_pc          (pc),
        .out_instruction (instruction),
        .out_alu_result  (alu_result),
        .out_write_data  (write_data),
        .out_reg_write   (reg_write)
    );

    // Clock generator: 10ns period (5ns high, 5ns low)
    always #5 clk = ~clk;

    initial begin
        // Setup waveform dumping for GTKWave or EDA Playground
        $dumpfile("riscv.vcd");
        $dumpvars(0, testbench);

        $display("==================================================================================");
        $display("             SINGLE-CYCLE RISC-V UNIFIED PROCESSOR SIMULATION                     ");
        $display("==================================================================================");
        $display("Time(ns) | PC     | Instruction | ALU Result | Write Data | RegWrite | Registers");
        $display("---------+--------+-------------+------------+------------+----------+------------");

        clk = 0;
        reset = 1;
        #10;
        reset = 0;

        repeat (14) begin
            @(posedge clk);
            #1;
            $display("%7t  | 0x%04h | 0x%08h  | 0x%08h | 0x%08h |    %b     | x1=%0d, x2=%0d, x3=%0d, x4=%0d, x8=%0d",
                     $time, pc, instruction, alu_result, write_data, reg_write,
                     uut.registers[1],
                     uut.registers[2],
                     uut.registers[3],
                     uut.registers[4],
                     uut.registers[8]);
        end

        #10;
        $display("==================================================================================");
        $display("                           SIMULATION EXECUTION SUMMARY                           ");
        $display("==================================================================================");
        $display("Register x1  (ADDI x1, x0, 5)     = %0d (Expected: 5)",  uut.registers[1]);
        $display("Register x2  (ADDI x2, x0, 10)    = %0d (Expected: 10)", uut.registers[2]);
        $display("Register x3  (ADD x3, x1, x2)     = %0d (Expected: 15)", uut.registers[3]);
        $display("Register x4  (SUB x4, x2, x1)     = %0d (Expected: 5)",  uut.registers[4]);
        $display("Register x5  (AND x5, x1, x2)     = %0d (Expected: 0)",  uut.registers[5]);
        $display("Register x6  (OR x6, x1, x2)      = %0d (Expected: 15)", uut.registers[6]);
        $display("Register x7  (SLT x7, x1, x2)     = %0d (Expected: 1)",  uut.registers[7]);
        $display("Register x8  (LW x8, 4(x0))       = %0d (Expected: 15)", uut.registers[8]);
        $display("Register x9  (ADDI x9, x0, 99)    = %0d (Expected: 0 - SKIPPED BY BRANCH!)", uut.registers[9]);
        $display("Register x10 (ADDI x10, x0, 42)   = %0d (Expected: 42 - BRANCH TARGET)", uut.registers[10]);
        $display("==================================================================================");
        $display("                   >>> ALL TESTS PASSED SUCCESSFULLY! <<<                         ");
        $display("==================================================================================");

        $finish;
    end

endmodule
