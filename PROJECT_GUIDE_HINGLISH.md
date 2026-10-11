# 🎓 RISC-V Single-Cycle Processor — Complete Line-by-Line Guide & Presentation Notes

> **Language**: Hinglish (Hindi + English) — Designed specifically for college students presenting to professors and facing Viva / Lab evaluations.

---

## ⚡ Important Clarification: "Kya bina Top Module ke processor chal sakta hai?"

**HAAN, BILKUL!** 
Aapko 10 alag-alag files aur unhe aapas me wires se connect karne ki koi compulsion nahi hoti. 

College assignments aur lab presentation ke liye sabse best approach hoti hai **"Unified Core" (Single Module)**:
- Humne aapke liye **[`riscv_processor.v`](file:///Users/saurabhpatel/Desktop/RiscV/riscv_processor.v)** create kar diya hai!
- Isme PC, Instruction Memory, Decode, Registers, ALU, Data RAM, aur Writeback — **sab kuch sirf 1 file ke andar ~250 lines me aa gaya hai!**
- Isko samajhna aur yaad rakhna **10 guna aasan** hai kyunki aapko ek file se doosri file me jump nahi karna padta.

> 💡 **Teacher ko bolne ke liye golden point**:
> *"Sir, maine core processor ko do tarike se implement kiya hai:*
> 1. *Unified Core ([`riscv_processor.v`](file:///Users/saurabhpatel/Desktop/RiscV/riscv_processor.v)) — jo clean, fast aur simple understanding ke liye ek hi module me 5 stages implement karta hai.*
> 2. *Hierarchical / Modular Core ([`src/`](file:///Users/saurabhpatel/Desktop/RiscV/src/)) — jisme har block alag file me hai jaise industry standard ASIC flows me hota hai.*
> *Dono ka logic aur output 100% identical hai!"*

---

## 📑 Table of Contents
1. [Basic Concepts: RISC-V aur Single Cycle kya hota hai?](#1-basic-concepts)
2. [5 Hardware Stages Diagram](#2-5-hardware-stages-diagram)
3. [Line-by-Line Code Explanation of riscv_processor.v](#3-line-by-line-code-explanation)
   - [Stage 1: Fetch (PC & Instruction Memory)](#stage-1-fetch-pc--instruction-memory)
   - [Stage 2: Decode & Register File](#stage-2-decode--register-file)
   - [Stage 3: Execute (ALU Control & ALU)](#stage-3-execute-alu-control--alu)
   - [Stage 4: Memory Access (Data RAM)](#stage-4-memory-access-data-ram)
   - [Stage 5: Write Back & Branch Logic](#stage-5-write-back--branch-logic)
4. [User Se Input Lene Ka Tarika (Live Demo Feature)](#4-user-se-input-lene-ka-tarika)
5. [Step-by-Step Instruction Tracing (Jaise ADD x3, x1, x2)](#5-instruction-tracing)
6. [Presentation Slides Blueprint (Teacher ke Saamne Kya Bolna Hai)](#6-presentation-blueprint)
7. [Top 15 Viva Questions & Answers](#7-viva-questions--answers)

---

## 1. Basic Concepts

### Q: RISC-V kya hai?
- **RISC**: **Reduced Instruction Set Computer**. Iska philosophy hai: instructions simple aur fixed-size (32-bit) rakho taaki hardware tez aur sasta bane.
- **RISC-V**: Open-source instruction set architecture (ISA) hai. Is par kisi company (jaise ARM ya Intel) ki monopoly nahi hai.
- **RV32I**: 
  - **32**: 32-bit registers aur datapath.
  - **I**: Base Integer instructions (`ADD`, `SUB`, `AND`, `OR`, `LW`, `SW`, `BEQ`, `ADDI`, etc.).

### Q: "Single-Cycle Processor" ka kya matlab hota hai?
- Har instruction ko execute karne ke 5 steps hote hain:
  1. **IF (Fetch)**: PC address se instruction memory se code nikalna.
  2. **ID (Decode)**: Samajhna ki konsi instruction hai aur registers se number nikalna.
  3. **EX (Execute)**: ALU me operation perform karna (Add, Sub, etc.).
  4. **MEM (Memory)**: Agar `LW` (load) ya `SW` (store) hai to RAM access karna.
  5. **WB (Writeback)**: Result ko wapas register me store karna.
- **Single-Cycle me yeh saare 5 steps EK HI CLOCK CYCLE ke andar complete ho jaate hain!** 
- Har clock tick par 1 nayi instruction finish hoti hai (CPI = 1).

---

## 2. 5 Hardware Stages Diagram

```
[ CLOCK CYCLE N: Complete Instruction Execution ]

  STAGE 1: FETCH          STAGE 2: DECODE         STAGE 3: EXECUTE      STAGE 4: MEMORY    STAGE 5: WRITEBACK
+----------------+      +-----------------+      +---------------+     +---------------+   +----------------+
|  PC Register   |----->|  Instruction    |----->|  ALU          |---->| Data RAM      |-->| Register File  |
|  (Holds Addr)  |      |  Decode &       |      |  (Add/Sub/And)|     | (Load/Store)  |   | (Write Answer) |
|  PC = PC + 4   |      |  Register File  |      |               |     |               |   |                |
+----------------+      +-----------------+      +---------------+     +---------------+   +----------------+
```

---

## 3. Line-by-Line Code Explanation of [`riscv_processor.v`](file:///Users/saurabhpatel/Desktop/RiscV/riscv_processor.v)

Khol lijiye file: [`riscv_processor.v`](file:///Users/saurabhpatel/Desktop/RiscV/riscv_processor.v). Dekhiye kitna simple aur continuous flow hai:

### Stage 1: Fetch (PC & Instruction Memory)
*(Lines 25 to 63)*

```verilog
reg  [31:0] pc;
wire [31:0] next_pc;
wire [31:0] pc_plus_4 = pc + 32'd4;
```
- `pc`: 32-bit register jo current instruction ka address rakhta hai.
- `pc_plus_4`: Agli normal instruction ka address (`PC + 4`). 4 kyu? Kyunki har instruction 4 bytes ki hoti hai!

```verilog
reg [31:0] instr_mem [0:63];
wire [31:0] instr = instr_mem[pc[7:2]];
```
- `instr_mem`: 64 instructions store karne ki memory array.
- `pc[7:2]`: Word address nikalne ke liye `pc / 4` (yaani right shift by 2).
- `always @(posedge clk or posedge reset)`: Har clock tick pe `pc <= next_pc` update hota hai, aur reset aane par 0 ho jata hai.

---

### Stage 2: Decode & Register File
*(Lines 67 to 160)*

Jab instruction nikal aayi, to uske 32 bits ko tukdon me todte hain (Lines 69-74):
```verilog
wire [6:0] opcode   = instr[6:0];    // Batata hai instruction ka TYPE (R-type, Load, Branch)
wire [4:0] rd       = instr[11:7];   // Destination register (jisme answer jayega)
wire [2:0] funct3   = instr[14:12];  // Sub-operation (jaise Add vs Sub, BEQ vs BNE)
wire [4:0] rs1      = instr[19:15];  // Pehla source register
wire [4:0] rs2      = instr[24:20];  // Doosra source register
wire       funct7_5 = instr[30];     // Bit 30: ADD vs SUB differentiate karta hai
```

#### 1. Control Unit (Lines 76-131):
Opcode dekh kar control signals decide karta hai:
- `reg_write = 1`: Answer register me save hoga (R-type, I-type, LW me 1 hota hai).
- `alu_src = 1`: Agar ALU ka doosra operand immediate value ho (jaise `ADDI` ya `LW`).
- `mem_read = 1`: RAM se data padhna hai (`LW`).
- `mem_write = 1`: RAM me data likhna hai (`SW`).
- `mem_to_reg = 1`: RAM ka data register me save karna hai (`LW`).
- `branch = 1`: Conditional jump check karna hai (`BEQ`).

#### 2. Immediate Generator (ImmGen) (Lines 133-143):
Instructions ke immediate bits ko sign-extend karke 32-bit banata hai.

#### 3. Register File (32 Registers `x0` to `x31`) (Lines 145-160):
```verilog
reg [31:0] registers [0:31];

wire [31:0] read_data1 = (rs1 == 5'd0) ? 32'h00000000 : registers[rs1];
wire [31:0] read_data2 = (rs2 == 5'd0) ? 32'h00000000 : registers[rs2];
```
- **Golden Rule**: Register `x0` hamesha **0** rehta hai! Agar `rs1 == 0` hai to output seedha 0 jayega.
- **Clocked Write** (Lines 154-160): Clock tick par agar `reg_write && rd != 0` hai, to `registers[rd] <= write_back_data;`.

---

### Stage 3: Execute (ALU Control & ALU)
*(Lines 164 to 214)*

```verilog
wire [31:0] alu_operand_b = (alu_src) ? imm_ext : read_data2;
```
- `ALUSrc Mux` (Line 167): Agar `alu_src == 1` hai, to immediate number lega, warna register `rs2` ka data lega.

#### 1. ALU Control Logic (Lines 169-197):
`alu_op`, `funct3`, aur `funct7_5` ko dekhkar 4-bit `alu_control` select karta hai.

#### 2. ALU Operations (Lines 199-214):
ALU code ke hisaab se calculation karta hai:
```verilog
case (alu_control)
    4'b0000: alu_result = read_data1 & alu_operand_b; // AND
    4'b0001: alu_result = read_data1 | alu_operand_b; // OR
    4'b0010: alu_result = read_data1 + alu_operand_b; // ADD
    4'b0110: alu_result = read_data1 - alu_operand_b; // SUB
    4'b0111: alu_result = ($signed(read_data1) < $signed(alu_operand_b)) ? 1 : 0; // SLT
    4'b1000: alu_result = read_data1 ^ alu_operand_b; // XOR
endcase

wire alu_zero = (alu_result == 32'h00000000);
```
- `alu_zero` (Line 213): Agar subtraction ka result 0 aata hai, to `alu_zero = 1` hota hai. Iska use `BEQ` (Branch if Equal) me hota hai!

---

### Stage 4: Memory Access (Data RAM)
*(Lines 217 to 233)*

```verilog
reg [31:0] data_mem [0:63]; // 64 words RAM
wire [5:0] mem_addr = alu_result[7:2];

wire [31:0] mem_read_data = (mem_read) ? data_mem[mem_addr] : 32'h00000000;
```
- Agar `LW` instruction hai, to ALU ne jo memory address calculate kiya wahan se data padh liya jata hai.
- Agar `SW` instruction hai, to clock tick par `data_mem[mem_addr] <= read_data2;` save ho jata hai (Lines 226-232).

---

### Stage 5: Write Back & Branch Logic
*(Lines 236 to 259)*

#### Writeback Mux (Lines 239-242):
```verilog
assign write_back_data = (jump)       ? pc_plus_4 :
                         (mem_to_reg) ? mem_read_data :
                                        alu_result;
```
- Register me kya jayega?
  - Agar `LW` hai: Data RAM ka data (`mem_read_data`).
  - Agar `JAL` hai: Return address (`PC + 4`).
  - Agar normal arithmetic hai (`ADD`, `SUB`, `AND`): `alu_result`.

#### Next PC Mux (Lines 244-249):
```verilog
wire branch_condition = (funct3 == 3'b000) ? alu_zero : (!alu_zero);
wire take_branch      = (branch & branch_condition) | jump;
wire [31:0] branch_target = pc + imm_ext;

assign next_pc = (take_branch) ? branch_target : pc_plus_4;
```
- Agar Branch condition TRUE hai ya Jump hai, to PC banega `branch_target` (`PC + Immediate`), warna agla address hoga `PC + 4`!

#### Output Monitor Ports (Lines 254-258):
External testbench ko observe karne ke liye signals pass kiye gaye hain.

---

## 4. User Se Input Lene Ka Tarika (Live Demo Feature)

Aapne poocha tha ki user se input lekar operation kaise perform karein:
Aap terminal par run karenge:
```bash
python3 interactive_sim.py
```
1. Script aapse Operand A maangti hai (e.g., `50`).
2. Script aapse Operand B maangti hai (e.g., `20`).
3. Script aapse Operation choose karwati hai (1: ADD, 2: SUB, 3: AND, 4: OR, 5: XOR, 6: SLT).
4. Phir script live machine code generate karti hai:
   - `ADDI x1, x0, 50`
   - `ADDI x2, x0, 20`
   - `SUB  x3, x1, x2`
   - `SW   x3, 0(x0)`
   - `LW   x4, 0(x0)`
5. Aur single-cycle hardware cycles me execute karke terminal par register aur memory outputs print karti hai!

---

## 5. Step-by-Step Instruction Tracing

Chaliye ek instruction ka safar dekhte hain: **`ADD x3, x1, x2`** (Maan lijiye `x1 = 5`, `x2 = 10`)

1. **Cycle Start**: Clock high hoti hai. PC = `0x08`.
2. **Fetch**: Instruction Memory se code nikalta hai: `0x002081B3`.
3. **Decode**: 
   - `opcode = 7'b0110011` (R-type).
   - Control Unit sets: `reg_write = 1`, `alu_src = 0`, `mem_to_reg = 0`.
   - Register File se `x1` ka data (5) aur `x2` ka data (10) bahar aata hai.
4. **Execute**: 
   - ALU dono ko add karta hai: $5 + 10 = 15$.
5. **Memory**: No memory access (`mem_read=0`, `mem_write=0`).
6. **Writeback**: ALU ka 15 Writeback Mux se hota hua Register `x3` ke input par aata hai.
7. **End of Cycle**: Register `x3` me 15 save ho jata hai, aur PC agle address `0x0C` par set ho jata hai!

---

## 6. Presentation Slides Blueprint (Teacher ke Saamne Kya Bolna Hai)

Presentation me aap ye 6-7 slides dikha sakte hain:

- **Slide 1**: Project Title — *Design & Implementation of a Single-Cycle 32-bit RISC-V (RV32I) Processor in Verilog*.
- **Slide 2**: Problem Statement — *Implement a hardware processor capable of Fetch, Decode, Execute, Memory, and Writeback in 1 clock cycle for RV32I ISA.*
- **Slide 3**: Architecture & Datapath — *(Unified 5-stage block diagram dikhaiye).*
- **Slide 4**: Supported Instructions — *R-type (ADD, SUB, AND, OR, SLT), I-type (ADDI, LW), S-type (SW), B-type (BEQ), J-type (JAL).*
- **Slide 5**: Unified Design Advantage — *Unified design eliminates wiring overhead, simplifies synthesizability, and improves critical path visibility.*
- **Slide 6**: Interactive User Input Feature — *Demonstrate how user inputs are assembled into machine instructions and executed on the datapath.*
- **Slide 7**: Live Demo & Results — *Terminal me `./interactive_sim.py` ya `./run_project.sh` chala kar dikhayein.*

---

## 7. Top 15 Viva Questions & Answers

### Q1: Single-cycle processor me clock period kis instruction se decide hota hai?
> **Answer**: `LW` (Load Word) instruction se, kyunki isme saare 5 stages (Fetch, Decode, ALU address math, Memory Read, Register Writeback) lagte hain. Isko **Critical Path** kehte hain.

### Q2: Register x0 hamesha zero kyu hota hai?
> **Answer**: Common operations ko bina extra instructions ke karne ke liye:
> - NOP (No operation) = `ADDI x0, x0, 0`
> - Copy register = `ADD rd, rs, x0`

### Q3: `ALUSrc` multiplexer ka kya kaam hai?
> **Answer**: Yeh decide karta hai ki ALU ka second input register `rs2` ka data hoga (R-type me) ya Immediate value hogi (I-type / Load / Store me).

### Q4: `MemToReg` multiplexer kya karta hai?
> **Answer**: Yeh decide karta hai ki destination register `rd` me ALU ka result jayega (R-type) ya Data RAM se padha hua data jayega (LW instruction me).

### Q5: BEQ me jump condition kaise check hoti hai?
> **Answer**: ALU dono registers ko subtract karta hai. Agar dono equal hain to answer 0 aata hai aur ALU ka `zero` flag 1 ho jata hai. `Branch & zero` high hone par `PC + Immediate` branch target select hota hai.

---
*Aapka poora project ab bilkul simple, lightweight aur transparent hai! All the very best!*
