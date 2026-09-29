function s = fmModulation(msgNorm, t, cfg)
%FMMODULATION Frequency modulation with peak deviation cfg.freqDev.
%   s(t) = Ac * cos(2*pi*fc*t + 2*pi*df * integral(m))
phase = 2*pi*cfg.freqDev * cumtrapz(t, msgNorm);
s = cfg.Ac * cos(2*pi*cfg.fc*t + phase);
end
