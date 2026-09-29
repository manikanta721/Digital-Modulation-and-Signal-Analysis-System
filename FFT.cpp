// FFT.cpp - iterative Cooley-Tukey radix-2 FFT
#include "FFT.h"
#include <algorithm>
#include <cmath>

namespace dsp {

size_t nextPow2(size_t n) { size_t p = 1; while (p < n) p <<= 1; return p; }

void fft(std::vector<Complex>& a, bool inverse) {
    const size_t n = a.size();
    for (size_t i = 1, j = 0; i < n; ++i) {            // bit-reversal permutation
        size_t bit = n >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(a[i], a[j]);
    }
    for (size_t len = 2; len <= n; len <<= 1) {        // butterflies
        const double ang = 2 * M_PI / len * (inverse ? 1 : -1);
        for (size_t k = 0; k < len / 2; ++k) {
            const Complex w(std::cos(ang * k), std::sin(ang * k));
            for (size_t i = k; i < n; i += len) {
                const Complex u = a[i], v = a[i + len / 2] * w;
                a[i] = u + v;
                a[i + len / 2] = u - v;
            }
        }
    }
    if (inverse) for (auto& v : a) v /= static_cast<double>(n);
}

Spectrum computeSpectrum(const Vec& x, double fs, bool hann, int numPeaks) {
    Spectrum sp;
    const size_t N = x.size();
    sp.nfft = std::max<size_t>(1024, nextPow2(N));
    std::vector<Complex> a(sp.nfft, 0.0);
    double wsum = 0;
    for (size_t n = 0; n < N; ++n) {
        const double w = hann ? 0.5 - 0.5 * std::cos(2 * M_PI * n / (N - 1)) : 1.0;
        a[n] = x[n] * w;
        wsum += w;
    }
    const double cg = wsum / N;                          // coherent gain
    fft(a);
    const size_t half = sp.nfft / 2;
    sp.df = fs / sp.nfft;
    sp.f.resize(half + 1); sp.mag.resize(half + 1);
    for (size_t k = 0; k <= half; ++k) {
        sp.f[k] = k * sp.df;
        sp.mag[k] = std::abs(a[k]) / (N * cg) * ((k > 0 && k < half) ? 2.0 : 1.0);
    }
    // dominant components: local maxima above 5 % of the largest value
    const double mx = *std::max_element(sp.mag.begin(), sp.mag.end());
    std::vector<size_t> cand;
    for (size_t k = 0; k <= half; ++k) {
        const double l = k > 0 ? sp.mag[k - 1] : -1, r = k < half ? sp.mag[k + 1] : -1;
        if (sp.mag[k] >= l && sp.mag[k] > r && sp.mag[k] > 0.05 * mx) cand.push_back(k);
    }
    std::sort(cand.begin(), cand.end(), [&](size_t a1, size_t b1) { return sp.mag[a1] > sp.mag[b1]; });
    for (size_t k : cand) {
        bool farEnough = true;
        for (double pf : sp.peakFreq) if (std::fabs(pf - sp.f[k]) <= 3 * sp.df) farEnough = false;
        if (farEnough) { sp.peakFreq.push_back(sp.f[k]); sp.peakMag.push_back(sp.mag[k]); }
        if (static_cast<int>(sp.peakFreq.size()) >= numPeaks) break;
    }
    return sp;
}

} // namespace dsp
