// SignalGenerator.h - configuration, message/carrier generation, bit framing
#pragma once
#include <string>
#include <vector>

namespace dsp {

using Vec = std::vector<double>;

enum class ModType { AM, FM, ASK, BPSK, QAM };
enum class FilterType { LowPass, HighPass, BandPass, None };

std::string toString(ModType m);
ModType parseModType(const std::string& s);   // throws std::invalid_argument
bool isDigital(ModType m);

// All user-configurable parameters (defaults match the MATLAB config.m)
struct Config {
    ModType modulation = ModType::AM;
    double fs = 20000.0, duration = 0.1;
    double fm = 50.0, Am = 1.0, fc = 1000.0, Ac = 1.0;
    double mu = 0.5, freqDev = 200.0, askLow = 0.0;
    int qamOrder = 4;
    std::string bits = "101101001011";
    bool useRandomBits = false;
    int numRandomBits = 200;
    unsigned dataSeed = 7;
    std::vector<int> bitsOverride;   // used by the SNR sweep
    int spbOverride = 0;
    bool noiseBySigma = false;
    bool snrIsEbN0 = false;          // digital only
    double snrDb = 10.0, noiseSigma = 0.1;
    unsigned noiseSeed = 42;
    FilterType filterType = FilterType::BandPass;
    int filterOrder = 4;
    double cutoff = 1500.0, bandLow = 850.0, bandHigh = 1150.0;
};

struct DigitalFraming {
    int nb = 0, k = 1, spb = 0, nbp = 0, sps = 0, N = 0;
    double Rb = 0, Rs = 0;
};

// Sampled message + carrier + references
struct Signal {
    bool digital = false;
    int N = 0;
    double fs = 0;
    Vec t, msg, msgNorm, carrier, cosC, sinC;
    std::vector<int> bits, bitsPad;
    DigitalFraming frame;
};

DigitalFraming deriveDigital(const Config& cfg);
std::vector<int> generateBinaryData(const Config& cfg);
Signal generateSignal(const Config& cfg);   // message m(t) and carrier c(t)

} // namespace dsp
