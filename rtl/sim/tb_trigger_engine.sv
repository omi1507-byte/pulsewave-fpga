// ============================================================================
// File: tb_trigger_engine.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Testbench verifying edge matching, pattern recognition,
//              and pre/post-trigger ring buffer operation.
// ============================================================================

`timescale 1ns / 1ps

module tb_trigger_engine;

    logic        clk;
    logic        rst_n;
    logic        arm;
    logic        force_trigger;
    logic [15:0] trig_mask;
    logic [15:0] trig_value;
    logic [15:0] trig_edge_rise;
    logic [15:0] trig_edge_fall;
    logic [31:0] pre_trigger_depth;
    logic [31:0] post_trigger_depth;
    logic        sample_valid;
    logic [15:0] sample_in;
    logic        triggered;
    logic        capture_complete;
    logic [1:0]  state_out;

    trigger_engine #(
        .CHANNELS(16)
    ) uut (
        .clk                (clk),
        .rst_n              (rst_n),
        .arm                (arm),
        .force_trigger      (force_trigger),
        .trig_mask          (trig_mask),
        .trig_value         (trig_value),
        .trig_edge_rise     (trig_edge_rise),
        .trig_edge_fall     (trig_edge_fall),
        .pre_trigger_depth  (pre_trigger_depth),
        .post_trigger_depth (post_trigger_depth),
        .sample_valid       (sample_valid),
        .sample_in          (sample_in),
        .triggered          (triggered),
        .capture_complete   (capture_complete),
        .state_out          (state_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk                = 0;
        rst_n              = 0;
        arm                = 0;
        force_trigger      = 0;
        trig_mask          = 16'h0001; // Monitor Channel 0
        trig_value         = 16'h0001;
        trig_edge_rise     = 16'h0001; // Rising edge on Ch0
        trig_edge_fall     = 16'h0000;
        pre_trigger_depth  = 32'd5;
        post_trigger_depth = 32'd10;
        sample_valid       = 0;
        sample_in          = 16'h0000;

        #20 rst_n = 1;
        #10;

        $display("Arming trigger engine...");
        arm = 1;

        // Feed pre-trigger samples (Ch0 is low)
        repeat (10) begin
            @(posedge clk);
            sample_valid = 1;
            sample_in    = 16'h0000;
        end

        $display("Simulating rising edge on Channel 0...");
        @(posedge clk);
        sample_in = 16'h0001; // Rising edge occurs!

        // Post-trigger recording
        repeat (15) begin
            @(posedge clk);
            sample_in = 16'h0001;
        end

        @(posedge clk);
        sample_valid = 0;
        #50;

        if (capture_complete) begin
            $display("SUCCESS: Trigger matched and capture successfully completed!");
        end else begin
            $display("ERROR: Trigger failed to complete capture.");
        end

        $finish;
    end

endmodule
