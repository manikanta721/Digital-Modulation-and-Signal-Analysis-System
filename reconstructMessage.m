function [rec, cutMsg] = reconstructMessage(mhat, cutIQ, cfg)
%RECONSTRUCTMESSAGE Final message low-pass, DC block and amplitude scaling.
fs = cfg.fs;
cutMsg = min(3*cfg.fm, cutIQ);
mhat = applyFilter(designFilter('lowpass', 4, cutMsg, fs), mhat, fs);
N = numel(mhat);
idx = floor(0.05*N)+1 : ceil(0.95*N);     % ignore filter edge transients
rec = cfg.Am * (mhat - mean(mhat(idx)));
end
