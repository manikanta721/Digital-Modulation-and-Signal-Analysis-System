function results = runTests()
%RUNTESTS Automated checks for the MATLAB implementation.
%   results = runTests() prints PASS/FAIL for each case and returns a table.
names = {}; pass = []; detail = {};

% 1. FFT finds the message frequency
cfg = config(); sig = generateMessage(cfg);
sp = fftAnalysis(sig.msg, cfg.fs);
check('FFT peak at message frequency', abs(sp.peakFreq(1) - cfg.fm) <= sp.df, sprintf('peak %.2f Hz', sp.peakFreq(1)));

% 2. AM spectrum has carrier and both sidebands
c = cfg; c.modulation = 'AM'; S = runPipeline(recommendedFilter(c));
pk = sort(S.spectra.modulated.peakFreq);
check('AM spectrum: fc-fm, fc, fc+fm', all(abs(pk - [950 1000 1050]) <= 2*S.spectra.modulated.df), mat2str(round(pk)));

% 3. Band-pass filter: unity gain at centre, strong rejection outside
f = designFilter('bandpass', 4, [850 1150], cfg.fs);
g = filterResponse(f, [1000 700 1300]);
check('Band-pass gain', abs(g(1) - 1) < 1e-3 && g(2) < 0.01 && g(3) < 0.01, mat2str(g, 3));

% 4. Low-pass filter: -3 dB (|H|^2 = 0.5 after zero-phase) at cutoff
f = designFilter('lowpass', 4, 500, cfg.fs);
check('Low-pass cutoff = 0.5 (zero-phase)', abs(filterResponse(f, 500) - 0.5) < 1e-6, sprintf('%.6f', filterResponse(f, 500)));

% 5. Analog reconstruction improves with SNR
for m = {'AM', 'FM'}
    c = cfg; c.modulation = m{1}; c = recommendedFilter(c);
    c.snrDb = 5;  S = runPipeline(c); lo = S.metrics;
    c.snrDb = 30; S = runPipeline(c); hi = S.metrics;
    check([m{1} ' MSE falls with SNR'], hi.MSE < lo.MSE && hi.correlation > 0.99, sprintf('%.3g -> %.3g', lo.MSE, hi.MSE));
end

% 6. Digital schemes are error-free at high SNR
for m = {'ASK', 'BPSK', 'QAM'}
    c = cfg; c.modulation = m{1}; c.snrDb = 30; c = recommendedFilter(c);
    S = runPipeline(c); r = S.metrics;
    check([m{1} ' BER = 0 at 30 dB'], r.BER == 0, sprintf('BER %.3g', r.BER));
end

% 7. BPSK BER matches theory at Eb/N0 = 4 dB
c = cfg; c.modulation = 'BPSK'; c.snrReference = 'ebn0'; c.snrDb = 4;
s = RandStream('mt19937ar', 'Seed', 1); c.bitsOverride = double(rand(s, 1, 10000) < 0.5); c.spbOverride = 100;
c = recommendedFilter(c); S = runPipeline(c); r = S.metrics;
th = theoreticalBER('BPSK', 10^0.4, c);
check('BPSK BER within 25% of theory at 4 dB', abs(r.BER - th)/th < 0.25, sprintf('%.4f vs %.4f', r.BER, th));

% 8. 16-QAM round trip without noise
c = cfg; c.modulation = 'QAM'; c.qamOrder = 16; c.noiseMode = 'sigma'; c.noiseSigma = 0;
c.bits = '0001001101111111101010001100'; c = recommendedFilter(c);
S = runPipeline(c); r = S.metrics;
check('16-QAM noiseless round trip', r.BER == 0, sprintf('BER %.3g', r.BER));

% 9. Validation catches invalid input
c = cfg; c.fs = 1500; e1 = validateConfig(c);
c = cfg; c.duration = -1; e2 = validateConfig(c);
c = cfg; c.modulation = 'BPSK'; c.bits = '10201'; e3 = validateConfig(c);
c = cfg; c.band = [1200 900]; e4 = validateConfig(c);
check('Validation: Nyquist, duration, bits, band', ~isempty(e1) && ~isempty(e2) && ~isempty(e3) && ~isempty(e4), '');

% 10. Reproducibility
c = recommendedFilter(cfg); S1 = runPipeline(c); S2 = runPipeline(c); a = S1.metrics.MSE; b = S2.metrics.MSE;
check('Same seed gives identical results', a == b, sprintf('%.6g', a));

results = table(names(:), pass(:), detail(:), 'VariableNames', {'Test', 'Passed', 'Detail'});
fprintf('\n%d of %d tests passed.\n', sum(pass), numel(pass));

    function check(name, ok, info)
        names{end+1} = name; pass(end+1) = logical(ok); detail{end+1} = info;
        if ok, tag = 'PASS'; else, tag = 'FAIL'; end
        fprintf('[%s] %-45s %s\n', tag, name, info);
    end
end
