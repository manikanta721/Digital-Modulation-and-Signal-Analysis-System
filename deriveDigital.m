function d = deriveDigital(cfg)
%DERIVEDIGITAL Framing for digital schemes: bits, samples per bit, rates.
if ~isempty(cfg.bitsOverride)
    nb = numel(cfg.bitsOverride);
elseif cfg.useRandomBits
    nb = cfg.numRandomBits;
else
    nb = numel(regexprep(char(cfg.bits), '\s', ''));
end
k = 1;
if strcmpi(cfg.modulation, 'QAM'), k = log2(cfg.qamOrder); end
if ~isempty(cfg.spbOverride)
    spb = cfg.spbOverride;
else
    spb = max(1, round(cfg.fs * cfg.duration / max(nb, 1)));
end
nbp = ceil(nb/k) * k;                   % bits padded to whole symbols
d = struct('nb', nb, 'k', k, 'spb', spb, 'nbp', nbp, 'sps', spb*k, ...
           'N', nbp*spb, 'Rb', cfg.fs/spb, 'Rs', cfg.fs/(spb*k));
end
