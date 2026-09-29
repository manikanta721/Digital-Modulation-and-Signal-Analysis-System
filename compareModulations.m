function T = compareModulations(cfg)
%COMPAREMODULATIONS Run all five schemes with the same settings and tabulate results.
%   Each scheme uses its recommended band-pass filter. Analog schemes
%   always use the sample-SNR reference.
mods = {'AM', 'FM', 'ASK', 'BPSK', 'QAM'};
rows = {};
for i = 1:numel(mods)
    c = cfg; c.modulation = mods{i};
    if ~isDigital(c.modulation), c.snrReference = 'sample'; end
    c = recommendedFilter(c);
    errs = validateConfig(c);
    if ~isempty(errs)
        warning('compareModulations:skip', '%s skipped: %s', mods{i}, errs{1});
        continue;
    end
    S = runPipeline(c); m = S.metrics;
    name = mods{i}; if strcmp(name, 'QAM'), name = sprintf('%d-QAM', c.qamOrder); end
    rows(end+1, :) = {name, m.snrMeasured, m.BER, m.accuracy, m.SER, m.MSE, m.RMSE, m.outputSNR, m.correlation}; %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'Modulation', 'ChannelSNR_dB', 'BER', 'Accuracy_pct', ...
    'SER', 'MSE', 'RMSE', 'OutputSNR_dB', 'Correlation'});
end
