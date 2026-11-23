# PulseWave-FPGA Hardware Bring-Up & Validation Guide

This step-by-step procedure guides engineers through validating a freshly assembled prototype PCB, verifying power sequencing, JTAG chain integrity, FPGA bitstream loading, and signal capture.

---

## Equipment Required
1. Bench Power Supply with adjustable current limit (set to **5.0V, 200mA limit**).
2. Digital Multimeter (DMM) with continuity and diode check modes.
3. Oscilloscope (at least 100MHz bandwidth) with passive 10x probes.
4. JTAG Programmer (Lattice HW-USBN-2B, FT232H, or Raspberry Pi GPIO).
5. USB-C to USB-A cable.

---

## Step 1: Cold Board Impedance & Short-Circuit Check
**DO NOT apply power yet.** Set your DMM to resistance mode and verify cold impedance from each power net to Ground (`GND`):

| Power Rail | Testpoint Designator | Expected Resistance to GND | Action if Lower |
| :--- | :--- | :--- | :--- |
| **VBUS (+5V)** | `TP_5V` | $> 50\text{ k}\Omega$ | Check USB-C CC resistors, D1 ESD diode |
| **+3V3** | `TP_3V3` | $> 10\text{ k}\Omega$ | Check FT232H decoupling capacitors |
| **+2V5_AUX** | `TP_2V5` | $> 5\text{ k}\Omega$ | Inspect ECP5 Bank 0 decoupling capacitors |
| **+1V8_RAM** | `TP_1V8` | $> 2\text{ k}\Omega$ | Inspect HyperRAM BGA solder bridges |
| **+1V1_CORE** | `TP_1V1` | **$80\,\Omega \dots 300\,\Omega$** | Normal for high-gate-count FPGA core. Below $10\,\Omega$ indicates solder short! |

---

## Step 2: First Power Application & Voltage Measurement
1. Connect the bench supply (5.0V, current limit 200mA).
2. Turn on supply and observe input current. **Normal idle current is 45mA to 85mA.**
3. Measure regulated voltage rails with your DMM:
   * `TP_1V1`: Must read **$1.10\text{ V} \pm 0.03\text{ V}$**
   * `TP_3V3`: Must read **$3.30\text{ V} \pm 0.05\text{ V}$**
   * `TP_2V5`: Must read **$2.50\text{ V} \pm 0.04\text{ V}$**
   * `TP_1V8`: Must read **$1.80\text{ V} \pm 0.03\text{ V}$**
4. Check 25.0 MHz Oscillator output (`TP_CLK`) with oscilloscope: Verify a clean 3.3V CMOS square wave with $< 1.5\text{ ns}$ rise time.

---

## Step 3: JTAG Chain Scan
Connect your JTAG adapter to header `J4` (Pin 1: VCC, Pin 2: TCK, Pin 3: TDO, Pin 4: TDI, Pin 5: TMS, Pin 6: GND). Run OpenOCD:

```bash
openocd -f /usr/share/openocd/scripts/interface/ftdi/um232h.cfg \
        -c "transport select jtag" \
        -c "jtag newtap ecp5 tap -irlen 8 -expected-id 0x41111043" \
        -c "init" -c "scan_chain" -c "shutdown"
```

**Expected Output:**
```
Found JTAG TAP: ecp5.tap (idcode: 0x41111043, irdna: 0x24)
Total TAPs detected: 1
```

---

## Step 4: Loading Test Bitstream
Synthesize and flash the top-level bitstream:

```bash
# 1. Synthesize with Yosys
yosys -p "synth_ecp5 -top pulsewave_top -json pulsewave.json" rtl/src/*.sv

# 2. Place & Route with nextpnr
nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json pulsewave.json \
             --lpf rtl/constraints/pulsewave_ecp5.lpf --textcfg pulsewave.config

# 3. Pack bitstream
ecppack --compress pulsewave.config pulsewave.bit

# 4. Program into SPI Flash
openFPGALoader -b ecp5 pulsewave.bit
```

* Verify that **LED1 (Green Power LED)** lights solid, confirming PLL lock.

---

## Step 5: High-Speed Signal Verification
1. Connect Probe Channel 0 (`CH0`) to a known 10MHz square wave signal generator.
2. Run host capture:
   ```bash
   python3 host/python/pulsewave_cli.py --rate 100000000 --samples 5000 --vcd test_10mhz.vcd
   ```
3. Open `test_10mhz.vcd` in GTKWave or PulseView:
   * Verify measured frequency is exactly $10.00\text{ MHz} \pm 0.01\%$.
   * Verify jitter is $< 5\text{ ns}$ (1 sample interval).
