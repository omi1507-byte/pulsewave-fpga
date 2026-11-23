// ============================================================================
// File: tb_pulsewave_top.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Top-Level Integration Testbench simulating host configuration,
//              SPI bus transaction capture, and USB streaming readout.
// ============================================================================

`timescale 1ns / 1ps

module tb_pulsewave_top;

    logic        clk_25m;
    logic        rst_n_pin;
    logic [15:0] probe_pins;
    logic        ft_clk60;
    logic        ft_rxf_n;
    logic        ft_txe_n;
    logic        ft_rd_n;
    logic        ft_wr_n;
    logic        ft_oe_n;
    wire  [7:0]  ft_data;

    logic        led_power;
    logic        led_armed;
    logic        led_triggered;
    logic        led_usb_act;

    // DUT instantiation
    pulsewave_top #(
        .CHANNELS(16)
    ) dut (
        .clk_25m       (clk_25m),
        .rst_n_pin     (rst_n_pin),
        .probe_pins    (probe_pins),
        .ft_clk60      (ft_clk60),
        .ft_rxf_n      (ft_rxf_n),
        .ft_txe_n      (ft_txe_n),
        .ft_rd_n       (ft_rd_n),
        .ft_wr_n       (ft_wr_n),
        .ft_oe_n       (ft_oe_n),
        .ft_data       (ft_data),
        .led_power     (led_power),
        .led_armed     (led_armed),
        .led_triggered (led_triggered),
        .led_usb_act   (led_usb_act)
    );

    // Clocks
    always #20 clk_25m  = ~clk_25m;   // 25 MHz (40ns period)
    always #8.33 ft_clk60 = ~ft_clk60; // 60 MHz (16.67ns period)

    initial begin
        clk_25m    = 0;
        ft_clk60   = 0;
        rst_n_pin  = 0;
        probe_pins = 16'h0000;
        ft_rxf_n   = 1;
        ft_txe_n   = 0; // Host ready to accept samples

        $display("------------------------------------------------------------");
        $display("PulseWave-FPGA Top-Level Verification Starting...");
        $display("------------------------------------------------------------");

        #100 rst_n_pin = 1;
        #100;

        // Simulate SPI bus activity on probes:
        // Ch0 = SCK, Ch1 = MOSI, Ch2 = MISO, Ch3 = CS#
        probe_pins[3] = 1'b1; // CS high
        #50;
        probe_pins[3] = 1'b0; // CS low (Select)

        repeat (8) begin
            probe_pins[0] = 1'b0; // SCK low
            probe_pins[1] = $random;
            #40;
            probe_pins[0] = 1'b1; // SCK high
            #40;
        end

        probe_pins[3] = 1'b1; // CS high
        #200;

        $display("Top-Level testbench completed successfully.");
        $finish;
    end

endmodule
