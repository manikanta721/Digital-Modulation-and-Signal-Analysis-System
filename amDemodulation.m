function [rec, info] = amDemodulation(r, sig, cfg)
%AMDEMODULATION Envelope detection using the I/Q magnitude.
%   The received signal is mixed down with cos/sin references, low-pass
%   filtered, and the envelope sqrt(I^2+Q^2) = Ac*(1+mu*m(t)) is inverted
%   to recover m(t). A final low-pass and DC block reconstruct the message.
fs = cfg.fs;
I = 2 * r .* sig.cosC;
Q = -2 * r .* sig.sinC;
info.cutIQ = min([5*cfg.fm, 0.8*cfg.fc, 0.45*fs]);
lp = designFilter('lowpass', 4, info.cutIQ, fs);
I = applyFilter(lp, I, fs);
Q = applyFilter(lp, Q, fs);
envelope = sqrt(I.^2 + Q.^2);
mhat = (envelope / cfg.Ac - 1) / cfg.mu;
[rec, info.cutMsg] = reconstructMessage(mhat, info.cutIQ, cfg);
info.detector = 'Envelope detector (I/Q magnitude)';
end
