// Pipeline.h - validation and the complete communication chain
#pragma once
#include <cmath>
#include <string>
#include "Demodulation.h"
#include "FFT.h"
#include "Filter.h"
#include "Noise.h"

namespace dsp {

struct Validation { std::vector<std::string> errors, warnings; bool ok() const { return errors.empty(); } };

struct Metrics {
    std::string modulation;
    double snrSet = 0, snrMeasured = 0, ebn0Measured = 0, snrAfterFilter = 0;
    double BER = NAN, accuracy = NAN, SER = NAN, MSE = NAN, RMSE = NAN, outputSNR = NAN, correlation = NAN;
    int bitErrors = 0, numBits = 0;
};

struct PipelineResult {
    Config cfg;
    Signal sig;
    Modulated mod;
    NoiseResult noise;
    IIRFilter filter;
    Vec filtered, recovered;
    AnalogResult analog;
    DigitalResult digital;
    Spectrum specModulated, specNoisy, specFiltered, specRecovered;
    Metrics metrics;
    std::vector<std::string> log;
};

Validation validateConfig(const Config& cfg);
Config recommendedFilter(Config cfg);
PipelineResult runPipeline(const Config& cfg);   // throws std::invalid_argument on invalid config

} // namespace dsp
