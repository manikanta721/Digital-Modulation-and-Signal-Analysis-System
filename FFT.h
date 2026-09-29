// FFT.h - radix-2 FFT and single-sided magnitude spectrum
#pragma once
#include <complex>
#include "SignalGenerator.h"

namespace dsp {

using Complex = std::complex<double>;

void fft(std::vector<Complex>& a, bool inverse = false);   // in place, size must be a power of two
size_t nextPow2(size_t n);

struct Spectrum {
    Vec f, mag;              // single-sided, amplitude calibrated
    size_t nfft = 0;
    double df = 0;
    std::vector<double> peakFreq, peakMag;   // dominant components
};

Spectrum computeSpectrum(const Vec& x, double fs, bool hann = true, int numPeaks = 3);

} // namespace dsp
