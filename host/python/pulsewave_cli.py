#!/usr/bin/env python3
"""
pulsewave_cli.py
----------------
Command-Line Interface and Host Driver for PulseWave-FPGA.
Provides live interactive device control, multi-level trigger configuration,
RLE stream decompression, real-time throughput benchmarks, and VCD export.
"""

import sys
import os
import argparse
import time
import struct
from typing import List, Tuple
from vcd_writer import VCDWriter

MAGIC_HEADER = 0xAA

class PulseWaveDevice:
    def __init__(self, port: str = "FT232H", baud: int = 3000000, mock: bool = True):
        self.port = port
        self.baud = baud
        self.mock = mock
        self.connected = False
        self.sample_rate = 200_000_000 # 200 MSPS default
        self.rle_enabled = True

    def connect(self) -> bool:
        if self.mock:
            print(f"[PulseWave] Mock Mode active. Connected to simulated PulseWave-FPGA on '{self.port}'.")
            self.connected = True
            return True
        else:
            try:
                import serial
                self.ser = serial.Serial(self.port, self.baud, timeout=1.0)
                self.connected = True
                print(f"[PulseWave] Successfully connected to hardware on {self.port} at {self.baud} baud.")
                return True
            except Exception as e:
                print(f"[PulseWave Error] Could not connect to {self.port}: {e}")
                return False

    def ping(self) -> bool:
        if not self.connected:
            return False
        if self.mock:
            return True
        # Send 0xAA 0x00 0x00 (Ping)
        self.ser.write(bytes([MAGIC_HEADER, 0x00, 0x00]))
        resp = self.ser.read(1)
        return len(resp) > 0 and resp[0] == 0x55

    def set_sample_rate(self, rate_hz: int, ddr: bool = False, rle: bool = True):
        self.sample_rate = rate_hz
        self.rle_enabled = rle
        # ECP5 master sampling clock = 200 MHz
        base_clock = 200_000_000
        if ddr:
            effective_clock = 400_000_000
            div = max(0, int(effective_clock / rate_hz) - 1)
        else:
            div = max(0, int(base_clock / rate_hz) - 1)
        flags = (1 if ddr else 0) | ((1 if rle else 0) << 1)
        payload = struct.pack(">IB", div, flags)
        print(f"[Config] Sample Rate: {rate_hz/1e6:.1f} MHz (Div: {div}, DDR: {ddr}, RLE: {rle})")
        if not self.mock:
            packet = bytes([MAGIC_HEADER, 0x01, len(payload)]) + payload
            self.ser.write(packet)

    def set_trigger(self, mask: int, value: int, edge_rise: int, edge_fall: int):
        payload = struct.pack(">HHHH", mask, value, edge_rise, edge_fall)
        print(f"[Trigger] Mask=0x{mask:04X}, Val=0x{value:04X}, Rise=0x{edge_rise:04X}, Fall=0x{edge_fall:04X}")
        if not self.mock:
            packet = bytes([MAGIC_HEADER, 0x02, len(payload)]) + payload
            self.ser.write(packet)

    def decompress_rle_stream(self, raw_bytes: bytes) -> List[int]:
        """Decodes 32-bit hardware RLE tokens into linear uncompressed samples."""
        uncompressed = []
        num_tokens = len(raw_bytes) // 4
        for i in range(num_tokens):
            word = struct.unpack(">I", raw_bytes[i*4 : (i+1)*4])[0]
            is_rle = (word >> 31) & 1
            if is_rle:
                count = (word >> 16) & 0x7FFF
                sample = word & 0xFFFF
                uncompressed.extend([sample] * count)
            else:
                sample = word & 0xFFFF
                uncompressed.append(sample)
        return uncompressed

    def capture(self, num_samples: int = 10000) -> List[int]:
        print(f"[Capture] Arming acquisition for {num_samples} samples...")
        if self.mock:
            # Generate realistic test patterns (I2C communication trace)
            samples = []
            # Idle lines (SDA=1, SCL=1)
            samples.extend([0x0003] * 500)
            # START condition (SDA drops while SCL is high)
            samples.extend([0x0001] * 50)
            # Clock and data bits
            for bit in [1, 0, 1, 0, 0, 1, 1, 0]: # 0xA6 address
                samples.extend([(bit << 1)] * 30)         # SCL low, data set
                samples.extend([(bit << 1) | 0x01] * 40)   # SCL high, data sampled
                samples.extend([(bit << 1)] * 20)         # SCL low
            # STOP condition (SDA rises while SCL is high)
            samples.extend([0x0001] * 30)
            samples.extend([0x0003] * 1000)
            return samples
        else:
            # Read from USB FIFO
            raw = self.ser.read(num_samples * 4)
            if self.rle_enabled:
                return self.decompress_rle_stream(raw)
            else:
                return [struct.unpack(">H", raw[i*2:(i+1)*2])[0] for i in range(len(raw)//2)]

def print_ascii_logic(samples: List[int], channels=[0, 1], length=60):
    """Renders a visual logic analyzer waveform directly in the terminal!"""
    step = max(1, len(samples) // length)
    decimated = samples[::step][:length]
    print("\n" + "=" * (length + 14))
    print(" LIVE TERMINAL WAVEFORM PREVIEW")
    print("=" * (length + 14))
    for ch in channels:
        row = f"CH{ch:02d} | "
        for s in decimated:
            bit = (s >> ch) & 1
            row += "‾" if bit else "_"
        print(row)
    print("=" * (length + 14) + "\n")

def main():
    parser = argparse.ArgumentParser(description="PulseWave-FPGA Logic Analyzer Host CLI")
    parser.add_argument("--port", type=str, default="FT232H", help="USB/Serial port or device ID")
    parser.add_argument("--rate", type=int, default=100000000, help="Sample rate in Hz (e.g. 100000000 = 100 MSPS)")
    parser.add_argument("--ddr", action="store_true", help="Enable 400 MSPS DDR capture mode")
    parser.add_argument("--rle", action="store_true", default=True, help="Enable hardware RLE compression")
    parser.add_argument("--samples", type=int, default=5000, help="Number of samples to capture")
    parser.add_argument("--vcd", type=str, default="capture.vcd", help="Output VCD waveform file")
    parser.add_argument("--hardware", action="store_true", help="Connect to physical hardware instead of mock simulator")

    args = parser.parse_args()

    dev = PulseWaveDevice(port=args.port, mock=(not args.hardware))
    if not dev.connect():
        sys.exit(1)

    dev.set_sample_rate(args.rate, ddr=args.ddr, rle=args.rle)
    dev.set_trigger(mask=0x0001, value=0x0001, edge_rise=0x0001, edge_fall=0x0000)

    samples = dev.capture(args.samples)
    print(f"[Capture] Completed: {len(samples)} valid samples acquired.")

    # Render terminal logic waveform
    print_ascii_logic(samples, channels=[0, 1])

    # Export to VCD
    writer = VCDWriter(args.vcd, channel_names=[f"PROBE_{i}" for i in range(16)])
    interval_ns = max(1, int(1e9 / args.rate))
    writer.write(samples, sample_interval_ns=interval_ns)
    print(f"[Success] Captured waveform exported to '{args.vcd}'. Ready for PulseView / GTKWave.")

if __name__ == "__main__":
    main()
