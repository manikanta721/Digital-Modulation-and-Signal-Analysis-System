// Demodulation.cpp
#include "Demodulation.h"
#include "Filter.h"
#include <algorithm>
#include <cmath>

namespace dsp {

// Final message low-pass, DC block (edges excluded) and amplitude scaling
static Vec reconstruct(Vec mhat, double cutIQ, const Config& cfg, double& cutMsg) {
    cutMsg = std::min(3 * cfg.fm, cutIQ);
    mhat = lowpassZeroPhase(mhat, cutMsg, cfg.fs, 4);
    const size_t N = mhat.size(), a = N / 20, b = N - N / 20;
    double mean = 0; for (size_t i = a; i < b; ++i) mean += mhat[i]; mean /= (b - a);
    for (double& v : mhat) v = cfg.Am * (v - mean);
    return mhat;
}

static void downconvert(const Vec& r, const Signal& sig, double cut, double fs, Vec& I, Vec& Q) {
    I.resize(r.size()); Q.resize(r.size());
    for (size_t n = 0; n < r.size(); ++n) { I[n] = 2 * r[n] * sig.cosC[n]; Q[n] = -2 * r[n] * sig.sinC[n]; }
    I = lowpassZeroPhase(I, cut, fs, 4);
    Q = lowpassZeroPhase(Q, cut, fs, 4);
}

AnalogResult amDemodulate(const Vec& r, const Signal& sig, const Config& cfg) {
    AnalogResult res;
    res.detector = "Envelope detector (I/Q magnitude)";
    res.cutIQ = std::min({5 * cfg.fm, 0.8 * cfg.fc, 0.45 * cfg.fs});
    Vec I, Q; downconvert(r, sig, res.cutIQ, cfg.fs, I, Q);
    Vec mhat(r.size());
    for (size_t n = 0; n < r.size(); ++n) mhat[n] = (std::hypot(I[n], Q[n]) / cfg.Ac - 1) / cfg.mu;
    res.recovered = reconstruct(mhat, res.cutIQ, cfg, res.cutMsg);
    return res;
}

AnalogResult fmDemodulate(const Vec& r, const Signal& sig, const Config& cfg) {
    AnalogResult res;
    res.detector = "Quadrature phase discriminator";
    const double B = cfg.freqDev + cfg.fm;
    res.cutIQ = std::max(std::min({1.5 * B + cfg.fm, 2 * cfg.fc - 1.5 * B - cfg.fm, 0.45 * cfg.fs}), 1.05 * cfg.fm);
    Vec I, Q; downconvert(r, sig, res.cutIQ, cfg.fs, I, Q);
    const size_t N = r.size();
    Vec ph(N);                                                   // unwrapped phase
    double prev = std::atan2(Q[0], I[0]), offset = 0; ph[0] = prev;
    for (size_t n = 1; n < N; ++n) {
        const double p = std::atan2(Q[n], I[n]), d = p - prev;
        if (d > M_PI) offset -= 2 * M_PI; else if (d < -M_PI) offset += 2 * M_PI;
        prev = p; ph[n] = p + offset;
    }
    const double g = cfg.fs / (2 * M_PI * cfg.freqDev);
    Vec mhat(N);
    for (size_t n = 1; n + 1 < N; ++n) mhat[n] = (ph[n + 1] - ph[n - 1]) / 2 * g;   // central difference
    mhat[0] = (ph[1] - ph[0]) * g; mhat[N - 1] = (ph[N - 1] - ph[N - 2]) * g;
    res.recovered = reconstruct(mhat, res.cutIQ, cfg, res.cutMsg);
    return res;
}

// Integrate-and-dump correlator over one symbol
static void correlate(const Vec& r, const Signal& sig, int j, int sps, double& zi, double& zq) {
    zi = 0; zq = 0;
    for (int n = j * sps; n < (j + 1) * sps; ++n) { zi += r[n] * sig.cosC[n]; zq -= r[n] * sig.sinC[n]; }
    zi *= 2.0 / sps; zq *= 2.0 / sps;
}

DigitalResult digitalDemodulate(const Vec& filtered, const Vec& noisy, const Signal& sig,
                                const Modulated& mod, const Config& cfg) {
    DigitalResult res;
    const int k = sig.frame.k, sps = sig.frame.sps, ns = sig.frame.nbp / k, M = cfg.qamOrder;
    const double scale = cfg.modulation == ModType::QAM ? std::sqrt(mod.Es) / cfg.Ac : 1.0 / cfg.Ac;
    res.rxBits.assign(sig.frame.nbp, 0);
    for (auto* v : {&res.softI, &res.softQ, &res.noisyI, &res.noisyQ, &res.idealI, &res.idealQ}) v->resize(ns);
    res.symbolError.assign(ns, 0);
    for (int j = 0; j < ns; ++j) {
        double zi, zq, ni, nq;
        correlate(filtered, sig, j, sps, zi, zq);
        correlate(noisy, sig, j, sps, ni, nq);
        const double x = zi * scale, y = zq * scale;
        res.softI[j] = x; res.softQ[j] = y; res.noisyI[j] = ni * scale; res.noisyQ[j] = nq * scale;
        int dec[4] = {0, 0, 0, 0};
        if (cfg.modulation == ModType::ASK) {
            res.idealI[j] = sig.bitsPad[j] ? 1.0 : cfg.askLow; res.idealQ[j] = 0;
            dec[0] = x > (1 + cfg.askLow) / 2;
        } else if (cfg.modulation == ModType::BPSK) {
            res.idealI[j] = sig.bitsPad[j] ? 1.0 : -1.0; res.idealQ[j] = 0;
            dec[0] = x > 0;
        } else {
            res.idealI[j] = mod.I[j]; res.idealQ[j] = mod.Q[j];
            qamLevelToBits(qamSlice(x, M), M, dec);
            qamLevelToBits(qamSlice(y, M), M, dec + k / 2);
        }
        for (int m = 0; m < k; ++m) {
            res.rxBits[j * k + m] = dec[m];
            if (dec[m] != sig.bitsPad[j * k + m]) res.symbolError[j] = 1;
        }
    }
    res.recovered.resize(sig.N);
    for (int n = 0; n < sig.N; ++n) res.recovered[n] = res.rxBits[n / sig.frame.spb];
    return res;
}

} // namespace dsp
