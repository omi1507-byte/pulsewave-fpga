// ============================================================================
// File: usb_stream_interface.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: FTDI FT232HQ Synchronous 245 FIFO protocol streaming engine.
//              Serializes 32-bit sample words into 8-bit bus transfers, achieving
//              up to 40 MB/s sustained host streaming bandwidth over USB 2.0.
// ============================================================================

`timescale 1ns / 1ps

module usb_stream_interface (
    input  logic                   usb_clk60,       // 60 MHz synchronous clock from FT232H
    input  logic                   rst_n,
    
    // FTDI FT232H Physical Interface
    input  logic                   ft_txe_n,        // Transmit buffer empty (active low)
    output logic                   ft_wr_n,         // Write strobe (active low)
    output logic [7:0]             ft_data,         // Outbound 8-bit data bus
    
    // Input Sample Stream from Asynchronous FIFO
    input  logic                   fifo_empty,
    input  logic [31:0]            fifo_data,
    output logic                   fifo_rd_en,
    
    // Activity indicator
    output logic                   usb_active
);

    typedef enum logic [2:0] {
        IDLE,
        BYTE_0,
        BYTE_1,
        BYTE_2,
        BYTE_3
    } stream_state_t;

    stream_state_t state;
    logic [31:0] sample_holding_reg;

    always_ff @(posedge usb_clk60 or negedge rst_n) begin
        if (!rst_n) begin
            state              <= IDLE;
            ft_wr_n            <= 1'b1;
            ft_data            <= 8'h00;
            fifo_rd_en         <= 1'b0;
            sample_holding_reg <= 32'h0;
            usb_active         <= 1'b0;
        end else begin
            fifo_rd_en <= 1'b0;
            ft_wr_n    <= 1'b1;

            case (state)
                IDLE: begin
                    usb_active <= 1'b0;
                    // When FTDI has space (txe_n = 0) and FIFO has samples (fifo_empty = 0)
                    if (!ft_txe_n && !fifo_empty) begin
                        fifo_rd_en         <= 1'b1;
                        sample_holding_reg <= fifo_data;
                        state              <= BYTE_0;
                    end
                end

                BYTE_0: begin
                    if (!ft_txe_n) begin
                        ft_data    <= sample_holding_reg[31:24];
                        ft_wr_n    <= 1'b0;
                        usb_active <= 1'b1;
                        state      <= BYTE_1;
                    end
                end

                BYTE_1: begin
                    if (!ft_txe_n) begin
                        ft_data <= sample_holding_reg[23:16];
                        ft_wr_n <= 1'b0;
                        state   <= BYTE_2;
                    end
                end

                BYTE_2: begin
                    if (!ft_txe_n) begin
                        ft_data <= sample_holding_reg[15:8];
                        ft_wr_n <= 1'b0;
                        state   <= BYTE_3;
                    end
                end

                BYTE_3: begin
                    if (!ft_txe_n) begin
                        ft_data <= sample_holding_reg[7:0];
                        ft_wr_n <= 1'b0;
                        
                        // Check if back-to-back transfer can occur
                        if (!fifo_empty) begin
                            fifo_rd_en         <= 1'b1;
                            sample_holding_reg <= fifo_data;
                            state              <= BYTE_0;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
