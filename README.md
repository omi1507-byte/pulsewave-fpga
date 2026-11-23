# PulseWave-FPGA

**An open-hardware 16-channel, 400 MSPS digital logic analyzer powered by the Lattice ECP5 FPGA, featuring real-time hardware run-length compression, 4-layer controlled-impedance PCB design, and deep Sigrok/PulseView support.**

---

## Technical Highlights

- **Sampling Speed:** Up to 400 MSPS in Dual-Data-Rate (DDR) mode and 200 MSPS in Single-Data-Rate (SDR) mode across all 16 channels simultaneously.
- **Hardware RLE Compression:** On-chip real-time compression engine packs static logic levels into 32-bit tokens, extending effective memory depth by 10x to 100x on common communication protocols.
- **Signal Frontend:** Compatible with logic levels from 1.2V to 5.0V with ESD protection arrays and 50Ω transmission lines.
- **Deep Buffer Memory:** Interfaces with onboard 64 Mbit low-pin-count HyperRAM delivering 200 MB/s sustained bandwidth.
- **High-Speed USB Streaming:** Powered by FTDI FT232HQ in synchronous FIFO mode, maintaining 40 MB/s sustained data transfer to the host workstation.
- **Full Open-Source Toolchain:** Synthesizable with Yosys, nextpnr, and Project Trellis, as well as proprietary FPGA synthesis suites.

---

## Repository Organization

- `hardware/`: KiCad schematics, PCB layout, layer stackup calculations, and complete bill of materials with LCSC references.
- `rtl/`: Synthesizable SystemVerilog modules, clock constraints, and simulation testbenches.
- `firmware/`: Companion microcontroller bridge source code for RP2040 and Cortex-M devices.
- `host/`: Python CLI utility, high-performance VCD exporter, and browser-based logic waveform previewer.
- `docs/`: Technical specifications covering system architecture, power sequencing, hardware bring-up, and benchmarks.

---

## Quick Start Guide

### 1. Run Bit-Accurate Golden Simulation
Verify the sampling and compression pipelines without third-party EDA dependencies:
```bash
python3 rtl/sim/simulate_golden.py
```

### 2. Capture and Export Logic Traces
Run the host command-line utility in emulation or live hardware mode:
```bash
python3 host/python/pulsewave_cli.py --rate 100000000 --samples 5000 --vcd trace.vcd
```

### 3. Open Interactive Waveform Viewer
Open `host/gui/web_scope_preview.html` in any web browser to inspect signals, pan across time intervals, and calculate timing parameters.

---

## Hardware Specifications

- **FPGA:** Lattice LFE5U-25F-6BG256C
- **PCB Dimensions:** 78 mm x 52 mm (4-Layer, JLC04161H stackup)
- **Power Input:** USB Type-C (5V / 2A max)
- **Core Voltage:** 1.1V derived via 4 MHz synchronous buck regulator
- **I/O Banks:** 3.3V, 2.5V, and 1.8V low-noise LDO rails
