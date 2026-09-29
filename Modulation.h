// Modulation.h - AM, FM, ASK, BPSK and 4/16-QAM modulators
#pragma once
#include "SignalGenerator.h"

namespace dsp {

struct Modulated {
    Vec s;              // modulated waveform
    Vec I, Q;           // QAM symbol levels (empty for other schemes)
    double Es = 1.0;    // QAM average symbol energy of the level grid
    double power = 0.0; // average signal power
};

Vec amModulate(const Signal& sig, const Config& cfg);   // Ac[1 + mu m(t)] cos(wc t)
Vec fmModulate(const Signal& sig, const Config& cfg);   // Ac cos(wc t + 2 pi df * int m)
Vec askModulate(const Signal& sig, const Config& cfg);  // 1 -> Ac, 0 -> askLow*Ac
Vec bpskModulate(const Signal& sig, const Config& cfg); // 1 -> 0 deg, 0 -> 180 deg
Modulated qamModulate(const Signal& sig, const Config& cfg);

Modulated modulate(const Signal& sig, const Config& cfg);   // dispatcher

// Gray mapping helpers (shared with the demodulator)
void qamMap(const int* bits, int M, double& I, double& Q);
double qamSlice(double v, int M);
void qamLevelToBits(double level, int M, int* out);         // writes log2(M)/2 bits

} // namespace dsp
