function s = amModulation(msgNorm, cosC, cfg)
%AMMODULATION Standard (DSB-LC) amplitude modulation.
%   s(t) = Ac * [1 + mu*m(t)] * cos(2*pi*fc*t),  m(t) normalised to |m| <= 1
s = cfg.Ac * (1 + cfg.mu * msgNorm) .* cosC;
end
