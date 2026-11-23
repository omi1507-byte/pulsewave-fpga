// ============================================================================
// File: protocol.h
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Shared binary host communication protocol definitions.
// ============================================================================

#ifndef PULSEWAVE_PROTOCOL_H
#define PULSEWAVE_PROTOCOL_H

#include <stdint.h>

#define PULSEWAVE_HEADER_MAGIC      0xAA
#define PULSEWAVE_ACK               0x06
#define PULSEWAVE_NACK              0x15

// Command Opcodes
typedef enum {
    CMD_PING                = 0x00,
    CMD_SET_SAMPLE_RATE     = 0x01,
    CMD_SET_TRIGGER         = 0x02,
    CMD_SET_BUFFER_DEPTH    = 0x03,
    CMD_ARM_CAPTURE         = 0x04,
    CMD_FORCE_TRIGGER       = 0x05,
    CMD_ABORT_CAPTURE       = 0x06,
    CMD_GET_STATUS          = 0x07,
    CMD_READ_STREAM_BURST   = 0x08
} pulsewave_cmd_t;

// Trigger Configuration Payload
typedef struct __attribute__((packed)) {
    uint16_t mask;              // 1 = active channel in pattern
    uint16_t value;             // expected logic level
    uint16_t edge_rise;         // 1 = trigger on 0 -> 1 transition
    uint16_t edge_fall;         // 1 = trigger on 1 -> 0 transition
} trigger_config_t;

// Sample Rate Configuration Payload
typedef struct __attribute__((packed)) {
    uint32_t prescaler_div;     // Clock division factor (0 = 200/400 MSPS)
    uint8_t  ddr_mode;          // 1 = 400 MSPS DDR, 0 = 200 MSPS SDR
    uint8_t  rle_enable;        // 1 = Hardware RLE enabled
} sample_rate_config_t;

// Status Response Payload
typedef struct __attribute__((packed)) {
    uint8_t capture_active   : 1;
    uint8_t triggered        : 1;
    uint8_t capture_complete : 1;
    uint8_t fifo_overflow    : 1;
    uint8_t reserved         : 4;
    uint32_t samples_captured;
} system_status_t;

// 32-Bit RLE Compressed Stream Token
typedef union {
    uint32_t raw_word;
    struct __attribute__((packed)) {
        uint16_t sample_data;   // 16 logic channels
        uint16_t run_count : 15;// number of consecutive cycles
        uint16_t is_rle    : 1; // 1 = RLE compressed run, 0 = raw sample
    } token;
} rle_packet_t;

#endif // PULSEWAVE_PROTOCOL_H
