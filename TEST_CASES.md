# Test cases

Automated versions run with `main('test')` (MATLAB) and `./dsp_app --test` (C++).

## Automated tests

| # | Test | Input | Expected result |
| --- | --- | --- | --- |
| 1 | FFT peak location | default message (50 Hz) | strongest peak within one bin (9.77 Hz) of 50 Hz |
| 2 | AM spectrum | AM, μ = 0.5 | peaks at 950, 1000 and 1050 Hz (MATLAB) |
| 3 | FFT/IFFT round trip | 8-point ramp | reconstruction error < 10⁻¹² (C++) |
| 4 | Band-pass response | BP 850–1150 Hz, order 4 | gain 1 at 1000 Hz, < 0.01 at 700 and 1300 Hz |
| 5 | Low-pass cutoff | LP 500 Hz, order 4 | zero-phase gain exactly 0.5 (−6 dB) at 500 Hz |
| 6 | AM reconstruction | 5 dB then 30 dB | MSE falls; correlation > 0.99 at 30 dB |
| 7 | FM reconstruction | 5 dB then 30 dB | MSE falls; correlation > 0.99 at 30 dB |
| 8 | ASK, BPSK, QAM | 30 dB | BER = 0 |
| 9 | BPSK vs theory | 10 000 bits, Eb/N0 = 4 dB | BER within 25% of 0.0125 |
| 10 | 16-QAM round trip | 28 bits, σ = 0 | BER = 0 (Gray mapping and slicing are consistent) |
| 11 | Validation | fs = 1500 Hz; duration −1; bits "10201"; band [1200 900] | each is rejected with a message |
| 12 | Reproducibility | same configuration twice | identical MSE |

## Manual test cases

| # | Action | Expected behaviour |
| --- | --- | --- |
| M1 | Set fs = 1500 Hz and run AM | Error: sampling frequency must exceed 2 × 1050 Hz; nothing is plotted |
| M2 | AM with μ = 1.2 | Runs with an over-modulation warning; the recovered message is distorted near its troughs |
| M3 | FM with fc = 200 Hz, Δf = 200 Hz | Error: carrier must exceed Δf + fm = 250 Hz. With fc = 400 Hz it runs with a warning that the carrier is close to the FM bandwidth |
| M4 | Bit string "10a1" | Error: only 0 and 1 are allowed |
| M5 | Low-pass cutoff 500 Hz with a 1 kHz carrier | Warning that the modulated signal will be removed; demodulation fails (high MSE / BER ≈ 0.5) |
| M6 | Band-pass 1200–1500 Hz with a 1 kHz carrier | Warning that the carrier is outside the pass band |
| M7 | BPSK, SNR reference Eb/N0, 0 dB, 1000 random bits, fs 50 kHz, 2 s | BER near 0.079 |
| M8 | 16-QAM, 12 dB Eb/N0, random bits | a few symbol errors, shown in red in the constellation |
| M9 | Filter type None | SNR after filter equals the channel SNR |
| M10 | SNR sweep | BER falls with SNR and follows the dashed theory curves; MSE of AM and FM falls with SNR |
| M11 | Change a parameter after a run | Status says results are out of date; the next stage restarts from Generate |
