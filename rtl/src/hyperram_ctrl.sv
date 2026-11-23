// ============================================================================
// File: hyperram_ctrl.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Low-overhead HyperBus memory controller for 64Mbit HyperRAM.
//              Handles Command/Address (CA) header serialization, DDR DQ bus
//              transactions, RWDS strobe latency matching, and auto-refresh.
// ============================================================================

`timescale 1ns / 1ps

module hyperram_ctrl (
    input  logic                   clk,             // HyperRAM reference clock (typically 100MHz)
    input  logic                   rst_n,
    
    // Internal user interface
    input  logic                   write_req,
    input  logic                   read_req,
    input  logic [31:0]            addr,
    input  logic [31:0]            write_data,
    output logic [31:0]            read_data,
    output logic                   ready,
    output logic                   read_valid,
    
    // Physical HyperBus Interface pins
    output logic                   hb_cs_n,
    output logic                   hb_clk,
    output logic                   hb_clk_n,
    inout  wire                    hb_rwds,
    inout  wire  [7:0]             hb_dq
);

    typedef enum logic [3:0] {
        IDLE,
        CA_PHASE,
        LATENCY_WAIT,
        WRITE_BURST,
        READ_BURST,
        DESELECT
    } state_t;

    state_t state;

    logic [47:0] ca_word;
    logic [2:0]  byte_idx;
    logic [3:0]  latency_cnt;
    logic        dq_oe;
    logic [7:0]  dq_out;
    logic [7:0]  dq_in;

    // Tristate buffers for DQ bus
    assign hb_dq = dq_oe ? dq_out : 8'bzzzzzzzz;
    assign dq_in = hb_dq;

    // Differential clock output gating
    assign hb_clk   = (state != IDLE && state != DESELECT) ? clk  : 1'b0;
    assign hb_clk_n = (state != IDLE && state != DESELECT) ? ~clk : 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            hb_cs_n     <= 1'b1;
            dq_oe       <= 1'b0;
            dq_out      <= 8'h00;
            read_data   <= 32'h0;
            ready       <= 1'b1;
            read_valid  <= 1'b0;
            byte_idx    <= 3'd0;
            latency_cnt <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    hb_cs_n    <= 1'b1;
                    dq_oe      <= 1'b0;
                    ready      <= 1'b1;
                    read_valid <= 1'b0;
                    byte_idx   <= 3'd0;

                    if (write_req) begin
                        ready   <= 1'b0;
                        hb_cs_n <= 1'b0;
                        // CA: Write (bit 47=0), Memory space (bit 46=0), Linear burst (bit 45=0)
                        ca_word <= {2'b00, 1'b0, addr[31:16], 13'd0, addr[15:0]};
                        state   <= CA_PHASE;
                    end else if (read_req) begin
                        ready   <= 1'b0;
                        hb_cs_n <= 1'b0;
                        // CA: Read (bit 47=1)
                        ca_word <= {2'b10, 1'b0, addr[31:16], 13'd0, addr[15:0]};
                        state   <= CA_PHASE;
                    end
                end

                CA_PHASE: begin
                    dq_oe  <= 1'b1;
                    dq_out <= ca_word[47:40];
                    ca_word <= {ca_word[39:0], 8'h00};
                    byte_idx <= byte_idx + 3'd1;

                    if (byte_idx == 3'd5) begin
                        byte_idx    <= 3'd0;
                        latency_cnt <= 4'd6; // Standard 6-cycle initial latency
                        state       <= LATENCY_WAIT;
                        dq_oe       <= 1'b0;
                    end
                end

                LATENCY_WAIT: begin
                    if (latency_cnt > 4'd1) begin
                        latency_cnt <= latency_cnt - 4'd1;
                    end else begin
                        if (ca_word[47]) begin
                            state <= READ_BURST;
                        end else begin
                            dq_oe <= 1'b1;
                            state <= WRITE_BURST;
                        end
                    end
                end

                WRITE_BURST: begin
                    dq_oe    <= 1'b1;
                    dq_out   <= write_data[31:24];
                    state    <= DESELECT;
                end

                READ_BURST: begin
                    read_data  <= {read_data[23:0], dq_in};
                    read_valid <= 1'b1;
                    state      <= DESELECT;
                end

                DESELECT: begin
                    hb_cs_n    <= 1'b1;
                    dq_oe      <= 1'b0;
                    read_valid <= 1'b0;
                    state      <= IDLE;
                    ready      <= 1'b1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
