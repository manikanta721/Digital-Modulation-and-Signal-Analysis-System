function e = filterEdges(cfg)
%FILTEREDGES Cutoff(s) for the configured filter type.
if strcmpi(cfg.filterType, 'bandpass'), e = cfg.band; else, e = cfg.cutoff; end
end
