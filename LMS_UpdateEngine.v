// =============================================================================
// LMS_UpdateEngine.v  –  LMS Weight Update Engine
// Project      : Adaptive Voice / Noise Cancellation
// Description  : Computes  w(n+1) = w(n) + mu * e(n) * x(n)
//                where mu = 2^(-MU_SHIFT)  (hardware-friendly shift)
// =============================================================================
`timescale 1ns / 1ps

module LMS_UpdateEngine #(
    parameter integer DATA_WIDTH = 16,
    parameter integer TAPS       = 32,
    parameter integer MU_SHIFT   = 8     // mu = 2^-8 = 0.00390625
)(
    // Clock & Reset
    input  wire                      clk,
    input  wire                      rst_n,

    // x(n) – current noise reference sample
    input  wire [DATA_WIDTH-1:0]     x_in,

    // e(n) – current error signal
    input  wire [DATA_WIDTH-1:0]     e_in,

    // Strobe: assert for one cycle when x_in & e_in are valid
    input  wire                      valid_in,

    // Updated weight output (single weight per cycle – pipeline stage)
    output reg  [DATA_WIDTH-1:0]     w_out,
    output reg                       w_valid
);

    // Internal weight storage
    reg signed [DATA_WIDTH-1:0] weights [0:TAPS-1];
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1)
                weights[i] <= {DATA_WIDTH{1'b0}};
            w_out   <= {DATA_WIDTH{1'b0}};
            w_valid <= 1'b0;
        end else if (valid_in) begin
            // Update all taps (simplified single-cycle; in real design pipeline this)
            for (i = 0; i < TAPS; i = i + 1)
                weights[i] <= weights[i] +
                    (($signed(e_in) * $signed(x_in)) >>> MU_SHIFT);

            w_out   <= weights[0];  // expose tap-0 for debug/monitoring
            w_valid <= 1'b1;
        end else begin
            w_valid <= 1'b0;
        end
    end

endmodule
