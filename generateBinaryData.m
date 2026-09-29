function bits = generateBinaryData(cfg)
%GENERATEBINARYDATA Return the transmitted bit sequence as a row of 0/1 doubles.
%   Uses cfg.bitsOverride if set, a seeded random sequence if
%   cfg.useRandomBits is true, otherwise parses cfg.bits ('1011...').

if ~isempty(cfg.bitsOverride)
    bits = double(cfg.bitsOverride(:).' ~= 0);
elseif cfg.useRandomBits
    s = RandStream('mt19937ar', 'Seed', cfg.dataSeed);
    bits = double(rand(s, 1, cfg.numRandomBits) < 0.5);
elseif ischar(cfg.bits) || isstring(cfg.bits)
    str = regexprep(char(cfg.bits), '\s', '');
    bits = double(str == '1');
else
    bits = double(cfg.bits(:).' ~= 0);
end
end
