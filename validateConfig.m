function [errors, warnings] = validateConfig(cfg)
%VALIDATECONFIG Check user parameters; return readable errors and warnings.
%   Errors stop the pipeline; warnings are shown but processing continues.
errors = {}; warnings = {};
mods = {'AM', 'FM', 'ASK', 'BPSK', 'QAM'};
if ~any(strcmpi(cfg.modulation, mods))
    errors{end+1} = sprintf('Unknown modulation "%s". Choose AM, FM, ASK, BPSK or QAM.', cfg.modulation);
    return;
end
analog = ~isDigital(cfg.modulation);
req = {'fs', 'Sampling frequency'; 'duration', 'Signal duration'; ...
       'fc', 'Carrier frequency'; 'Ac', 'Carrier amplitude'};
if analog, req = [req; {'fm', 'Message frequency'; 'Am', 'Message amplitude'}]; end
for i = 1:size(req, 1)
    v = cfg.(req{i,1});
    if ~isnumeric(v) || ~isscalar(v) || ~isfinite(v)
        errors{end+1} = sprintf('%s must be a finite number.', req{i,2}); %#ok<AGROW>
    elseif v <= 0
        errors{end+1} = sprintf('%s must be greater than zero.', req{i,2}); %#ok<AGROW>
    end
end
if ~isempty(errors), return; end

fmax = []; N = [];
if analog
    N = round(cfg.fs * cfg.duration);
    if strcmpi(cfg.modulation, 'AM')
        if ~(cfg.mu > 0 && cfg.mu <= 1.5)
            errors{end+1} = 'Modulation index mu must be greater than 0 and at most 1.5.';
        elseif cfg.mu > 1
            warnings{end+1} = sprintf('mu = %.2f over-modulates the carrier; the envelope detector will distort the message.', cfg.mu);
        end
        fmax = cfg.fc + cfg.fm;
        if cfg.fc <= 2*cfg.fm
            errors{end+1} = sprintf('Carrier frequency (%g Hz) must be more than twice the message frequency (%g Hz) for envelope detection.', cfg.fc, cfg.fm);
        end
    else
        if ~(cfg.freqDev > 0)
            errors{end+1} = 'Frequency deviation must be greater than zero.';
        else
            B = cfg.freqDev + cfg.fm; fmax = cfg.fc + B;
            if cfg.fc <= B
                errors{end+1} = sprintf('Carrier frequency (%g Hz) must exceed df + fm = %g Hz, otherwise the FM spectrum folds through 0 Hz.', cfg.fc, B);
            elseif cfg.fc < 2*B
                warnings{end+1} = sprintf('The carrier is close to the FM bandwidth (Carson %g Hz); try fc >= %g Hz.', 2*B, 2*B);
            end
        end
    end
    if cfg.fm * cfg.duration < 1
        warnings{end+1} = 'The duration covers less than one message cycle.';
    end
else
    if isempty(cfg.bitsOverride)
        if cfg.useRandomBits
            n = cfg.numRandomBits;
            if ~(isscalar(n) && n == round(n) && n >= 2 && n <= 1e5)
                errors{end+1} = 'Number of random bits must be a whole number from 2 to 100000.';
            end
        else
            str = regexprep(char(cfg.bits), '\s', '');
            if isempty(str) || any(str ~= '0' & str ~= '1')
                errors{end+1} = 'The bit sequence may contain only 0 and 1.';
            elseif numel(str) < 2 || numel(str) > 4096
                errors{end+1} = 'The bit sequence must be 2 to 4096 bits long.';
            end
        end
    end
    if strcmpi(cfg.modulation, 'ASK') && ~(cfg.askLow >= 0 && cfg.askLow < 1)
        errors{end+1} = 'The ASK amplitude for bit 0 must be at least 0 and below 1.';
    end
    if strcmpi(cfg.modulation, 'QAM') && ~any(cfg.qamOrder == [4 16])
        errors{end+1} = 'QAM order must be 4 or 16.';
    end
    if ~isempty(errors), return; end
    d = deriveDigital(cfg); N = d.N;
    if d.spb < 4
        errors{end+1} = sprintf('Only %d samples per bit. Increase fs or the duration, or send fewer bits.', d.spb);
    end
    fmax = cfg.fc + d.Rs;
    cyc = cfg.fc / d.Rs;
    if cyc < 1
        errors{end+1} = sprintf('The carrier completes only %.2f cycles per symbol. Raise fc above %.1f Hz.', cyc, d.Rs);
    elseif cyc < 2
        warnings{end+1} = sprintf('Only %.1f carrier cycles per symbol; aim for at least 2.', cyc);
    end
    if strcmpi(cfg.modulation, 'QAM') && mod(d.nb, d.k)
        warnings{end+1} = sprintf('%d zero bit(s) pad the last QAM symbol and are excluded from the BER.', d.nbp - d.nb);
    end
end

if ~isempty(fmax)
    if cfg.fs <= 2*fmax
        errors{end+1} = sprintf('Sampling frequency (%g Hz) must be greater than twice the highest signal frequency (2 x %g = %g Hz).', cfg.fs, fmax, 2*fmax);
    elseif cfg.fs < 4*fmax
        warnings{end+1} = 'fs is below 4x the highest signal frequency; waveforms will look coarse.';
    end
end
if ~isempty(N)
    if N < 64, errors{end+1} = sprintf('Only %d samples; at least 64 are needed.', N); end
    if N > 2e6, errors{end+1} = sprintf('%d samples is too many; reduce the duration, fs or number of bits.', N); end
end

if ~strcmpi(cfg.noiseType, 'AWGN')
    errors{end+1} = 'Only AWGN noise is supported.';
end
if strcmpi(cfg.noiseMode, 'snr')
    if ~(isfinite(cfg.snrDb) && cfg.snrDb >= -20 && cfg.snrDb <= 60)
        errors{end+1} = 'SNR must be between -20 and 60 dB.';
    end
    if strcmpi(cfg.snrReference, 'ebn0') && analog
        errors{end+1} = 'Eb/N0 applies to digital schemes only. Use the sample SNR reference for AM and FM.';
    end
elseif ~(cfg.noiseSigma >= 0)
    errors{end+1} = 'Noise level sigma must be zero or positive.';
end

if ~strcmpi(cfg.filterType, 'none')
    nyq = cfg.fs/2;
    if ~(cfg.filterOrder >= 1 && cfg.filterOrder <= 10 && cfg.filterOrder == round(cfg.filterOrder))
        errors{end+1} = 'Filter order must be a whole number from 1 to 10.';
    end
    if strcmpi(cfg.filterType, 'bandpass')
        f1 = cfg.band(1); f2 = cfg.band(2);
        if ~(f1 > 0 && f2 > f1 && f2 < nyq)
            errors{end+1} = sprintf('Band-pass edges must satisfy 0 < lower < upper < fs/2 (%g Hz).', nyq);
        elseif cfg.fc < f1 || cfg.fc > f2
            warnings{end+1} = sprintf('The carrier (%g Hz) lies outside the pass band %g-%g Hz.', cfg.fc, f1, f2);
        end
    else
        if ~(cfg.cutoff > 0 && cfg.cutoff < nyq)
            errors{end+1} = sprintf('Cutoff frequency must be between 0 and fs/2 (%g Hz).', nyq);
        elseif strcmpi(cfg.filterType, 'lowpass') && cfg.cutoff < cfg.fc
            warnings{end+1} = sprintf('Low-pass cutoff (%g Hz) is below the carrier (%g Hz); the modulated signal will be removed.', cfg.cutoff, cfg.fc);
        elseif strcmpi(cfg.filterType, 'highpass') && cfg.cutoff > cfg.fc
            warnings{end+1} = sprintf('High-pass cutoff (%g Hz) is above the carrier (%g Hz); the modulated signal will be removed.', cfg.cutoff, cfg.fc);
        end
    end
end
end
