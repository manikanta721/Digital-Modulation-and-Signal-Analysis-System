function [bits, softI, softQ] = bpskDemodulation(r, sig, cfg)
%BPSKDEMODULATION Coherent correlator + sign decision.
[zi, zq] = correlateSymbols(r, sig.cosC, sig.sinC, sig.sps);
softI = zi / cfg.Ac;
softQ = zq / cfg.Ac;
bits = double(softI > 0);
end
