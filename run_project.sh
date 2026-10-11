#!/bin/bash
# ==============================================================================
# RISC-V Single-Cycle Processor Project Execution Script
# ==============================================================================

echo "========================================================================"
echo "         RISC-V SINGLE-CYCLE 32-BIT PROCESSOR PROJECT RUNNER           "
echo "========================================================================"
echo "Select execution mode:"
echo "  1) Interactive Simulator (Enter your own inputs A, B, and Operation)"
echo "  2) Full Automated Hardware Test Suite (All RV32I instructions check)"
echo "  3) Verilog Simulation via Icarus Verilog (Generates riscv.vcd waveform)"
echo "  4) Interactive Verilog Testbench via Icarus Verilog (CLI Interactive)"
echo "========================================================================"
read -p "Enter choice [1-4] (Default: 1): " choice
choice=${choice:-1}

PYTHON_CMD="python3"
if ! command -v python3 &> /dev/null; then
    if [ -f "/Library/Frameworks/Python.framework/Versions/3.14/bin/python3" ]; then
        PYTHON_CMD="/Library/Frameworks/Python.framework/Versions/3.14/bin/python3"
    fi
fi

case $choice in
    1)
        echo -e "\n[Starting Interactive RISC-V Hardware Simulator...]\n"
        $PYTHON_CMD interactive_sim.py
        ;;
    2)
        echo -e "\n[Running Automated RV32I Hardware Verification...]\n"
        $PYTHON_CMD interactive_sim.py --test
        ;;
    3)
        if ! command -v iverilog &> /dev/null; then
            echo -e "\n[Error] 'iverilog' is not installed yet on your system."
            echo "To install on Mac: brew install icarus-verilog"
            echo "You can still run Option 1 or 2 right now without any installation!"
            exit 1
        fi
        echo -e "\n[Compiling Verilog files with Icarus Verilog...]"
        iverilog -o sim_riscv riscv_processor.v testbench.v
        echo -e "[Running Simulation...]\n"
        vvp sim_riscv
        echo -e "\nWaveform saved to 'riscv.vcd'. You can open it in GTKWave!"
        ;;
    4)
        if ! command -v iverilog &> /dev/null; then
            echo -e "\n[Error] 'iverilog' is not installed yet on your system."
            echo "To install on Mac: brew install icarus-verilog"
            echo "You can still run Option 1 or 2 right now without any installation!"
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
