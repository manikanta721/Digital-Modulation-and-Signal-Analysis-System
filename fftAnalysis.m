function spec = fftAnalysis(x, fs, windowType, numPeaks)
%FFTANALYSIS Single-sided magnitude spectrum and dominant frequencies.
%   spec = fftAnalysis(x, fs)             Hann window, 3 peaks
%   spec = fftAnalysis(x, fs, 'rect', 5)
%   The magnitude is amplitude-calibrated: a sine of amplitude A shows a
%   peak of about A. The FFT length is the next power of two (>= 1024).
if nargin < 3 || isempty(windowType), windowType = 'hann'; end
if nargin < 4, numPeaks = 3; end
x = x(:).';
N = numel(x);
if strcmpi(windowType, 'hann')
    w = 0.5 - 0.5*cos(2*pi*(0:N-1)/(N-1));
else
    w = ones(1, N);
end
cg = mean(w);                                    % coherent gain
nfft = max(1024, 2^nextpow2(N));
X = fft(x .* w, nfft);
half = nfft/2;
mag = abs(X(1:half+1)) / (N * cg);
mag(2:end-1) = 2 * mag(2:end-1);                 % single-sided
f = (0:half) * fs / nfft;

% --- dominant components: local maxima above 5% of the largest peak ----
isPk = [mag(1) > mag(2), mag(2:end-1) >= mag(1:end-2) & mag(2:end-1) > mag(3:end), false];
cand = find(isPk & mag > 0.05*max(mag));
[~, order] = sort(mag(cand), 'descend');
cand = cand(order);
df = fs / nfft;
pf = []; pm = [];
for k = cand
    if all(abs(pf - f(k)) > 3*df)
        pf(end+1) = f(k); pm(end+1) = mag(k); %#ok<AGROW>
    end
    if numel(pf) >= numPeaks, break; end
end
spec = struct('f', f, 'mag', mag, 'nfft', nfft, 'df', df, 'fs', fs, ...
              'window', windowType, 'peakFreq', pf, 'peakMag', pm);
end
