// ============================================================================
// File: rle_compressor.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Real-time hardware Run-Length Encoding (RLE) stream compressor.
//              Compresses identical consecutive samples into 32-bit tokens,
//              multiplying effective BRAM and HyperRAM buffer depth by 10x-100x.
// ============================================================================

`timescale 1ns / 1ps

module rle_compressor #(
    parameter int CHANNELS = 16,
    parameter int COUNT_BITS = 15
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   enable,          // 1 = Active RLE compression, 0 = Bypass raw mode
    input  logic                   flush,           // Force emission of buffered run upon capture completion
    
    // Uncompressed input sample stream
    input  logic                   sample_valid,
    input  logic [CHANNELS-1:0]    sample_in,
    
    // Compressed output stream to FIFO / HyperRAM
    output logic                   out_valid,
    output logic [31:0]            out_data,        // [31]: is_rle, [30:16]: count, [15:0]: data
    input  logic                   out_ready        // Backpressure from memory/FIFO
);

    localparam logic [COUNT_BITS-1:0] MAX_COUNT = {COUNT_BITS{1'b1}}; // 32,767

    logic [CHANNELS-1:0]    current_sample;
    logic [COUNT_BITS-1:0]  run_count;
    logic                   has_pending;

    // Output holding register for handshake
    logic [31:0]            out_data_reg;
    logic                   out_valid_reg;

    assign out_data  = out_data_reg;
    assign out_valid = out_valid_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_sample <= '0;
            run_count      <= '0;
            has_pending    <= 1'b0;
            out_data_reg   <= '0;
            out_valid_reg  <= 1'b0;
        end else begin
            // Clear valid flag once accepted by downstream consumer
            if (out_ready && out_valid_reg) begin
                out_valid_reg <= 1'b0;
            end

            if (!enable) begin
                // Passthrough / Raw Mode
                if (sample_valid && (!out_valid_reg || out_ready)) begin
                    out_data_reg  <= {1'b0, 15'd1, sample_in};
                    out_valid_reg <= 1'b1;
                end
            end else begin
                // RLE Compression Mode
                if (sample_valid) begin
                    if (!has_pending) begin
                        // First sample initialization
                        current_sample <= sample_in;
                        run_count      <= {{(COUNT_BITS-1){1'b0}}, 1'b1};
                        has_pending    <= 1'b1;
                    end else if (sample_in == current_sample && run_count < MAX_COUNT) begin
                        // Repeated sample: increment run length
                        run_count <= run_count + {{(COUNT_BITS-1){1'b0}}, 1'b1};
                    end else begin
                        // Value transition or count saturation: emit compressed token
                        out_data_reg  <= {1'b1, run_count, current_sample};
                        out_valid_reg <= 1'b1;
                        
                        // Start new run with current incoming sample
                        current_sample <= sample_in;
                        run_count      <= {{(COUNT_BITS-1){1'b0}}, 1'b1};
                    end
                end else if (flush && has_pending && (!out_valid_reg || out_ready)) begin
                    // Flush lingering pending run when capture stops
                    out_data_reg   <= {1'b1, run_count, current_sample};
                    out_valid_reg  <= 1'b1;
                    has_pending    <= 1'b0;
                    run_count      <= '0;
                end
            end
        end
    end

endmodule
