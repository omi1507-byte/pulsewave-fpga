// ============================================================================
// File: sampling_frontend.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: 16-channel Dual-Data-Rate (DDR) / Single-Data-Rate (SDR)
//              sampling engine with programmable decimation prescaler.
// ============================================================================

`timescale 1ns / 1ps

module sampling_frontend #(
    parameter int CHANNELS = 16
)(
    input  logic                   clk_sample,      // High-speed capture clock (up to 200 MHz)
    input  logic                   rst_n,           // Active-low synchronous reset
    input  logic                   enable,          // Sampling active gate
    input  logic                   ddr_mode,        // 1 = DDR 400 MSPS, 0 = SDR 200 MSPS
    input  logic [31:0]            sample_div,      // Clock divider prescaler (0 = div by 1)
    
    // Physical probe inputs from level-shifters
    input  logic [CHANNELS-1:0]    probe_in,
    
    // Sample output interface to trigger and compression engines
    output logic                   sample_valid,
    output logic [CHANNELS-1:0]    sample_phase0,   // Captured on clk rising edge
    output logic [CHANNELS-1:0]    sample_phase1    // Captured on clk falling edge (DDR)
);

    // Synchronize and register input signals
    logic [CHANNELS-1:0] sync_stage1_pos;
    logic [CHANNELS-1:0] sync_stage2_pos;
    logic [CHANNELS-1:0] sync_stage1_neg;
    logic [CHANNELS-1:0] sync_stage2_neg;

    // Prescaler decimation counter
    logic [31:0] prescaler_cnt;
    logic        sample_tick;

    // ------------------------------------------------------------------------
    // Clock divider / decimation logic
    // ------------------------------------------------------------------------
    always_ff @(posedge clk_sample or negedge rst_n) begin
        if (!rst_n) begin
            prescaler_cnt <= 32'd0;
            sample_tick   <= 1'b0;
        end else if (enable) begin
            if (prescaler_cnt >= sample_div) begin
                prescaler_cnt <= 32'd0;
                sample_tick   <= 1'b1;
            end else begin
                prescaler_cnt <= prescaler_cnt + 32'd1;
                sample_tick   <= 1'b0;
            end
        end else begin
            prescaler_cnt <= 32'd0;
            sample_tick   <= 1'b0;
        end
    end

    // ------------------------------------------------------------------------
    // Rising Edge Capture Register (Phase 0)
    // ------------------------------------------------------------------------
    always_ff @(posedge clk_sample or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1_pos <= '0;
            sync_stage2_pos <= '0;
            sample_phase0   <= '0;
        end else if (enable) begin
            sync_stage1_pos <= probe_in;
            sync_stage2_pos <= sync_stage1_pos;
            if (sample_tick) begin
                sample_phase0 <= sync_stage2_pos;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Falling Edge Capture Register (Phase 1) - Provides 400 MSPS DDR capability
    // ------------------------------------------------------------------------
    always_ff @(negedge clk_sample or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1_neg <= '0;
            sync_stage2_neg <= '0;
        end else if (enable) begin
            sync_stage1_neg <= probe_in;
            sync_stage2_neg <= sync_stage1_neg;
        end
    end

    // Forward falling edge sample into rising clock domain
    always_ff @(posedge clk_sample or negedge rst_n) begin
        if (!rst_n) begin
            sample_phase1 <= '0;
            sample_valid  <= 1'b0;
        end else if (enable && sample_tick) begin
            sample_phase1 <= ddr_mode ? sync_stage2_neg : sync_stage2_pos;
            sample_valid  <= 1'b1;
        end else begin
            sample_valid  <= 1'b0;
        end
    end

endmodule
