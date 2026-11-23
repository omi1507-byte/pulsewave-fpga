# PulseWave-FPGA Host Binary Communication Protocol

## 1. Frame Structure
Host communication uses structured variable-length packets:

| Byte Offset | Field Name | Width | Description |
| :--- | :--- | :--- | :--- |
| `0` | `HEADER` | 1 Byte | Always `0xAA` |
| `1` | `OPCODE` | 1 Byte | Command identifier (see table below) |
| `2` | `LENGTH` | 1 Byte | Payload byte length ($N$) |
| `3 .. 2+N` | `PAYLOAD` | $N$ Bytes | Command-specific arguments (Big-Endian) |
| `3+N` | `CHECKSUM` | 1 Byte | XOR sum of all preceding bytes |

---

## 2. Command Set

### `0x00` - PING
* **Payload Length:** 0
* **Response:** Single byte `0x55` (PONG)

### `0x01` - SET_SAMPLE_RATE
* **Payload Length:** 5 Bytes
* **Format:**
  * `[0..3]`: 32-bit Prescaler divider counter ($div$)
    * $f_{sample} = \frac{200\text{ MHz}}{div + 1}$
  * `[4]`: Flags byte
    * Bit 0: DDR mode enable ($1 = \text{400 MSPS}, 0 = \text{200 MSPS}$)
    * Bit 1: Hardware RLE compression enable ($1 = \text{On}, 0 = \text{Bypass}$)
* **Response:** `0x06` (ACK)

### `0x02` - SET_TRIGGER
* **Payload Length:** 8 Bytes
* **Format:**
  * `[0..1]`: 16-bit Pattern Mask (1 = channel active in pattern comparison)
  * `[2..3]`: 16-bit Expected Value
  * `[4..5]`: 16-bit Rising Edge Mask (1 = channel requires $0 \to 1$ transition)
  * `[6..7]`: 16-bit Falling Edge Mask (1 = channel requires $1 \to 0$ transition)
* **Response:** `0x06` (ACK)

### `0x03` - SET_BUFFER_DEPTH
* **Payload Length:** 8 Bytes
* **Format:**
  * `[0..3]`: 32-bit Pre-trigger samples required before arming
  * `[4..7]`: 32-bit Post-trigger samples to record after trigger match
* **Response:** `0x06` (ACK)

### `0x04` - ARM_CAPTURE
* **Payload Length:** 0
* **Action:** Arms the trigger state machine and begins ring buffer filling.
* **Response:** `0x06` (ACK)

### `0x05` - FORCE_TRIGGER
* **Payload Length:** 0
* **Action:** Forces immediate trigger firing regardless of probe input states.
* **Response:** `0x06` (ACK)

### `0x06` - ABORT_CAPTURE
* **Payload Length:** 0
* **Action:** Halts active sampling immediately and flushes pending FIFO data.
* **Response:** `0x06` (ACK)

### `0x07` - GET_STATUS
* **Payload Length:** 0
* **Response:** 1 Byte Status Flags:
  * Bit 0: `capture_active`
  * Bit 1: `triggered`
  * Bit 2: `capture_complete`
  * Bit 3: `fifo_overflow`
