# Two-minute presentation script

**[0:00 – 0:15] Introduction**
"Hello, I'm ___. My project is a Digital Modulation and Signal Analysis System, built in MATLAB and C++. It simulates a complete communication link: transmitter, noisy channel and receiver, for five modulation schemes."

**[0:15 – 0:35] Problem and goal**
"Every real channel adds noise. I wanted to see how AM, FM, ASK, BPSK and QAM behave under that noise, how much digital filtering helps, and how accurately each receiver recovers the original information, measured, not just calculated from formulas."

**[0:35 – 1:05] Live demo** *(dashboard open)*
"On the left I set the signal: a 50 Hz message on a 1 kHz carrier, sampled at 20 kHz. I pick AM and press Run Complete Pipeline. Here's the message, the carrier, the AM waveform and the signal after 10 dB of Gaussian noise. The FFT shows the carrier and the two sidebands at 950 and 1050 Hz. A band-pass Butterworth filter around the carrier raises the in-band SNR from 10 to about 24 dB, and the recovered message matches the original with a correlation of 0.995."

**[1:05 – 1:30] Digital results**
"Switching to 16-QAM, the constellation shows the received symbols clustering around the 16 ideal points; errors are marked in red. The SNR sweep plots bit error rate against Eb/N0, and my measured points sit on the theoretical curves. For BPSK at 4 dB I measured 0.012 against a theoretical 0.0125."

**[1:30 – 1:50] Implementation**
"The MATLAB version needs no toolboxes: I wrote the Butterworth filter design, zero-phase filtering and all modulators myself. I then reimplemented every algorithm independently in C++, including a radix-2 FFT, with 13 automated tests. Inputs are validated, for example against the Nyquist criterion."

**[1:50 – 2:00] Close**
"Next steps are fading channels, carrier recovery and OFDM. Thank you. I'm happy to take questions."
