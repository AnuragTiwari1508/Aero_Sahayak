# FPGA-Based Real-Time Adaptive Voice & Acoustic Noise Cancellation System

This project implements an Adaptive Voice / Noise Cancellation pipeline on the **PYNQ-Z2** development board (Xilinx Zynq-7020), targeting cockpit/cabin acoustic environments where a clean voice signal must be recovered from a noisy mixture in real time.

## 🚀 Project Overview

- **Board**: PYNQ-Z2 (Xilinx Zynq-7020, xc7z020clg400-1)
- **Tool**: Vivado 2025.1
- **Status**: Hardware implementation complete (timing closed). PYNQ-Z2 hardware bring-up in progress.

## 🧠 System Architecture

The overall acoustic-attenuation system is designed around two parallel processing pipelines that share the same front-end frequency-domain mixing (FDM) stage:

### 1. Communication Pipeline (Implemented)
- **Stage 1 (FDM)**: Frequency-domain mixing / decomposition of the incoming noisy audio.
- **Stage 2 (LMS Adaptive Filtering)**: A custom 32-tap `LMS_Filter` RTL IP adaptively estimates the noise component from a reference signal and subtracts it from the noisy voice: `e(n) = d(n) - y(n)`.
- **Stage 3 (Matched-Wavelet Denoising)**: Per-scale wavelet attenuation applied to the LMS output to further suppress residual broadband noise.

### 2. ANC Pipeline (Planned Next Phase)
- **Stage 1 (FDM)**: Shared frequency-domain front-end.
- **Stage 2 (FxLMS Controller)**: Filtered-x LMS controller for active noise control.
- **Stage 3 (Secondary-Path Compensation)**: Compensates for the acoustic secondary path between the cancelling speaker and the error microphone.

## 📊 Python Golden Model Analysis

Before RTL design, the signal-processing algorithm was validated in Python using NumPy/SciPy/librosa. The optimal step size ($\mu$) for the LMS filter was determined through a $\mu$-sweep for fastest convergence and lowest steady-state error.

![Python Analysis Dashboard](docs/images/python_analysis.png)
*(Screenshot of the Python analysis dashboard showing NLMS convergence and spectrograms)*

## 🛠️ Hardware Design (RTL Modules)

The validated algorithm was translated into synthesizable Verilog RTL. Core modules include:

| Module | Description |
|--------|-------------|
| **LMS_Filter** | 32-tap AXI4-Stream LMS adaptive filter. Packaged as reusable IP (`cognicity.in:user:LMS_Filter:1.0`). |
| **LMS_UpdateEngine** | Weight-update engine implementing $w(n+1) = w(n) + \mu \cdot e(n) \cdot x(n)$. Uses a hardware-friendly shift instead of a multiplier. |
| **ErrorCalc** | Standalone registered subtractor computing $e(n) = d(n) - y(n)$. |
| **db_calculator** | Converts linear magnitude to dB for level/peak reporting. |
| **peak_detector** | Detects the peak amplitude / frequency bin from the magnitude stream. |

## 🧩 Vivado Block Design & IP Integration

The top-level `design_1` integrates the custom AXI4-Stream IP with the ZYNQ7 Processing System, AXI DMA engines (for streaming noise/voice samples from DDR), and AXI SmartConnect fabric.

![Vivado Block Design](docs/images/vivado_block_design.png)
*(Complete `design_1` block design in Vivado IP Integrator)*

## 📈 Verification & Simulation

The custom datapath was verified through behavioral and post-synthesis functional simulations, running for 1000ns with identical stimulus (noise/voice sample arrays) confirming functional equivalence.

![Behavioral Simulation](docs/images/behavioral_simulation.png)
*(Behavioral simulation of `tb_LMS_Filter` showing AXI-Stream valid/ready handshaking)*

## 🚀 Implementation Results

Implementation (Opt $\rightarrow$ Place $\rightarrow$ Route $\rightarrow$ Bitstream) completed successfully with positive slack.

- **Total On-Chip Power**: 1.912 W
- **Worst Negative Slack (WNS)**: 2.696 ns
- **Worst Hold Slack (WHS)**: 0.020 ns
- **Worst Pulse-Width Slack (WPWS)**: 3.000 ns

## 📂 Repository Structure

```text
AVC_Project/
├── AdaptiveVoiceCancellation.xpr   # Vivado project file (top-level)
├── AdaptiveVoiceCancellation.srcs/ # HDL sources, constraints, sim sources
├── AdaptiveVoiceCancellation.gen/  # Generated outputs (BD wrapper, netlists, .hwh)
├── AdaptiveVoiceCancellation.runs/ # Synthesis & Implementation run directories
├── ip_repo/                        # Custom packaged IPs (LMS_Filter, ErrorCalc)
├── PYNQ_FILES/                     # design_1.bit + design_1.hwh for board deployment
├── pynq_avc_runtime.py             # Python/Jupyter runtime for PYNQ-Z2 overlay
├── *.tcl                           # TCL automation scripts for build and simulation
└── *.wav / *.coe / *.hex           # Test audio vectors and memory init files
```

## 📋 Planned Next Steps

1. Complete on-board PYNQ-Z2 validation by streaming real recorded cockpit-style noisy audio through the DMA $\rightarrow$ LMS_Filter $\rightarrow$ DMA path.
2. Resolve high-severity timing-check warnings by adding proper I/O timing constraints to `pynq_z2_final.xdc`.
3. Begin RTL design of the ANC pipeline (FxLMS controller).
4. Integrate the matched-wavelet denoising stage into the FPGA datapath or evaluate a hybrid ARM+FPGA split.
