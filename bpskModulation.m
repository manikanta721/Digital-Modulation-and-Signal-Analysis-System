function s = bpskModulation(bitsPad, cosC, spb, cfg)
%BPSKMODULATION Binary phase shift keying.
%   bit 1 -> phase 0 deg (+Ac),  bit 0 -> phase 180 deg (-Ac)
s = cfg.Ac * repelem(2*bitsPad - 1, spb) .* cosC;
end
