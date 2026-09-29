function plotConstellation(S, parent)
%PLOTCONSTELLATION Noisy (before filter) and recovered (after filter) constellations.
if nargin < 2, parent = []; end
t = prepareLayout(parent, 1, 2, 'Constellation diagram');
cfg = S.cfg;
if ~S.sig.digital || ~stageDone(S, 'demodulate')
    placeholder(nexttile(t), 'Constellation', 'Digital modulation + Demodulate required');
    return;
end
d = S.demod;
switch upper(cfg.modulation)
    case 'ASK', iI = [cfg.askLow 1]; iQ = [0 0]; lim = 1.75;
    case 'BPSK', iI = [-1 1]; iQ = [0 0]; lim = 1.75;
    otherwise
        L = [-1 1]; if cfg.qamOrder == 16, L = [-3 -1 1 3]; end
        [A, B] = meshgrid(L, L); iI = A(:).'; iQ = B(:).'; lim = 1.75*max(L);
end
ax = nexttile(t);
scatter(ax, d.noisyI, d.noisyQ, 10, [0.5 0.55 0.6], 'filled'); hold(ax, 'on');
plot(ax, iI, iQ, 'ko', 'MarkerSize', 10, 'LineWidth', 1.5); hold(ax, 'off');
axis(ax, 'equal'); xlim(ax, [-lim lim]); ylim(ax, [-lim lim]);
legend(ax, 'Received', 'Ideal', 'Location', 'northeastoutside');
styleAxes(ax, 'Noisy constellation (before filter)', 'In-phase (I)', 'Quadrature (Q)');

ax = nexttile(t);
ok = ~d.symbolError;
scatter(ax, d.softI(ok), d.softQ(ok), 12, [0.2 0.6 0.3], 'filled'); hold(ax, 'on');
scatter(ax, d.softI(~ok), d.softQ(~ok), 18, [0.85 0.2 0.2], 'filled');
plot(ax, iI, iQ, 'ko', 'MarkerSize', 10, 'LineWidth', 1.5); hold(ax, 'off');
axis(ax, 'equal'); xlim(ax, [-lim lim]); ylim(ax, [-lim lim]);
legend(ax, 'Correct', 'Symbol error', 'Ideal', 'Location', 'northeastoutside');
styleAxes(ax, sprintf('Recovered constellation (SER %.3g)', S.metrics.SER), 'In-phase (I)', 'Quadrature (Q)');
end
