// =============================================================================
// ErrorCalc.v  –  Error / Difference Calculator
// Project      : Adaptive Voice / Noise Cancellation
// Description  : Computes e(n) = d(n) - y(n) with registered output.
//                Standalone module for use in RTL-only datapath.
// =============================================================================
`timescale 1ns / 1ps

module ErrorCalc #(
    parameter integer DATA_WIDTH = 16
)(
    // Clock & Reset
    input  wire                      clk,
    input  wire                      rst_n,    // active-low reset

    // d(n) – noisy voice (desired signal)
    input  wire [DATA_WIDTH-1:0]     d_in,
    input  wire                      d_valid,

    // y(n) – filter output (noise estimate)
    input  wire [DATA_WIDTH-1:0]     y_in,
    input  wire                      y_valid,

    // e(n) = d(n) - y(n)
    output reg  [DATA_WIDTH-1:0]     e_out,
    output reg                       e_valid
);

    always @(posedge clk) begin
        if (!rst_n) begin
            e_out   <= {DATA_WIDTH{1'b0}};
            e_valid <= 1'b0;
        end else if (d_valid && y_valid) begin
            e_out   <= $signed(d_in) - $signed(y_in);
            e_valid <= 1'b1;
        end else begin
            e_valid <= 1'b0;
        end
    end

endmodule
