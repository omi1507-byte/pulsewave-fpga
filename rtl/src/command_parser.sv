// ============================================================================
// File: command_parser.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Host command decoder for USB/UART communication. Decodes
//              configuration packets for sample rate, multi-stage triggers,
//              buffer sizes, and capture initiation.
// ============================================================================

`timescale 1ns / 1ps

module command_parser #(
    parameter int CHANNELS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    
    // Byte stream from USB bridge
    input  logic                   rx_valid,
    input  logic [7:0]             rx_byte,
    
    // Status reply to USB bridge
    output logic                   tx_valid,
    output logic [7:0]             tx_byte,
    
    // Decoded control parameters
    output logic                   arm,
    output logic                   abort_cmd,
    output logic                   force_trigger,
    output logic                   ddr_mode,
    output logic                   rle_enable,
    output logic [31:0]            sample_div,
    output logic [CHANNELS-1:0]    trig_mask,
    output logic [CHANNELS-1:0]    trig_value,
    output logic [CHANNELS-1:0]    trig_edge_rise,
    output logic [CHANNELS-1:0]    trig_edge_fall,
    output logic [31:0]            pre_trigger_depth,
    output logic [31:0]            post_trigger_depth,
    
    // Status inputs from capture system
    input  logic                   capture_active,
    input  logic                   triggered_status,
    input  logic                   capture_complete
);

    typedef enum logic [3:0] {
        WAIT_HEADER,
        GET_CMD,
        GET_LEN,
        GET_PAYLOAD,
        PROCESS_CMD,
        SEND_ACK
    } cmd_state_t;

    cmd_state_t state;

    logic [7:0]  cmd_opcode;
    logic [7:0]  payload_len;
    logic [7:0]  byte_counter;
    logic [7:0]  payload_buf [0:15];

    // Opcodes
    localparam logic [7:0] CMD_PING            = 8'h00;
    localparam logic [7:0] CMD_SET_SAMPLE_RATE = 8'h01;
    localparam logic [7:0] CMD_SET_TRIGGER     = 8'h02;
    localparam logic [7:0] CMD_SET_DEPTH       = 8'h03;
    localparam logic [7:0] CMD_ARM             = 8'h04;
    localparam logic [7:0] CMD_FORCE_TRIG      = 8'h05;
    localparam logic [7:0] CMD_ABORT           = 8'h06;
    localparam logic [7:0] CMD_GET_STATUS      = 8'h07;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state              <= WAIT_HEADER;
            arm                <= 1'b0;
            abort_cmd          <= 1'b0;
            force_trigger      <= 1'b0;
            ddr_mode           <= 1'b0;
            rle_enable         <= 1'b1;
            sample_div         <= 32'd0;
            trig_mask          <= '0;
            trig_value         <= '0;
            trig_edge_rise     <= '0;
            trig_edge_fall     <= '0;
            pre_trigger_depth  <= 32'd1024;
            post_trigger_depth <= 32'd65536;
            tx_valid           <= 1'b0;
            tx_byte            <= 8'h00;
            byte_counter       <= 8'd0;
        end else begin
            force_trigger <= 1'b0;
            abort_cmd     <= 1'b0;
            tx_valid      <= 1'b0;

            case (state)
                WAIT_HEADER: begin
                    if (rx_valid && rx_byte == 8'hAA) begin
                        state <= GET_CMD;
                    end
                end

                GET_CMD: begin
                    if (rx_valid) begin
                        cmd_opcode <= rx_byte;
                        state      <= GET_LEN;
                    end
                end

                GET_LEN: begin
                    if (rx_valid) begin
                        payload_len  <= rx_byte;
                        byte_counter <= 8'd0;
                        if (rx_byte == 8'd0) begin
                            state <= PROCESS_CMD;
                        end else begin
                            state <= GET_PAYLOAD;
                        end
                    end
                end

                GET_PAYLOAD: begin
                    if (rx_valid) begin
                        payload_buf[byte_counter] <= rx_byte;
                        byte_counter <= byte_counter + 8'd1;
                        if (byte_counter + 8'd1 >= payload_len) begin
                            state <= PROCESS_CMD;
                        end
                    end
                end

                PROCESS_CMD: begin
                    case (cmd_opcode)
                        CMD_PING: begin
                            tx_byte  <= 8'h55; // PONG
                            tx_valid <= 1'b1;
                        end

                        CMD_SET_SAMPLE_RATE: begin
                            sample_div <= {payload_buf[0], payload_buf[1], payload_buf[2], payload_buf[3]};
                            ddr_mode   <= payload_buf[4][0];
                            rle_enable <= payload_buf[4][1];
                            tx_byte    <= 8'h06; // ACK
                            tx_valid   <= 1'b1;
                        end

                        CMD_SET_TRIGGER: begin
                            trig_mask      <= {payload_buf[0], payload_buf[1]};
                            trig_value     <= {payload_buf[2], payload_buf[3]};
                            trig_edge_rise <= {payload_buf[4], payload_buf[5]};
                            trig_edge_fall <= {payload_buf[6], payload_buf[7]};
                            tx_byte        <= 8'h06; // ACK
                            tx_valid       <= 1'b1;
                        end

                        CMD_SET_DEPTH: begin
                            pre_trigger_depth  <= {payload_buf[0], payload_buf[1], payload_buf[2], payload_buf[3]};
                            post_trigger_depth <= {payload_buf[4], payload_buf[5], payload_buf[6], payload_buf[7]};
                            tx_byte            <= 8'h06; // ACK
                            tx_valid           <= 1'b1;
                        end

                        CMD_ARM: begin
                            arm      <= 1'b1;
                            tx_byte  <= 8'h06; // ACK
                            tx_valid <= 1'b1;
                        end

                        CMD_FORCE_TRIG: begin
                            force_trigger <= 1'b1;
                            tx_byte       <= 8'h06; // ACK
                            tx_valid      <= 1'b1;
                        end

                        CMD_ABORT: begin
                            arm       <= 1'b0;
                            abort_cmd <= 1'b1;
                            tx_byte   <= 8'h06; // ACK
                            tx_valid  <= 1'b1;
                        end

                        CMD_GET_STATUS: begin
                            tx_byte  <= {5'd0, capture_complete, triggered_status, capture_active};
                            tx_valid <= 1'b1;
                        end

                        default: begin
                            tx_byte  <= 8'h15; // NACK
                            tx_valid <= 1'b1;
                        end
                    endcase
                    state <= WAIT_HEADER;
                end

                default: state <= WAIT_HEADER;
            endcase
        end
    end

endmodule
