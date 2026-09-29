// Metrics.h - signal-quality and error-rate measurements
#pragma once
#include "SignalGenerator.h"

namespace dsp {

double calculateMSE(const Vec& ref, const Vec& est, size_t from = 0, size_t to = 0);
double calculateRMSE(const Vec& ref, const Vec& est, size_t from = 0, size_t to = 0);
double calculateSNR(const Vec& ref, const Vec& est, size_t from = 0, size_t to = 0);   // dB
double calculateCorrelation(const Vec& x, const Vec& y, size_t from = 0, size_t to = 0);
// Returns BER; numErrors receives the error count. Compares the first tx.size() bits.
double calculateBER(const std::vector<int>& tx, const std::vector<int>& rx, int& numErrors);
double qFunction(double x);
double theoreticalBER(ModType m, double ebn0Linear, int qamOrder, double askLow);

} // namespace dsp
