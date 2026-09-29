function [bits, softI, softQ] = qamDemodulation(r, sig, cfg)
%QAMDEMODULATION Coherent I/Q correlator, per-axis slicer and Gray demapping.
M = cfg.qamOrder;
Es = 2; if M == 16, Es = 10; end
[zi, zq] = correlateSymbols(r, sig.cosC, sig.sinC, sig.sps);
softI = zi * sqrt(Es) / cfg.Ac;
softQ = zq * sqrt(Es) / cfg.Ac;
ns = numel(softI);
if M == 4
    B = [softI > 0; softQ > 0];
else
    li = slice16(softI); lq = slice16(softQ);
    B = [li > 0; abs(li) == 1; lq > 0; abs(lq) == 1];
end
bits = double(reshape(B, 1, []));
bits = bits(1:ns*log2(M));
end

function L = slice16(v)
%SLICE16 Nearest of the levels -3, -1, 1, 3.
L = 3*ones(size(v));
L(v < 2) = 1;
L(v < 0) = -1;
L(v < -2) = -3;
end
