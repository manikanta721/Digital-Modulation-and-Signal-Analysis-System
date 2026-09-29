function plotTimeDomain(S, parent)
%PLOTTIMEDOMAIN Message, carrier, modulated, noisy, filtered and recovered signals.
%   plotTimeDomain(S) opens a new figure; plotTimeDomain(S, panel) draws in a GUI panel.
if nargin < 2, parent = []; end
t = prepareLayout(parent, 3, 2, 'Time-domain signals');
sig = S.sig; tm = sig.t * 1000; modn = upper(S.cfg.modulation);
xl = 'Time (ms)';

ax = nexttile(t);
if sig.digital
    plot(ax, tm, sig.msg, 'LineWidth', 1.4); ylim(ax, [-0.25 1.25]);
    styleAxes(ax, 'Binary input sequence', xl, 'Bit value');
else
    plot(ax, tm, sig.msg, 'LineWidth', 1.2);
    styleAxes(ax, 'Message signal m(t)', xl, 'Amplitude');
end

ax = nexttile(t);
plot(ax, tm, sig.carrier, 'Color', [0 0.6 0.75]);
styleAxes(ax, 'Carrier c(t) = A_c cos(2\pi f_c t)', xl, 'Amplitude');

ax = nexttile(t);
if stageDone(S, 'modulate')
    plot(ax, tm, S.modulated, 'Color', [0.8 0.2 0.5]);
    styleAxes(ax, sprintf('%s modulated signal s(t)', modn), xl, 'Amplitude');
else, placeholder(ax, 'Modulated signal', 'Press Modulate'); end

ax = nexttile(t);
if stageDone(S, 'noise')
    plot(ax, tm, S.noisy, 'Color', [0.45 0.5 0.55]);
    styleAxes(ax, sprintf('Noisy %s signal (SNR %.1f dB)', modn, S.noise.snrMeasured), xl, 'Amplitude');
else, placeholder(ax, 'Noisy signal', 'Press Add Noise'); end

ax = nexttile(t);
if stageDone(S, 'filter')
    plot(ax, tm, S.filtered, 'Color', [0.2 0.6 0.3]);
    styleAxes(ax, 'Filtered signal', xl, 'Amplitude');
else, placeholder(ax, 'Filtered signal', 'Press Apply Filter'); end

ax = nexttile(t);
if stageDone(S, 'demodulate')
    plot(ax, tm, sig.msg, 'LineWidth', 1.4); hold(ax, 'on');
    plot(ax, tm, S.recovered, '--', 'LineWidth', 1.4);
    if sig.digital
        e = S.demod.errorIdx;
        if ~isempty(e)
            plot(ax, (e - 0.5) * sig.spb / sig.fs * 1000, 1.15*ones(size(e)), 'rx', 'LineWidth', 1.5);
            legend(ax, 'Transmitted', 'Recovered', 'Bit error', 'Location', 'best');
        else
            legend(ax, 'Transmitted', 'Recovered', 'Location', 'best');
        end
        ylim(ax, [-0.25 1.35]);
        styleAxes(ax, sprintf('Recovered bits (BER %.3g)', S.metrics.BER), xl, 'Bit value');
    else
        legend(ax, 'Original', 'Recovered', 'Location', 'best');
        styleAxes(ax, sprintf('Recovered vs original (corr %.4f)', S.metrics.correlation), xl, 'Amplitude');
    end
    hold(ax, 'off');
else, placeholder(ax, 'Recovered signal', 'Press Demodulate'); end
end
