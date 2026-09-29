// Filter.h - Butterworth IIR filters as cascaded biquads, zero-phase filtering
#pragma once
#include <string>
#include "SignalGenerator.h"

namespace dsp {

struct Biquad { double b0, b1, b2, a1, a2; };   // a0 normalised to 1

struct IIRFilter {
    FilterType type = FilterType::None;
    int order = 0;
    std::vector<double> edges;
    std::vector<Biquad> sections;
    double fs = 0;
    std::string description() const;
    bool empty() const { return type == FilterType::None; }
};

// fc for low/high-pass, (f1, f2) for band-pass (2*order poles). Throws on invalid edges.
IIRFilter designFilter(FilterType type, int order, double f1, double f2, double fs);
Vec sosFilter(const std::vector<Biquad>& sos, const Vec& x);   // single causal pass
Vec applyFilter(const IIRFilter& f, const Vec& x);            // zero-phase, mirror padding
double filterMagnitude(const IIRFilter& f, double freq);      // |H(f)|^2 of the zero-phase filter
Vec lowpassZeroPhase(const Vec& x, double fc, double fs, int order = 4);

} // namespace dsp
