<p align="center">
  <img src="https://img.shields.io/badge/FPGA-Xilinx%20Zynq--7020-blue?style=for-the-badge&logo=xilinx" alt="FPGA">
  <img src="https://img.shields.io/badge/Board-PYNQ--Z2-orange?style=for-the-badge" alt="Board">
  <img src="https://img.shields.io/badge/Tool-Vivado%202025.1-purple?style=for-the-badge" alt="Vivado">
  <img src="https://img.shields.io/badge/Status-Implementation%20Complete-brightgreen?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/Scheme-C2S%20(MeitY)-red?style=for-the-badge" alt="C2S">
</p>

# ✈️ Aero Sahayak — FPGA-Based Real-Time Adaptive Voice & Acoustic Noise Cancellation

> **Research Project** — VLSI Lab, IET DAVV Indore | **Cognicity Startup** | For **HAL (Hindustan Aeronautics Limited)** under the **C2S (Chips to Startup) Scheme**, MeitY, Govt. of India

An FPGA-accelerated, real-time adaptive noise cancellation system for cockpit/cabin acoustic environments. The system recovers clean voice from a noisy mixture using a custom **LMS Adaptive Filter** IP core on the **PYNQ-Z2** (Xilinx Zynq-7020) SoC, followed by **Matched-Wavelet Denoising** for residual noise suppression.

---

## 👨‍💻 Author

| | |
|---|---|
| **Name** | Anurag Tiwari |
| **GitHub** | [@AnuragTiwari1508](https://github.com/AnuragTiwari1508) |
| **Email** | [anuragtiwari1508@gmail.com](mailto:anuragtiwari1508@gmail.com) |
| **Institution** | IET DAVV, Indore |
| **Lab** | VLSI Lab |
| **Startup** | Cognicity |

---

## 🚀 Project Overview

| Parameter | Value |
|-----------|-------|
| **Target Board** | PYNQ-Z2 (Xilinx Zynq-7020, xc7z020clg400-1) |
| **EDA Tool** | AMD Vivado 2025.1 |
| **Algorithm** | NLMS Adaptive Filter + Matched-Wavelet Denoising |
| **Filter Taps** | 32-tap FIR (AXI4-Stream) |
| **Step Size (μ)** | 0.050 (optimized via μ-sweep) |
| **Total Attenuation** | 14.3 dB (NLMS) + Wavelet per-scale cleanup |
| **On-Chip Power** | 1.912 W |
| **Timing (WNS)** | 2.696 ns (positive slack ✅) |

---

## 🧠 System Architecture

The overall acoustic-attenuation system is designed around two parallel processing pipelines:

### Pipeline 1: Communication (Voice Recovery) — ✅ Implemented
```
Noisy Audio ──► FDM (Freq. Domain Mixing) ──► LMS Adaptive Filter ──► Wavelet Denoising ──► Clean Voice
                                                  ▲
                                            Noise Reference
```
- **Stage 1 — FDM**: Frequency-domain mixing / decomposition of the incoming noisy audio
- **Stage 2 — LMS Adaptive Filtering**: Custom 32-tap `LMS_Filter` RTL IP adaptively estimates the noise and subtracts it: `e(n) = d(n) - y(n)`
- **Stage 3 — Matched-Wavelet Denoising**: Per-scale wavelet attenuation on the LMS output for residual broadband noise suppression

### Pipeline 2: ANC (Active Noise Control) — 🔜 Planned
- **Stage 2 — FxLMS Controller**: Filtered-x LMS for active cancellation
- **Stage 3 — Secondary-Path Compensation**: Acoustic secondary path modeling

---

## 📊 Python Golden-Model & Signal Analysis

Before RTL design, the algorithm was validated in Python (NumPy / SciPy / librosa). The optimal step size (μ = 0.050) was determined through a μ-sweep for fastest convergence and lowest steady-state error.

### Full Analysis Dashboard
> FPGA-Centric Airborne ANC with Real Audio — NLMS convergence, spectrograms, μ-sweep, wavelet attenuation, and full pipeline overlay

![Full Analysis Dashboard](./public/Screenshot_2026-07-18_124333.png)

### Wavelet Denoising Results
> Matched-Wavelet Denoising (Lifting Scheme) — Before vs. After waveforms, final output spectrogram, and per-scale attenuation (D1: 31.1 dB, D2: 34.8 dB, D3: 27.5 dB, D4: 24.2 dB)

![Wavelet Denoising Stage](./public/Screenshot_2026-07-17_142618.png)

### Full Pipeline Summary — Real Audio
> Total Attenuation: 1.9 dB across 5 LMS loops + Wavelet, with attenuation-per-loop and μ decay curves

![Full Pipeline Summary](./public/Screenshot_2026-07-18_120755.png)

---

## 🛠️ Hardware Design — RTL Modules

The validated algorithm was translated into synthesizable Verilog RTL:

| Module | File | Description |
|--------|------|-------------|
| **LMS_Filter** | `LMS_Filter.v` | 32-tap AXI4-Stream LMS adaptive filter. Packaged as reusable IP (`cognicity.in:user:LMS_Filter:1.0`) |
| **LMS_UpdateEngine** | `LMS_UpdateEngine.v` | Weight-update engine: `w(n+1) = w(n) + μ·e(n)·x(n)`. Uses hardware-friendly shift instead of multiplier |
| **ErrorCalc** | `ErrorCalc.v` | Registered subtractor: `e(n) = d(n) - y(n)` |
| **AVC_DataPath** | `AVC_DataPath.v` | Top-level datapath connecting filter, update engine, and error calculator |
| **db_calculator** | `db_calculator.v` | Linear magnitude → dB conversion for level/peak reporting |
| **peak_detector** | `peak_detector.v` | Peak amplitude / frequency bin detector |
| **magnitude_calculator** | `magnitude_calculator.v` | Magnitude computation from complex samples |
| **sample_controller** | `sample_controller.v` | Sample sequencing and flow control |

---

## 🧩 Vivado Block Design & IP Integration

The top-level `design_1` integrates the custom AXI4-Stream IP with the ZYNQ7 Processing System, AXI DMA engines (noise/voice streaming from DDR), AXI SmartConnect fabric, BRAMs, GPIO, and interrupt controller.

### Block Design (IP Integrator)
![Block Design - Full View](./public/Screenshot_2026-07-14_160401.png)

### Block Design (Source Hierarchy + Clock Domain)
![Block Design - Source Hierarchy](./public/Screenshot_2026-07-17_143131.png)

---

## 📈 Verification & Simulation

### Behavioral Simulation — `tb_LMS_Filter`
> XSim behavioral simulation (1000 ns) showing AXI-Stream valid/ready handshaking, noise/voice sample streaming, and error output convergence

![Behavioral Simulation](./public/Screenshot_2026-07-14_160510.png)

### Post-Synthesis Functional Simulation
> Post-synthesis simulation confirming functional equivalence with behavioral results (gain = 2240.895)

![Post-Synthesis Simulation](./public/Screenshot_2026-07-14_160702.png)

### PCPI Co-Processor Interface Simulation
> Detailed waveform of the PCPI (Pico Co-Processor Interface) showing instruction decode, memory read/write, and test execution

![PCPI Simulation](./public/Screenshot_2026-06-25_144536.png)

---

## 🚀 Implementation Results

Implementation (Optimize → Place → Route → Bitstream) completed successfully with **positive slack** on all timing paths.

### Timing Summary & Device Floorplan
> WNS: 2.696 ns | WHS: 0.020 ns | WPWS: 3.000 ns — All timing constraints met ✅

![Timing Summary](./public/Screenshot_2026-07-15_160251.png)

### Source Hierarchy & Check Timing
> Design sources (10 modules), timing check report with no_input_delay / no_output_delay warnings

![Check Timing](./public/Screenshot_2026-07-15_160513.png)

### Synthesis & Implementation Reports
> Utilization reports, synthesis reports for all out-of-context modules

![Reports](./public/Screenshot_2026-07-15_160532.png)

### Power Analysis — Summary
> Total On-Chip Power: **1.912 W** | Dynamic: 1.767 W (92%) | PS7: 1.535 W (85%) | Junction Temp: 47.1°C

![Power Summary](./public/Screenshot_2026-07-15_160650.png)

### Power Analysis — Hierarchical Breakdown
> Hierarchical power distribution across design_1_wrapper, design_1_i, leaf cells, and GPIO IOBUFs

![Power Hierarchical](./public/Screenshot_2026-07-15_172433.png)

### Schematic View — I/O Ports & Nets
> Post-implementation schematic: 17 Cells, 146 I/O Ports, 178 Nets

![Schematic View](./public/Screenshot_2026-07-15_160708.png)

### Power Report Configuration
> Report Power dialog — Environment settings, thermal analysis configuration

![Power Report Config](./public/Screenshot_2026-07-15_160721.png)

---

## 📂 Repository Structure

```
AVC_Project/
├── AdaptiveVoiceCancellation.xpr       # Vivado project file (top-level)
├── AdaptiveVoiceCancellation.srcs/     # HDL sources, constraints, simulation sources
├── AdaptiveVoiceCancellation.gen/      # Generated outputs (BD wrapper, netlists, .hwh)
├── AdaptiveVoiceCancellation.runs/     # Synthesis & Implementation run directories
├── AdaptiveVoiceCancellation.sim/      # Simulation output directories
├── AdaptiveVoiceCancellation.ip_user_files/ # IP user files & BD references
├── AdaptiveVoiceCancellation.cache/    # IP cache (synthesis checkpoints)
├── ip_repo/                            # Custom packaged IPs (LMS_Filter, ErrorCalc, etc.)
├── PYNQ_FILES/                         # design_1.bit + design_1.hwh for PYNQ deployment
├── sim_files/                          # Simulation vectors (.hex, .wav, .vcd)
├── public/                             # Project screenshots & documentation images
├── *.v                                 # Verilog source files & testbenches
├── *.tcl                               # TCL automation scripts
├── *.wav / *.coe                       # Audio test vectors & COE files
├── pynq_avc_runtime.py                 # Python/Jupyter runtime for PYNQ-Z2 overlay
└── README.md                           # This file
```

---

## 📋 Roadmap

- [x] Python golden-model validation (NLMS + Wavelet)
- [x] RTL design of LMS_Filter, ErrorCalc, LMS_UpdateEngine
- [x] IP packaging & AXI4-Stream integration
- [x] Vivado Block Design with ZYNQ7 PS + DMA + BRAM
- [x] Behavioral & post-synthesis simulation
- [x] Synthesis, Implementation & Bitstream generation
- [ ] On-board PYNQ-Z2 validation with real recorded cockpit audio
- [ ] Resolve I/O timing constraints in `pynq_z2_final.xdc`
- [ ] RTL design of ANC pipeline (FxLMS controller)
- [ ] Wavelet denoising stage in FPGA fabric (or hybrid ARM+FPGA split)
- [ ] Integration with HAL cockpit audio system

---

## 🏛️ Acknowledgments

This project is being developed at the **VLSI Lab, Institute of Engineering & Technology (IET), Devi Ahilya Vishwavidyalaya (DAVV), Indore** as part of the **Cognicity Startup** initiative, for **Hindustan Aeronautics Limited (HAL)** under the **Chips to Startup (C2S) Programme** of MeitY, Government of India.

---

## 📜 License

This project is developed for research and academic purposes under the C2S scheme. For collaboration or licensing inquiries, please contact [anuragtiwari1508@gmail.com](mailto:anuragtiwari1508@gmail.com).

---

<p align="center">
  <b>Made with ❤️ by <a href="https://github.com/AnuragTiwari1508">Anurag Tiwari</a></b><br>
  <i>VLSI Lab, IET DAVV | Cognicity | C2S Programme</i>
</p>
