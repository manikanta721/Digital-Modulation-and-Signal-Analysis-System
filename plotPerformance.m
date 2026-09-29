function plotPerformance(R, cfg, parent)
%PLOTPERFORMANCE BER vs SNR, accuracy vs SNR and MSE vs SNR from snrExperiment.
if nargin < 3, parent = []; end
t = prepareLayout(parent, 1, 3, 'Performance vs SNR');
digital = intersect({'ASK', 'BPSK', 'QAM'}, fieldnames(R), 'stable');
analog = intersect({'AM', 'FM'}, fieldnames(R), 'stable');
if strcmpi(cfg.sweepAxis, 'ebn0'), xl = 'E_b/N_0 (dB)'; else, xl = 'Channel SNR (dB)'; end
colors = lines(5);

ax = nexttile(t); hold(ax, 'on'); leg = {};
for i = 1:numel(digital)
    r = R.(digital{i}); ber = r.BER; ber(ber == 0) = NaN;     % zero errors cannot be drawn on a log axis
    c = colors(i+2, :);
    semilogy(ax, r.snr, ber, 'o-', 'Color', c, 'LineWidth', 1.4, 'MarkerFaceColor', c);
    xs = linspace(min(r.snr), max(r.snr), 200);
    g = 10.^(xs/10); if ~strcmpi(cfg.sweepAxis, 'ebn0'), g = g * r.spb/2; end
    th = theoreticalBER(digital{i}, g, cfg); th(th < 1e-7) = NaN;
    semilogy(ax, xs, th, '--', 'Color', c);
    leg = [leg, {digital{i}, [digital{i} ' theory']}]; %#ok<AGROW>
end
set(ax, 'YScale', 'log'); hold(ax, 'off');
if ~isempty(leg), legend(ax, leg, 'Location', 'southwest'); end
styleAxes(ax, 'BER vs SNR', xl, 'Bit error rate');

ax = nexttile(t); hold(ax, 'on'); leg = {};
for i = 1:numel(digital)
    r = R.(digital{i}); c = colors(i+2, :);
    plot(ax, r.snr, r.accuracy, 'o-', 'Color', c, 'LineWidth', 1.4, 'MarkerFaceColor', c);
    leg{end+1} = digital{i}; %#ok<AGROW>
end
hold(ax, 'off'); ylim(ax, [40 101]);
if ~isempty(leg), legend(ax, leg, 'Location', 'southeast'); end
styleAxes(ax, 'Accuracy vs SNR', xl, 'Accuracy (%)');

ax = nexttile(t); hold(ax, 'on'); leg = {};
for i = 1:numel(analog)
    r = R.(analog{i}); c = colors(i, :);
    semilogy(ax, r.snr, r.MSE, 'o-', 'Color', c, 'LineWidth', 1.4, 'MarkerFaceColor', c);
    leg{end+1} = analog{i}; %#ok<AGROW>
end
set(ax, 'YScale', 'log'); hold(ax, 'off');
if ~isempty(leg), legend(ax, leg, 'Location', 'northeast'); end
styleAxes(ax, 'MSE vs SNR (analog reconstruction)', 'Channel SNR (dB)', 'MSE');
end
