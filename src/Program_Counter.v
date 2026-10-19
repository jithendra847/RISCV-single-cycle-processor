// ============================================================================
// Module Name: Program_Counter (PC)
// Description: Holds the memory address of the current instruction to be executed.
//              On each positive clock edge, it updates to the next PC address.
//              If reset is activated, it resets the PC to 0.
// ============================================================================

`timescale 1ns / 1ps

module Program_Counter (
    input  wire        clk,        // System clock: the PC updates on each rising clock edge.
    input  wire        reset,      // Active-high reset signal: when asserted, the PC resets to zero.
    input  wire [31:0] next_pc,    // 32-bit address of the next instruction to be fetched.
    output reg  [31:0] pc          // 32-bit address of the current instruction being executed.
);

    // The PC is updated on the positive edge of clk or reset.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;    // On reset, initialize the PC to address 0.
        end else begin
            pc <= next_pc;         // In normal operation, store the address of the next instruction.
        end
    end

endmodule
