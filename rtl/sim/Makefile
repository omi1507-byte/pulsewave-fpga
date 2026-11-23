# ==============================================================================
# Makefile for PulseWave-FPGA Simulation & Synthesis
# Supports: Icarus Verilog (iverilog), Verilator, and Python Golden Reference
# ==============================================================================

RTL_SRCS = ../src/sampling_frontend.sv \
           ../src/trigger_engine.sv \
           ../src/rle_compressor.sv \
           ../src/sample_fifo.sv \
           ../src/hyperram_ctrl.sv \
           ../src/command_parser.sv \
           ../src/usb_stream_interface.sv \
           ../src/pulsewave_top.sv

.PHONY: all clean test_golden sim_rle sim_trigger sim_top lint_verilator

all: test_golden

# Run bit-accurate Python verification and VCD dump
test_golden:
	@echo "--- Running Golden Reference Verification ---"
	python3 simulate_golden.py

# Simulate RLE Compressor with Icarus Verilog
sim_rle:
	@echo "--- Compiling and Running tb_rle_compressor ---"
	iverilog -g2012 -o tb_rle.vvp ../src/rle_compressor.sv tb_rle_compressor.sv
	vvp tb_rle.vvp

# Simulate Trigger Engine with Icarus Verilog
sim_trigger:
	@echo "--- Compiling and Running tb_trigger_engine ---"
	iverilog -g2012 -o tb_trigger.vvp ../src/trigger_engine.sv tb_trigger_engine.sv
	vvp tb_trigger.vvp

# Simulate Top-Level with Icarus Verilog
sim_top:
	@echo "--- Compiling and Running tb_pulsewave_top ---"
	iverilog -g2012 -o tb_top.vvp $(RTL_SRCS) tb_pulsewave_top.sv
	vvp tb_top.vvp

# Lint RTL with Verilator
lint_verilator:
	@echo "--- Linting SystemVerilog RTL with Verilator ---"
	verilator --lint-only -Wall --top-module pulsewave_top $(RTL_SRCS)

clean:
	rm -f *.vvp *.vcd *.vcd.hier
