// =============================================================================
// tb_LMS_Filter.v  —  Testbench for LMS_Filter + AVC_DataPath
// Vivado Simulation mein run karo
//
// SETUP:
//   1. noise_samples.hex  → C:/Users/HP/AVC_Project/sim_files/
//   2. voice_samples.hex  → C:/Users/HP/AVC_Project/sim_files/
//   3. Ye testbench Vivado simulation sources mein add karo
//   4. Run Simulation → Run Behavioral Simulation
//
// OUTPUT:
//   - Waveform mein x(n), d(n), e(n) signals dekh sakte ho
//   - output_samples.hex file mein cleaned audio save hoga
// =============================================================================
`timescale 1ns / 1ps

module tb_LMS_Filter;

    // ── Parameters ────────────────────────────────────────────────────────────
    parameter DATA_WIDTH   = 16;
    parameter FILTER_TAPS  = 32;
    parameter N_SAMPLES    = 1000;
    parameter CLK_PERIOD   = 10; // 100 MHz = 10ns

    // ── DUT Signals ───────────────────────────────────────────────────────────
    reg                      aclk;
    reg                      aresetn;

    // x(n) — noise reference
    reg  [DATA_WIDTH-1:0]    s_axis_x_tdata;
    reg                      s_axis_x_tvalid;
    wire                     s_axis_x_tready;

    // d(n) — noisy voice
    reg  [DATA_WIDTH-1:0]    s_axis_d_tdata;
    reg                      s_axis_d_tvalid;
    wire                     s_axis_d_tready;

    // e(n) — cleaned output
    wire [DATA_WIDTH-1:0]    m_axis_e_tdata;
    wire                     m_axis_e_tvalid;
    reg                      m_axis_e_tready;

    // ── Sample Storage ────────────────────────────────────────────────────────
    reg  [DATA_WIDTH-1:0]    noise_mem  [0:N_SAMPLES-1];
    reg  [DATA_WIDTH-1:0]    voice_mem  [0:N_SAMPLES-1];
    integer                  output_file;
    integer                  i;
    integer                  sample_count;
    integer                  out_count;

    // ── DUT Instantiation ─────────────────────────────────────────────────────
    LMS_Filter #(
        .FILTER_TAPS (FILTER_TAPS),
        .DATA_WIDTH  (DATA_WIDTH)
    ) dut (
        .aclk             (aclk),
        .aresetn          (aresetn),
        .s_axis_x_tdata   (s_axis_x_tdata),
        .s_axis_x_tvalid  (s_axis_x_tvalid),
        .s_axis_x_tready  (s_axis_x_tready),
        .s_axis_d_tdata   (s_axis_d_tdata),
        .s_axis_d_tvalid  (s_axis_d_tvalid),
        .s_axis_d_tready  (s_axis_d_tready),
        .m_axis_e_tdata   (m_axis_e_tdata),
        .m_axis_e_tvalid  (m_axis_e_tvalid),
        .m_axis_e_tready  (m_axis_e_tready)
    );

    // ── Clock Generation ──────────────────────────────────────────────────────
    initial aclk = 0;
    always #(CLK_PERIOD/2) aclk = ~aclk;

    // ── Main Test ─────────────────────────────────────────────────────────────
    initial begin
        // ── Load sample files ────────────────────────────────────────────────
        // PATH: apna path yahan daalo
        $readmemh("C:/Users/HP/AVC_Project/sim_files/noise_samples.hex", noise_mem);
        $readmemh("C:/Users/HP/AVC_Project/sim_files/voice_samples.hex", voice_mem);

        // ── Open output file ─────────────────────────────────────────────────
        output_file = $fopen("C:/Users/HP/AVC_Project/sim_files/output_samples.hex", "w");

        // ── Initialize ───────────────────────────────────────────────────────
        aresetn          = 0;
        s_axis_x_tvalid  = 0;
        s_axis_d_tvalid  = 0;
        m_axis_e_tready  = 1;
        s_axis_x_tdata   = 0;
        s_axis_d_tdata   = 0;
        sample_count     = 0;
        out_count        = 0;

        // ── Reset sequence ───────────────────────────────────────────────────
        repeat(10) @(posedge aclk);
        aresetn = 1;
        repeat(5)  @(posedge aclk);

        $display("=== AVC Simulation Start ===");
        $display("Feeding %0d samples to LMS Filter...", N_SAMPLES);

        // ── Feed samples one by one ──────────────────────────────────────────
        for (i = 0; i < N_SAMPLES; i = i + 1) begin
            @(posedge aclk);
            s_axis_x_tdata  = noise_mem[i];
            s_axis_d_tdata  = voice_mem[i];
            s_axis_x_tvalid = 1;
            s_axis_d_tvalid = 1;

            // Wait one cycle
            @(posedge aclk);
            s_axis_x_tvalid = 0;
            s_axis_d_tvalid = 0;

            // Capture output if valid
            @(posedge aclk);
            if (m_axis_e_tvalid) begin
                $fdisplay(output_file, "%04X", m_axis_e_tdata & 16'hFFFF);
                out_count = out_count + 1;
            end

            // Progress print every 100 samples
            if (i % 100 == 0)
                $display("Sample %0d/%0d processed | e(n) = %0d",
                          i, N_SAMPLES, $signed(m_axis_e_tdata));
        end

        // ── Wait for pipeline to flush ───────────────────────────────────────
        repeat(50) @(posedge aclk);

        $display("=== Simulation Complete ===");
        $display("Input samples  : %0d", N_SAMPLES);
        $display("Output samples : %0d", out_count);
        $display("Output saved to: output_samples.hex");

        $fclose(output_file);
        $finish;
    end

    // ── Waveform Dump (VCD) ───────────────────────────────────────────────────
    initial begin
        $dumpfile("C:/Users/HP/AVC_Project/sim_files/avc_sim.vcd");
        $dumpvars(0, tb_LMS_Filter);
    end

    // ── Timeout watchdog ──────────────────────────────────────────────────────
    initial begin
        #(N_SAMPLES * CLK_PERIOD * 10);
        $display("TIMEOUT! Simulation took too long.");
        $finish;
    end

endmodule
