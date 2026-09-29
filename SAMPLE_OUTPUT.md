# Sample output

Real output from the C++ build (`g++ 13, -O2`). MATLAB produces the same trends; exact numbers differ slightly because it uses a different random-number generator.

## AM at 10 dB (`./dsp_app --mod AM --snr 10`)

```
=== AM ===
[Generate] 2000 samples at fs = 2e+04 Hz
[Modulate] AM, average power 0.5625
[Noise] AWGN sigma 0.2372, measured SNR 9.782 dB
[Filter] Band-pass Butterworth, order 4, 850-1150 Hz, SNR after filter 23.75 dB
[Demodulate] done
Channel SNR (measured)  :    9.782 dB
SNR after filter        :   23.755 dB
Dominant components     : 996.1 Hz 947.3 Hz 1054.7 Hz  (modulated, 2048-point FFT)
MSE                     : 0.00455247
RMSE                    : 0.067472
Output SNR              : 20.407 dB
Correlation             : 0.995443
```

## BPSK at Eb/N0 = 4 dB (`./dsp_app --mod BPSK --snr 4 --ebn0 --random 1000 --fs 50000 --duration 2`)

Theory: Q(√(2 × 10^0.4)) = 0.0125. Measured 12 errors in 1000 bits (0.012).

```
=== BPSK ===
[Generate] 100000 samples at fs = 5e+04 Hz
[Modulate] BPSK, average power 0.5
[Noise] AWGN sigma 3.155, measured SNR -12.99 dB
[Filter] Low-pass Butterworth, order 4, 2000 Hz, SNR after filter -1.577 dB
[Demodulate] done
Channel SNR (measured)  :  -12.993 dB
SNR after filter        :   -1.577 dB
Dominant components     : 1098.3 Hz 1038.4 Hz 901.8 Hz  (modulated, 131072-point FFT)
Eb/N0 (measured)        :    3.997 dB
Bit errors              : 12 / 1000
BER                     : 0.012
Accuracy                : 98.8000 %
SER                     : 0.012
Soft-symbol MSE         : 0.372719
Tx bits : 1101111110011000101010100111111001110111011011001100011010001010
Rx bits : 1101111110011001101010100111111001110111011011001100011010001010
```

## All modulations at 10 dB (`./dsp_app --compare`)

```
Mod         SNR(dB)        BER     Acc(%)        SER        MSE     OutSNR       Corr
AM            9.782          -          -          -   0.004552     20.407    0.99544
FM            9.782          -          -          -  0.0002777     32.554    0.99972
ASK           9.784          0    100.000          0   0.002293          -          -
BPSK          9.784          0    100.000          0    0.00613          -          -
4-QAM         9.784          0    100.000          0   0.009807          -          -
```

## SNR sweep (`./dsp_app --sweep`)

Digital rows use Eb/N0 on the SNR axis; analog rows use channel SNR. "Theory" is the coherent-detection BER.

```
Mod         SNR          BER       Theory     Acc(%)        MSE
AM          0.0            -            -          -    0.05653
AM          5.0            -            -          -    0.01032
AM         10.0            -            -          -   0.003304
AM         15.0            -            -          -   0.002321
AM         20.0            -            -          -  0.0005248
AM         25.0            -            -          -  0.0002024
AM         30.0            -            -          -  0.0001553
FM          0.0            -            -          -   0.001778
FM          5.0            -            -          -  0.0006935
FM         10.0            -            -          -  0.0003626
FM         15.0            -            -          -  0.0001045
FM         20.0            -            -          -  3.667e-05
FM         25.0            -            -          -  4.038e-05
FM         30.0            -            -          -  3.068e-05
ASK         0.0        0.161      0.15866     83.900     0.4485
ASK         5.0        0.041     0.037679     95.900     0.1466
ASK        10.0       0.0005    0.0007827     99.950    0.04619
ASK        15.0            0    9.361e-09    100.000    0.01553
ASK        20.0            0            0    100.000   0.005593
ASK        25.0            0            0    100.000   0.002505
ASK        30.0            0            0    100.000   0.001513
BPSK        0.0        0.083      0.07865     91.700     0.9326
BPSK        5.0         0.01    0.0059539     99.000     0.3056
BPSK       10.0            0   3.8721e-06    100.000    0.09766
BPSK       15.0            0            0    100.000    0.03414
BPSK       20.0            0            0    100.000    0.01337
BPSK       25.0            0            0    100.000   0.007043
BPSK       30.0            0            0    100.000   0.004978
4-QAM       0.0       0.0765      0.07865     92.350     0.9436
4-QAM       5.0       0.0065    0.0059539     99.350     0.3051
4-QAM      10.0            0   3.8721e-06    100.000     0.1016
4-QAM      15.0            0            0    100.000    0.03907
4-QAM      20.0            0            0    100.000    0.01847
4-QAM      25.0            0            0    100.000    0.01135
4-QAM      30.0            0            0    100.000   0.009396
Sweep written to sweep.csv
```

## Tests (`./dsp_app --test`)

```
[PASS] FFT peak at message frequency                48.828125
[PASS] FFT / IFFT round trip                        0.000000
[PASS] Band-pass: unity at 1000 Hz, < 1% at 700/1300 Hz 
[PASS] Low-pass |H|^2 = 0.5 at cutoff               0.500000
[PASS] AM MSE falls with SNR, corr > 0.99           0.014623 -> 0.000098
[PASS] FM MSE falls with SNR, corr > 0.99           0.000835 -> 0.000034
[PASS] ASK BER = 0 at 30 dB                         
[PASS] BPSK BER = 0 at 30 dB                        
[PASS] QAM BER = 0 at 30 dB                         
[PASS] BPSK BER within 25% of theory at 4 dB        0.013600 vs 0.012501
[PASS] 16-QAM noiseless round trip                  
[PASS] Validation rejects bad inputs                
[PASS] Same seed gives identical MSE                

13 of 13 tests passed.
```

## MATLAB console (`main('demo')`, abridged)

The table printed by `compareModulations` has the columns
`Modulation, ChannelSNR_dB, BER, Accuracy_pct, SER, MSE, RMSE, OutputSNR_dB, Correlation`,
followed by the processing log of each run, for example:

```
[Generate] m(t) = 1 sin(2 pi 50 t), 2000 samples at fs = 20000 Hz; carrier 1000 Hz, amplitude 1.
[Modulate] AM (mu = 0.5). Average power 0.5625.
[Add noise] AWGN sigma = 0.2372, measured SNR ~10 dB.
[FFT] 2048-point FFT, 9.77 Hz/bin. Noisy signal peaks: ~996, ~947, ~1055 Hz.
[Filter] Band-pass Butterworth, order 4, 850-1150 Hz, zero-phase. SNR vs clean signal: ~10 dB before, ~24 dB after.
[Demodulate] Envelope detector (I/Q magnitude). MSE ~0.004, output SNR ~20 dB, correlation ~0.995.
```
