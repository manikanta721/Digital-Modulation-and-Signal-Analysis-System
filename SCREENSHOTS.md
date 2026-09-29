# Screenshots for GitHub and your resume

The `screenshots/` folder already contains six images captured from the browser version. For the MATLAB version, capture these figures (use `exportgraphics(fig, 'name.png', 'Resolution', 200)` or the figure's export button).

| # | Screenshot | How to produce it | Why it matters |
| --- | --- | --- | --- |
| 1 | Full dashboard after a run | `main`, choose AM, Run Complete Pipeline | Shows the three-panel GUI at a glance; use as the README hero image |
| 2 | AM time-domain figure | AM at 10 dB | Envelope, noise and a recovered message that overlaps the original |
| 3 | FFT spectrum | Spectrum tab after the AM run | Carrier and sidebands labelled, filter pass band visible |
| 4 | FM waveform and recovery | FM at 10 dB | Shows angle modulation and the discriminator output |
| 5 | BPSK waveform + recovered bits | BPSK at 0 dB sample SNR | Noisy signal that still decodes perfectly (processing gain) |
| 6 | 16-QAM constellation | QAM, 16-QAM, random bits, Eb/N0 12 dB | Before/after filter clouds with errors in red |
| 7 | BER vs SNR | Run SNR Sweep | Measured points on top of theory curves: proves correctness |
| 8 | MSE vs SNR | same sweep | Analog reconstruction quality improving with SNR |
| 9 | Comparison table | Compare All Modulations | One table summarising all five schemes |
| 10 | Validation message | Set fs = 1500 Hz and run | Demonstrates input checking |
| 11 | C++ terminal output | `./dsp_app --compare` and `--test` | Shows the independent C++ engine and its passing tests |

For a resume or LinkedIn post, use at most two images: the dashboard (1) and BER vs SNR with theory (7).

## Resume bullet points

- Built a digital communication simulator in MATLAB and C++ covering AM, FM, ASK, BPSK and 4/16-QAM over an AWGN channel, with an interactive MATLAB dashboard for stage-by-stage analysis.
- Implemented FFT spectral analysis and Butterworth low/high/band-pass filters (bilinear transform, second-order sections, zero-phase filtering) from scratch; the band-pass filter raised in-band SNR by about 11–14 dB.
- Designed coherent receivers (envelope detector, FM phase discriminator, matched-filter correlators); measured BER matched theoretical curves (BPSK: 0.012 vs 0.0125 at Eb/N0 = 4 dB).
- Automated SNR sweeps (0–30 dB) producing BER, accuracy and MSE curves, plus 13 unit tests in C++ and a MATLAB test suite.
