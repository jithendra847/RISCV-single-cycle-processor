# Single-Cycle 32-Bit RISC-V (RV32I) Processor in Verilog

A complete, clean, and modular implementation of a **Single-Cycle RISC-V (RV32I) Processor Core** written in standard Verilog HDL. Includes an **interactive simulation mode** that accepts live user inputs, dynamic machine code generation, automated verification testbenches, and line-by-line documentation.

---

## 📌 Project Highlights
- **Architecture**: 32-bit Single-Cycle RISC-V (RV32I Base Integer Instruction Set).
- **Execution Model**: 1 Instruction executed per clock cycle (Fetch -> Decode -> Execute -> Memory -> Writeback).
- **Supported Instructions**:
  - **R-type**: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLL`, `SRL`
  - **I-type Arithmetic**: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI`, `SLLI`, `SRLI`
  - **Load / Store**: `LW` (Load Word), `SW` (Store Word)
  - **Branch / Jump**: `BEQ` (Branch if Equal), `BNE` (Branch if Not Equal), `JAL` (Jump and Link)
- **Interactive Mode**: User can enter operands $A$ and $B$, select an arithmetic/logic operation, and watch the processor execute it cycle-by-cycle!
- **Zero-Dependency Runner**: Includes both standard Verilog testbenches (`iverilog`/ModelSim/EDA Playground) and a Python cycle-accurate simulator that runs instantly on any machine.

---

## 🏗️ Hardware Architecture & Datapath

```
                                  +-------------------+
                                  |    Imm Generator  |----+
                                  +-------------------+    |
                                      ^                    |
                                      | [31:0]             v
                 +--------------+     |                +-------+
                 | Instruction  |-----+ [19:15] rs1--->|       |
      +--------->|    Memory    |-----+ [24:20] rs2--->|  ALU  |----+
      |          +--------------+     | [11:7]  rd --->|       |    |
      |                 ^             v                +-------+    |
+-----------+           |         +--------+               |        |
|    PC     |-----------+         | Register|              v        v
|  Register |                     |  File  |           +-------------+
+-----------+                     +--------+           | Data Memory |
      ^                                                +-------------+
      |                                                       |
      +----------------- Next PC Logic / Multiplexers <-------+
```

### Project Design Structure

The project offers **two design formats** depending on preference:
1. **Unified Core (Recommended for Presentation & Learning)**:
   - [`riscv_processor.v`](riscv_processor.v): The entire single-cycle processor in **one clean, continuous module** (~250 lines). All 5 stages (Fetch, Decode, Execute, Memory, Writeback) are clearly visible in sequence without jumping across files!
   - [`testbench.v`](testbench.v): Simple, self-checking testbench.
2. **Modular Hierarchy (Alternative for Advanced Grading)**:
   - Located in [`src/`](src/): Separated into 8 dedicated sub-modules (`Program_Counter.v`, `Instruction_Memory.v`, `Register_File.v`, `Imm_Gen.v`, `Control_Unit.v`, `ALU_Control.v`, `ALU.v`, `Data_Memory.v`) interconnected by [`src/riscv_top.v`](src/riscv_top.v).

---

## 🚀 How to Run the Project

### Option 1: One-Click Interactive Runner (Recommended for Demo)
Open terminal in the project folder and run:
```bash
./run_project.sh
```
Or directly via Python:
```bash
python3 interactive_sim.py
```
**Interactive Demo Prompt:**
1. Enter Operand A (e.g. `45`).
2. Enter Operand B (e.g. `15`).
3. Select operation: `1` for ADD, `2` for SUB, `3` for AND, `4` for OR, `5` for XOR, `6` for SLT.
4. Watch the processor load the numbers into registers `x1` and `x2`, compute into `x3`, store into Data Memory via `SW`, and load back via `LW`!

### Option 2: Automated Hardware Verification Suite
```bash
python3 interactive_sim.py --test
```
Executes a 12-cycle diagnostic test program covering `ADDI`, `ADD`, `SUB`, `AND`, `OR`, `SLT`, `SW`, `LW`, `BEQ` (branch skip), and destination jump.

### Option 3: Verilog Simulation via Icarus Verilog (`iverilog`)
If you have `iverilog` installed:
```bash
# Automated Testbench
iverilog -o sim_riscv src/*.v testbench/tb_riscv.v
vvp sim_riscv

# Interactive Verilog Testbench
iverilog -o sim_interactive src/*.v testbench/tb_interactive.v
vvp sim_interactive
```
Waveform file `riscv.vcd` is generated and can be viewed using **GTKWave**:
```bash
gtkwave riscv.vcd
```

### Option 4: Run Online on EDA Playground (No Installation Required!)
1. Go to [https://www.edaplayground.com](https://www.edaplayground.com).
2. Set **Language** to `Verilog/SystemVerilog`.
3. Set **Simulator** to `Icarus Verilog 0.10.0` or `Aldec Riviera Pro`.
4. Copy the entire contents of [`src/riscv_single_file.v`](src/riscv_single_file.v) into the **left pane (`design.sv`)**.
5. Copy [`testbench/tb_riscv.v`](testbench/tb_riscv.v) or [`testbench/tb_interactive.v`](testbench/tb_interactive.v) into the **right pane (`testbench.sv`)**.
6. Check **Open EPWave after run** and click **Run**!

---

## 📁 Repository Structure
```
RiscV/
├── riscv_processor.v           # [MAIN] Unified Single-Module Core (~250 lines, all 5 stages in 1 file!)
├── testbench.v                 # [MAIN] Testbench for unified processor
├── interactive_sim.py          # Interactive user-input hardware runner
├── run_project.sh              # One-click execution shell script
├── PROJECT_GUIDE_HINGLISH.md   # Line-by-line explanation, slides, & viva prep
├── README.md                   # Project overview & documentation
├── src/                        # Modular alternative (8 sub-modules + riscv_top.v)
│   ├── Program_Counter.v
│   ├── Instruction_Memory.v
│   ├── Register_File.v
│   ├── Imm_Gen.v
│   ├── Control_Unit.v
│   ├── ALU_Control.v
│   ├── ALU.v
│   ├── Data_Memory.v
│   └── riscv_top.v
└── testbench/
    ├── tb_riscv.v
    └── tb_interactive.v
```
