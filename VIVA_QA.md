# Viva and interview questions

## Fundamentals

**1. Why do we need modulation at all?**
To shift a low-frequency message to a carrier frequency suitable for the channel: antennas become a practical size (about λ/4), several signals can share the medium by frequency-division multiplexing, and the signal can be matched to the channel's bandwidth and noise characteristics.

**2. State the Nyquist sampling theorem and how your project uses it.**
A band-limited signal must be sampled at more than twice its highest frequency to avoid aliasing. The validator computes the highest frequency for each scheme (fc + fm for AM, fc + Δf + fm for FM using Carson's rule, fc + symbol rate for digital schemes) and rejects fs ≤ 2 f<sub>max</sub>. It warns below 4 f<sub>max</sub> because waveforms look coarse.

**3. What is AWGN and why is it the standard noise model?**
Additive white Gaussian noise: added to the signal, a flat power spectral density, Gaussian amplitudes. It models thermal noise well, and the central limit theorem makes the sum of many small independent disturbances Gaussian. It is also mathematically tractable, so theoretical BER formulas exist to compare against.

**4. What is the difference between SNR and Eb/N0?**
SNR is signal power over noise power in some bandwidth; here it is per sample (the full fs/2 bandwidth). Eb/N0 is the energy per bit over the noise power spectral density, independent of bandwidth and bit rate, so it compares modulation schemes fairly. In this project Eb/N0 = SNR + 10 log₁₀(samples per bit / 2).

**5. Why is the BER zero at 0 dB sample SNR for BPSK in your simulation?**
Each bit spans about 167 samples. The correlator adds them coherently, so signal energy grows with N while noise grows with √N, a processing gain of about 19 dB. 0 dB sample SNR is roughly 19 dB Eb/N0, where the BPSK BER is far below 10⁻⁹. That's why the sweep uses Eb/N0 by default.

## Analog modulation

**6. What is the modulation index in AM, and what happens when μ > 1?**
μ is the ratio of message amplitude to carrier amplitude. For μ > 1 the envelope A<sub>c</sub>(1 + μm) goes negative, the envelope detector sees its absolute value, and the recovered message is distorted (over-modulation). The GUI warns about it.

**7. What is the power efficiency of AM with μ = 0.5?**
η = μ²/(2 + μ²) = 0.25/2.25 ≈ 11%. Most of the power is in the carrier, which carries no information. The simulated average power, 0.5625 = 0.5(1 + μ²/2), agrees.

**8. How does your AM demodulator work?**
It multiplies the signal by 2cos and −2sin of the carrier, low-pass filters to get I and Q, and takes √(I² + Q²), which equals A<sub>c</sub>(1 + μm). It then solves for m, low-pass filters at 3 f<sub>m</sub>, removes DC and scales by A<sub>m</sub>. Using I and Q makes it insensitive to carrier phase, like a diode envelope detector.

**9. Explain Carson's rule for your FM signal.**
B ≈ 2(Δf + f<sub>m</sub>) = 2(200 + 50) = 500 Hz, containing about 98% of the power. The modulation index β = Δf/f<sub>m</sub> = 4, so there are several significant Bessel sidebands spaced f<sub>m</sub> apart.

**10. How is FM demodulated here?**
With a quadrature discriminator: I/Q down-conversion, phase = unwrap(atan2(Q, I)), then the time derivative of the phase divided by 2πΔf gives m(t). A central difference keeps the estimate time-aligned.

**11. Why does FM outperform AM at the same channel SNR in your results?**
FM trades bandwidth for noise immunity. Above threshold, the output SNR improves roughly with 3β², so with β = 4 the FM output SNR (about 33 dB) beats AM (about 20 dB) at 10 dB channel SNR. Below the threshold (about 10 dB in-band SNR) FM degrades sharply with "clicks".

## Digital modulation

**12. Compare the BER of ASK, BPSK and 4-QAM.**
BPSK has antipodal symbols (±A), the largest distance for a given energy: BER = Q(√(2Eb/N0)). OOK-ASK has symbols 0 and A, half the distance for the same average energy: Q(√(Eb/N0)), a 3 dB penalty. 4-QAM is two BPSK signals on orthogonal carriers, so it has the same BER per bit as BPSK at twice the data rate in the same bandwidth.

**13. Why use Gray coding in QAM?**
Adjacent constellation points differ in only one bit. The most likely error (to a neighbouring point) then causes one bit error instead of up to four, which lowers the BER for a given SER.

**14. What is a matched filter and where is it used here?**
It maximises the output SNR at the sampling instant by correlating the received signal with the known pulse shape. For rectangular pulses on a carrier, integrating r(t)·cos(ω<sub>c</sub>t) over the symbol is the matched filter. That's the correlator in `correlateSymbols.m`.

**15. What does the constellation diagram tell you?**
Each point is a received symbol's (I, Q) value. The spread around the ideal points shows the noise level; the distance between clusters relative to the spread predicts the error rate; rotation would show phase error; compression would show gain or distortion. Points past a decision boundary are symbol errors.

**16. Why does 16-QAM need more Eb/N0 than 4-QAM for the same BER?**
For the same average energy its points are much closer together (minimum distance shrinks by about √(2/5) per axis relative to the energy), so smaller noise causes decision errors. The benefit is 4 bits per symbol instead of 2.

## FFT and filtering

**17. Why do you use a Hann window before the FFT?**
The FFT assumes the block repeats periodically. If the signal doesn't complete an integer number of cycles, the discontinuity spreads energy into other bins (spectral leakage). Hann tapers the ends, reducing sidelobes from −13 dB to −31 dB, at the cost of a slightly wider main lobe. I divide by the window's coherent gain to keep amplitudes correct.

**18. What is the frequency resolution of your FFT?**
Δf = fs / N<sub>FFT</sub> = 20000 / 2048 ≈ 9.77 Hz. Zero-padding interpolates the spectrum, but true resolution is set by the observation time (1/0.1 s = 10 Hz).

**19. Why Butterworth, and why IIR instead of FIR?**
Butterworth has a maximally flat passband, so it doesn't distort the modulated signal's amplitude. IIR reaches a given roll-off with far fewer coefficients than FIR. Its non-linear phase is removed with forward–backward filtering.

**20. Explain the bilinear transform and pre-warping.**
The bilinear transform s = 2fs(z − 1)/(z + 1) maps the analog s-plane to the z-plane, keeping stability, but compresses the frequency axis non-linearly (ω<sub>a</sub> = 2fs tan(ω<sub>d</sub>/2)). Pre-warping designs the analog prototype at 2fs tan(πf<sub>c</sub>/fs) so the digital cutoff lands exactly at f<sub>c</sub>.

**21. Why implement the filter as second-order sections?**
A single high-order transfer function has coefficients extremely sensitive to rounding, which can move poles outside the unit circle. Cascaded biquads keep each pole pair well conditioned.

**22. What does zero-phase filtering do, and what is its limitation?**
Filtering forward and then backward cancels the phase delay, so filtered and original signals line up in time, and the magnitude response becomes |H|². It is non-causal (it needs the whole signal), so it suits offline analysis, not real-time processing.

**23. Why did you design a true band-pass instead of cascading a high-pass and low-pass?**
With a narrow band (850–1150 Hz), the cascade's two roll-offs overlap and attenuated the AM sidebands at 950/1050 Hz by about 30%, creating a reconstruction error floor. The low-pass-to-band-pass transformation gives a flat passband centred on the carrier.

## Implementation and design

**24. How did you verify the implementation is correct?**
Measured BER is compared with theoretical formulas across Eb/N0; the FFT peak is checked at the known message frequency and the AM sidebands at fc ± fm; filter gain is checked at the centre and cutoff; a noiseless 16-QAM round trip must give zero errors; results must be identical with the same seed. MATLAB and C++ implementations were developed independently and agree on the trends.

**25. Why implement everything again in C++?**
To show the algorithms are understood, not just called from toolboxes, and because embedded and real-time DSP runs in C/C++. The C++ version has its own FFT, filter design, noise generation and receivers, and exports CSV for plotting.

**26. What assumptions or limitations does your system have?**
Perfect carrier and symbol synchronisation, rectangular pulses (wide spectrum, no pulse shaping), AWGN only (no fading or multipath), and offline zero-phase filtering. These are the natural next extensions.

**27. How would you add carrier recovery?**
With a Costas loop for BPSK/QAM: multiply by the local I and Q references, form an error signal (e.g. I·Q for BPSK), filter it with a loop filter and drive an NCO. For timing, a Gardner or early-late gate detector.

**28. How would the system change for a fading channel?**
Multiply the signal by a complex Rayleigh or Rician gain (Jakes model for time variation) before adding noise, then add channel estimation and equalisation. The BER curves would flatten (roughly 1/SNR for Rayleigh) instead of falling as a waterfall.

**29. What is the time complexity of your FFT?**
O(N log N): log₂N stages of N/2 butterflies each, compared with O(N²) for a direct DFT. For N = 2048 that is about 22 000 butterflies instead of about 4 million multiplications.

**30. What was the hardest bug you fixed?**
The FM reconstruction error grew at high SNR. The cause was odd-reflection padding in the final low-pass filter: a small edge spike was reflected and amplified into the signal. Switching to mirror (even) padding and excluding edges from the DC estimate fixed it; MSE then fell steadily with SNR, as expected.
