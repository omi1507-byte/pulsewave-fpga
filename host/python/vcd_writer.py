#!/usr/bin/env python3
"""
vcd_writer.py
-------------
High-performance Value Change Dump (VCD) generator for PulseWave-FPGA.
Converts captured digital sample arrays into IEEE 1364 standard VCD files
compatible with GTKWave, Sigrok PulseView, and Surfer.
"""

from typing import List, Tuple

class VCDWriter:
    def __init__(self, filename: str, channel_names: List[str] = None, timescale: str = "1ns"):
        self.filename = filename
        self.channel_count = 16
        if channel_names is None:
            self.channel_names = [f"CH{i}" for i in range(self.channel_count)]
        else:
            self.channel_names = channel_names
            self.channel_count = len(channel_names)
        self.timescale = timescale
        self.identifiers = [chr(33 + i) for i in range(self.channel_count)]  # '!' to '0'

    def write(self, samples: List[int], sample_interval_ns: int = 5):
        """
        Writes raw 16-bit logic samples to VCD.
        :param samples: Array of integer values (bit 0 = CH0, bit 15 = CH15)
        :param sample_interval_ns: Nanoseconds per sample
        """
        with open(self.filename, "w", encoding="utf-8") as f:
            # Header
            f.write("$date 2026-11-23 $end\n")
            f.write("$version PulseWave-FPGA VCD Exporter v1.2 $end\n")
            f.write(f"$timescale {self.timescale} $end\n")
            f.write("$scope module pulsewave $end\n")
            
            for ch_idx in range(self.channel_count):
                f.write(f"$var wire 1 {self.identifiers[ch_idx]} {self.channel_names[ch_idx]} $end\n")
            
            f.write("$upscope $end\n")
            f.write("$enddefinitions $end\n")

            # Initial state
            f.write("#0\n$dumpvars\n")
            for ch_idx in range(self.channel_count):
                f.write(f"0{self.identifiers[ch_idx]}\n")
            f.write("$end\n")

            current_time = 0
            prev_sample = None

            for s in samples:
                if prev_sample != s:
                    f.write(f"#{current_time}\n")
                    for ch_idx in range(self.channel_count):
                        val = (s >> ch_idx) & 1
                        if prev_sample is None or ((prev_sample >> ch_idx) & 1) != val:
                            f.write(f"{val}{self.identifiers[ch_idx]}\n")
                    prev_sample = s
                current_time += sample_interval_ns

        print(f"[VCDWriter] Wrote {len(samples)} samples to '{self.filename}'.")
