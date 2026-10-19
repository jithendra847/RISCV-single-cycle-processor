// ============================================================================
// Module Name: Instruction_Memory
// Description: Stores instructions in memory. 
//              Takes 32-bit PC as input address and outputs the 32-bit instruction.
//              Since instructions are 4 bytes (32-bit), we index using PC[7:2].
// ============================================================================

`timescale 1ns / 1ps

module Instruction_Memory (
    input  wire [31:0] pc,            // Program counter address from PC module
    output wire [31:0] instruction    // 32-bit instruction fetched from memory
);

    // 64 instructions are stored in this memory array, with each element holding a 32-bit word.
    reg [31:0] memory [0:63];

    // Word-aligned access: RISC-V instructions are 4 bytes long, so the memory index is derived using pc >> 2,
    // which is equivalent to using bits [7:2] of the program counter.
    assign instruction = memory[pc[7:2]];

    // Default test program loaded at startup.
    // Instruction encodings:
    // 0: ADDI x1, x0, 5    (x1 = 0 + 5 = 5)          -> 32'h00500093
    // 1: ADDI x2, x0, 10   (x2 = 0 + 10 = 10)        -> 32'h00a00113
    // 2: ADD  x3, x1, x2   (x3 = x1 + x2 = 15)       -> 32'h002081b3
    // 3: SUB  x4, x2, x1   (x4 = 10 - 5 = 5)         -> 32'h40110233
    // 4: AND  x5, x1, x2   (x5 = 5 & 10 = 0)         -> 32'h0020f2b3
    // 5: OR   x6, x1, x2   (x6 = 5 | 10 = 15)        -> 32'h0020e333
    // 6: SLT  x7, x1, x2   (x7 = (5 < 10) ? 1 : 0)   -> 32'h0020a3b3
    // 7: SW   x3, 4(x0)    (mem[4] = x3 = 15)        -> 32'h00302223
    // 8: LW   x8, 4(x0)    (x8 = mem[4] = 15)        -> 32'h00402403
    // 9: BEQ  x1, x4, +8   (if 5==5 jump PC+8)       -> 32'h00408463
    // 10: ADDI x9, x0, 99  (Skipped by branch!)       -> 32'h06300493
    // 11: ADDI x10, x0, 42 (Target of branch, x10=42)-> 32'h02a00513
    integer i;
    initial begin
        // First fill the memory with NOP instructions so unused locations have a safe default value.
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h00000013; // NOP instruction: addi x0, x0, 0
        end

        // Sample program for demonstration and verification.
        memory[0]  = 32'h00500093; // ADDI x1, x0, 5    (x1 = 5)
        memory[1]  = 32'h00a00113; // ADDI x2, x0, 10   (x2 = 10)
        memory[2]  = 32'h002081b3; // ADD  x3, x1, x2   (x3 = 15)
        memory[3]  = 32'h40110233; // SUB  x4, x2, x1   (x4 = 5)
        memory[4]  = 32'h0020f2b3; // AND  x5, x1, x2   (x5 = 0)
        memory[5]  = 32'h0020e333; // OR   x6, x1, x2   (x6 = 15)
        memory[6]  = 32'h0020a3b3; // SLT  x7, x1, x2   (x7 = 1)
        memory[7]  = 32'h00302223; // SW   x3, 4(x0)    (Store x3 in mem[4])
        memory[8]  = 32'h00402403; // LW   x8, 4(x0)    (Load mem[4] to x8)
        memory[9]  = 32'h00408463; // BEQ  x1, x4, 8    (Branch to memory[11])
        memory[10] = 32'h06300493; // ADDI x9, x0, 99   (Skipped by the branch!)
        memory[11] = 32'h02a00513; // ADDI x10, x0, 42  (x10 = 42)
    end

endmodule
