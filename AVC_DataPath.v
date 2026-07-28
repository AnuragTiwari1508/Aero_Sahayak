// =============================================================================
// AVC_DataPath.v  –  Top-level RTL datapath connecting DMA streams to LMS
// Project      : Adaptive Voice / Noise Cancellation
// Description  : Wires AXI DMA MM2S outputs into LMS_Filter and routes
//                e(n) back to AXI DMA S2MM input.
//                Instantiate this module manually or use it as reference.
//
//  DMA Noise  MM2S ──► s_axis_x  ┐
//                                 ├─► LMS_Filter ─► m_axis_e ──► DMA Voice S2MM
//  DMA Voice  MM2S ──► s_axis_d  ┘
// =============================================================================
`timescale 1ns / 1ps

module AVC_DataPath #(
    parameter integer FILTER_TAPS = 32,
    parameter integer DATA_WIDTH  = 16
)(
    input  wire        aclk,
    input  wire        aresetn,

    // ── From DMA Noise MM2S  (x(n) reference noise) ─────────────────────────
    input  wire [31:0] s_axis_noise_tdata,    // 32-bit AXI-DMA word
    input  wire        s_axis_noise_tvalid,
    output wire        s_axis_noise_tready,
    input  wire        s_axis_noise_tlast,

    // ── From DMA Voice MM2S  (d(n) noisy voice) ─────────────────────────────
    input  wire [31:0] s_axis_voice_tdata,
    input  wire        s_axis_voice_tvalid,
    output wire        s_axis_voice_tready,
    input  wire        s_axis_voice_tlast,

    // ── To DMA Voice S2MM   (e(n) cleaned voice) ────────────────────────────
    output wire [31:0] m_axis_out_tdata,
    output wire        m_axis_out_tvalid,
    input  wire        m_axis_out_tready,
    output wire        m_axis_out_tlast
);

    // ── Extract 16-bit samples from 32-bit DMA words (lower 16 bits) ─────────
    wire [DATA_WIDTH-1:0] x_sample = s_axis_noise_tdata[DATA_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] d_sample = s_axis_voice_tdata[DATA_WIDTH-1:0];

    // ── LMS Filter output wires ───────────────────────────────────────────────
    wire [DATA_WIDTH-1:0] e_sample;
    wire                  e_valid;
    wire                  e_ready;

    // ── Instantiate LMS Filter ───────────────────────────────────────────────
    LMS_Filter #(
        .FILTER_TAPS (FILTER_TAPS),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_lms (
        .aclk             (aclk),
        .aresetn          (aresetn),
        // x(n)
        .s_axis_x_tdata   (x_sample),
        .s_axis_x_tvalid  (s_axis_noise_tvalid),
        .s_axis_x_tready  (s_axis_noise_tready),
        // d(n)
        .s_axis_d_tdata   (d_sample),
        .s_axis_d_tvalid  (s_axis_voice_tvalid),
        .s_axis_d_tready  (s_axis_voice_tready),
        // e(n)
        .m_axis_e_tdata   (e_sample),
        .m_axis_e_tvalid  (e_valid),
        .m_axis_e_tready  (e_ready)
    );

    // ── Pack 16-bit output back to 32-bit DMA word ───────────────────────────
    assign m_axis_out_tdata  = {{(32-DATA_WIDTH){e_sample[DATA_WIDTH-1]}}, e_sample}; // sign-extend
    assign m_axis_out_tvalid = e_valid;
    assign e_ready            = m_axis_out_tready;
    assign m_axis_out_tlast  = s_axis_voice_tlast;  // propagate packet boundary

endmodule
