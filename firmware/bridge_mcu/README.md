# PulseWave Companion Bridge Firmware

This optional companion firmware runs on a Raspberry Pi RP2040 or STM32 microcontroller to serve as an open-source USB High-Speed bridge alternative to the dedicated FTDI FT232HQ chip.

## Features
* **TinyUSB Bulk Endpoint Streaming:** Sustained data transfer over USB Full-Speed (12 Mbps) or High-Speed with external ULPI PHY.
* **PIO Fast Parallel Bus Capture:** Uses RP2040 Programmable I/O (PIO) state machines to latch 8-bit or 16-bit parallel words from the FPGA without CPU intervention.
* **Dual DMA Ping-Pong Buffers:** Completely avoids dropped samples during host scheduling jitter.

## Building with Pico SDK
```bash
mkdir build && cd build
cmake ..
make -j4
```
Flash the generated `pulsewave_bridge.uf2` by holding the BOOTSEL button and dragging the file onto the RP2040 USB drive.
