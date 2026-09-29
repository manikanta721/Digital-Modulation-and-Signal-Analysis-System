function [rec, info] = fmDemodulation(r, sig, cfg)
%FMDEMODULATION Quadrature (phase-derivative) FM discriminator.
%   I/Q down-conversion -> low-pass -> unwrap(atan2(Q,I)) -> d/dt.
%   The instantaneous frequency deviation divided by df gives m(t).
fs = cfg.fs;
B = cfg.freqDev + cfg.fm;                       % Carson half-bandwidth
I = 2 * r .* sig.cosC;
Q = -2 * r .* sig.sinC;
info.cutIQ = max(min([1.5*B + cfg.fm, 2*cfg.fc - 1.5*B - cfg.fm, 0.45*fs]), 1.05*cfg.fm);
lp = designFilter('lowpass', 4, info.cutIQ, fs);
I = applyFilter(lp, I, fs);
Q = applyFilter(lp, Q, fs);
phase = unwrap(atan2(Q, I));
instFreqDev = gradient(phase) * fs / (2*pi);   % central differences
mhat = instFreqDev / cfg.freqDev;
[rec, info.cutMsg] = reconstructMessage(mhat, info.cutIQ, cfg);
info.detector = 'Quadrature phase discriminator';
end
