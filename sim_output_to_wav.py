##############################################################################
#  sim_output_to_wav.py
#  Simulation output (output_samples.hex) ko WAV mein convert karo
#  PC pe run karo (PYNQ pe nahi)
#
#  Usage: python sim_output_to_wav.py
##############################################################################

import numpy as np
import scipy.io.wavfile as wav

SAMPLE_RATE = 16000
INPUT_HEX   = "C:/Users/HP/AVC_Project/sim_files/output_samples.hex"
OUTPUT_WAV  = "C:/Users/HP/AVC_Project/sim_files/sim_clean_output.wav"

# Read hex output
samples = []
with open(INPUT_HEX, 'r') as f:
    for line in f:
        line = line.strip()
        if line:
            val = int(line, 16)
            # Convert from unsigned 16-bit to signed
            if val > 32767:
                val -= 65536
            samples.append(val)

samples = np.array(samples, dtype=np.int16)
wav.write(OUTPUT_WAV, SAMPLE_RATE, samples)

print(f"Samples read    : {len(samples)}")
print(f"Duration        : {len(samples)/SAMPLE_RATE:.2f} sec")
print(f"Output saved to : {OUTPUT_WAV}")
print(f"Ab {OUTPUT_WAV} open karo aur suno!")
