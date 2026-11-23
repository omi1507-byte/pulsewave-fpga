// ============================================================================
// File: pulsewave_top.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Top-Level Integration Module. Interfaces physical probes,
//              DDR sampling cores, real-time RLE compressor, trigger engine,
//              dual-clock CDC FIFO, FT232H USB bridge, and status LEDs.
// ============================================================================

`timescale 1ns / 1ps

module pulsewave_top #(
    parameter int CHANNELS = 16
)(
    // Primary 25.0 MHz On-Board Oscillator
    input  logic                   clk_25m,
    input  logic                   rst_n_pin,       // External reset button (optional)
    
    // 16-Channel Physical Probe Inputs
    input  logic [CHANNELS-1:0]    probe_pins,
    
    // FTDI FT232HQ USB 2.0 High-Speed FIFO Interface
    input  logic                   ft_clk60,        // 60 MHz Synchronous Clock from FTDI
    input  logic                   ft_rxf_n,        // Host data available to read (active low)
    input  logic                   ft_txe_n,        // Host ready for transmit (active low)
    output logic                   ft_rd_n,         // Read strobe (active low)
    output logic                   ft_wr_n,         // Write strobe (active low)
    output logic                   ft_oe_n,         // Output enable (active low)
    inout  wire  [7:0]             ft_data,         // Bidirectional 8-bit data bus
    
    // Front Panel Diagnostic LEDs
    output logic                   led_power,       // LED1: Power & Clock OK
    output logic                   led_armed,       // LED2: Armed & Waiting
    output logic                   led_triggered,   // LED3: Trigger Fired
    output logic                   led_usb_act      // LED4: High-Speed Streaming
);

    // ------------------------------------------------------------------------
    // Clock & Reset Management
    // ------------------------------------------------------------------------
    // In synthesis, clk_sample is generated via ECP5 EHXPLLL from 25MHz to 200MHz.
    // For simulation / synthesis compatibility, a clock placeholder is defined.
    logic clk_sample;
    logic pll_locked;

`ifdef SYNTHESIS
    // Lattice ECP5 PLL Primitive (Project Trellis / Diamond)
    EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENA("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .CLKOP_FPHASE(0),
        .CLKOP_CPHASE(2),
        .OUTDIVIDER_MUXA("DIVA"),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(3),          // 200 MHz output
        .CLKFB_DIV(8),
        .CLKI_DIV(1),
        .FEEDBK_PATH("INT_OP")
    ) pll_inst (
        .CLKI(clk_25m),
        .CLKFB(clk_sample),
        .CLKOP(clk_sample),
        .CLKOS(),
        .CLKOS2(),
        .CLKOS3(),
        .LOCK(pll_locked),
        .RST(1'b0),
        .STDBY(1'b0),
        .PHASCNS(),
        .PHASDIR(),
        .PHASSTEP(),
        .PHASLOADREG(),
        .ENCLKOP(1'b0),
        .ENCLKOS(1'b0),
        .ENCLKOS2(1'b0),
        .ENCLKOS3(1'b0)
    );
`else
    // Behavioral Clock Generator for Simulation
    assign clk_sample = clk_25m;
    assign pll_locked = 1'b1;
`endif

    logic sys_rst_n;
    assign sys_rst_n = rst_n_pin & pll_locked;

    // ------------------------------------------------------------------------
    // Internal Interconnect Signals
    // ------------------------------------------------------------------------
    logic                   sample_valid;
    logic [CHANNELS-1:0]    sample_p0;
    logic [CHANNELS-1:0]    sample_p1;
    
    logic                   arm_cmd;
    logic                   abort_cmd;
    logic                   force_trigger_cmd;
    logic                   ddr_mode;
    logic                   rle_enable;
    logic [31:0]            sample_div;
    logic [CHANNELS-1:0]    trig_mask;
    logic [CHANNELS-1:0]    trig_val;
    logic [CHANNELS-1:0]    trig_rise;
    logic [CHANNELS-1:0]    trig_fall;
    logic [31:0]            pre_depth;
    logic [31:0]            post_depth;

    logic                   trig_fired;
    logic                   capture_done;
    logic [1:0]             trig_state;

    logic                   rle_out_valid;
    logic [31:0]            rle_out_data;
    logic                   fifo_wr_full;
    logic                   fifo_almost_full;

    logic                   fifo_rd_empty;
    logic [31:0]            fifo_rd_data;
    logic                   fifo_rd_en;

    logic                   usb_act_pulse;

    // ------------------------------------------------------------------------
    // 1. Sampling Frontend Core
    // ------------------------------------------------------------------------
    sampling_frontend #(
        .CHANNELS(CHANNELS)
    ) u_frontend (
        .clk_sample     (clk_sample),
        .rst_n          (sys_rst_n),
        .enable         (arm_cmd),
        .ddr_mode       (ddr_mode),
        .sample_div     (sample_div),
        .probe_in       (probe_pins),
        .sample_valid   (sample_valid),
        .sample_phase0  (sample_p0),
        .sample_phase1  (sample_p1)
    );

    // ------------------------------------------------------------------------
    // 2. Multi-Stage Trigger Engine
    // ------------------------------------------------------------------------
    trigger_engine #(
        .CHANNELS(CHANNELS)
    ) u_trigger (
        .clk                (clk_sample),
        .rst_n              (sys_rst_n),
        .arm                (arm_cmd),
        .force_trigger      (force_trigger_cmd),
        .trig_mask          (trig_mask),
        .trig_value         (trig_val),
        .trig_edge_rise     (trig_rise),
        .trig_edge_fall     (trig_fall),
        .pre_trigger_depth  (pre_depth),
        .post_trigger_depth (post_depth),
        .sample_valid       (sample_valid),
        .sample_in          (sample_p0),
        .triggered          (trig_fired),
        .capture_complete   (capture_done),
        .state_out          (trig_state)
    );

    // ------------------------------------------------------------------------
    // 3. Real-Time Hardware RLE Compressor
    // ------------------------------------------------------------------------
    rle_compressor #(
        .CHANNELS(CHANNELS)
    ) u_rle (
        .clk          (clk_sample),
        .rst_n        (sys_rst_n),
        .enable       (rle_enable),
        .flush        (capture_done),
        .sample_valid (sample_valid),
        .sample_in    (sample_p0),
        .out_valid    (rle_out_valid),
        .out_data     (rle_out_data),
        .out_ready    (!fifo_almost_full)
    );

    // ------------------------------------------------------------------------
    // 4. Asynchronous Dual-Clock CDC FIFO (Capture clk -> USB 60MHz clk)
    // ------------------------------------------------------------------------
    sample_fifo #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(11) // 2048 words buffer
    ) u_fifo (
        .wr_clk         (clk_sample),
        .wr_rst_n       (sys_rst_n),
        .wr_en          (rle_out_valid),
        .wr_data        (rle_out_data),
        .wr_full        (fifo_wr_full),
        .wr_almost_full (fifo_almost_full),
        .rd_clk         (ft_clk60),
        .rd_rst_n       (sys_rst_n),
        .rd_en          (fifo_rd_en),
        .rd_data        (fifo_rd_data),
        .rd_empty       (fifo_rd_empty)
    );

    // ------------------------------------------------------------------------
    // 5. FT232H Synchronous 245 FIFO Streaming Interface
    // ------------------------------------------------------------------------
    logic [7:0] usb_tx_data;
    assign ft_data = (!ft_wr_n) ? usb_tx_data : 8'hzz;
    assign ft_oe_n = 1'b1; // Write-only to host during streaming
    assign ft_rd_n = 1'b1;

    usb_stream_interface u_usb_stream (
        .usb_clk60   (ft_clk60),
        .rst_n       (sys_rst_n),
        .ft_txe_n    (ft_txe_n),
        .ft_wr_n     (ft_wr_n),
        .ft_data     (usb_tx_data),
        .fifo_empty  (fifo_rd_empty),
        .fifo_data   (fifo_rd_data),
        .fifo_rd_en  (fifo_rd_en),
        .usb_active  (usb_act_pulse)
    );

    // ------------------------------------------------------------------------
    // 6. Command Parser & Host Control
    // ------------------------------------------------------------------------
    command_parser #(
        .CHANNELS(CHANNELS)
    ) u_cmd_parser (
        .clk                (ft_clk60),
        .rst_n              (sys_rst_n),
        .rx_valid           (!ft_rxf_n),
        .rx_byte            (ft_data),
        .tx_valid           (),
        .tx_byte            (),
        .arm                (arm_cmd),
        .abort_cmd          (abort_cmd),
        .force_trigger      (force_trigger_cmd),
        .ddr_mode           (ddr_mode),
        .rle_enable         (rle_enable),
        .sample_div         (sample_div),
        .trig_mask          (trig_mask),
        .trig_value         (trig_val),
        .trig_edge_rise     (trig_rise),
        .trig_edge_fall     (trig_fall),
        .pre_trigger_depth  (pre_depth),
        .post_trigger_depth (post_depth),
        .capture_active     (arm_cmd),
        .triggered_status   (trig_fired),
        .capture_complete   (capture_done)
    );

    // ------------------------------------------------------------------------
    // 7. Status LED Indicators
    // ------------------------------------------------------------------------
    assign led_power     = pll_locked;
    assign led_armed     = (trig_state == 2'b10); // Armed waiting
    assign led_triggered = trig_fired;
    assign led_usb_act   = usb_act_pulse;

endmodule
