// Demodulation.h - analog detectors and coherent digital receivers
#pragma once
#include "Modulation.h"

namespace dsp {

struct AnalogResult {
    Vec recovered;
    double cutIQ = 0, cutMsg = 0;
    std::string detector;
};

struct DigitalResult {
    std::vector<int> rxBits;           // decided bits (padded length)
    Vec softI, softQ;                  // normalised correlator outputs (after filter)
    Vec noisyI, noisyQ;                // same, computed on the unfiltered noisy signal
    Vec idealI, idealQ;                // transmitted constellation points
    std::vector<int> symbolError;      // 1 if the symbol was decided wrongly
    Vec recovered;                     // NRZ waveform of the decided bits
};

AnalogResult amDemodulate(const Vec& r, const Signal& sig, const Config& cfg);   // envelope (I/Q magnitude)
AnalogResult fmDemodulate(const Vec& r, const Signal& sig, const Config& cfg);   // phase discriminator
DigitalResult digitalDemodulate(const Vec& filtered, const Vec& noisy, const Signal& sig,
                                const Modulated& mod, const Config& cfg);        // ASK, BPSK, QAM

} // namespace dsp
