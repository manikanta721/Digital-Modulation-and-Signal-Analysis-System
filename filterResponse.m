function g = filterResponse(filt, f)
%FILTERRESPONSE Magnitude of the zero-phase filter |H(f)|^2 at frequencies f (Hz).
if isempty(filt), g = ones(size(f)); return; end
w = 2*pi*f/filt.fs; ez = exp(-1i*w); H = ones(size(f));
for i = 1:size(filt.sos, 1)
    s = filt.sos(i, :);
    H = H .* (s(1) + s(2)*ez + s(3)*ez.^2) ./ (1 + s(5)*ez + s(6)*ez.^2);
end
g = abs(H).^2;
end
