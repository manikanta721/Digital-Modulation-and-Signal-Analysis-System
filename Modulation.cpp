// Modulation.cpp
#include "Modulation.h"
#include <cmath>

namespace dsp {

Vec amModulate(const Signal& sig, const Config& cfg) {
    Vec s(sig.N);
    for (int n = 0; n < sig.N; ++n) s[n] = cfg.Ac * (1.0 + cfg.mu * sig.msgNorm[n]) * sig.cosC[n];
    return s;
}

Vec fmModulate(const Signal& sig, const Config& cfg) {
    Vec s(sig.N);
    const double K = 2.0 * M_PI * cfg.freqDev / cfg.fs;
    double phase = 0.0;
    for (int n = 0; n < sig.N; ++n) {
        if (n > 0) phase += K * 0.5 * (sig.msgNorm[n] + sig.msgNorm[n - 1]);   // trapezoidal integral
        s[n] = cfg.Ac * std::cos(2.0 * M_PI * cfg.fc * sig.t[n] + phase);
    }
    return s;
}

Vec askModulate(const Signal& sig, const Config& cfg) {
    Vec s(sig.N);
    for (int n = 0; n < sig.N; ++n) {
        const int b = sig.bitsPad[n / sig.frame.spb];
        s[n] = (b ? cfg.Ac : cfg.Ac * cfg.askLow) * sig.cosC[n];
    }
    return s;
}

Vec bpskModulate(const Signal& sig, const Config& cfg) {
    Vec s(sig.N);
    for (int n = 0; n < sig.N; ++n) {
        const int b = sig.bitsPad[n / sig.frame.spb];
        s[n] = (b ? cfg.Ac : -cfg.Ac) * sig.cosC[n];
    }
    return s;
}

// 16-QAM per-axis Gray code: 00 -> -3, 01 -> -1, 11 -> +1, 10 -> +3
void qamMap(const int* b, int M, double& I, double& Q) {
    if (M == 4) { I = b[0] ? 1 : -1; Q = b[1] ? 1 : -1; return; }
    static const double lut[4] = {-3, -1, 3, 1};   // index = 2*b1 + b2
    I = lut[2 * b[0] + b[1]];
    Q = lut[2 * b[2] + b[3]];
}

double qamSlice(double v, int M) {
    if (M == 4) return v >= 0 ? 1 : -1;
    return v < -2 ? -3 : (v < 0 ? -1 : (v < 2 ? 1 : 3));
}

void qamLevelToBits(double level, int M, int* out) {
    if (M == 4) { out[0] = level > 0; return; }
    out[0] = level > 0;
    out[1] = std::fabs(level) == 1.0;
}

Modulated qamModulate(const Signal& sig, const Config& cfg) {
    Modulated r;
    const int M = cfg.qamOrder, k = sig.frame.k, ns = sig.frame.nbp / k, sps = sig.frame.sps;
    r.Es = (M == 4) ? 2.0 : 10.0;
    r.I.resize(ns); r.Q.resize(ns);
    for (int j = 0; j < ns; ++j) qamMap(&sig.bitsPad[j * k], M, r.I[j], r.Q[j]);
    const double g = cfg.Ac / std::sqrt(r.Es);
    r.s.resize(sig.N);
    for (int n = 0; n < sig.N; ++n) {
        const int j = n / sps;
        r.s[n] = g * (r.I[j] * sig.cosC[n] - r.Q[j] * sig.sinC[n]);
    }
    return r;
}

Modulated modulate(const Signal& sig, const Config& cfg) {
    Modulated r;
    switch (cfg.modulation) {
        case ModType::AM:   r.s = amModulate(sig, cfg); break;
        case ModType::FM:   r.s = fmModulate(sig, cfg); break;
        case ModType::ASK:  r.s = askModulate(sig, cfg); break;
        case ModType::BPSK: r.s = bpskModulate(sig, cfg); break;
        case ModType::QAM:  r = qamModulate(sig, cfg); break;
    }
    double p = 0; for (double v : r.s) p += v * v;
    r.power = p / r.s.size();
    return r;
}

} // namespace dsp
