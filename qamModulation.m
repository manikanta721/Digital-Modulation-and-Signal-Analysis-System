function [s, symbols] = qamModulation(bitsPad, cosC, sinC, sps, cfg)
%QAMMODULATION Gray-coded square 4-QAM or 16-QAM.
%   s(t) = Ac/sqrt(Es) * [ I(t) cos(wc t) - Q(t) sin(wc t) ]
%   4-QAM levels: +-1        (Es = 2)
%   16-QAM levels: +-1, +-3  (Es = 10), Gray map per axis 00,01,11,10 -> -3,-1,1,3
M = cfg.qamOrder;
k = log2(M);
ns = numel(bitsPad) / k;
B = reshape(bitsPad, k, ns);
if M == 4
    I = 2*B(1,:) - 1;
    Q = 2*B(2,:) - 1;
    Es = 2;
elseif M == 16
    lut = [-3 -1 3 1];                 % index = 2*b1 + b2 + 1
    I = lut(2*B(1,:) + B(2,:) + 1);
    Q = lut(2*B(3,:) + B(4,:) + 1);
    Es = 10;
else
    error('qamModulation:order', 'Only 4-QAM and 16-QAM are supported.');
end
g = cfg.Ac / sqrt(Es);
s = g * (repelem(I, sps) .* cosC - repelem(Q, sps) .* sinC);
symbols = struct('I', I, 'Q', Q, 'Es', Es, 'M', M, 'k', k);
end
