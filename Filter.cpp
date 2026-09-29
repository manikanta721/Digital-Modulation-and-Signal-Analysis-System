// Filter.cpp - bilinear-transform Butterworth design (pre-warped edges)
#include "Filter.h"
#include <algorithm>
#include <cmath>
#include <complex>
#include <sstream>
#include <stdexcept>

namespace dsp {

static std::vector<Biquad> butterLowHigh(bool low, double fc, double fs, int order) {
    std::vector<Biquad> sos;
    const double w0 = 2 * M_PI * fc / fs, cw = std::cos(w0), sw = std::sin(w0);
    for (int k = 0; k < order / 2; ++k) {                       // conjugate pole pairs
        const double Q = 1.0 / (2.0 * std::sin(M_PI * (2 * k + 1) / (2.0 * order)));
        const double al = sw / (2 * Q), a0 = 1 + al;
        Biquad b;
        if (low) { b.b0 = (1 - cw) / 2; b.b1 = 1 - cw;    b.b2 = (1 - cw) / 2; }
        else     { b.b0 = (1 + cw) / 2; b.b1 = -(1 + cw); b.b2 = (1 + cw) / 2; }
        b.b0 /= a0; b.b1 /= a0; b.b2 /= a0;
        b.a1 = -2 * cw / a0; b.a2 = (1 - al) / a0;
        sos.push_back(b);
    }
    if (order % 2) {                                              // real pole
        const double K = std::tan(w0 / 2), a1 = (K - 1) / (K + 1);
        if (low) { const double b0 = K / (1 + K); sos.push_back({b0, b0, 0, a1, 0}); }
        else     { const double b0 = 1 / (1 + K); sos.push_back({b0, -b0, 0, a1, 0}); }
    }
    return sos;
}

static double sosMag2(const std::vector<Biquad>& sos, double f, double fs) {
    const std::complex<double> z1 = std::polar(1.0, -2 * M_PI * f / fs), z2 = z1 * z1;
    std::complex<double> H = 1.0;
    for (const auto& s : sos) H *= (s.b0 + s.b1 * z1 + s.b2 * z2) / (1.0 + s.a1 * z1 + s.a2 * z2);
    return std::norm(H);
}

// Low-pass prototype -> band-pass transform -> bilinear transform
static std::vector<Biquad> butterBand(double f1, double f2, double fs, int order) {
    using C = std::complex<double>;
    const double W1 = 2 * fs * std::tan(M_PI * f1 / fs), W2 = 2 * fs * std::tan(M_PI * f2 / fs);
    const double w0sq = W1 * W2, B = W2 - W1;
    std::vector<C> zp;
    for (int k = 0; k < order; ++k) {
        const C p = std::polar(1.0, M_PI * (2 * k + order + 1) / (2.0 * order));
        const C root = std::sqrt(p * B * p * B - 4.0 * w0sq);
        for (int sg : {1, -1}) {
            const C s = (p * B + double(sg) * root) / 2.0;
            const C z = (2 * fs + s) / (2 * fs - s);
            if (z.imag() > 1e-12) zp.push_back(z);
        }
    }
    if (static_cast<int>(zp.size()) != order) {                  // very wide band: fallback
        auto hp = butterLowHigh(false, f1, fs, order), lp = butterLowHigh(true, f2, fs, order);
        hp.insert(hp.end(), lp.begin(), lp.end());
        return hp;
    }
    std::vector<Biquad> sos;
    for (const C& z : zp) sos.push_back({1, 0, -1, -2 * z.real(), std::norm(z)});
    const double wc = 2 * std::atan(std::sqrt(w0sq) / (2 * fs)) * fs / (2 * M_PI);
    const double g = std::sqrt(sosMag2(sos, wc, fs));
    sos[0].b0 /= g; sos[0].b1 /= g; sos[0].b2 /= g;               // unity gain at centre
    return sos;
}

IIRFilter designFilter(FilterType type, int order, double f1, double f2, double fs) {
    IIRFilter f;
    f.type = type; f.order = order; f.fs = fs;
    if (type == FilterType::None) return f;
    const double nyq = fs / 2;
    if (order < 1 || order > 10) throw std::invalid_argument("Filter order must be 1..10.");
    if (type == FilterType::BandPass) {
        if (!(f1 > 0 && f2 > f1 && f2 < nyq)) throw std::invalid_argument("Band-pass edges must satisfy 0 < f1 < f2 < fs/2.");
        f.edges = {f1, f2};
        f.sections = butterBand(f1, f2, fs, order);
    } else {
        if (!(f1 > 0 && f1 < nyq)) throw std::invalid_argument("Cutoff must be between 0 and fs/2.");
        f.edges = {f1};
        f.sections = butterLowHigh(type == FilterType::LowPass, f1, fs, order);
    }
    return f;
}

std::string IIRFilter::description() const {
    if (type == FilterType::None) return "No filter (bypass)";
    std::ostringstream os;
    os << (type == FilterType::LowPass ? "Low-pass" : type == FilterType::HighPass ? "High-pass" : "Band-pass")
       << " Butterworth, order " << order << ", ";
    for (size_t i = 0; i < edges.size(); ++i) os << (i ? "-" : "") << edges[i];
    os << " Hz";
    return os.str();
}

Vec sosFilter(const std::vector<Biquad>& sos, const Vec& x) {
    Vec y(x);
    for (const auto& s : sos) {                                   // transposed direct form II
        double z1 = 0, z2 = 0;
        for (double& v : y) {
            const double in = v, out = s.b0 * in + z1;
            z1 = s.b1 * in - s.a1 * out + z2;
            z2 = s.b2 * in - s.a2 * out;
            v = out;
        }
    }
    return y;
}

Vec applyFilter(const IIRFilter& f, const Vec& x) {
    if (f.empty() || x.size() < 3) return x;
    const long n = static_cast<long>(x.size());
    const double minEdge = *std::min_element(f.edges.begin(), f.edges.end());
    long pad = std::max<long>(12L * f.order, std::lround(3 * f.fs / minEdge));
    pad = std::min(pad, n - 1);
    Vec ext;
    ext.reserve(n + 2 * pad);
    for (long i = pad; i >= 1; --i) ext.push_back(x[i]);             // mirror padding
    ext.insert(ext.end(), x.begin(), x.end());
    for (long i = n - 2; i >= n - 1 - pad; --i) ext.push_back(x[i]);
    ext = sosFilter(f.sections, ext);
    std::reverse(ext.begin(), ext.end());
    ext = sosFilter(f.sections, ext);
    std::reverse(ext.begin(), ext.end());
    return Vec(ext.begin() + pad, ext.begin() + pad + n);
}

double filterMagnitude(const IIRFilter& f, double freq) {
    return f.empty() ? 1.0 : sosMag2(f.sections, freq, f.fs);
}

Vec lowpassZeroPhase(const Vec& x, double fc, double fs, int order) {
    return applyFilter(designFilter(FilterType::LowPass, order, fc, 0, fs), x);
}

} // namespace dsp
