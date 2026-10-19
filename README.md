# Single-Cycle 32-Bit RISC-V Processor

**Prepared by: Jithendra**

This project implements a 32-bit single-cycle processor based on the RISC-V RV32I instruction set using Verilog HDL. It includes a modular hardware design and Verilog testbenches for simulation and validation.

## Features

- 32-bit datapath and 32 integer registers (`x0`–`x31`); register `x0` always reads as zero.
- Single-cycle instruction execution with instruction fetch, decode, execute, memory access, and writeback.
- Arithmetic and logic operations: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLL`, and `SRL`.
- Immediate operations: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI`, `SLLI`, and `SRLI`.
- Word memory operations: `LW` and `SW`.
- Control flow: `BEQ`, `BNE`, and `JAL`.
- Verilog-only simulation and hardware verification flow.

## Run the project

From the project directory, use the project runner to select a Verilog simulation mode:

```bash
./run_project.sh
```

The script supports:

- Automated verification of the RV32I instruction set
- Compilation and execution of the base Verilog testbench
- Interactive Verilog simulation using the testbench modules in `testbench/`

## Run the Verilog testbenches

With Icarus Verilog installed, compile and run the automated testbench:

```bash
iverilog -o sim_riscv riscv_processor.v testbench.v
vvp sim_riscv
```

To run the interactive Verilog testbench:

```bash
iverilog -o sim_interactive src/*.v testbench/tb_interactive.v
vvp sim_interactive
```

The testbenches may also be run with another Verilog simulator that supports the source files. If waveform output is enabled, open the generated VCD file in GTKWave.

## Design overview

The modular implementation is assembled from the Verilog modules in `src/`. The top-level processor connects the program counter, instruction memory, register file, immediate generator, control logic, ALU, and data memory. The testbenches in `testbench/` exercise the processor and validate the implemented instruction set using a hardware-only simulation flow.

## Instruction flow

1. **Fetch:** Use the program counter to read an instruction.
2. **Decode:** Interpret the instruction fields and read source registers.
3. **Execute:** The ALU performs the requested operation or calculates a memory address.
4. **Memory:** Load from or store to data memory when required.
5. **Writeback:** Save the result to the destination register when required.

Each instruction completes in one clock cycle. As a result, the clock period must accommodate the longest instruction path, typically a load that reads data memory before register writeback.

## Example instruction

For `ADD x3, x1, x2`, if `x1` contains 5 and `x2` contains 10, the processor reads both registers, adds their values in the ALU, and writes 15 to `x3` at the active clock edge. Register `x0` is not writable and always reads as zero.
