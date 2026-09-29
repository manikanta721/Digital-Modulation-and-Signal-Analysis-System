// Noise.h - additive white Gaussian noise channel
#pragma once
#include "SignalGenerator.h"

namespace dsp {

struct NoiseResult {
    Vec noisy;
    double sigma = 0, signalPower = 0, noisePower = 0;
    double snrMeasuredDb = 0;
    double ebn0MeasuredDb = 0;   // NaN for analog schemes
};

// sigma from SNR (sample SNR = Ps/Pn, or Eb/N0 with N0 = 2 sigma^2 / fs)
// or directly from cfg.noiseSigma. Seeded with cfg.noiseSeed.
NoiseResult addAWGN(const Vec& s, const Signal& sig, const Config& cfg);

} // namespace dsp
