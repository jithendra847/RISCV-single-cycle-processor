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

### Module Breakdown
| Module | File | Function |
|---|---|---|
| **Program Counter** | [`src/Program_Counter.v`](src/Program_Counter.v) | Holds the 32-bit address of current instruction; updates on clock edge. |
| **Instruction Memory** | [`src/Instruction_Memory.v`](src/Instruction_Memory.v) | Stores 64 words (32-bit each) of instructions; indexed by `PC[7:2]`. |
| **Register File** | [`src/Register_File.v`](src/Register_File.v) | 32 general-purpose 32-bit registers (`x0` to `x31`). `x0` is hardwired to 0. |
| **Immediate Generator** | [`src/Imm_Gen.v`](src/Imm_Gen.v) | Extracts and sign-extends immediate fields (I, S, B, J, U formats). |
| **Control Unit** | [`src/Control_Unit.v`](src/Control_Unit.v) | Decodes 7-bit opcode to generate datapath control signals. |
| **ALU Control** | [`src/ALU_Control.v`](src/ALU_Control.v) | Decodes `ALUOp`, `funct3`, and `funct7[5]` into 4-bit ALU operation code. |
| **ALU** | [`src/ALU.v`](src/ALU.v) | Performs 32-bit arithmetic, logic, shift, and comparison operations. |
| **Data Memory** | [`src/Data_Memory.v`](src/Data_Memory.v) | 64-word RAM for `LW` (read) and `SW` (synchronous write) instructions. |
| **Top Core** | [`src/riscv_top.v`](src/riscv_top.v) | Wires together all components and exposes debug observation signals. |
| **Single-File Core** | [`src/riscv_single_file.v`](src/riscv_single_file.v) | Combined design file for easy copy-pasting into EDA Playground. |

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
├── src/
│   ├── Program_Counter.v       # 32-bit PC register with synchronous update
│   ├── Instruction_Memory.v    # 64-word ROM initialized with program
│   ├── Register_File.v         # 32x32 general purpose register file (x0=0)
│   ├── Imm_Gen.v               # Sign extension immediate generator
│   ├── Control_Unit.v          # Main opcode decoder
│   ├── ALU_Control.v           # ALU operation code generator
│   ├── ALU.v                   # 32-bit Arithmetic Logic Unit
│   ├── Data_Memory.v           # Data RAM for load/store
│   ├── riscv_top.v             # Top-level integrated processor core
│   └── riscv_single_file.v     # Single-file bundle for EDA Playground
├── testbench/
│   ├── tb_riscv.v              # Automated verification testbench with VCD dump
│   └── tb_interactive.v        # Interactive stdin-based Verilog testbench
├── interactive_sim.py          # Cycle-accurate interactive simulator & runner
├── run_project.sh              # One-click execution shell script
├── PROJECT_GUIDE_HINGLISH.md   # Line-by-line explanation, slides, & viva prep
└── README.md                   # Project overview & documentation
```
# RiscV
