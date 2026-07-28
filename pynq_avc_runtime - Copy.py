##############################################################################
#  pynq_avc_runtime.py  –  Adaptive Voice Cancellation Runtime
#  Board   : PYNQ-Z2
#  Python  : 3.8+  with pynq library installed
#
#  Run on the PYNQ-Z2 board:
#    from pynq_avc_runtime import run_avc
#    run_avc("noise.wav", "noisy_voice.wav", "clean_output.wav")
##############################################################################

import numpy as np
import scipy.io.wavfile as wav
from pynq import Overlay, allocate
import time, os

BITFILE = "/home/xilinx/design_1.bit"

# ── Address Map (must match Vivado Address Editor output) ──────────────────
ADDR_DMA_NOISE  = 0x40400000   # axi_dma_noise
ADDR_DMA_VOICE  = 0x40410000   # axi_dma_voice
ADDR_GPIO_CTRL  = 0x41200000   # axi_gpio_ctrl
ADDR_INTC       = 0x41800000   # axi_intc_0

# AXI DMA register offsets (Xilinx PG021)
MM2S_DMACR   = 0x00
MM2S_DMASR   = 0x04
MM2S_SA      = 0x18
MM2S_LENGTH  = 0x28
S2MM_DMACR   = 0x30
S2MM_DMASR   = 0x34
S2MM_DA      = 0x48
S2MM_LENGTH  = 0x58


def load_overlay(bitfile: str = BITFILE) -> Overlay:
    """Load the bitstream onto the FPGA."""
    print(f"[AVC] Loading overlay: {bitfile}")
    ol = Overlay(bitfile)
    print("[AVC] Overlay loaded OK")
    return ol


def read_wav_mono_int16(path: str) -> np.ndarray:
    """Load a WAV file and return 16-bit signed mono samples."""
    rate, data = wav.read(path)
    if data.ndim > 1:
        data = data[:, 0]                   # take left channel
    if data.dtype != np.int16:
        data = (data / np.abs(data).max() * 32767).astype(np.int16)
    print(f"[AVC] Loaded {path}: {len(data)} samples @ {rate} Hz")
    return rate, data


def write_wav(path: str, rate: int, samples: np.ndarray):
    """Write 16-bit mono PCM WAV."""
    wav.write(path, rate, samples.astype(np.int16))
    print(f"[AVC] Saved output → {path}")


def dma_transfer(dma_base, src_buf_phys: int, dst_buf_phys: int,
                 n_bytes: int, include_s2mm: bool = True):
    """
    Kick off a simple DMA transfer (no scatter-gather).
    dma_base: pynq MMIO object pointing to DMA base address.
    """
    # ── MM2S (memory → stream) ───────────────────────────────────────────────
    dma_base.write(MM2S_DMACR, 0x0001)       # Run
    dma_base.write(MM2S_SA,    src_buf_phys)
    dma_base.write(MM2S_LENGTH, n_bytes)

    if include_s2mm:
        # ── S2MM (stream → memory) ───────────────────────────────────────────
        dma_base.write(S2MM_DMACR, 0x0001)
        dma_base.write(S2MM_DA,    dst_buf_phys)
        dma_base.write(S2MM_LENGTH, n_bytes)


def wait_dma_done(dma_base, include_s2mm: bool = True, timeout_s: float = 5.0):
    """Poll DMA status until idle or timeout."""
    deadline = time.time() + timeout_s

    while time.time() < deadline:
        mm2s_status = dma_base.read(MM2S_DMASR)
        if mm2s_status & 0x2:   # Idle bit
            break
    else:
        raise TimeoutError("MM2S DMA timed out")

    if include_s2mm:
        deadline = time.time() + timeout_s
        while time.time() < deadline:
            s2mm_status = dma_base.read(S2MM_DMASR)
            if s2mm_status & 0x2:
                break
        else:
            raise TimeoutError("S2MM DMA timed out")


def run_avc(noise_wav: str, noisy_voice_wav: str, output_wav: str,
            block_size: int = 1024):
    """
    Full pipeline:
      1. Load .bit overlay
      2. Read WAV files
      3. Process in blocks via DMA + LMS FPGA
      4. Save cleaned audio
    """
    # -- Load FPGA overlay --
    ol = load_overlay()
    from pynq import MMIO
    dma_noise = MMIO(ADDR_DMA_NOISE, 0x1000)
    dma_voice = MMIO(ADDR_DMA_VOICE, 0x1000)

    # -- Read audio --
    rate_n, x_all = read_wav_mono_int16(noise_wav)
    rate_v, d_all = read_wav_mono_int16(noisy_voice_wav)

    assert rate_n == rate_v, "Sample rates must match!"
    n_samples = min(len(x_all), len(d_all))
    x_all = x_all[:n_samples]
    d_all = d_all[:n_samples]

    # Output buffer
    e_all = np.zeros(n_samples, dtype=np.int16)

    # -- Allocate contiguous DMA buffers (4 bytes per sample = int32 DMA word)
    n_bytes = block_size * 4
    buf_x   = allocate(shape=(block_size,), dtype=np.int32)
    buf_d   = allocate(shape=(block_size,), dtype=np.int32)
    buf_e   = allocate(shape=(block_size,), dtype=np.int32)

    n_blocks = (n_samples + block_size - 1) // block_size
    print(f"[AVC] Processing {n_samples} samples in {n_blocks} blocks of {block_size}")

    for blk in range(n_blocks):
        start = blk * block_size
        end   = min(start + block_size, n_samples)
        sz    = end - start

        # Copy data to DMA buffers (zero-pad last block)
        buf_x[:sz]    = x_all[start:end].astype(np.int32)
        buf_x[sz:]    = 0
        buf_d[:sz]    = d_all[start:end].astype(np.int32)
        buf_d[sz:]    = 0
        buf_x.flush()
        buf_d.flush()

        # ── Kick Noise DMA (MM2S only: x(n) → LMS) ──────────────────────────
        dma_transfer(dma_noise,
                     src_buf_phys=buf_x.physical_address,
                     dst_buf_phys=0,
                     n_bytes=block_size * 4,
                     include_s2mm=False)

        # ── Kick Voice DMA (MM2S d(n) → LMS, S2MM ← e(n) from LMS) ─────────
        dma_transfer(dma_voice,
                     src_buf_phys=buf_d.physical_address,
                     dst_buf_phys=buf_e.physical_address,
                     n_bytes=block_size * 4,
                     include_s2mm=True)

        wait_dma_done(dma_noise, include_s2mm=False)
        wait_dma_done(dma_voice, include_s2mm=True)

        buf_e.invalidate()
        e_all[start:end] = buf_e[:sz].astype(np.int16)

        if blk % 10 == 0:
            print(f"[AVC] Block {blk+1}/{n_blocks} done")

    # -- Save output --
    write_wav(output_wav, rate_v, e_all)
    print("[AVC] Done!")

    # Cleanup
    buf_x.freebuffer()
    buf_d.freebuffer()
    buf_e.freebuffer()

    return e_all


# ── Quick test (run directly on PYNQ board) ──────────────────────────────────
if __name__ == "__main__":
    import sys
    if len(sys.argv) == 4:
        run_avc(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        print("Usage: python pynq_avc_runtime.py noise.wav noisy_voice.wav output.wav")
