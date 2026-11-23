# Contributing to PulseWave-FPGA

We welcome contributions from hardware designers, FPGA engineers, and embedded software developers!

## Development Guidelines

### RTL & Verilog Style
- Write synthesizable SystemVerilog code compatible with both open-source synthesis (`yosys`) and commercial toolchains.
- Keep clock domains clearly separated. All clock domain crossings (CDC) must use parameterized synchronization FIFOs with Gray code pointers.
- Ensure every new RTL core is accompanied by a unit testbench in `rtl/sim/`.
- Run `make test_golden` and lint before submitting PRs.

### Hardware & KiCad Guidelines
- Keep all schematic symbols aligned to the 50 mil grid in KiCad.
- Maintain controlled impedance rules: 50Ω single-ended for probe traces and 90Ω differential for USB data pairs.
- When adding components, always provide manufacturer part numbers and LCSC references in the BOM.

### Pull Request Checklist
1. Unit tests pass locally (`python3 rtl/sim/simulate_golden.py`).
2. Timing constraints in `.sdc` and `.lpf` are updated if clock frequencies or pinouts change.
3. Documentation in `docs/` reflects any modifications to communication registers or hardware topology.
