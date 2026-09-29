function y = applyFilter(filt, x, fs)
%APPLYFILTER Zero-phase (forward-backward) filtering with mirror padding.
%   y = applyFilter(filt, x, fs)  filt from designFilter; [] means bypass.
%   Running the filter forward and backward removes phase delay, so the
%   filtered and original signals line up in time. The effective
%   magnitude response is |H(f)|^2.
if isempty(filt), y = x; return; end
x = x(:).';
n = numel(x);
pad = max(12*filt.order, round(3*fs/min(filt.edges)));
pad = min(pad, n-1);
ext = [x(pad+1:-1:2), x, x(n-1:-1:n-pad)];        % mirror (even) reflection
ext = sosPass(filt.sos, ext);
ext = fliplr(sosPass(filt.sos, fliplr(ext)));
y = ext(pad+1:pad+n);
end

function y = sosPass(sos, x)
y = x;
for i = 1:size(sos, 1)
    y = filter(sos(i, 1:3), sos(i, 4:6), y);
end
end
