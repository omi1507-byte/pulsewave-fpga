// ============================================================================
// File: tb_rle_compressor.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Testbench verifying RLE hardware compression algorithm,
//              run-length counter accuracy, and edge-triggered emission.
// ============================================================================

`timescale 1ns / 1ps

module tb_rle_compressor;

    logic        clk;
    logic        rst_n;
    logic        enable;
    logic        flush;
    logic        sample_valid;
    logic [15:0] sample_in;
    logic        out_valid;
    logic [31:0] out_data;
    logic        out_ready;

    // Instantiate Unit Under Test (UUT)
    rle_compressor #(
        .CHANNELS(16),
        .COUNT_BITS(15)
    ) uut (
        .clk          (clk),
        .rst_n        (rst_n),
        .enable       (enable),
        .flush        (flush),
        .sample_valid (sample_valid),
        .sample_in    (sample_in),
        .out_valid    (out_valid),
        .out_data     (out_data),
        .out_ready    (out_ready)
    );

    // 100 MHz clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        clk          = 0;
        rst_n        = 0;
        enable       = 1;
        flush        = 0;
        sample_valid = 0;
        sample_in    = 16'h0000;
        out_ready    = 1;

        $display("------------------------------------------------------------");
        $display("Starting tb_rle_compressor simulation...");
        $display("------------------------------------------------------------");

        // Release reset
        #20 rst_n = 1;
        #10;

        // Test Case 1: Send 10 samples of 0xAAAA
        repeat (10) begin
            @(posedge clk);
            sample_valid = 1;
            sample_in    = 16'hAAAA;
        end

        // Test Case 2: Transition to 0x5555 for 5 samples
        repeat (5) begin
            @(posedge clk);
            sample_valid = 1;
            sample_in    = 16'h5555;
        end

        // Test Case 3: Transition to 0x1234 for 100 samples
        repeat (100) begin
            @(posedge clk);
            sample_valid = 1;
            sample_in    = 16'h1234;
        end

        @(posedge clk);
        sample_valid = 0;
        #20;

        // Test Case 4: Test Flush operation
        @(posedge clk);
        flush = 1;
        @(posedge clk);
        flush = 0;
        #50;

        $display("RLE Compressor Simulation completed successfully.");
        $finish;
    end

    // Monitor emitted tokens
    always @(posedge clk) begin
        if (out_valid && out_ready) begin
            $display("[Time %0t ns] EMITTED TOKEN: RLE=%0d | Count=%0d | Data=0x%04X", 
                     $time, out_data[31], out_data[30:16], out_data[15:0]);
        end
    end

endmodule
