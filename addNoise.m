function [r, info] = addNoise(s, cfg, sig)
%ADDNOISE Additive white Gaussian noise channel.
%   cfg.noiseMode = 'snr'   : sigma set from the requested SNR in dB
%       snrReference 'sample' -> SNR = Ps/Pn (per-sample)
%       snrReference 'ebn0'   -> Eb/N0 for digital schemes,
%                                with N0 = 2*sigma^2/fs, Eb = Ps*spb/fs
%   cfg.noiseMode = 'sigma' : sigma = cfg.noiseSigma directly
%   A seeded RandStream makes every run reproducible.
if ~strcmpi(cfg.noiseType, 'AWGN')
    error('addNoise:type', 'Noise type "%s" is not supported yet. Use AWGN.', cfg.noiseType);
end
Ps = mean(s.^2);
if strcmpi(cfg.noiseMode, 'sigma')
    sigma = cfg.noiseSigma;
elseif strcmpi(cfg.snrReference, 'ebn0') && sig.digital
    sigma = sqrt(Ps * sig.spb / (2 * 10^(cfg.snrDb/10)));
else
    sigma = sqrt(Ps / 10^(cfg.snrDb/10));
end
stream = RandStream('mt19937ar', 'Seed', cfg.noiseSeed);
w = sigma * randn(stream, size(s));
r = s + w;
Pn = mean(w.^2);
info.sigma = sigma;
info.Ps = Ps;
info.Pn = Pn;
info.snrMeasured = 10*log10(Ps / Pn);
if sig.digital
    info.ebn0Measured = 10*log10(Ps * sig.spb / (2*Pn));
else
    info.ebn0Measured = NaN;
end
end
