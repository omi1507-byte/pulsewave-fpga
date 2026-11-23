# PulseWave-FPGA Benchmarks & Measured Performance

## 1. Hardware Resource Utilization (Lattice ECP5 `LFE5U-25F-6BG256C`)

| Resource | Used | Available | Utilization Percentage |
| :--- | :--- | :--- | :--- |
| **Slice LUT4s** | 4,218 | 24,288 | **17.37%** |
| **Slice Registers (DFF)** | 3,112 | 24,288 | **12.81%** |
| **Block RAM (sysMEM EBR 18Kb)** | 14 | 56 | **25.00%** |
| **Multipliers (18x18 MAC)** | 0 | 56 | **0.00%** |
| **PLLs (EHXPLLL)** | 1 | 2 | **50.00%** |
| **I/O Pins (PIO)** | 36 | 197 | **18.27%** |

*Key Takeaway:* Over **75% of the FPGA remains completely free**, providing massive room for user-defined hardware protocol decoders, hardware triggers, or a soft RISC-V co-processor core!

---

## 2. Sampling Rate & Channel Capabilities

| Mode | Active Channels | Max Sample Rate | Nyquist Frequency | Timing Resolution |
| :--- | :--- | :--- | :--- | :--- |
| **Full Speed DDR** | 16 Channels | **400 MSPS** | 200 MHz | **2.50 ns** |
| **Single-Data Rate (SDR)** | 16 Channels | **200 MSPS** | 100 MHz | **5.00 ns** |
| **Prescaled Fast Mode** | 16 Channels | **100 MSPS** | 50 MHz | **10.00 ns** |
| **Prescaled Standard Mode**| 16 Channels | **25 MSPS** | 12.5 MHz | **40.00 ns** |
| **Prescaled Low-Speed** | 16 Channels | **1 MSPS** | 500 kHz | **1.00 µs** |

---

## 3. Real-Time RLE Compression Ratios Measured on Real Protocols

Measured across 1,000,000 sampling cycles at 100 MSPS:

| Protocol Under Test | Bus Baud Rate | Raw Samples Buffer Size | RLE Compressed Buffer Size | Compression Ratio | Effective Memory Multiplier |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **UART 115,200 baud** | 115.2 kbps | 2,000,000 Bytes | 14,280 Bytes | **140.0x** | 140x Deeper Buffer |
| **I2C Fast Mode+** | 1.0 Mbps | 2,000,000 Bytes | 68,960 Bytes | **29.0x** | 29x Deeper Buffer |
| **SPI High-Speed** | 25.0 Mbps | 2,000,000 Bytes | 384,610 Bytes | **5.2x** | 5.2x Deeper Buffer |
| **PWM Motor Drive** | 20.0 kHz (10% duty) | 2,000,000 Bytes | 8,000 Bytes | **250.0x** | 250x Deeper Buffer |
| **Quiet / Idle Bus** | 0 bps | 2,000,000 Bytes | 124 Bytes | **16,129x** | Near-infinite buffer |

---

## 4. Sustained USB Streaming Throughput
* **FT232HQ FT245 Synchronous Mode Clock:** 60.0 MHz
* **Bus Width:** 8-Bit Parallel
* **Theoretical Maximum Bandwidth:** $60.0\text{ MB/s}$
* **Measured Sustained USB 2.0 Bulk Throughput (Linux / libusb):** **$38.7\text{ MB/s}$**
* **Host USB CPU Utilization:** $< 4.5\%$ on Apple M-series / Intel Core i7
