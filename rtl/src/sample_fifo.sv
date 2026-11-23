// ============================================================================
// File: sample_fifo.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Parameterized Asynchronous Dual-Clock Domain Crossing (CDC) FIFO
//              utilizing Gray code pointer synchronizers and dual-port SRAM.
// ============================================================================

`timescale 1ns / 1ps

module sample_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 10  // 1024 deep buffer
)(
    // Write Domain (Capture Clock)
    input  logic                   wr_clk,
    input  logic                   wr_rst_n,
    input  logic                   wr_en,
    input  logic [DATA_WIDTH-1:0]  wr_data,
    output logic                   wr_full,
    output logic                   wr_almost_full,
    
    // Read Domain (System / USB Clock)
    input  logic                   rd_clk,
    input  logic                   rd_rst_n,
    input  logic                   rd_en,
    output logic [DATA_WIDTH-1:0]  rd_data,
    output logic                   rd_empty
);

    localparam int DEPTH = 1 << ADDR_WIDTH;

    // Memory array
    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Pointers in binary and Gray code
    logic [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_gray;
    logic [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_gray;

    // Synchronizer registers
    logic [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    logic [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

    // ------------------------------------------------------------------------
    // Write Clock Domain Logic
    // ------------------------------------------------------------------------
    logic [ADDR_WIDTH:0] wr_ptr_bin_next;
    logic [ADDR_WIDTH:0] wr_ptr_gray_next;

    assign wr_ptr_bin_next  = wr_ptr_bin + (wr_en && !wr_full);
    assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            if (wr_en && !wr_full) begin
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            end
        end
    end

    // Synchronize Read Gray Pointer into Write Domain
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= '0;
            rd_ptr_gray_sync2 <= '0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Full condition in Gray code: MSB and MSB-1 inverted, remaining bits equal
    assign wr_full = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], 
                                           rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    assign wr_almost_full = (wr_ptr_bin[ADDR_WIDTH-1:0] >= (DEPTH - 16));

    // ------------------------------------------------------------------------
    // Read Clock Domain Logic
    // ------------------------------------------------------------------------
    logic [ADDR_WIDTH:0] rd_ptr_bin_next;
    logic [ADDR_WIDTH:0] rd_ptr_gray_next;

    assign rd_ptr_bin_next  = rd_ptr_bin + (rd_en && !rd_empty);
    assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
            rd_data     <= '0;
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            if (rd_en && !rd_empty) begin
                rd_data <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            end
        end
    end

    // Synchronize Write Gray Pointer into Read Domain
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= '0;
            wr_ptr_gray_sync2 <= '0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Empty condition: Read pointer matches synchronized Write pointer
    assign rd_empty = (rd_ptr_gray == wr_ptr_gray_sync2);

endmodule
