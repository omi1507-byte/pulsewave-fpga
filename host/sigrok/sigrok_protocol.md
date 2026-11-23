# Sigrok / PulseView Integration Guide

PulseWave-FPGA is designed for seamless operation with the open-source **Sigrok** suite and **PulseView** GUI.

## 1. Quick Launch with Sigrok CLI
You can capture logic traces and decode protocols directly from your terminal:

```bash
# Capture 100,000 samples at 100 MHz and export directly to Sigrok native session file
sigrok-cli --driver pulsewave-fpga:conn=1.2 --config samplerate=100m --samples 100000 -o trace.sr

# Pipe capture directly into Sigrok protocol decoder (e.g. SPI decoder)
sigrok-cli -i trace.sr -P spi:clk=CH0:mosi=CH1:miso=CH2:cs=CH3
```

## 2. Opening in PulseView GUI
1. Launch **PulseView**.
2. Click **Connect to Device**.
3. Select Driver: `PulseWave-FPGA` or import via `VCD file format`.
4. Add Protocol Decoders:
   * I2C / SMBus
   * SPI / Dual-SPI / Quad-SPI
   * CAN 2.0A/B & CAN-FD
   * UART / RS-232 / RS-485
   * USB 1.1 / 2.0 Packets
   * ARM SWD / JTAG
5. Set complex trigger conditions (Edge, Pattern, or Timing) and click **Run**.
