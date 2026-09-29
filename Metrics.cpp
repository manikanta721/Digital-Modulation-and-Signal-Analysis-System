// Metrics.cpp
#include "Metrics.h"
#include <cmath>
#include <limits>
#include <stdexcept>

namespace dsp {

static void range(const Vec& a, size_t& from, size_t& to) { if (to == 0 || to > a.size()) to = a.size(); if (from >= to) from = 0; }

double calculateMSE(const Vec& ref, const Vec& est, size_t from, size_t to) {
    range(ref, from, to);
    double s = 0; for (size_t i = from; i < to; ++i) { const double e = ref[i] - est[i]; s += e * e; }
    return s / (to - from);
}

double calculateRMSE(const Vec& ref, const Vec& est, size_t from, size_t to) { return std::sqrt(calculateMSE(ref, est, from, to)); }

double calculateSNR(const Vec& ref, const Vec& est, size_t from, size_t to) {
    range(ref, from, to);
    double ps = 0, pe = 0;
    for (size_t i = from; i < to; ++i) { ps += ref[i] * ref[i]; const double e = ref[i] - est[i]; pe += e * e; }
    return pe > 0 ? 10 * std::log10(ps / pe) : std::numeric_limits<double>::infinity();
}

double calculateCorrelation(const Vec& x, const Vec& y, size_t from, size_t to) {
    range(x, from, to);
    const double n = static_cast<double>(to - from);
    double mx = 0, my = 0; for (size_t i = from; i < to; ++i) { mx += x[i]; my += y[i]; }
    mx /= n; my /= n;
    double sxy = 0, sxx = 0, syy = 0;
    for (size_t i = from; i < to; ++i) { const double a = x[i] - mx, b = y[i] - my; sxy += a * b; sxx += a * a; syy += b * b; }
    return (sxx > 0 && syy > 0) ? sxy / std::sqrt(sxx * syy) : std::numeric_limits<double>::quiet_NaN();
}

double calculateBER(const std::vector<int>& tx, const std::vector<int>& rx, int& numErrors) {
    if (rx.size() < tx.size()) throw std::invalid_argument("Received sequence is shorter than transmitted.");
    numErrors = 0;
    for (size_t i = 0; i < tx.size(); ++i) numErrors += (tx[i] != rx[i]);
    return tx.empty() ? 0.0 : static_cast<double>(numErrors) / tx.size();
}

double qFunction(double x) { return 0.5 * std::erfc(x / std::sqrt(2.0)); }

double theoreticalBER(ModType m, double g, int qamOrder, double askLow) {
    switch (m) {
        case ModType::BPSK: return qFunction(std::sqrt(2 * g));
        case ModType::ASK:  return qFunction(std::sqrt(g * (1 - askLow) * (1 - askLow) / (1 + askLow * askLow)));
        case ModType::QAM:  return qamOrder == 4 ? qFunction(std::sqrt(2 * g)) : 0.375 * std::erfc(std::sqrt(0.4 * g));
        default: return std::numeric_limits<double>::quiet_NaN();
    }
}

} // namespace dsp
