// ============================================================================
// Module Name: Data_Memory
// Description: Implements data RAM for load (LW) and store (SW) instructions.
//              - Synchronous write on clock posedge (MemWrite = 1)
//              - Asynchronous read (MemRead = 1)
//              - Word-aligned addressing: memory[addr[7:2]]
// ============================================================================

`timescale 1ns / 1ps

module Data_Memory (
    input  wire        clk,          // Clock signal
    input  wire        reset,        // Active-high reset signal
    input  wire        mem_read,     // Read enable control signal (LW)
    input  wire        mem_write,    // Write enable control signal (SW)
    input  wire [31:0] addr,         // Memory address from ALU result
    input  wire [31:0] write_data,   // Data to write into memory (from rs2)
    output wire [31:0] read_data     // Data read from memory (to write into rd)
);

    // 64 memory words (each 32-bit wide)
    reg [31:0] memory [0:63];
    integer i;

    // Word alignment: RISC-V addresses are in bytes,
    // to word-aligned index ke liye hum bits [7:2] use karte hain
    wire [5:0] word_addr = addr[7:2];

    // Asynchronous Read: Agar mem_read 1 hai to memory se data do, warna 0
    assign read_data = (mem_read) ? memory[word_addr] : 32'h00000000;

    // Synchronous Write: Clock ke posedge par write hota hai
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset hone par saari data memory 0 kar do
            for (i = 0; i < 64; i = i + 1) begin
                memory[i] <= 32'h00000000;
            end
        end else if (mem_write) begin
            memory[word_addr] <= write_data;
        end
    end

endmodule
