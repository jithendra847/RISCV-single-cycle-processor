// ============================================================================
// Module Name: Program_Counter (PC)
// Description: Holds the memory address of the current instruction to be executed.
//              On each positive clock edge, it updates to the next PC address.
//              If reset is activated, it resets the PC to 0.
// ============================================================================

`timescale 1ns / 1ps

module Program_Counter (
    input  wire        clk,        // Clock signal (har clock tick pe PC update hota hai)
    input  wire        reset,      // Reset signal (active high: jab 1 hoga, PC = 0 ho jayega)
    input  wire [31:0] next_pc,    // Agli instruction ka 32-bit address
    output reg  [31:0] pc          // Current instruction ka 32-bit address
);

    // Clock ke positive edge ya Reset ke positive edge pe trigger hota hai
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;    // Reset hone par PC ko 0 par initialize karo
        end else begin
            pc <= next_pc;         // Normal operation: next instruction ka address store karo
        end
    end

endmodule
