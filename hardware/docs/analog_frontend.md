# PulseWave-FPGA Input Analog Frontend Design

## 1. High-Speed Probe Interface Requirements
A high-performance logic analyzer frontend must satisfy four strict engineering criteria:
1. **Low Input Capacitance ($C_{in} < 5\text{ pF}$):** Avoid loading high-frequency target signals (such as 50MHz QSPI or fast rising edge I2C pull-ups).
2. **Wide Input Voltage Dynamic Range (1.2V to 5.0V):** Seamlessly interface with modern 1.2V/1.8V core logic, 3.3V microcontrollers, and vintage 5.0V TTL/CMOS circuits.
3. **Overvoltage and Transient Protection:** Survive user miswiring up to $\pm 15\text{ kV}$ ESD contact and continuous overvoltage up to $+9\text{ V}$.
4. **Controlled Impedance Propagation:** Equalized line delays across all 16 channels to avoid skew artifacts during parallel bus analysis.

---

## 2. Channel Circuit Topology

For each channel $k \in \{0, \dots, 15\}$, the signal path is structured as follows:

```
Probe Input J2/J3 Pin
       │
       ├───[ 100kΩ R_pull ]─── GND (Known state when disconnected)
       │
       ├───[ USBLC6-2SC6 ESD Diode ]─── VCC / GND (Clamping < 0.25pF)
       │
       ├───[ 49.9Ω R_series ]─── Low-pass damping & reflections suppression
       │
       ▼
  SN74AVC8T245 Input Pin (V_CCA = 1.2V - 5.0V target system)
       │
   (Level Shifter)
       │
       ▼
  SN74AVC8T245 Output Pin (V_CCB = 2.5V or 3.3V FPGA Bank Voltage)
       │
       └───[ Matched 50Ω PCB Microstrip ]─── FPGA Input Pin (LFE5U-25F)
```

### 2.1 Bandwidth and Rise Time Calculation
The effective analog frontend bandwidth is limited by the $RC$ time constant formed by the series resistance and parasitic capacitance:

$$R_{total} = R_{source} + R_{series} \approx 50\,\Omega + 49.9\,\Omega \approx 100\,\Omega$$
$$C_{total} = C_{probe} + C_{ESD} + C_{transceiver} \approx 2.0\text{ pF} + 0.25\text{ pF} + 3.0\text{ pF} \approx 5.25\text{ pF}$$

The $-3\text{ dB}$ cutoff frequency is:
$$f_{-3\text{dB}} = \frac{1}{2 \pi \cdot R_{total} \cdot C_{total}} = \frac{1}{2 \pi \cdot 100 \cdot 5.25 \times 10^{-12}} \approx 303\text{ MHz}$$

The corresponding minimum measurable $10\%-90\%$ rise time is:
$$t_{r} = \frac{0.35}{f_{-3\text{dB}}} = \frac{0.35}{303 \times 10^6} \approx 1.15\text{ ns}$$

This ensures that digital signals running at up to 150 MHz fundamental frequency (with fast edge transitions down to ~1.2 ns) are captured without distortion or edge jitter.

---

## 3. PCB Layout & Trace Length Matching
To prevent channel-to-channel skew from corrupting high-speed synchronous parallel buses (e.g. 8-bit camera interfaces or parallel DACs):
* **Trace Topology:** Coplanar waveguide over continuous ground plane (Layer 2).
* **Length Matching Target:** All 16 channels matched within $\pm 0.5\text{ mm}$ ($\Delta t_{skew} < 3.5\text{ ps}$).
* **Trace Clearance:** $3W$ spacing rule (3x trace width) maintained between adjacent channels to keep crosstalk coupling below $-42\text{ dB}$.
