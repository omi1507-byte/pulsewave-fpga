# PulseWave-FPGA Bill of Materials & Architecture Rationale

## 1. Executive Summary
PulseWave-FPGA is engineered to hit an aggressive sweet spot: **commercial-grade 400 MSPS sampling performance** at an open-source hobbyist BOM cost under **\$35 in single-unit quantities** (under \$22 at 1k volume). Every silicon component was selected based on open-source toolchain compatibility, signal integrity, and ease of automated assembly (PCBA) through turnkey vendors like JLCPCB, PCBWay, and OshPark.

---

## 2. Core Silicon & IC Selection Rationale

### 2.1 FPGA: Lattice Semiconductor ECP5 (`LFE5U-25F-6BG256C`)
* **Why not Xilinx Artix-7?**
  * While Artix-7 (XC7A35T) has immense popularity, it is strictly bound to proprietary AMD/Xilinx Vivado (a 50GB+ installation).
  * The **Lattice ECP5** is fully supported by the open-source **Project Trellis / Yosys / nextpnr** toolchain. Users can clone this repository, run `make bitstream`, and synthesize in under 45 seconds using completely free, open-source Linux/macOS/Windows tools.
* **Why BGA-256 (0.8mm Pitch)?**
  * 0.8mm pitch ball grid array allows full dog-bone via breakout on standard low-cost **4-layer PCBs** (0.2mm drill / 0.45mm pad diameter, 3.5mil trace/space). It completely eliminates the need for expensive laser micro-vias or 6+ layer fabrication.
* **Internal Resources:**
  * 24,288 Look-Up Tables (LUTs) provide ample headroom for the 16-channel DDR sampler, multi-level trigger comparator state machines, and real-time RLE hardware compressor with only ~34% resource utilization.
  * 1,008 Kbit of high-speed dual-port Block RAM (sysMEM EBR) allows immediate burst ring-buffering before streaming to HyperRAM.

---

### 2.2 Deep Storage Memory: Winbond HyperRAM (`W956A8MBYA5I`)
* **Why HyperRAM over Parallel SDRAM or DDR3?**
  * Parallel SDRAM (e.g. 16-bit MT48LC) requires **38 to 44 dedicated FPGA pins**, ballooning PCB routing complexity and consuming scarce I/O banks.
  * DDR3 requires dedicated DQS/DQ differential layout, complex multi-bank termination networks (VTT), and high FPGA core power.
  * **HyperBus** uses only **11 pins total** (CS#, CLK, CLK#, RWDS, DQ[7:0]), while delivering **200 MB/s (1600 Mbps)** throughput at 100 MHz double-data-rate (DDR).
* **Storage Depth:**
  * 64 Mbit (8 Megabytes) stores up to **4 million raw 16-channel samples**, or over **50 million samples when combined with the real-time RLE compression engine**.

---

### 2.3 USB Host Bridge: FTDI FT232HQ vs RP2040
* The design supports the FTDI **FT232HQ** in **Synchronous 245 FIFO mode**, delivering sustained **40 MB/s streaming bandwidth** straight over USB 2.0 High-Speed without requiring host microcontroller firmware compilation.
* For users seeking ultra-low cost, the PCB includes footprint-breakout pads for an optional **Raspberry Pi RP2040** companion bridge running TinyUSB as a streaming co-processor.

---

### 2.4 High-Speed Input Protection & Level Shifting
* **Transceiver (`SN74AVC8T245`):**
  * Dual-supply voltage translation down to 1.2V and up to 3.6V directly into the FPGA bank, with input over-voltage tolerance up to 5.5V.
  * Propagation delay: $t_{pd} < 1.8\text{ ns}$, supporting clock rates well above 200 MHz.
* **ESD Arrays (`USBLC6-2SC6`):**
  * Ultra-low parasitic capacitance ($C_{in} = 0.25\text{ pF}$) ensures minimal signal degradation and prevents capacitive loading on sensitive high-speed I2C/SPI/UART busses under test.

---

## 3. Power Architecture & Decoupling Budget

| Rail | Voltage | Typical Current | Peak Current | Source IC | Topology | Decoupling Strategy |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **VBUS** | 5.0 V | 350 mA | 500 mA | Host USB-C | Filtered Input | 10uF + Ferrite Bead (0805, 600Ω @ 100MHz) |
| **VCC_CORE** | 1.1 V | 450 mA | 1200 mA | TPS62088 | Synchronous Buck (4 MHz) | 2x 22uF X5R + 8x 0.1uF 0402 right under BGA core |
| **VCC_AUX** | 2.5 V | 80 mA | 150 mA | TLV73325 | Low-Noise LDO | 4.7uF + 4x 0.1uF |
| **VCC_RAM** | 1.8 V | 60 mA | 120 mA | TLV73318 | Low-Noise LDO | 4.7uF + 2x 0.1uF |
| **VCC_IO** | 3.3 V | 120 mA | 250 mA | TLV73333 | Low-Noise LDO | 10uF + 6x 0.1uF |

---

## 4. Total Assembled Unit Cost (PCBA 5-Unit Prototype Run)

* **Raw PCB Fabrication (4-Layer, JLC04161H, ENIG finish, 5 pcs):** \$18.00 total (\$3.60/board)
* **SMD Components & ICs:** \$32.15 per board
* **SMT Assembly Setup & Stencil:** \$12.00 total (\$2.40/board)
* **Estimated Prototype Unit Cost:** **\$38.15**
* **Estimated Volume 1,000+ Unit Cost:** **\$19.40**
