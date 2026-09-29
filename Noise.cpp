// Noise.cpp
#include "Noise.h"
#include <cmath>
#include <limits>
#include <random>

namespace dsp {

NoiseResult addAWGN(const Vec& s, const Signal& sig, const Config& cfg) {
    NoiseResult r;
    const size_t N = s.size();
    double Ps = 0; for (double v : s) Ps += v * v; Ps /= N;
    if (cfg.noiseBySigma) r.sigma = cfg.noiseSigma;
    else if (cfg.snrIsEbN0 && sig.digital)
        r.sigma = std::sqrt(Ps * sig.frame.spb / (2.0 * std::pow(10.0, cfg.snrDb / 10.0)));
    else
        r.sigma = std::sqrt(Ps / std::pow(10.0, cfg.snrDb / 10.0));

    std::mt19937 rng(cfg.noiseSeed);
    std::normal_distribution<double> gauss(0.0, 1.0);
    r.noisy.resize(N);
    double Pn = 0;
    for (size_t n = 0; n < N; ++n) {
        const double w = r.sigma * gauss(rng);
        r.noisy[n] = s[n] + w;
        Pn += w * w;
    }
    Pn /= N;
    r.signalPower = Ps; r.noisePower = Pn;
    r.snrMeasuredDb = Pn > 0 ? 10 * std::log10(Ps / Pn) : std::numeric_limits<double>::infinity();
    r.ebn0MeasuredDb = sig.digital && Pn > 0 ? 10 * std::log10(Ps * sig.frame.spb / (2 * Pn))
                                             : std::numeric_limits<double>::quiet_NaN();
    return r;
}

} // namespace dsp
