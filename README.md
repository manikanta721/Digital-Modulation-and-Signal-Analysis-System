# C++ implementation

An independent C++17 implementation of every algorithm: signal generation, modulators, AWGN, radix-2 FFT, Butterworth filters, demodulators and metrics. It uses only the standard library.

## Build

```bash
make                         # g++ -std=c++17 -O2
# or
cmake -B build && cmake --build build
```

On Windows with MSVC, use CMake (it defines `_USE_MATH_DEFINES` for `M_PI`).

## Run

| Command | What it does |
| --- | --- |
| `./dsp_app` | AM at 10 dB with the recommended filter |
| `./dsp_app --mod FM --snr 5` | FM at 5 dB |
| `./dsp_app --mod BPSK --snr 4 --ebn0 --random 1000 --fs 50000 --duration 2` | BPSK at Eb/N0 = 4 dB |
| `./dsp_app --mod QAM --qam 16 --random 400 --snr 20` | 16-QAM |
| `./dsp_app --filter band --band 900 1100 --order 6` | manual filter |
| `./dsp_app --sigma 0.3` | set noise σ instead of SNR |
| `--csv name` | writes `name_signals.csv`, `name_spectrum.csv`, `name_constellation.csv` |
| `./dsp_app --compare` | table for all five modulations |
| `./dsp_app --sweep [--sample-axis] [--csv name]` | 0–30 dB sweep, writes `sweep.csv` |
| `./dsp_app --test` | 13 built-in tests |

Other options: `--fs --duration --fm --fc --mu --dev --bits --seed --cutoff --filter low|high|band|none|auto`.

The CSV files can be plotted in MATLAB (`readtable`), Python (pandas/matplotlib) or Excel.

## Files

| File | Responsibility |
| --- | --- |
| `SignalGenerator.*` | `Config`, bit framing, message and carrier |
| `Modulation.*` | AM, FM, ASK, BPSK, 4/16-QAM (Gray mapping) |
| `Noise.*` | seeded AWGN from SNR, Eb/N0 or σ |
| `FFT.*` | iterative radix-2 FFT/IFFT, calibrated spectrum, peak detection |
| `Filter.*` | Butterworth LP/HP/BP biquads, zero-phase filtering, magnitude response |
| `Demodulation.*` | envelope detector, FM discriminator, coherent correlators |
| `Metrics.*` | MSE, RMSE, SNR, correlation, BER, Q-function, theoretical BER |
| `Pipeline.*` | validation, recommended filter, complete pipeline |
| `main.cpp` | command-line interface, CSV export, comparison, sweep, tests |
