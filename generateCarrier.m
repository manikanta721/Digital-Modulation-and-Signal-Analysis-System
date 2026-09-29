function [c, cosC, sinC] = generateCarrier(cfg, t)
%GENERATECARRIER Carrier c(t) = Ac*cos(2*pi*fc*t) plus unit I/Q references.
w = 2*pi*cfg.fc*t;
cosC = cos(w);
sinC = sin(w);
c = cfg.Ac * cosC;
end
