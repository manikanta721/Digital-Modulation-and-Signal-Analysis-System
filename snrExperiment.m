function [T, R] = snrExperiment(cfg, showPlots)
%SNREXPERIMENT BER / accuracy / MSE versus SNR for every modulation.
%   [T, R] = snrExperiment(cfg, showPlots)
%   For each SNR in cfg.snrList: generate -> add noise -> filter ->
%   demodulate -> measure. Digital schemes use cfg.sweepBits random bits
%   and, by default, an Eb/N0 axis (cfg.sweepAxis = 'ebn0'); set it to
%   'sample' to use per-sample SNR. Every scheme uses its recommended filter.
if nargin < 1 || isempty(cfg), cfg = config(); end
if nargin < 2, showPlots = true; end
mods = {'AM', 'FM', 'ASK', 'BPSK', 'QAM'};
snrs = cfg.snrList;
rows = {}; R = struct();
for mi = 1:numel(mods)
    c = cfg; c.modulation = mods{mi}; c.noiseMode = 'snr';
    if isDigital(c.modulation)
        c.snrReference = cfg.sweepAxis;
        tmp = c; tmp.modulation = 'BPSK'; d0 = deriveDigital(tmp);
        spb = max([d0.spb, 8, ceil(4*c.fs/c.fc)]);          % >= 4 carrier cycles per bit
        nb = min(cfg.sweepBits, floor(2e6/spb));
        s = RandStream('mt19937ar', 'Seed', cfg.dataSeed + 101);
        c.bitsOverride = double(rand(s, 1, nb) < 0.5);
        c.spbOverride = spb;
    else
        c.snrReference = 'sample'; spb = NaN;
    end
    c = recommendedFilter(c);
    errs = validateConfig(c);
    if ~isempty(errs)
        warning('snrExperiment:skip', '%s skipped: %s', mods{mi}, errs{1});
        continue;
    end
    res = struct('snr', snrs, 'BER', nan(size(snrs)), 'accuracy', nan(size(snrs)), ...
                 'SER', nan(size(snrs)), 'MSE', nan(size(snrs)), 'spb', spb);
    for si = 1:numel(snrs)
        c.snrDb = snrs(si);
        c.noiseSeed = cfg.noiseSeed + 17*(si-1) + 3;
        S = runPipeline(c); m = S.metrics;
        res.BER(si) = m.BER; res.accuracy(si) = m.accuracy; res.SER(si) = m.SER; res.MSE(si) = m.MSE;
        rows(end+1, :) = {mods{mi}, snrs(si), m.snrMeasured, m.BER, m.accuracy, m.SER, m.MSE, m.correlation}; %#ok<AGROW>
    end
    R.(mods{mi}) = res;
end
T = cell2table(rows, 'VariableNames', {'Modulation', 'SNR_dB', 'MeasuredSNR_dB', 'BER', ...
    'Accuracy_pct', 'SER', 'MSE', 'Correlation'});
if showPlots, plotPerformance(R, cfg); end
end
