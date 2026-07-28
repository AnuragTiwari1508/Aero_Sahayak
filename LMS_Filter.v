// =============================================================================
// LMS_Filter.v  –  Least Mean Squares Adaptive Filter
// Project      : Adaptive Voice / Noise Cancellation
// Board        : PYNQ-Z2 (xc7z020clg400-1)
// Author       : AVC Project
// Description  : 32-tap LMS adaptive filter with AXI-Stream I/O.
//                x(n) = noise reference,  d(n) = noisy voice
//                y(n) = filter output (noise estimate)
//                e(n) = d(n) - y(n) = cleaned voice  ← FPGA output
// Interface    : Pure AXI-Stream (compatible with AXI DMA MM2S/S2MM)
// =============================================================================
`timescale 1ns / 1ps

module LMS_Filter #(
    parameter integer FILTER_TAPS  = 32,    // Number of filter taps
    parameter integer DATA_WIDTH   = 16,    // Input/output sample width (bits)
    parameter integer COEFF_WIDTH  = 24,    // Internal coefficient width
    parameter integer MU_SHIFT     = 8      // Step size mu = 2^(-MU_SHIFT)
)(
    // Clock & Reset (active-low, AXI convention)
    input  wire                      aclk,
    input  wire                      aresetn,

    // ── AXI-Stream SLAVE: x(n) noise reference ─────────────────────────────
    input  wire [DATA_WIDTH-1:0]     s_axis_x_tdata,
    input  wire                      s_axis_x_tvalid,
    output wire                      s_axis_x_tready,

    // ── AXI-Stream SLAVE: d(n) noisy voice ──────────────────────────────────
    input  wire [DATA_WIDTH-1:0]     s_axis_d_tdata,
    input  wire                      s_axis_d_tvalid,
    output wire                      s_axis_d_tready,

    // ── AXI-Stream MASTER: e(n) error = cleaned voice ───────────────────────
    output reg  [DATA_WIDTH-1:0]     m_axis_e_tdata,
    output reg                       m_axis_e_tvalid,
    input  wire                      m_axis_e_tready
);

    // ── Internal Registers ───────────────────────────────────────────────────
    reg signed [COEFF_WIDTH-1:0]         w      [0:FILTER_TAPS-1];  // weights
    reg signed [DATA_WIDTH-1:0]          x_buf  [0:FILTER_TAPS-1];  // input buffer
    reg signed [DATA_WIDTH+COEFF_WIDTH:0] accum;                     // accumulator
    reg signed [DATA_WIDTH-1:0]          y_n;                        // filter output
    reg signed [DATA_WIDTH-1:0]          e_n;                        // error signal

    integer i;

    // Always ready to receive (back-pressure not implemented in stub)
    assign s_axis_x_tready = 1'b1;
    assign s_axis_d_tready = 1'b1;

    // ── Main LMS Algorithm ───────────────────────────────────────────────────
    always @(posedge aclk) begin
        if (!aresetn) begin
            // Reset all weights and buffer
            for (i = 0; i < FILTER_TAPS; i = i + 1) begin
                w[i]     <= {COEFF_WIDTH{1'b0}};
                x_buf[i] <= {DATA_WIDTH{1'b0}};
            end
            m_axis_e_tdata  <= {DATA_WIDTH{1'b0}};
            m_axis_e_tvalid <= 1'b0;
            accum           <= 0;
            y_n             <= 0;
            e_n             <= 0;

        end else if (s_axis_x_tvalid && s_axis_d_tvalid) begin

            // ── Step 1: Shift input buffer ──────────────────────────────────
            for (i = FILTER_TAPS-1; i > 0; i = i - 1)
                x_buf[i] <= x_buf[i-1];
            x_buf[0] <= $signed(s_axis_x_tdata);

            // ── Step 2: FIR filter  y(n) = Σ w_i · x(n-i) ─────────────────
            accum = 0;
            for (i = 0; i < FILTER_TAPS; i = i + 1)
                accum = accum + ($signed(w[i]) * $signed(x_buf[i]));

            // Saturate / truncate to DATA_WIDTH
            y_n = accum >>> (COEFF_WIDTH - DATA_WIDTH);

            // ── Step 3: Error  e(n) = d(n) - y(n) ──────────────────────────
            e_n = $signed(s_axis_d_tdata) - y_n;

            // ── Step 4: LMS weight update  w(n+1) = w(n) + μ·e(n)·x(n-i) ──
            for (i = 0; i < FILTER_TAPS; i = i + 1)
                w[i] <= w[i] + (($signed(e_n) * $signed(x_buf[i])) >>> MU_SHIFT);

            // ── Step 5: Output ───────────────────────────────────────────────
            m_axis_e_tdata  <= e_n;
            m_axis_e_tvalid <= 1'b1;

        end else begin
            m_axis_e_tvalid <= 1'b0;
        end
    end

endmodule
