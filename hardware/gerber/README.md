# PCB Manufacturing & Gerber Fabrication Specifications

This board is optimized for standard 4-layer low-cost prototype pools (e.g. JLCPCB JLC04161H-7628 stackup or PCBWay standard 4-layer).

## 1. Board Specifications
* **Dimensions:** 78.0 mm x 52.0 mm (standard credit card pocket footprint)
* **Layer Count:** 4 Layers
* **PCB Thickness:** 1.6 mm ±10%
* **Surface Finish:** ENIG (Electroless Nickel Immersion Gold) - Highly recommended for 0.8mm BGA coplanarity
* **Copper Weight:** 1 oz Outer (35µm) / 1 oz Inner (35µm)
* **Solder Mask:** Matte Black or Classic Green (LPI)
* **Silkscreen:** High-resolution White
* **Minimum Trace / Clearance:** 3.5 mil / 3.5 mil (0.09mm)
* **Minimum Drill Size:** 0.20 mm (via drill), 0.45 mm via outer pad diameter
* **Impedance Control:** Yes (Controlled 50Ω Single-Ended / 100Ω Differential)

---

## 2. 4-Layer Stackup Definition (JLC04161H-7628)

| Layer | Type | Material | Thickness | Copper | Description / Primary Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Top (L1)** | Signal | Copper Foil | 0.035 mm | 1 oz | High-speed probe lines, BGA breakout, RF osc |
| *Dielectric* | Prepreg | 7628 (Dielectric constant $\varepsilon_r \approx 4.6$) | 0.210 mm | - | Core isolation |
| **Inner 1 (L2)**| Plane | Copper Foil | 0.035 mm | 1 oz | Continuous, uninterrupted Ground Reference Plane |
| *Dielectric* | Core | FR4 Core ($\varepsilon_r \approx 4.5$) | 1.065 mm | - | Rigid structural core |
| **Inner 2 (L3)**| Power | Copper Foil | 0.035 mm | 1 oz | Split Power Planes (1.1V Core, 3.3V, 2.5V, 1.8V) |
| *Dielectric* | Prepreg | 7628 ($\varepsilon_r \approx 4.6$) | 0.210 mm | - | Core isolation |
| **Bottom (L4)**| Signal | Copper Foil | 0.035 mm | 1 oz | USB differential pairs, status LEDs, debug testpoints |

### Impedance Calculation Reference
* **50Ω Single-Ended Microstrip (Layer 1 over Layer 2 GND):**
  * Trace Width: **0.360 mm (14.2 mil)**
  * Height above ground ($H$): **0.210 mm**
  * Target Impedance: **$50.2\,\Omega$**
* **90Ω USB 2.0 Differential Pair (Layer 4 over Layer 3 PWR):**
  * Trace Width: **0.250 mm (9.8 mil)**
  * Edge-to-Edge Spacing: **0.180 mm (7.1 mil)**
  * Target Differential Impedance: **$90.1\,\Omega$**

---

## 3. Gerber File Naming Convention
Standard RS-274X Gerber export format:
* `PulseWave_FPGA-F_Cu.gbr` (Top Copper)
* `PulseWave_FPGA-In1_Cu.gbr` (Inner GND Plane)
* `PulseWave_FPGA-In2_Cu.gbr` (Inner Power Plane)
* `PulseWave_FPGA-B_Cu.gbr` (Bottom Copper)
* `PulseWave_FPGA-F_Mask.gbr` (Top Soldermask)
* `PulseWave_FPGA-B_Mask.gbr` (Bottom Soldermask)
* `PulseWave_FPGA-F_Silkscreen.gbr` (Top Legend)
* `PulseWave_FPGA-B_Silkscreen.gbr` (Bottom Legend)
* `PulseWave_FPGA-Edge_Cuts.gbr` (Board Outline & Slots)
* `PulseWave_FPGA-PTH.drl` (Plated Through-Hole Drill)
* `PulseWave_FPGA-NPTH.drl` (Non-Plated Tooling Holes)
