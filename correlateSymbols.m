function [zi, zq] = correlateSymbols(r, cosC, sinC, sps)
%CORRELATESYMBOLS Integrate-and-dump correlator (matched filter for rectangular pulses).
%   zi = (2/sps) * sum over each symbol of r*cos(wc t)
%   zq = -(2/sps) * sum over each symbol of r*sin(wc t)
ns = numel(r) / sps;
zi = (2/sps) * sum(reshape(r .* cosC, sps, ns), 1);
zq = -(2/sps) * sum(reshape(r .* sinC, sps, ns), 1);
end
