#!/bin/bash
# ==================================================================================
# RISC-V Single-Cycle Processor Project Execution Script
# ==================================================================================

echo "========================================================================"
echo "         RISC-V SINGLE-CYCLE 32-BIT PROCESSOR PROJECT RUNNER           "
echo "========================================================================"
echo "Select execution mode:"
echo "  1) Full Automated Hardware Test Suite (All RV32I instructions check)"
echo "  2) Verilog Simulation via Icarus Verilog (Generates riscv.vcd waveform)"
echo "  3) Interactive Verilog Testbench via Icarus Verilog (CLI Interactive)"
echo "========================================================================"
read -p "Enter choice [1-3] (Default: 1): " choice
choice=${choice:-1}

case $choice in
    1)
        if ! command -v iverilog &> /dev/null; then
            echo -e "\n[Error] 'iverilog' is not installed yet on your system."
            echo "Install it with: brew install icarus-verilog"
            exit 1
        fi
        echo -e "\n[Running Automated RV32I Hardware Verification...]\n"
        iverilog -o sim_riscv riscv_processor.v testbench.v
        vvp sim_riscv
        ;;
    2)
        if ! command -v iverilog &> /dev/null; then
            echo -e "\n[Error] 'iverilog' is not installed yet on your system."
            echo "Install it with: brew install icarus-verilog"
            exit 1
        fi
        echo -e "\n[Compiling Verilog files with Icarus Verilog...]"
        iverilog -o sim_riscv riscv_processor.v testbench.v
        echo -e "[Running Simulation...]\n"
        vvp sim_riscv
        echo -e "\nWaveform saved to 'riscv.vcd'. You can open it in GTKWave!"
        ;;
    3)
        if ! command -v iverilog &> /dev/null; then
            echo -e "\n[Error] 'iverilog' is not installed yet on your system."
            echo "Install it with: brew install icarus-verilog"
            exit 1
        fi
        echo -e "\n[Compiling Interactive Verilog Testbench...]"
        iverilog -o sim_interactive src/*.v testbench/tb_interactive.v
        echo -e "[Running Interactive Verilog Simulation...]\n"
        vvp sim_interactive
        ;;
    *)
        echo "Invalid choice. Exiting."
        ;;
esac
