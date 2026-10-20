# Single-Cycle RISC-V Processor: Project Guide

**Prepared by: Jithendra and teja**

This guide describes the design, instruction flow, simulation options, and presentation points for the 32-bit single-cycle RISC-V processor implemented in this project.

## 1. Project objective

The objective is to model a basic processor datapath in Verilog. The design fetches a 32-bit instruction, decodes its fields, reads register operands, performs an operation, accesses data memory when needed, and writes a result back to a register. Each supported instruction is designed to complete in one clock cycle.

RISC-V is an open instruction-set architecture. RV32I refers to its 32-bit base integer instruction set. This project implements a teaching subset of RV32I operations, listed in the README.

## 2. Main processor blocks

- **Program counter (PC):** Holds the address of the current instruction. Normal execution advances by four bytes; branches and jumps can select a target address.
- **Instruction memory:** Supplies the instruction addressed by the PC.
- **Control logic:** Decodes the opcode and selects the control signals needed by the datapath.
- **Immediate generator:** Extracts and sign-extends immediate fields for instructions that use constants or offsets.
- **Register file:** Provides two source operands and accepts a result for the destination register. Register `x0` always reads as zero.
- **ALU:** Performs arithmetic, logical, comparison, and address-calculation operations.
- **Data memory:** Supplies values for loads and accepts values for stores.
- **Writeback and next-PC selection:** Selects the value written to a register and the address of the next instruction.

## 3. Instruction cycle

The major datapath stages are:

1. **Fetch:** The PC selects an instruction from instruction memory.
2. **Decode:** The control logic interprets the opcode and fields. The register file provides source values.
3. **Execute:** The ALU performs an arithmetic or logic operation, compares operands, or calculates an address.
4. **Memory access:** A load reads data memory; a store writes a source-register value to data memory. Other instructions do not use this stage's memory operation.
5. **Writeback:** The processor selects the ALU result, loaded data, or return address as appropriate and writes it to the destination register.

These operations form combinational paths during a cycle. State, including the PC, register file, and memory writes, updates at clock edges. Because the design is single-cycle, the clock period must be long enough for the slowest supported instruction path.

## 4. Understanding the instruction fields

A 32-bit instruction contains fields such as:

```text
31                         0
+---------------------------+
| opcode, registers, functs,|
| and/or immediate fields   |
+---------------------------+
```

Common decoded fields include `opcode` (instruction class), `rd` (destination register), `rs1` and `rs2` (source registers), `funct3` and `funct7` (operation details), and an immediate value. The bit positions and immediate layout depend on the instruction format. The immediate generator reconstructs the value and sign-extends it where needed.

## 5. Example: `ADD x3, x1, x2`

Assume `x1` contains 5 and `x2` contains 10.

1. The PC addresses the `ADD` instruction in instruction memory.
2. Decode identifies an integer-register operation and selects `x1` and `x2` as sources.
3. The register file supplies 5 and 10 to the ALU.
4. The ALU adds the values and produces 15.
5. Data memory is not read or written for this instruction.
6. At the clock edge, 15 is written to `x3`; the PC advances to the next instruction.

## 6. Loads, stores, branches, and jumps

- **`LW`:** The ALU adds a base register and a sign-extended offset to form an address. Data memory supplies the word, which is selected for register writeback.
- **`SW`:** The ALU calculates the address from a base register and offset. The second source register supplies the word written to data memory.
- **`BEQ` and `BNE`:** The ALU or comparison logic checks the source operands. The branch condition and immediate offset determine whether the PC selects the branch target or the next sequential address.
- **`JAL`:** The PC selects the jump target, and the return address (`PC + 4`) is written to the destination register.

## 7. Running and demonstrating the project

Use the project runner from the project directory:

```bash
./run_project.sh
```

The script offers hardware-only verification options for the project and runs the corresponding Verilog simulation. A standard automated testbench execution is provided via the shell runner, and interactive Verilog-based behavior can also be selected from the same menu.

With Icarus Verilog installed, compile and execute the hardware testbench directly:

```bash
iverilog -o sim_riscv riscv_processor.v testbench.v
vvp sim_riscv
```

The interactive Verilog testbench can be compiled with:

```bash
iverilog -o sim_interactive src/*.v testbench/tb_interactive.v
vvp sim_interactive
```

## 8. Suggested presentation outline

1. State the objective: implement a 32-bit single-cycle processor in Verilog.
2. Introduce the datapath blocks and explain how they connect.
3. Trace an arithmetic instruction from fetch through writeback.
4. Explain how loads, stores, branches, and jumps differ from arithmetic instructions.
5. Demonstrate the Python simulation or the Verilog testbench and describe the observed result.
6. Discuss the single-cycle trade-off: simple control flow, with the clock period set by the longest instruction path.

