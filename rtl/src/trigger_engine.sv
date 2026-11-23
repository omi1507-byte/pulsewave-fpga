// ============================================================================
// File: trigger_engine.sv
// Project: PulseWave-FPGA High-Speed Logic Analyzer
// Description: Multi-stage, multi-condition configurable trigger engine.
//              Supports edge detection, bitwise mask/value matching,
//              sequenced states, and pre/post-trigger ring buffer counters.
// ============================================================================

`timescale 1ns / 1ps

module trigger_engine #(
    parameter int CHANNELS = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    
    // Control and configuration registers
    input  logic                   arm,                 // Arm trigger system
    input  logic                   force_trigger,       // Host forced trigger
    input  logic [CHANNELS-1:0]    trig_mask,           // Active bitmask for pattern matching
    input  logic [CHANNELS-1:0]    trig_value,          // Target logic values
    input  logic [CHANNELS-1:0]    trig_edge_rise,      // Channel bitmask for rising-edge detection
    input  logic [CHANNELS-1:0]    trig_edge_fall,      // Channel bitmask for falling-edge detection
    input  logic [31:0]            pre_trigger_depth,   // Samples required before trigger fires
    input  logic [31:0]            post_trigger_depth,  // Samples to capture after trigger fires
    
    // Incoming sample stream
    input  logic                   sample_valid,
    input  logic [CHANNELS-1:0]    sample_in,
    
    // Status and capture control outputs
    output logic                   triggered,           // Pulse / flag indicating trigger event
    output logic                   capture_complete,    // High when post-trigger buffer fills
    output logic [1:0]             state_out            // Current trigger state machine
);

    typedef enum logic [1:0] {
        ST_IDLE      = 2'b00,
        ST_FILL_PRE  = 2'b01,  // Filling mandatory pre-trigger ring buffer
        ST_ARMED     = 2'b10,  // Evaluating trigger conditions
        ST_TRIGGERED = 2'b11   // Trigger matched, recording post-trigger samples
    } trig_fsm_t;

    trig_fsm_t state;
    assign state_out = state;

    logic [CHANNELS-1:0] prev_sample;
    logic [31:0] pre_count;
    logic [31:0] post_count;

    // Edge detection generation
    logic [CHANNELS-1:0] rising_edges;
    logic [CHANNELS-1:0] falling_edges;

    assign rising_edges  = (~prev_sample) & sample_in;
    assign falling_edges = prev_sample & (~sample_in);

    // Condition matching evaluation
    logic pattern_matched;
    logic edge_matched;
    logic condition_met;

    // Pattern match: check unmasked bits against target values
    assign pattern_matched = ((sample_in & trig_mask) == (trig_value & trig_mask));

    // Edge match: true if no edge triggers are enabled, OR if enabled edge occurred
    assign edge_matched = ((trig_edge_rise == '0) && (trig_edge_fall == '0)) ||
                          (|(rising_edges & trig_edge_rise)) ||
                          (|(falling_edges & trig_edge_fall));

    assign condition_met = pattern_matched && edge_matched;

    // ------------------------------------------------------------------------
    // Trigger State Machine
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= ST_IDLE;
            triggered        <= 1'b0;
            capture_complete <= 1'b0;
            pre_count        <= 32'd0;
            post_count       <= 32'd0;
            prev_sample      <= '0;
        end else begin
            if (sample_valid) begin
                prev_sample <= sample_in;
            end

            case (state)
                ST_IDLE: begin
                    triggered        <= 1'b0;
                    capture_complete <= 1'b0;
                    pre_count        <= 32'd0;
                    post_count       <= 32'd0;
                    if (arm) begin
                        state <= (pre_trigger_depth > 0) ? ST_FILL_PRE : ST_ARMED;
                    end
                end

                ST_FILL_PRE: begin
                    if (!arm) begin
                        state <= ST_IDLE;
                    end else if (sample_valid) begin
                        pre_count <= pre_count + 32'd1;
                        if (pre_count >= pre_trigger_depth) begin
                            state <= ST_ARMED;
                        end
                    end
                end

                ST_ARMED: begin
                    if (!arm) begin
                        state <= ST_IDLE;
                    end else if (force_trigger || (sample_valid && condition_met)) begin
                        state     <= ST_TRIGGERED;
                        triggered <= 1'b1;
                    end
                end

                ST_TRIGGERED: begin
                    if (!arm) begin
                        state <= ST_IDLE;
                    end else if (sample_valid) begin
                        post_count <= post_count + 32'd1;
                        if (post_count >= post_trigger_depth) begin
                            capture_complete <= 1'b1;
                            state            <= ST_IDLE;
                        end
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
