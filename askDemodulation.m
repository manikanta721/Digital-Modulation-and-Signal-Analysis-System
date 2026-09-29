function [bits, softI, softQ] = askDemodulation(r, sig, cfg)
%ASKDEMODULATION Coherent correlator + mid-point threshold.
%   softI is the per-bit correlator output normalised so that bit 1 -> 1
%   and bit 0 -> askLow. The decision threshold is (1 + askLow)/2.
[zi, zq] = correlateSymbols(r, sig.cosC, sig.sinC, sig.sps);
softI = zi / cfg.Ac;
softQ = zq / cfg.Ac;
bits = double(softI > (1 + cfg.askLow) / 2);
end
