function plotFrequencyDomain(S, parent)
%PLOTFREQUENCYDOMAIN Single-sided spectra of all available signals + filter response.
if nargin < 2, parent = []; end
t = prepareLayout(parent, 2, 1, 'Frequency-domain analysis');
cfg = S.cfg; fs = cfg.fs;
names = {'message', 'modulated', 'noisy', 'filtered', 'recovered'};
labels = {'Message', 'Modulated', 'Noisy', 'Filtered', 'Recovered'};
srcStage = {'generate', 'modulate', 'noise', 'filter', 'demodulate'};
colors = [0.9 0.7 0.1; 0.8 0.2 0.5; 0.55 0.6 0.65; 0.2 0.6 0.3; 0.95 0.5 0.1];
switch upper(cfg.modulation)
    case 'AM', fmax = cfg.fc + 8*cfg.fm;
    case 'FM', fmax = cfg.fc + 2*(cfg.freqDev + cfg.fm);
    otherwise, fmax = cfg.fc + 6*S.sig.Rs;
end
fmax = min(fs/2, 1.3*fmax);

ax = nexttile(t); hold(ax, 'on'); leg = {};
for i = 1:numel(names)
    if ~stageDone(S, srcStage{i}), continue; end
    switch names{i}
        case 'message', x = S.sig.msg; case 'modulated', x = S.modulated;
        case 'noisy', x = S.noisy; case 'filtered', x = S.filtered; case 'recovered', x = S.recovered;
    end
    sp = fftAnalysis(x, fs);
    plot(ax, sp.f, 20*log10(max(sp.mag, 1e-6)), 'Color', colors(i,:), 'LineWidth', 1.1);
    leg{end+1} = labels{i}; %#ok<AGROW>
    if strcmp(names{i}, 'modulated')
        plot(ax, sp.peakFreq, 20*log10(sp.peakMag), 'kv', 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
        for k = 1:numel(sp.peakFreq)
            text(ax, sp.peakFreq(k), 20*log10(sp.peakMag(k)) + 4, sprintf('%.0f Hz', sp.peakFreq(k)), ...
                 'HorizontalAlignment', 'center', 'FontSize', 8);
        end
    end
end
hold(ax, 'off'); xlim(ax, [0 fmax]); ylim(ax, [-90 10]);
legend(ax, leg, 'Location', 'northeast');
styleAxes(ax, sprintf('Single-sided magnitude spectrum (f_s = %g Hz, Hann window)', fs), ...
          'Frequency (Hz)', 'Magnitude (dB)');

ax = nexttile(t);
filt = [];
if stageDone(S, 'filter'), filt = S.filter;
elseif ~strcmpi(cfg.filterType, 'none'), filt = designFilter(cfg.filterType, cfg.filterOrder, filterEdges(cfg), fs); end
if isempty(filt)
    placeholder(ax, 'Filter response', 'Filter bypassed');
else
    f = linspace(0, fmax, 800);
    plot(ax, f, 20*log10(max(filterResponse(filt, f), 1e-8)), 'Color', [0.2 0.6 0.3], 'LineWidth', 1.5);
    xline(ax, cfg.fc, '--', 'Carrier');
    ylim(ax, [-80 5]);
    styleAxes(ax, [filt.description ' (zero-phase |H(f)|^2)'], 'Frequency (Hz)', 'Gain (dB)');
end
end
