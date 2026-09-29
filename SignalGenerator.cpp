// SignalGenerator.cpp
#include "SignalGenerator.h"
#include <algorithm>
#include <cmath>
#include <random>
#include <stdexcept>

namespace dsp {

std::string toString(ModType m) {
    switch (m) {
        case ModType::AM: return "AM";
        case ModType::FM: return "FM";
        case ModType::ASK: return "ASK";
        case ModType::BPSK: return "BPSK";
        default: return "QAM";
    }
}

ModType parseModType(const std::string& s) {
    std::string u(s);
    std::transform(u.begin(), u.end(), u.begin(), ::toupper);
    if (u == "AM") return ModType::AM;
    if (u == "FM") return ModType::FM;
    if (u == "ASK") return ModType::ASK;
    if (u == "BPSK") return ModType::BPSK;
    if (u == "QAM") return ModType::QAM;
    throw std::invalid_argument("Unknown modulation '" + s + "'. Use AM, FM, ASK, BPSK or QAM.");
}

bool isDigital(ModType m) { return m == ModType::ASK || m == ModType::BPSK || m == ModType::QAM; }

static int countBits(const std::string& s) {
    return static_cast<int>(std::count_if(s.begin(), s.end(), [](char c) { return c == '0' || c == '1'; }));
}

DigitalFraming deriveDigital(const Config& cfg) {
    DigitalFraming d;
    if (!cfg.bitsOverride.empty()) d.nb = static_cast<int>(cfg.bitsOverride.size());
    else if (cfg.useRandomBits) d.nb = cfg.numRandomBits;
    else d.nb = countBits(cfg.bits);
    d.k = (cfg.modulation == ModType::QAM) ? (cfg.qamOrder == 16 ? 4 : 2) : 1;
    d.spb = cfg.spbOverride > 0 ? cfg.spbOverride
                                : std::max(1, static_cast<int>(std::lround(cfg.fs * cfg.duration / std::max(d.nb, 1))));
    d.nbp = ((d.nb + d.k - 1) / d.k) * d.k;
    d.sps = d.spb * d.k;
    d.N = d.nbp * d.spb;
    d.Rb = cfg.fs / d.spb;
    d.Rs = cfg.fs / d.sps;
    return d;
}

std::vector<int> generateBinaryData(const Config& cfg) {
    std::vector<int> b;
    if (!cfg.bitsOverride.empty()) return cfg.bitsOverride;
    if (cfg.useRandomBits) {
        std::mt19937 rng(cfg.dataSeed);
        std::bernoulli_distribution coin(0.5);
        for (int i = 0; i < cfg.numRandomBits; ++i) b.push_back(coin(rng) ? 1 : 0);
    } else {
        for (char c : cfg.bits) if (c == '0' || c == '1') b.push_back(c == '1');
    }
    return b;
}

Signal generateSignal(const Config& cfg) {
    Signal s;
    s.fs = cfg.fs;
    s.digital = isDigital(cfg.modulation);
    if (s.digital) {
        s.frame = deriveDigital(cfg);
        s.bits = generateBinaryData(cfg);
        s.bitsPad = s.bits;
        s.bitsPad.resize(s.frame.nbp, 0);            // pad the last QAM symbol
        s.N = s.frame.N;
    } else {
        s.N = static_cast<int>(std::lround(cfg.fs * cfg.duration));
    }
    const int N = s.N;
    s.t.resize(N); s.msg.resize(N); s.msgNorm.resize(N);
    s.carrier.resize(N); s.cosC.resize(N); s.sinC.resize(N);
    for (int n = 0; n < N; ++n) {
        const double t = n / cfg.fs;
        const double w = 2.0 * M_PI * cfg.fc * t;
        s.t[n] = t;
        s.cosC[n] = std::cos(w);
        s.sinC[n] = std::sin(w);
        s.carrier[n] = cfg.Ac * s.cosC[n];
        if (s.digital) {
            s.msg[n] = s.bitsPad[n / s.frame.spb];
            s.msgNorm[n] = s.msg[n];
        } else {
            s.msgNorm[n] = std::sin(2.0 * M_PI * cfg.fm * t);
            s.msg[n] = cfg.Am * s.msgNorm[n];
        }
    }
    return s;
}

} // namespace dsp
