# 🎓 RISC-V Single-Cycle Processor — Complete Line-by-Line Guide & Presentation Notes

> **Language**: Hinglish (Hindi + English) — Designed specifically for college students presenting to professors and facing Viva / Lab evaluations.

---

## 📑 Table of Contents
1. [Basic Concepts: RISC-V aur Single Cycle kya hota hai?](#1-basic-concepts)
2. [Processor Architecture & Datapath Blocks](#2-processor-architecture)
3. [Line-by-Line Code Explanation](#3-line-by-line-code-explanation)
   - [Module 1: Program_Counter.v](#module-1-program_counterv)
   - [Module 2: Instruction_Memory.v](#module-2-instruction_memoryv)
   - [Module 3: Register_File.v](#module-3-register_filev)
   - [Module 4: Imm_Gen.v](#module-4-imm_genv)
   - [Module 5: Control_Unit.v](#module-5-control_unitv)
   - [Module 6: ALU_Control.v](#module-6-alu_controlv)
   - [Module 7: ALU.v](#module-7-aluv)
   - [Module 8: Data_Memory.v](#module-8-data_memoryv)
   - [Module 9: riscv_top.v](#module-9-riscv_topv)
   - [Module 10: tb_interactive.v (User Input Module)](#module-10-tb_interactivev)
4. [Step-by-Step Instruction Tracing (Signals Kaise Travel Karte Hain)](#4-instruction-tracing)
5. [Presentation Slides Blueprint (Teacher ke Saamne Kya Bolna Hai)](#5-presentation-blueprint)
6. [Top 15 Viva Questions & Answers](#6-viva-questions--answers)

---

## 1. Basic Concepts

### Q: RISC-V kya hai?
- **RISC** ka full form hai: **Reduced Instruction Set Computer**.
- **RISC-V** (pronunciation: "Risk-Five") ek **Open Source Instruction Set Architecture (ISA)** hai jo UC Berkeley ne banayi thi. Iske liye koi license fee nahi deni padti (jaise ARM ya x86 me deni padti hai).
- Humne **RV32I** implement kiya hai:
  - **32**: Data bus aur Registers 32-bit ke hain.
  - **I**: Base Integer instruction set (add, sub, lw, sw, beq, etc.).

### Q: "Single-Cycle Processor" ka kya matlab hota hai?
- Ek instruction ko execute hone me 5 steps lagte hain:
  1. **Instruction Fetch (IF)**: Memory se instruction nikalna.
  2. **Instruction Decode (ID)**: Opcode samajhna aur registers se data read karna.
  3. **Execute (EX)**: ALU me calculation karna.
  4. **Memory Access (MEM)**: Agar LW/SW hai to RAM se data padhna ya likhna.
  5. **Write Back (WB)**: Result ko destination register me store karna.
- **Single-Cycle** me ye saare 5 steps **ek hi clock cycle** ke andar complete hote hain!
- Clock ka time period processor ki sabse lambi instruction (`LW` - Load Word) ke delay ke barabar rakha jata hai.

---

## 2. Processor Architecture

```
                  +--------------------------------------------------------+
                  |                     Control Unit                       |
                  +--------------------------------------------------------+
                        |           |         |        |         |       |
                     Branch     MemRead   MemToReg   ALUOp    MemWrite ALUSrc RegWrite
                        |           |         |        |         |       |       |
                        v           v         v        v         v       v       v
   +-------+        +-------+               +-----+          +-----+   +-----+
   |  PC   |------->| IMEM  |---+ [19:15] ->|     |--------->|     |-->|DMEM |
   +-------+        +-------+   | [24:20] ->| RF  |----+     | ALU |   +-----+
       ^                        | [11:7]  ->|     |    |     |     |      |
       |                        |           +-----+    |     +-----+      |
   Next PC Mux <----------------+                      v        |         |
                                |                   ALUSrc Mux  |         |
                                v                      |        |         |
                            +-------+                  v        |         |
                            |ImmGen |--------------> MuxB       |         |
                            +-------+                           v         v
                                                        Writeback Mux <---+
```

---

## 3. Line-by-Line Code Explanation

### Module 1: `Program_Counter.v`
```verilog
module Program_Counter (
    input  wire        clk,        // Clock signal
    input  wire        reset,      // Reset signal
    input  wire [31:0] next_pc,    // Agli instruction ka address
    output reg  [31:0] pc          // Current instruction ka address
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;    // Reset high hone par PC = 0
        end else begin
            pc <= next_pc;         // Har clock tick par next_pc ko store karo
        end
    end
endmodule
```
- **Line 1-6**: Module declaration. PC ek 32-bit register hai jiska input `next_pc` aur output `pc` hai.
- **Line 8**: `always @(posedge clk or posedge reset)`: Yeh sequential circuit hai. Yeh block tab run hota hai jab Clock 0 se 1 hoti hai (rising edge) ya Reset 1 hota hai.
- **Line 9-13**: Reset aane par PC ko 0 pe initialize karte hain. Normal operation me PC update hoke agla address le leta hai.

---

### Module 2: `Instruction_Memory.v`
```verilog
module Instruction_Memory (
    input  wire [31:0] pc,            // PC se 32-bit address aata hai
    output wire [31:0] instruction    // 32-bit instruction output hoti hai
);

    reg [31:0] memory [0:63];         // 64 instructions ka array (32-bit each)

    assign instruction = memory[pc[7:2]]; // Word alignment: pc >> 2
```
- **`reg [31:0] memory [0:63]`**: 64 words ki ROM memory jisme hamara machine code store rehta hai.
- **`pc[7:2]` kyu use kiya?**:
  - RISC-V me memory **byte-addressable** hoti hai aur har instruction **4 bytes (32-bit)** ki hoti hai.
  - Iska matlab instruction addresses hote hain: 0, 4, 8, 12, 16...
  - Address 0 = Instruction 0 (`0 / 4 = 0`)
  - Address 4 = Instruction 1 (`4 / 4 = 1`)
  - Address 8 = Instruction 2 (`8 / 4 = 2`)
  - Binary me kisi number ko 4 se divide karne ka matlab hota hai last 2 bits drop karna (`pc >> 2`). Isliye hum bits `pc[7:2]` se index karte hain.
- **`assign instruction = ...`**: Yeh combinational read hai, jaise hi PC change hoga, instruction instantly wire par aa jayegi.

---

### Module 3: `Register_File.v`
```verilog
module Register_File (
    input  wire        clk,
    input  wire        reset,
    input  wire        reg_write,    // 1 = destination register me likhna hai
    input  wire [4:0]  rs1,          // Source 1 register number (0 to 31)
    input  wire [4:0]  rs2,          // Source 2 register number (0 to 31)
    input  wire [4:0]  rd,           // Destination register number (0 to 31)
    input  wire [31:0] write_data,   // Data jo store karna hai
    output wire [31:0] read_data1,   // rs1 ki value
    output wire [31:0] read_data2    // rs2 ki value
);
    reg [31:0] registers [0:31];
```
- **RISC-V me 32 registers hote hain** (`x0` se `x31`). Isliye register address 5-bit ka hota hai ($2^5 = 32$).
- **Combinational Read**:
  ```verilog
  assign read_data1 = (rs1 == 5'd0) ? 32'h00000000 : registers[rs1];
  assign read_data2 = (rs2 == 5'd0) ? 32'h00000000 : registers[rs2];
  ```
  - **Most Important Rule**: Register `x0` hamesha **0** rehta hai! Agar `rs1 == 0`, to direct 0 bhejo.
- **Synchronous Write**:
  ```verilog
  always @(posedge clk or posedge reset) begin
      if (reset) begin ... end
      else if (reg_write && (rd != 5'd0)) begin
          registers[rd] <= write_data;
      end
  end
  ```
  - `reg_write` high hona chahiye aur `rd != 0` hona chahiye (kyunki `x0` par kabhi write nahi ho sakta).

---

### Module 4: `Imm_Gen.v` (Immediate Generator)
RISC-V me constants (immediates) instruction ke alag-alag bit positions me hote hain:
- **I-type (ADDI, LW)**: Bits `[31:20]` immediate hote hain (12-bit).
  ```verilog
  imm_ext = {{20{instruction[31]}}, instruction[31:20]};
  ```
  - `{{20{instruction[31]}}}` ka matlab hai sign bit (bit 31) ko 20 baar copy karo taaki 12-bit number 32-bit signed integer ban jaye!
- **S-type (SW)**: Immediate bits 2 tukdon me hoti hain: `[31:25]` aur `[11:7]`.
  ```verilog
  imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
  ```
- **B-type (BEQ, BNE)**: Branch offset me bit 0 hamesha 0 hoti hai (kyunki instructions 2/4 byte aligned hoti hain).
  ```verilog
  imm_ext = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
  ```

---

### Module 5: `Control_Unit.v`
Yeh module instruction ke pehle 7 bits (`opcode = instruction[6:0]`) dekhkar decision leta hai:
| Instruction Type | Opcode | `RegWrite` | `ALUSrc` | `MemWrite` | `MemRead` | `MemToReg` | `Branch` | `ALUOp` |
|---|---|---|---|---|---|---|---|---|
| **R-type** (ADD, SUB...) | `0110011` | 1 | 0 | 0 | 0 | 0 | 0 | `2'b10` |
| **I-type** (ADDI...) | `0010011` | 1 | 1 | 0 | 0 | 0 | 0 | `2'b11` |
| **Load** (LW) | `0000011` | 1 | 1 | 0 | 1 | 1 | 0 | `2'b00` |
| **Store** (SW) | `0100011` | 0 | 1 | 1 | 0 | 0 | 0 | `2'b00` |
| **Branch** (BEQ) | `1100011` | 0 | 0 | 0 | 0 | 0 | 1 | `2'b01` |
| **Jump** (JAL) | `1101111` | 1 | 0 | 0 | 0 | 0 | 0 | `2'b00` |

- **`ALUSrc`**: Agar 1 hai, to ALU ka second operand immediate value banega (`imm_ext`). Agar 0 hai, to register `rs2` ka data aayega.
- **`MemToReg`**: Agar 1 hai (LW me), to memory se aaya hua data register me likha jayega. Agar 0 hai, to ALU ka result register me likha jayega.

---

### Module 6: `ALU_Control.v`
Yeh unit 2-bit `alu_op`, 3-bit `funct3`, aur `funct7[5]` ko dekhkar exact 4-bit operation code banati hai:
- `4'b0000` = AND
- `4'b0001` = OR
- `4'b0010` = ADD
- `4'b0110` = SUB
- `4'b0111` = SLT (Set Less Than)
- `4'b1000` = XOR
- `4'b0011` = SLL (Shift Left)
- `4'b0101` = SRL (Shift Right)

---

### Module 7: `ALU.v`
```verilog
module ALU (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] result,
    output wire        zero
);
    assign zero = (result == 32'h00000000); // Agar result 0 hai to zero = 1
```
- `zero` flag ka role: Jab BEQ instruction aati hai, ALU `a - b` karta hai. Agar $a == b$ hoga to result 0 hoga, aur `zero` flag 1 ho jayega. Isse processor samajhta hai ki condition TRUE hai aur branch lena hai!

---

### Module 8: `Data_Memory.v`
- 64 words ki RAM memory hai.
- **`MemRead == 1`**: Asynchronous read hota hai (`read_data = memory[addr[7:2]]`).
- **`MemWrite == 1`**: Clock ke rising edge par data memory me write hota hai (`memory[addr[7:2]] <= write_data`).

---

### Module 9: `riscv_top.v`
Yeh saare modules ko aapas me wire se jodta hai:
1. **PC Logic**:
   ```verilog
   assign pc_plus_4     = pc_current + 32'd4;
   assign branch_target = pc_current + imm_ext;
   assign pc_next       = (take_branch) ? branch_target : pc_plus_4;
   ```
2. **ALU Input Multiplexer**:
   ```verilog
   assign alu_operand_b = (alu_src) ? imm_ext : reg_read_data2;
   ```
3. **Register Writeback Multiplexer**:
   ```verilog
   assign reg_write_data = (jump)       ? pc_plus_4 :
                           (mem_to_reg) ? mem_read_data :
                                          alu_result;
   ```

---

### Module 10: `tb_interactive.v` (User Input Module)
Aapke requirement ke mutabik: *"take input from user for performig operation in project"*.
1. `$fscanf(32'h8000_0000, "%d", numA)` se user se terminal par Operand A aur B input liya jata hai.
2. User se operation choose karwaya jata hai (ADD, SUB, AND, OR, SLT, XOR).
3. **Dynamic Machine Code Generation**:
   Testbench khud Verilog ke andar binary machine code generate karta hai:
   - `instr0 = {numA[11:0], 5'd0, 3'b000, 5'd1, 7'b0010011};` (ADDI x1, x0, numA)
   - `instr1 = {numB[11:0], 5'd0, 3'b000, 5'd2, 7'b0010011};` (ADDI x2, x0, numB)
   - `instr2` = Target Operation between `x1` and `x2`, saving to `x3`!
   - `instr3` = `SW x3, 0(x0)` (Store in RAM)
   - `instr4` = `LW x4, 0(x0)` (Load back from RAM to verify)
4. Ye instructions Instruction Memory me load hoti hain aur processor inhein hardware cycle-by-cycle execute karta hai!

---

## 4. Step-by-Step Instruction Tracing

Chaliye ek example dekhte hain: **`ADD x3, x1, x2`** (Maano `x1 = 5`, `x2 = 10`)
1. **Clock Cycle Start**: PC = `0x08`.
2. **Fetch**: `Instruction_Memory` se `0x002081B3` nikalta hai.
3. **Decode**:
   - `opcode = 7'b0110011` (R-type).
   - `Control_Unit` sets: `RegWrite = 1`, `ALUSrc = 0`, `MemWrite = 0`, `MemRead = 0`, `MemToReg = 0`, `ALUOp = 2'b10`.
   - `Register_File` reads `x1` (output = 5) and `x2` (output = 10).
4. **Execute**:
   - `ALUSrc = 0` hone ki wajah se `alu_b = read_data2 = 10`.
   - `ALU_Control` sets `4'b0010` (ADD).
   - ALU computes: `5 + 10 = 15`.
5. **Memory**: `MemRead = 0` and `MemWrite = 0` (No memory operation).
6. **Writeback**: `MemToReg = 0` hone par ALU output (15) register `x3` ke input par aata hai.
7. **Clock Next Edge**: Register `x3` updates to 15! PC updates to `0x0C` (`PC + 4`).

---

## 5. Presentation Slides Blueprint

Teacher ke saamne presentation dete waqt ye 8-10 slides follow kijiye:

### Slide 1: Title Slide
- **Title**: Design and Implementation of a Single-Cycle 32-Bit RISC-V Processor Core in Verilog HDL
- **Subtitle**: RV32I Architecture with Interactive Simulation Interface
- **Your Name & Roll No.**

### Slide 2: Problem Statement & Objectives
- Objective: To design a functional, synthesizable single-cycle 32-bit RISC-V (RV32I) core.
- Implement key instruction formats: R-type, I-type, S-type, B-type, and J-type.
- Provide interactive verification where user inputs operands and operations dynamically.

### Slide 3: What is RISC-V & Single-Cycle Datapath?
- RISC-V: Open, royalty-free, modular ISA with 32 general-purpose registers.
- Single-cycle: 1 instruction executed per clock cycle across 5 functional stages (Fetch, Decode, Execute, Memory, Writeback).

### Slide 4: Datapath Block Diagram
- *(Show the block diagram from Section 2 of this guide)*.
- Mention all 8 core modules: PC, IMEM, RegFile, ImmGen, Control Unit, ALU Control, ALU, DMEM.

### Slide 5: Instruction Formats Implemented
- **R-type**: ADD, SUB, AND, OR, XOR, SLT (Register to Register)
- **I-type**: ADDI, ANDI, ORI, LW (Immediate / Load)
- **S-type**: SW (Store to Memory)
- **B-type**: BEQ, BNE (Conditional Branching)
- **J-type**: JAL (Unconditional Jump)

### Slide 6: Control Unit & Decoding Logic
- Show the Control Signals Table (RegWrite, ALUSrc, MemToReg, etc.).
- Explain how the 7-bit opcode dictates data routing through multiplexers.

### Slide 7: Interactive User Input Feature
- Explain how user inputs $A$ and $B$ are converted into binary instructions on-the-fly.
- Show that hardware executes the user operation and verifies data via Memory Store (`SW`) and Load (`LW`).

### Slide 8: Live Demonstration & Results
- Run `./run_project.sh` or `python3 interactive_sim.py`.
- Show cycle-by-cycle register updates and final output.

### Slide 9: Conclusion & Future Scope
- Successfully implemented and verified RV32I single-cycle processor.
- Future Scope: Extending to a 5-stage Pipelined processor with Hazard Detection and Branch Prediction.

---

## 6. Top 15 Viva Questions & Answers

### Q1: RISC-V me register x0 hamesha 0 kyu rehta hai?
> **Answer**: `x0` ko hardwire zero isliye banaya jata hai taaki common operations ke liye alag se instructions na banani pade. Jaise:
> - NOP (No Operation) = `ADDI x0, x0, 0`
> - MOV (Copy register) = `ADD rd, rs, x0`
> - Clear register = `ADD rd, x0, x0`

### Q2: Single-cycle processor me clock speed kis cheez se limit hoti hai?
> **Answer**: Clock period sabse slow instruction ke critical path delay se decide hota hai, jo ki **`LW` (Load Word)** instruction hai. LW me instruction fetch, register read, ALU address calculation, memory read, aur register writeback—saare 5 steps ek hi cycle me hote hain.

### Q3: Single-Cycle aur Multi-Cycle / Pipelined processor me kya farak hai?
> **Answer**:
> - **Single-Cycle**: Har instruction 1 clock cycle me poori hoti hai, clock slow hoti hai, CPI = 1.
> - **Pipelined**: Har stage alag clock cycle me hoti hai. Multiple instructions ek saath alag stages me chal sakti hain (throughput badh jata hai).

### Q4: Instruction memory me `pc[7:2]` kyu use kiya gaya na ki `pc[7:0]`?
> **Answer**: Kyunki RISC-V instructions 32-bit (4 bytes) ki hoti hain aur word-aligned hoti hain. Byte address ko 4 se divide karne ke liye hum right shift by 2 karte hain (`pc >> 2`), jiska matlab bits `[7:2]` index banti hain.

### Q5: ALU me `zero` flag ka kya use hai?
> **Answer**: `zero` flag branch instructions (`BEQ`) ke liye use hota hai. Branch instruction me ALU dono registers ko subtract karta hai. Agar dono barabar hote hain to result 0 aata hai, aur `zero` flag 1 ho jata hai, jisse processor ko pata chalta hai ki branch target par jump karna hai.

### Q6: Sign Extension (`Imm_Gen`) ki zaroorat kyu padti hai?
> **Answer**: Instructions me immediate values 12-bit ya 20-bit ki hoti hain, lekin hamara ALU aur Registers 32-bit ke hote hain. Signed arithmetic sahi hone ke liye 12-bit number ko 32-bit signed format me convert (sign-extend) karna zaroori hota hai.

### Q7: Register file me read combinational aur write synchronous (clocked) kyu hota hai?
> **Answer**: Read combinational hota hai taaki usi cycle me register ka data ALU tak pahunch sake. Write synchronous hota hai taaki naya result agle clock cycle ke start pe safely latch ho sake, race condition na ho.

### Q8: `ALUSrc` multiplexer ka kya kaam hai?
> **Answer**: Yeh decide karta hai ki ALU ka doosra operand register `rs2` ka data hoga (R-type me) ya Immediate value hogi (I-type aur Load/Store me).

### Q9: `MemToReg` multiplexer ka kya kaam hai?
> **Answer**: Yeh decide karta hai ki destination register `rd` me ALU ka result jayega (R-type/I-type) ya Data Memory se padha hua data jayega (LW instruction me).

### Q10: BEQ instruction me `PC + 4` ki jagah kya load hota hai?
> **Answer**: Agar condition satisfy hoti hai to `PC + (Immediate)` load hota hai, jise branch target address kehte hain.

---
*Wish you all the best for your project presentation and viva! You will ace it!*
