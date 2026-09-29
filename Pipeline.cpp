// Pipeline.cpp - generate -> modulate -> AWGN -> FFT -> filter -> demodulate -> metrics
#include "Pipeline.h"
#include "Metrics.h"
#include <algorithm>
#include <cmath>
#include <sstream>
#include <stdexcept>

namespace dsp {

static std::string fmtd(double v, int p = 4) { std::ostringstream os; os.precision(p); os << v; return os.str(); }

Validation validateConfig(const Config& c) {
    Validation v;
    auto err = [&](const std::string& s) { v.errors.push_back(s); };
    auto warn = [&](const std::string& s) { v.warnings.push_back(s); };
    const bool analog = !isDigital(c.modulation);
    if (!(c.fs > 0)) err("Sampling frequency must be greater than zero.");
    if (!(c.duration > 0)) err("Signal duration must be positive.");
    if (!(c.fc > 0)) err("Carrier frequency must be greater than zero.");
    if (!(c.Ac > 0)) err("Carrier amplitude must be greater than zero.");
    if (analog && !(c.fm > 0)) err("Message frequency must be greater than zero.");
    if (analog && !(c.Am > 0)) err("Message amplitude must be greater than zero.");
    if (!v.ok()) return v;

    double fmax = 0; long N = 0;
    if (analog) {
        N = std::lround(c.fs * c.duration);
        if (c.modulation == ModType::AM) {
            if (!(c.mu > 0 && c.mu <= 1.5)) err("Modulation index mu must be in (0, 1.5].");
            else if (c.mu > 1) warn("mu > 1 over-modulates the carrier; envelope detection will distort.");
            fmax = c.fc + c.fm;
            if (c.fc <= 2 * c.fm) err("Carrier frequency must be more than twice the message frequency.");
        } else {
            const double B = c.freqDev + c.fm;
            fmax = c.fc + B;
            if (!(c.freqDev > 0)) err("Frequency deviation must be greater than zero.");
            else if (c.fc <= B) err("Carrier frequency must exceed deviation + message frequency (" + fmtd(B) + " Hz).");
            else if (c.fc < 2 * B) warn("Carrier is close to the FM bandwidth; demodulation will be noisier.");
        }
    } else {
        if (c.bitsOverride.empty()) {
            if (c.useRandomBits) {
                if (c.numRandomBits < 2 || c.numRandomBits > 100000) err("Number of random bits must be 2..100000.");
            } else {
                int n = 0;
                for (char ch : c.bits) { if (ch == '0' || ch == '1') ++n; else if (!std::isspace(static_cast<unsigned char>(ch))) { err("The bit sequence may contain only 0 and 1."); break; } }
                if (n < 2 || n > 4096) err("The bit sequence must be 2 to 4096 bits long.");
            }
        }
        if (c.modulation == ModType::ASK && !(c.askLow >= 0 && c.askLow < 1)) err("ASK level for bit 0 must be in [0, 1).");
        if (c.modulation == ModType::QAM && c.qamOrder != 4 && c.qamOrder != 16) err("QAM order must be 4 or 16.");
        if (!v.ok()) return v;
        const DigitalFraming d = deriveDigital(c);
        N = d.N;
        if (d.spb < 4) err("Only " + std::to_string(d.spb) + " samples per bit; increase fs or duration.");
        fmax = c.fc + d.Rs;
        const double cyc = c.fc / d.Rs;
        if (cyc < 1) err("Carrier completes fewer than 1 cycle per symbol; raise fc.");
        else if (cyc < 2) warn("Fewer than 2 carrier cycles per symbol.");
    }
    if (c.fs <= 2 * fmax) err("Sampling frequency (" + fmtd(c.fs) + " Hz) must exceed twice the highest signal frequency (" + fmtd(2 * fmax) + " Hz).");
    if (N < 64) err("At least 64 samples are required.");
    if (N > 5000000) err("Too many samples (limit 5,000,000).");
    if (!c.noiseBySigma) {
        if (!(c.snrDb >= -20 && c.snrDb <= 60)) err("SNR must be between -20 and 60 dB.");
        if (c.snrIsEbN0 && analog) err("Eb/N0 applies to digital schemes only.");
    } else if (!(c.noiseSigma >= 0)) err("Noise sigma must be zero or positive.");
    if (c.filterType != FilterType::None) {
        const double nyq = c.fs / 2;
        if (c.filterOrder < 1 || c.filterOrder > 10) err("Filter order must be 1..10.");
        if (c.filterType == FilterType::BandPass) {
            if (!(c.bandLow > 0 && c.bandHigh > c.bandLow && c.bandHigh < nyq)) err("Band-pass edges must satisfy 0 < low < high < fs/2.");
            else if (c.fc < c.bandLow || c.fc > c.bandHigh) warn("The carrier lies outside the pass band.");
        } else if (!(c.cutoff > 0 && c.cutoff < nyq)) err("Cutoff must be between 0 and fs/2.");
        else if (c.filterType == FilterType::LowPass && c.cutoff < c.fc) warn("Low-pass cutoff is below the carrier.");
        else if (c.filterType == FilterType::HighPass && c.cutoff > c.fc) warn("High-pass cutoff is above the carrier.");
    }
    return v;
}

Config recommendedFilter(Config c) {
    double hb;
    if (c.modulation == ModType::AM) hb = 3 * c.fm;
    else if (c.modulation == ModType::FM) hb = 1.5 * (c.freqDev + c.fm) + c.fm;
    else hb = 2 * deriveDigital(c).Rs;
    const double hi = std::round(std::min(c.fc + hb, 0.95 * c.fs / 2)), lo = std::round(c.fc - hb);
    c.filterOrder = 4;
    if (lo < std::max(1.0, 0.01 * c.fs / 2)) { c.filterType = FilterType::LowPass; c.cutoff = hi; }
    else { c.filterType = FilterType::BandPass; c.bandLow = lo; c.bandHigh = hi; }
    return c;
}

PipelineResult runPipeline(const Config& cfg) {
    const Validation v = validateConfig(cfg);
    if (!v.ok()) {
        std::string msg = "Invalid configuration:";
        for (const auto& e : v.errors) msg += "\n  - " + e;
        throw std::invalid_argument(msg);
    }
    PipelineResult R;
    R.cfg = cfg;
    for (const auto& w : v.warnings) R.log.push_back("[Warning] " + w);

    R.sig = generateSignal(cfg);                                                   // 1-2
    R.log.push_back("[Generate] " + std::to_string(R.sig.N) + " samples at fs = " + fmtd(cfg.fs) + " Hz");
    R.mod = modulate(R.sig, cfg);                                                  // 3
    R.log.push_back("[Modulate] " + toString(cfg.modulation) + ", average power " + fmtd(R.mod.power));
    R.noise = addAWGN(R.mod.s, R.sig, cfg);                                        // 4
    R.log.push_back("[Noise] AWGN sigma " + fmtd(R.noise.sigma) + ", measured SNR " + fmtd(R.noise.snrMeasuredDb) + " dB");
    R.specModulated = computeSpectrum(R.mod.s, cfg.fs);                            // 5
    R.specNoisy = computeSpectrum(R.noise.noisy, cfg.fs);
    R.filter = designFilter(cfg.filterType, cfg.filterOrder,                       // 6
                            cfg.filterType == FilterType::BandPass ? cfg.bandLow : cfg.cutoff, cfg.bandHigh, cfg.fs);
    R.filtered = applyFilter(R.filter, R.noise.noisy);
    R.specFiltered = computeSpectrum(R.filtered, cfg.fs);

    Metrics& m = R.metrics;
    m.modulation = toString(cfg.modulation);
    if (cfg.modulation == ModType::QAM) m.modulation = std::to_string(cfg.qamOrder) + "-QAM";
    m.snrSet = cfg.snrDb;
    m.snrMeasured = R.noise.snrMeasuredDb;
    m.ebn0Measured = R.noise.ebn0MeasuredDb;
    m.snrAfterFilter = calculateSNR(R.mod.s, R.filtered);
    R.log.push_back("[Filter] " + R.filter.description() + ", SNR after filter " + fmtd(m.snrAfterFilter) + " dB");

    if (R.sig.digital) {                                                           // 7-9
        R.digital = digitalDemodulate(R.filtered, R.noise.noisy, R.sig, R.mod, cfg);
        R.recovered = R.digital.recovered;
        m.BER = calculateBER(R.sig.bits, R.digital.rxBits, m.bitErrors);
        m.numBits = static_cast<int>(R.sig.bits.size());
        m.accuracy = 100 * (1 - m.BER);
        int se = 0; for (int e : R.digital.symbolError) se += e;
        m.SER = static_cast<double>(se) / R.digital.symbolError.size();
        m.MSE = calculateMSE(R.digital.idealI, R.digital.softI) + calculateMSE(R.digital.idealQ, R.digital.softQ);
        m.RMSE = std::sqrt(m.MSE);
    } else {
        R.analog = cfg.modulation == ModType::AM ? amDemodulate(R.filtered, R.sig, cfg) : fmDemodulate(R.filtered, R.sig, cfg);
        R.recovered = R.analog.recovered;
        const size_t a = R.sig.N / 20, b = R.sig.N - R.sig.N / 20;                // skip filter edges
        m.MSE = calculateMSE(R.sig.msg, R.recovered, a, b);
        m.RMSE = calculateRMSE(R.sig.msg, R.recovered, a, b);
        m.outputSNR = calculateSNR(R.sig.msg, R.recovered, a, b);
        m.correlation = calculateCorrelation(R.sig.msg, R.recovered, a, b);
    }
    R.specRecovered = computeSpectrum(R.recovered, cfg.fs);
    R.log.push_back("[Demodulate] done");
    return R;
}

} // namespace dsp
