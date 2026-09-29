# Module explanations

Names refer to the MATLAB files; the C++ file with the same responsibility is given in brackets.

## Configuration and validation

**`config.m`** (`Config` in `SignalGenerator.h`) holds every parameter with sensible defaults: fs = 20 kHz, 0.1 s, fm = 50 Hz, fc = 1 kHz, μ = 0.5, Δf = 200 Hz, the bit string `101101001011`, 10 dB SNR and a 4th-order band-pass filter.

**`core/validateConfig.m`** (`validateConfig`) returns *errors* that stop processing and *warnings* that don't. It checks positive values, the Nyquist criterion (fs > 2 × highest frequency, where the highest frequency is fc + fm for AM, fc + Δf + fm for FM and fc + symbol rate for digital schemes), carrier above the message band, at least 4 samples per bit and 1 carrier cycle per symbol, valid bit strings, the SNR range (−20 to 60 dB), filter order 1–10 and cutoffs below fs/2. It warns when the filter would remove the carrier.

## Signal generation

**`generateMessage.m`** creates the time vector and m(t) = A<sub>m</sub> sin(2πf<sub>m</sub>t) for analog schemes, or an NRZ waveform of the bits for digital schemes. For digital schemes, `deriveDigital.m` works out the samples per bit (spb = round(fs × duration / bits)), bits per symbol (1, 2 for 4-QAM, 4 for 16-QAM), padding to whole symbols, the bit rate and the symbol rate.

**`generateCarrier.m`** returns c(t) = A<sub>c</sub> cos(2πf<sub>c</sub>t) and the unit cos/sin references used by the coherent receivers.

**`generateBinaryData.m`** parses the bit string or draws seeded random bits.

## Modulation

- **AM:** s = A<sub>c</sub>(1 + μm)cos(ω<sub>c</sub>t). With μ ≤ 1 the envelope never crosses zero, so envelope detection works.
- **FM:** the phase is 2πΔf times the running integral of m(t) (trapezoidal rule, `cumtrapz`). The modulation index is β = Δf/f<sub>m</sub> = 4 by default and Carson's bandwidth is 2(Δf + f<sub>m</sub>) = 500 Hz.
- **ASK:** each bit sets the carrier amplitude to A<sub>c</sub> or L·A<sub>c</sub>.
- **BPSK:** each bit multiplies the carrier by +1 or −1 (0° or 180°).
- **QAM:** bits are grouped into symbols; each group sets an in-phase level I and a quadrature level Q. 16-QAM uses the Gray code 00 → −3, 01 → −1, 11 → +1, 10 → +3 on each axis, so neighbouring points differ by one bit. The waveform is normalised by √E<sub>s</sub> (2 for 4-QAM, 10 for 16-QAM).

## Channel

**`addNoise.m`** (`addAWGN`) measures the signal power P<sub>s</sub> and sets the noise standard deviation:

- sample SNR: σ = √(P<sub>s</sub> / 10<sup>SNR/10</sup>)
- Eb/N0 (digital): with N<sub>0</sub> = 2σ²/fs and E<sub>b</sub> = P<sub>s</sub>·spb/fs, σ = √(P<sub>s</sub>·spb / (2·10<sup>EbN0/10</sup>))
- or σ directly

It then adds seeded Gaussian noise and reports the *measured* SNR, which is slightly different from the requested one because the noise is random.

## FFT analysis

**`fftAnalysis.m`** (`computeSpectrum`) applies a Hann window, zero-pads to a power of two, takes the FFT, keeps the positive half, scales it so peak height equals sinusoid amplitude and finds the strongest local maxima. The C++ version implements the FFT itself (bit-reversal permutation + butterflies).

## Filtering

**`designFilter.m`** (`designFilter`) builds Butterworth filters as second-order sections. Low/high-pass sections use Q<sub>k</sub> = 1 / (2 sin((2k+1)π / 2N)) with bilinear pre-warping at the cutoff; odd orders add a first-order section. The band-pass maps each prototype pole p to two band-pass poles, the roots of s² − pBs + ω₀² = 0, then applies the bilinear transform and normalises the gain to 1 at the centre frequency.

**`applyFilter.m`** (`applyFilter`) mirror-pads the signal, filters forward, reverses, filters again and reverses back. This cancels the phase delay. The padding length is about three time constants of the lowest edge.

**`recommendedFilter.m`** picks a band-pass that just contains the modulated signal, reducing out-of-band noise. With the defaults the in-band SNR improves from about 10 dB to about 21–24 dB.

## Demodulation and reconstruction

- **AM:** multiply by 2cos and −2sin, low-pass to get I and Q, then envelope = √(I² + Q²) = A<sub>c</sub>(1 + μm). Solve for m, low-pass at 3f<sub>m</sub>, remove DC, scale by A<sub>m</sub>.
- **FM:** the same I/Q step, then phase = unwrap(atan2(Q, I)). The derivative (central difference) divided by 2πΔf gives m(t).
- **ASK / BPSK / QAM:** an integrate-and-dump correlator over each symbol, the matched filter for rectangular pulses. It gives the I (and Q) amplitude of each symbol. Decisions are the midpoint threshold (ASK), the sign (BPSK) or the nearest level per axis followed by Gray demapping (QAM). The decided bits are expanded back to an NRZ waveform for plotting.

The receivers assume perfect carrier and symbol synchronisation, which is standard for a simulation of this scope.

## Metrics

`calculateBER`, `calculateMSE`, `calculateRMSE`, `calculateSNR` and `calculateCorrelation` follow the textbook definitions. `theoreticalBER` gives Q(√(2Eb/N0)) for BPSK and 4-QAM, Q(√(Eb/N0 (1−L)²/(1+L²))) for ASK and (3/8)erfc(√(0.4Eb/N0)) for Gray 16-QAM.

## Pipeline and experiments

**`core/pipelineStage.m`** runs one named stage and logs what it did; re-running a stage clears the later ones. **`runPipeline.m`** validates and runs the whole chain. **`compareModulations.m`** runs all five with their recommended filters. **`experiments/snrExperiment.m`** loops over SNR = 0:5:30 dB with 2000 random bits per point and returns a table plus the data for `plotPerformance.m`.

## Visualisation and GUI

`plotTimeDomain`, `plotFrequencyDomain`, `plotConstellation` and `plotPerformance` draw into a new figure or into a dashboard panel. Every axis has a title, axis labels and a grid, and legends where there are several series. **`gui/dashboard.m`** builds the three-panel `uifigure`: configuration on the left, modulation and stage buttons in the centre, and tabs for time domain, spectrum, constellation, metrics, SNR sweep and log on the right.
