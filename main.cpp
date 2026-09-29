// main.cpp - command-line front end for the C++ DSP engine
//
//   dsp_app [--mod AM|FM|ASK|BPSK|QAM] [--snr dB] [--ebn0] [--qam 4|16]
//           [--bits 1011...] [--random N] [--filter low|high|band|none|auto]
//           [--order N] [--cutoff Hz] [--band f1 f2] [--csv prefix]
//   dsp_app --compare        all five modulations at the current settings
//   dsp_app --sweep [--csv prefix]   BER / accuracy / MSE vs SNR (0:5:30 dB)
//   dsp_app --test           built-in test cases
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iostream>
#include <random>
#include <string>
#include "Metrics.h"
#include "Pipeline.h"

using namespace dsp;

// Formats a number, or "-" when the metric does not apply (NaN)
static std::string num(double v, const char* fmt = "%.4g") {
    if (std::isnan(v)) return "-";
    char buf[32]; std::snprintf(buf, sizeof buf, fmt, v); return buf;
}

static void printMetrics(const PipelineResult& R) {
    const Metrics& m = R.metrics;
    std::printf("\n=== %s ===\n", m.modulation.c_str());
    for (const auto& l : R.log) std::printf("%s\n", l.c_str());
    std::printf("Channel SNR (measured)  : %8.3f dB\n", m.snrMeasured);
    std::printf("SNR after filter        : %8.3f dB\n", m.snrAfterFilter);
    std::printf("Dominant components     :");
    for (size_t i = 0; i < R.specModulated.peakFreq.size(); ++i) std::printf(" %.1f Hz", R.specModulated.peakFreq[i]);
    std::printf("  (modulated, %zu-point FFT)\n", R.specModulated.nfft);
    if (R.sig.digital) {
        std::printf("Eb/N0 (measured)        : %8.3f dB\n", m.ebn0Measured);
        std::printf("Bit errors              : %d / %d\n", m.bitErrors, m.numBits);
        std::printf("BER                     : %.6g\n", m.BER);
        std::printf("Accuracy                : %.4f %%\n", m.accuracy);
        std::printf("SER                     : %.6g\n", m.SER);
        std::printf("Soft-symbol MSE         : %.6g\n", m.MSE);
        std::printf("Tx bits : "); for (int i = 0; i < std::min(m.numBits, 64); ++i) std::printf("%d", R.sig.bits[i]); std::printf("\n");
        std::printf("Rx bits : "); for (int i = 0; i < std::min(m.numBits, 64); ++i) std::printf("%d", R.digital.rxBits[i]); std::printf("\n");
    } else {
        std::printf("MSE                     : %.6g\n", m.MSE);
        std::printf("RMSE                    : %.6g\n", m.RMSE);
        std::printf("Output SNR              : %.3f dB\n", m.outputSNR);
        std::printf("Correlation             : %.6f\n", m.correlation);
    }
}

static void writeCsv(const PipelineResult& R, const std::string& prefix) {
    std::ofstream f(prefix + "_signals.csv");
    f << "t,message,carrier,modulated,noisy,filtered,recovered\n";
    for (int n = 0; n < R.sig.N; ++n)
        f << R.sig.t[n] << ',' << R.sig.msg[n] << ',' << R.sig.carrier[n] << ',' << R.mod.s[n] << ','
          << R.noise.noisy[n] << ',' << R.filtered[n] << ',' << R.recovered[n] << '\n';
    std::ofstream s(prefix + "_spectrum.csv");
    s << "f,modulated,noisy,filtered,recovered\n";
    for (size_t k = 0; k < R.specNoisy.f.size(); ++k)
        s << R.specNoisy.f[k] << ',' << R.specModulated.mag[k] << ',' << R.specNoisy.mag[k] << ','
          << R.specFiltered.mag[k] << ',' << R.specRecovered.mag[k] << '\n';
    if (R.sig.digital) {
        std::ofstream c(prefix + "_constellation.csv");
        c << "idealI,idealQ,noisyI,noisyQ,recoveredI,recoveredQ,symbolError\n";
        for (size_t j = 0; j < R.digital.softI.size(); ++j)
            c << R.digital.idealI[j] << ',' << R.digital.idealQ[j] << ',' << R.digital.noisyI[j] << ',' << R.digital.noisyQ[j]
              << ',' << R.digital.softI[j] << ',' << R.digital.softQ[j] << ',' << R.digital.symbolError[j] << '\n';
    }
    std::printf("CSV written with prefix '%s'\n", prefix.c_str());
}

static void compareAll(const Config& base) {
    std::printf("\n%-8s %10s %10s %10s %10s %10s %10s %10s\n", "Mod", "SNR(dB)", "BER", "Acc(%)", "SER", "MSE", "OutSNR", "Corr");
    for (ModType m : {ModType::AM, ModType::FM, ModType::ASK, ModType::BPSK, ModType::QAM}) {
        Config c = base; c.modulation = m;
        if (!isDigital(m)) c.snrIsEbN0 = false;
        c = recommendedFilter(c);
        try {
            const Metrics r = runPipeline(c).metrics;
            std::printf("%-8s %10.3f %10s %10s %10s %10s %10s %10s\n", r.modulation.c_str(), r.snrMeasured,
                        num(r.BER).c_str(), num(r.accuracy, "%.3f").c_str(), num(r.SER).c_str(), num(r.MSE).c_str(),
                        num(r.outputSNR, "%.3f").c_str(), num(r.correlation, "%.5f").c_str());
        } catch (const std::exception& e) {
            std::printf("%-8s skipped: %s\n", toString(m).c_str(), e.what());
        }
    }
}

static void sweep(const Config& base, const std::string& prefix, bool ebn0Axis) {
    std::ofstream csv(prefix.empty() ? "sweep.csv" : prefix + "_sweep.csv");
    csv << "modulation,snr_db,axis,measured_snr_db,ber,theory_ber,accuracy,ser,mse\n";
    std::printf("\n%-8s %6s %12s %12s %10s %10s\n", "Mod", "SNR", "BER", "Theory", "Acc(%)", "MSE");
    std::mt19937 rng(base.dataSeed + 101);
    std::bernoulli_distribution coin(0.5);
    std::vector<int> bits(2000);
    for (int& b : bits) b = coin(rng);
    for (ModType m : {ModType::AM, ModType::FM, ModType::ASK, ModType::BPSK, ModType::QAM}) {
        Config c = base; c.modulation = m; c.noiseBySigma = false;
        if (isDigital(m)) {
            Config t = base; t.modulation = ModType::BPSK;
            c.bitsOverride = bits;
            c.spbOverride = std::max({deriveDigital(t).spb, 8, static_cast<int>(std::ceil(4 * c.fs / c.fc))});
            c.snrIsEbN0 = ebn0Axis;
        } else c.snrIsEbN0 = false;
        c = recommendedFilter(c);
        for (int si = 0; si <= 6; ++si) {
            c.snrDb = 5.0 * si;
            c.noiseSeed = base.noiseSeed + 17 * si + 3;
            try {
                const PipelineResult R = runPipeline(c);
                const Metrics& r = R.metrics;
                double g = std::pow(10.0, c.snrDb / 10.0);
                if (!c.snrIsEbN0) g *= R.sig.frame.spb / 2.0;
                const double th = theoreticalBER(m, g, c.qamOrder, c.askLow);
                std::printf("%-8s %6.1f %12s %12s %10s %10s\n", r.modulation.c_str(), c.snrDb, num(r.BER, "%.5g").c_str(),
                            num(th < 1e-12 ? 0.0 : th, "%.5g").c_str(), num(r.accuracy, "%.3f").c_str(), num(r.MSE).c_str());
                csv << r.modulation << ',' << c.snrDb << ',' << (c.snrIsEbN0 ? "ebn0" : "sample") << ',' << r.snrMeasured << ','
                    << r.BER << ',' << th << ',' << r.accuracy << ',' << r.SER << ',' << r.MSE << '\n';
            } catch (const std::exception& e) {
                std::printf("%-8s skipped: %s\n", toString(m).c_str(), e.what());
                break;
            }
        }
    }
    std::printf("Sweep written to %s\n", prefix.empty() ? "sweep.csv" : (prefix + "_sweep.csv").c_str());
}

static int runTests() {
    int pass = 0, total = 0;
    auto check = [&](const char* name, bool ok, const std::string& info) {
        ++total; pass += ok;
        std::printf("[%s] %-44s %s\n", ok ? "PASS" : "FAIL", name, info.c_str());
    };
    Config cfg;
    // 1 FFT of the message
    Signal s = generateSignal(cfg);
    Spectrum sp = computeSpectrum(s.msg, cfg.fs);
    check("FFT peak at message frequency", std::fabs(sp.peakFreq[0] - cfg.fm) <= sp.df, std::to_string(sp.peakFreq[0]));
    // 2 FFT round trip
    std::vector<Complex> a(8); for (int i = 0; i < 8; ++i) a[i] = i; auto b = a; fft(b); fft(b, true);
    double err = 0; for (int i = 0; i < 8; ++i) err += std::abs(a[i] - b[i]);
    check("FFT / IFFT round trip", err < 1e-12, std::to_string(err));
    // 3 filters
    IIRFilter bp = designFilter(FilterType::BandPass, 4, 850, 1150, cfg.fs);
    check("Band-pass: unity at 1000 Hz, < 1% at 700/1300 Hz",
          std::fabs(filterMagnitude(bp, 1000) - 1) < 1e-3 && filterMagnitude(bp, 700) < 0.01 && filterMagnitude(bp, 1300) < 0.01, "");
    IIRFilter lp = designFilter(FilterType::LowPass, 4, 500, 0, cfg.fs);
    check("Low-pass |H|^2 = 0.5 at cutoff", std::fabs(filterMagnitude(lp, 500) - 0.5) < 1e-6, std::to_string(filterMagnitude(lp, 500)));
    // 4 analog reconstruction
    for (ModType m : {ModType::AM, ModType::FM}) {
        Config c = cfg; c.modulation = m; c = recommendedFilter(c);
        c.snrDb = 5; const double lo = runPipeline(c).metrics.MSE;
        c.snrDb = 30; const Metrics hi = runPipeline(c).metrics;
        check((toString(m) + " MSE falls with SNR, corr > 0.99").c_str(), hi.MSE < lo && hi.correlation > 0.99,
              std::to_string(lo) + " -> " + std::to_string(hi.MSE));
    }
    // 5 digital, high SNR
    for (ModType m : {ModType::ASK, ModType::BPSK, ModType::QAM}) {
        Config c = cfg; c.modulation = m; c.snrDb = 30; c = recommendedFilter(c);
        check((toString(m) + " BER = 0 at 30 dB").c_str(), runPipeline(c).metrics.BER == 0, "");
    }
    // 6 BPSK vs theory
    {
        Config c = cfg; c.modulation = ModType::BPSK; c.snrIsEbN0 = true; c.snrDb = 4; c.spbOverride = 100;
        std::mt19937 rng(1); std::bernoulli_distribution coin(0.5);
        c.bitsOverride.resize(10000); for (int& bit : c.bitsOverride) bit = coin(rng);
        c = recommendedFilter(c);
        const double ber = runPipeline(c).metrics.BER, th = theoreticalBER(ModType::BPSK, std::pow(10, 0.4), 4, 0);
        check("BPSK BER within 25% of theory at 4 dB", std::fabs(ber - th) / th < 0.25, std::to_string(ber) + " vs " + std::to_string(th));
    }
    // 7 16-QAM noiseless
    {
        Config c = cfg; c.modulation = ModType::QAM; c.qamOrder = 16; c.noiseBySigma = true; c.noiseSigma = 0;
        c.bits = "0001001101111111101010001100"; c = recommendedFilter(c);
        check("16-QAM noiseless round trip", runPipeline(c).metrics.BER == 0, "");
    }
    // 8 validation
    {
        Config c1 = cfg; c1.fs = 1500;
        Config c2 = cfg; c2.duration = -1;
        Config c3 = cfg; c3.modulation = ModType::BPSK; c3.bits = "10201";
        Config c4 = cfg; c4.bandLow = 1200; c4.bandHigh = 900;
        check("Validation rejects bad inputs", !validateConfig(c1).ok() && !validateConfig(c2).ok() &&
              !validateConfig(c3).ok() && !validateConfig(c4).ok(), "");
    }
    // 9 reproducibility
    {
        Config c = recommendedFilter(cfg);
        check("Same seed gives identical MSE", runPipeline(c).metrics.MSE == runPipeline(c).metrics.MSE, "");
    }
    std::printf("\n%d of %d tests passed.\n", pass, total);
    return pass == total ? 0 : 1;
}

int main(int argc, char** argv) {
    Config cfg;
    std::string csv;
    bool doCompare = false, doSweep = false, autoFilter = true, sweepSample = false;
    try {
        for (int i = 1; i < argc; ++i) {
            const std::string a = argv[i];
            auto next = [&]() -> std::string {
                if (i + 1 >= argc) throw std::invalid_argument("Missing value after " + a);
                return argv[++i];
            };
            if (a == "--mod") cfg.modulation = parseModType(next());
            else if (a == "--snr") cfg.snrDb = std::stod(next());
            else if (a == "--ebn0") cfg.snrIsEbN0 = true;
            else if (a == "--sigma") { cfg.noiseBySigma = true; cfg.noiseSigma = std::stod(next()); }
            else if (a == "--fs") cfg.fs = std::stod(next());
            else if (a == "--duration") cfg.duration = std::stod(next());
            else if (a == "--fm") cfg.fm = std::stod(next());
            else if (a == "--fc") cfg.fc = std::stod(next());
            else if (a == "--mu") cfg.mu = std::stod(next());
            else if (a == "--dev") cfg.freqDev = std::stod(next());
            else if (a == "--qam") cfg.qamOrder = std::stoi(next());
            else if (a == "--bits") cfg.bits = next();
            else if (a == "--random") { cfg.useRandomBits = true; cfg.numRandomBits = std::stoi(next()); }
            else if (a == "--seed") cfg.noiseSeed = static_cast<unsigned>(std::stoul(next()));
            else if (a == "--order") cfg.filterOrder = std::stoi(next());
            else if (a == "--cutoff") cfg.cutoff = std::stod(next());
            else if (a == "--band") { cfg.bandLow = std::stod(next()); cfg.bandHigh = std::stod(next()); }
            else if (a == "--filter") {
                const std::string f = next(); autoFilter = (f == "auto");
                if (f == "low") cfg.filterType = FilterType::LowPass;
                else if (f == "high") cfg.filterType = FilterType::HighPass;
                else if (f == "band") cfg.filterType = FilterType::BandPass;
                else if (f == "none") cfg.filterType = FilterType::None;
                else if (f != "auto") throw std::invalid_argument("Unknown filter '" + f + "'.");
            }
            else if (a == "--csv") csv = next();
            else if (a == "--compare") doCompare = true;
            else if (a == "--sweep") doSweep = true;
            else if (a == "--sample-axis") sweepSample = true;
            else if (a == "--test") return runTests();
            else if (a == "--help" || a == "-h") {
                std::printf("See the header of main.cpp or README.md for options.\n"); return 0;
            } else throw std::invalid_argument("Unknown option '" + a + "'. Use --help.");
        }
        if (doSweep) { sweep(cfg, csv, !sweepSample); return 0; }
        if (doCompare) { compareAll(cfg); return 0; }
        if (autoFilter) cfg = recommendedFilter(cfg);
        const Validation v = validateConfig(cfg);
        for (const auto& e : v.errors) std::fprintf(stderr, "Error: %s\n", e.c_str());
        if (!v.ok()) return 2;
        const PipelineResult R = runPipeline(cfg);
        printMetrics(R);
        if (!csv.empty()) writeCsv(R, csv);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "Error: %s\n", e.what());
        return 2;
    }
    return 0;
}
