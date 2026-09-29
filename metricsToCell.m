function C = metricsToCell(S)
%METRICSTOCELL Two-column {name, value} cell array for display in tables.
C = cell(0, 2);
if ~stageDone(S, 'noise'), return; end
C(end+1, :) = {'Channel SNR (dB)', sprintf('%.3f', S.noise.snrMeasured)};
C(end+1, :) = {'Noise sigma', sprintf('%.4g', S.noise.sigma)};
if S.sig.digital, C(end+1, :) = {'Eb/N0 (dB)', sprintf('%.3f', S.noise.ebn0Measured)}; end
if stageDone(S, 'filter'), C(end+1, :) = {'SNR after filter (dB)', sprintf('%.3f', S.snrAfterFilter)}; end
if ~stageDone(S, 'demodulate'), return; end
m = S.metrics;
if S.sig.digital
    C(end+1, :) = {'Bit error rate', sprintf('%.4g', m.BER)};
    C(end+1, :) = {'Bit accuracy (%)', sprintf('%.3f', m.accuracy)};
    C(end+1, :) = {'Bit errors', sprintf('%d / %d', m.bitErrors, m.numBits)};
    C(end+1, :) = {'Symbol error rate', sprintf('%.4g', m.SER)};
    C(end+1, :) = {'Soft-symbol MSE', sprintf('%.4g', m.MSE)};
else
    C(end+1, :) = {'MSE', sprintf('%.4g', m.MSE)};
    C(end+1, :) = {'RMSE', sprintf('%.4g', m.RMSE)};
    C(end+1, :) = {'Output SNR (dB)', sprintf('%.3f', m.outputSNR)};
    C(end+1, :) = {'Correlation', sprintf('%.5f', m.correlation)};
end
end
