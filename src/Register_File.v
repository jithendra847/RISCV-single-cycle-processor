// ============================================================================
// Module Name: Register_File
// Description: Implements the 32 general-purpose registers (x0 to x31) of RISC-V.
//              - 2 Read Ports (Combinational/Asynchronous)
//              - 1 Write Port (Synchronous on clock posedge)
//              - Register x0 is HARDWIRED to 0. Writing to x0 has NO effect!
// ============================================================================

`timescale 1ns / 1ps

module Register_File (
    input  wire        clk,          // Clock signal
    input  wire        reset,        // Active-high reset signal
    input  wire        reg_write,    // Control signal: 1 = Write enable, 0 = Write disabled
    input  wire [4:0]  rs1,          // Source register 1 address (5-bit: 0 to 31)
    input  wire [4:0]  rs2,          // Source register 2 address (5-bit: 0 to 31)
    input  wire [4:0]  rd,           // Destination register address (5-bit: 0 to 31)
    input  wire [31:0] write_data,   // Data to write into destination register rd
    output wire [31:0] read_data1,   // Data read from register rs1
    output wire [31:0] read_data2    // Data read from register rs2
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];
    integer i;

    // Asynchronous Read (Combinational Logic):
    // RISC-V rule: Register x0 is ALWAYS 0!
    assign read_data1 = (rs1 == 5'd0) ? 32'h00000000 : registers[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'h00000000 : registers[rs2];

    // Synchronous Write (Clock ke rising edge par write hota hai):
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset par saare registers ko 0 kar do
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (reg_write && (rd != 5'd0)) begin
            // Agar reg_write enabled hai AND rd zero nahi hai (kyunki x0 hamesha 0 rehta hai)
            registers[rd] <= write_data;
        end
    end

endmodule
