// ============================================================================
// File: main.c
// Project: PulseWave-FPGA Companion Bridge Firmware
// Description: Microcontroller companion firmware (RP2040 / Cortex-M0+) for
//              high-throughput USB CDC/BULK sample streaming, DMA capture from
//              FPGA parallel bus, and host protocol command routing.
// ============================================================================

#include <stdio.h>
#include <string.h>
#include "protocol.h"

// Hardware Pin Mappings for Companion Microcontroller
#define PIN_FPGA_D0         0   // GPIO 0-7: 8-bit parallel bus
#define PIN_FPGA_WR_STROBE  8
#define PIN_FPGA_RD_STROBE  9
#define PIN_FPGA_BUSY       10
#define PIN_STATUS_LED      25

#define BUFFER_SIZE         4096
static uint8_t stream_dma_buffer[BUFFER_SIZE];

void system_init(void) {
    // Configure GPIOs, high-speed clocks, and DMA channels
    printf("[PulseWave Bridge] Initializing High-Speed Bridge...\n");
}

void fpga_write_command(uint8_t opcode, const void *payload, uint8_t len) {
    uint8_t header[3];
    header[0] = PULSEWAVE_HEADER_MAGIC;
    header[1] = opcode;
    header[2] = len;

    // Send header followed by payload over parallel/SPI interface
    printf("[CMD] Sending opcode 0x%02X, length %d\n", opcode, len);
}

void process_host_command(const uint8_t *buffer, uint16_t len) {
    if (len < 3 || buffer[0] != PULSEWAVE_HEADER_MAGIC) {
        return;
    }

    uint8_t opcode = buffer[1];
    uint8_t payload_len = buffer[2];
    const uint8_t *payload = &buffer[3];

    switch (opcode) {
        case CMD_PING:
            printf("[Host] Ping received. Sending ACK.\n");
            break;
            
        case CMD_SET_SAMPLE_RATE: {
            if (payload_len >= sizeof(sample_rate_config_t)) {
                sample_rate_config_t *cfg = (sample_rate_config_t*)payload;
                printf("[Host] Configure: Div=%u, DDR=%d, RLE=%d\n",
                       cfg->prescaler_div, cfg->ddr_mode, cfg->rle_enable);
                fpga_write_command(CMD_SET_SAMPLE_RATE, cfg, sizeof(sample_rate_config_t));
            }
            break;
        }

        case CMD_SET_TRIGGER: {
            if (payload_len >= sizeof(trigger_config_t)) {
                trigger_config_t *trig = (trigger_config_t*)payload;
                printf("[Host] Trigger: Mask=0x%04X, Val=0x%04X, Rise=0x%04X, Fall=0x%04X\n",
                       trig->mask, trig->value, trig->edge_rise, trig->edge_fall);
                fpga_write_command(CMD_SET_TRIGGER, trig, sizeof(trigger_config_t));
            }
            break;
        }

        case CMD_ARM_CAPTURE:
            printf("[Host] Arming Capture Engine.\n");
            fpga_write_command(CMD_ARM_CAPTURE, NULL, 0);
            break;

        case CMD_FORCE_TRIGGER:
            printf("[Host] Force Trigger Triggered.\n");
            fpga_write_command(CMD_FORCE_TRIGGER, NULL, 0);
            break;

        case CMD_ABORT_CAPTURE:
            printf("[Host] Abort Capture Requested.\n");
            fpga_write_command(CMD_ABORT_CAPTURE, NULL, 0);
            break;

        default:
            printf("[Host] Unknown opcode 0x%02X\n", opcode);
            break;
    }
}

int main(void) {
    system_init();
    printf("[PulseWave Bridge] Ready for host connection.\n");

    while (1) {
        // High-speed event loop: Poll USB endpoints, manage DMA descriptors,
        // and stream captured samples from FPGA buffer to host.
    }

    return 0;
}
