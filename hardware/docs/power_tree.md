# PulseWave-FPGA Power Delivery Network (PDN) Architecture

```
                       [ USB-C 5.0V / 2.0A Input ]
                                    │
                         [ Polyfuse 1.5A PTC ]
                                    │
                  [ Ferrite Bead BLM18PG601SN1 (600Ω) ]
                                    │
                   ┌────────────────┴────────────────┐
                   │                                 │
          [ TPS62088 Buck ]                [ TLV73333 LDO 3.3V ]
       (4 MHz Sync Switching)                        │
                   │                        ┌────────┴────────┬────────┐
              1.1V V_CORE                   │                 │        │
                   │                        ▼                 ▼        ▼
       [ FPGA Core Logic & PLLs ]     FT232H USB      Oscillator   Status LEDs
          (Max 1.2A @ 1.1V)               Bridge        25.0MHz      (4x)
                                            │
                                            ├────────► [ TLV73325 LDO 2.5V ]
                                            │                 │
                                            │           2.5V VCC_AUX / VCCIO
                                            │
                                            └────────► [ TLV73318 LDO 1.8V ]
                                                              │
                                                        1.8V HyperRAM & Bank
```

## Power Sequencing Requirements
The Lattice ECP5 FPGA family requires monotonic power-up sequencing to guarantee proper POR (Power-On Reset) state machine initialization:
1. **$V_{CORE}$ (1.1V) and $V_{CCAUX}$ (2.5V)** ramp simultaneously or $V_{CORE}$ first within $0.1\text{ ms} \dots 50\text{ ms}$.
2. **$V_{CCIO}$ (3.3V and 1.8V)** ramp following $V_{CORE}$ stabilization.
3. The TPS62088 soft-start pin ($t_{ss} = 1.2\text{ ms}$) prevents host USB inrush current tripping on unpowered laptop hubs.
