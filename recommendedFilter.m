function cfg = recommendedFilter(cfg)
%RECOMMENDEDFILTER Band-pass filter around the carrier that fits the signal bandwidth.
%   AM : fc +- 3 fm            FM : fc +- (1.5 (df + fm) + fm)
%   ASK/BPSK/QAM : fc +- 2 * symbol rate
%   Falls back to a low-pass filter when the lower edge would reach 0 Hz.
switch upper(cfg.modulation)
    case 'AM', hb = 3*cfg.fm;
    case 'FM', hb = 1.5*(cfg.freqDev + cfg.fm) + cfg.fm;
    otherwise, d = deriveDigital(cfg); hb = 2*d.Rs;
end
hi = round(min(cfg.fc + hb, 0.95*cfg.fs/2));
lo = round(cfg.fc - hb);
cfg.filterOrder = 4;
if lo < max(1, 0.01*cfg.fs/2)
    cfg.filterType = 'lowpass';
    cfg.cutoff = hi;
else
    cfg.filterType = 'bandpass';
    cfg.band = [lo hi];
end
end
