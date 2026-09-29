function s = askModulation(bitsPad, cosC, spb, cfg)
%ASKMODULATION Amplitude shift keying.
%   bit 1 -> Ac*cos(wc t),  bit 0 -> askLow*Ac*cos(wc t)  (askLow = 0 gives OOK)
level = bitsPad + (1 - bitsPad) * cfg.askLow;
s = cfg.Ac * repelem(level, spb) .* cosC;
end
