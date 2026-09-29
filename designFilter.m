function filt = designFilter(type, order, edges, fs)
%DESIGNFILTER Butterworth IIR filter as second-order sections (toolbox-free).
%   filt = designFilter('lowpass',  N, fc, fs)
%   filt = designFilter('highpass', N, fc, fs)
%   filt = designFilter('bandpass', N, [f1 f2], fs)   % 2N poles
%   filt = designFilter('none', ...)                   % returns []
%
%   Design: analog Butterworth prototype, (low-pass -> band-pass transform
%   for band-pass), bilinear transform with frequency pre-warping.
%   filt.sos rows are [b0 b1 b2 1 a1 a2], the same layout as MATLAB's
%   butter(..., 'sos') output, so results can be cross-checked with the
%   Signal Processing Toolbox if it is installed.
type = lower(type);
if strcmp(type, 'none'), filt = []; return; end
nyq = fs/2;
if any(edges <= 0) || any(edges >= nyq)
    error('designFilter:edges', 'Cutoff frequencies must lie between 0 and fs/2 = %g Hz.', nyq);
end
switch type
    case 'lowpass',  sos = butterLH('low', edges(1), fs, order);
    case 'highpass', sos = butterLH('high', edges(1), fs, order);
    case 'bandpass'
        if numel(edges) ~= 2 || edges(1) >= edges(2)
            error('designFilter:band', 'Band-pass needs [lower upper] with lower < upper.');
        end
        sos = butterBand(edges(1), edges(2), fs, order);
    otherwise
        error('designFilter:type', 'Unknown filter type "%s".', type);
end
filt = struct('type', type, 'order', order, 'edges', edges, 'sos', sos, 'fs', fs);
names = struct('lowpass', 'Low-pass', 'highpass', 'High-pass', 'bandpass', 'Band-pass');
filt.description = sprintf('%s Butterworth, order %d, %s Hz', names.(type), order, ...
    strjoin(arrayfun(@(e) sprintf('%g', e), edges, 'UniformOutput', false), '-'));
end

function sos = butterLH(kind, fc, fs, order)
% Butterworth low/high-pass: conjugate pole pairs -> biquads, odd order -> 1st-order section.
w0 = 2*pi*fc/fs; cw = cos(w0); sw = sin(w0);
sos = zeros(0, 6);
for k = 0:floor(order/2)-1
    Qk = 1 / (2*sin(pi*(2*k+1)/(2*order)));
    al = sw / (2*Qk); a0 = 1 + al;
    if strcmp(kind, 'low')
        b = [(1-cw)/2, 1-cw, (1-cw)/2];
    else
        b = [(1+cw)/2, -(1+cw), (1+cw)/2];
    end
    sos(end+1, :) = [b/a0, 1, -2*cw/a0, (1-al)/a0]; %#ok<AGROW>
end
if mod(order, 2)
    K = tan(w0/2); a1 = (K-1)/(K+1);
    if strcmp(kind, 'low')
        b0 = K/(1+K); sos(end+1, :) = [b0, b0, 0, 1, a1, 0];
    else
        b0 = 1/(1+K); sos(end+1, :) = [b0, -b0, 0, 1, a1, 0];
    end
end
end

function sos = butterBand(f1, f2, fs, order)
% Butterworth band-pass: LP prototype poles -> BP (s^2 + w0^2)/(B s) -> bilinear.
W1 = 2*fs*tan(pi*f1/fs); W2 = 2*fs*tan(pi*f2/fs);
w0sq = W1*W2; B = W2 - W1;
k = 0:order-1;
p = exp(1i*pi*(2*k + order + 1)/(2*order));        % prototype poles
root = sqrt((p*B).^2 - 4*w0sq);
sBP = [(p*B + root)/2, (p*B - root)/2];             % 2N analog band-pass poles
z = (2*fs + sBP) ./ (2*fs - sBP);                   % bilinear transform
z = z(imag(z) > 1e-12);                             % one pole of each conjugate pair
if numel(z) ~= order
    % very wide band: fall back to a high-pass/low-pass cascade
    sos = [butterLH('high', f1, fs, order); butterLH('low', f2, fs, order)];
    return;
end
sos = zeros(order, 6);
for i = 1:order
    sos(i, :) = [1, 0, -1, 1, -2*real(z(i)), abs(z(i))^2];   % zeros at z = +1 and -1
end
wc = 2*atan(sqrt(w0sq)/(2*fs));                     % centre frequency (rad/sample)
g = abs(sosResponse(sos, wc));
sos(1, 1:3) = sos(1, 1:3) / g;                      % unity gain at the centre
end

function H = sosResponse(sos, w)
ez = exp(-1i*w);
H = 1;
for i = 1:size(sos, 1)
    H = H .* (sos(i,1) + sos(i,2)*ez + sos(i,3)*ez.^2) ./ (1 + sos(i,5)*ez + sos(i,6)*ez.^2);
end
end
