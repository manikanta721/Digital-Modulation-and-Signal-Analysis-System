function S = pipelineStage(S, stage)
%PIPELINESTAGE Run one stage of the communication chain on pipeline state S.
%   Stages: 'generate','modulate','noise','fft','filter','demodulate'.
%   Re-running a stage invalidates the stages after it.
cfg = S.cfg; fs = cfg.fs;
stage = lower(stage);
S = clearLater(S, stage);
switch stage
    case 'generate'
        S.sig = generateMessage(cfg);
        [S.sig.carrier, S.sig.cosC, S.sig.sinC] = generateCarrier(cfg, S.sig.t);
        if S.sig.digital
            S = addLog(S, 'Generate', sprintf('%d bits, %d samples/bit (%.1f bit/s), %.2f carrier cycles per symbol, %d samples at fs = %g Hz.', ...
                S.sig.nb, S.sig.spb, S.sig.Rb, cfg.fc/S.sig.Rs, S.sig.N, fs));
        else
            S = addLog(S, 'Generate', sprintf('m(t) = %g sin(2 pi %g t), %d samples at fs = %g Hz; carrier %g Hz, amplitude %g.', ...
                cfg.Am, cfg.fm, S.sig.N, fs, cfg.fc, cfg.Ac));
        end

    case 'modulate'
        requireStage(S, 'generate');
        sig = S.sig;
        switch upper(cfg.modulation)
            case 'AM',   S.modulated = amModulation(sig.msgNorm, sig.cosC, cfg); d = sprintf('mu = %g', cfg.mu);
            case 'FM',   S.modulated = fmModulation(sig.msgNorm, sig.t, cfg);    d = sprintf('df = %g Hz, beta = %.2f', cfg.freqDev, cfg.freqDev/cfg.fm);
            case 'ASK',  S.modulated = askModulation(sig.bitsPad, sig.cosC, sig.spb, cfg); d = sprintf('bit 0 level = %g', cfg.askLow);
            case 'BPSK', S.modulated = bpskModulation(sig.bitsPad, sig.cosC, sig.spb, cfg); d = '1 -> 0 deg, 0 -> 180 deg';
            case 'QAM',  [S.modulated, S.symbols] = qamModulation(sig.bitsPad, sig.cosC, sig.sinC, sig.sps, cfg); d = sprintf('%d-QAM, Gray coded', cfg.qamOrder);
        end
        S.Ps = mean(S.modulated.^2);
        S = addLog(S, 'Modulate', sprintf('%s (%s). Average power %.4g.', upper(cfg.modulation), d, S.Ps));

    case 'noise'
        requireStage(S, 'modulate');
        [S.noisy, S.noise] = addNoise(S.modulated, cfg, S.sig);
        S = addLog(S, 'Add noise', sprintf('AWGN sigma = %.4g, measured SNR %.2f dB%s.', S.noise.sigma, S.noise.snrMeasured, ...
            ternary(S.sig.digital, sprintf(', Eb/N0 %.2f dB', S.noise.ebn0Measured), '')));

    case 'fft'
        requireStage(S, 'noise');
        S.spectra = struct();
        S.spectra.message = fftAnalysis(S.sig.msg, fs);
        S.spectra.modulated = fftAnalysis(S.modulated, fs);
        S.spectra.noisy = fftAnalysis(S.noisy, fs);
        if isfield(S, 'filtered') && stageDone(S, 'filter'), S.spectra.filtered = fftAnalysis(S.filtered, fs); end
        if isfield(S, 'recovered') && stageDone(S, 'demodulate'), S.spectra.recovered = fftAnalysis(S.recovered, fs); end
        S = addLog(S, 'FFT', sprintf('%d-point FFT, %.3g Hz/bin. Noisy signal peaks: %s Hz.', S.spectra.noisy.nfft, ...
            S.spectra.noisy.df, strjoin(arrayfun(@(v) sprintf('%.1f', v), S.spectra.noisy.peakFreq, 'UniformOutput', false), ', ')));

    case 'filter'
        requireStage(S, 'noise');
        S.filter = designFilter(cfg.filterType, cfg.filterOrder, filterEdges(cfg), fs);
        S.filtered = applyFilter(S.filter, S.noisy, fs);
        S.snrAfterFilter = calculateSNR(S.modulated, S.filtered);
        desc = 'No filter (bypass)'; if ~isempty(S.filter), desc = S.filter.description; end
        S = addLog(S, 'Filter', sprintf('%s, zero-phase. SNR vs clean signal: %.2f dB before, %.2f dB after.', ...
            desc, S.noise.snrMeasured, S.snrAfterFilter));

    case 'demodulate'
        requireStage(S, 'filter');
        [S, m] = demodulateAndMeasure(S);
        S.metrics = m;
        if S.sig.digital
            S = addLog(S, 'Demodulate', sprintf('Coherent correlator: %d of %d bits wrong (BER %.4g), SER %.4g.', m.bitErrors, m.numBits, m.BER, m.SER));
        else
            S = addLog(S, 'Demodulate', sprintf('%s. MSE %.4g, RMSE %.4g, output SNR %.2f dB, correlation %.4f.', ...
                S.demodInfo.detector, m.MSE, m.RMSE, m.outputSNR, m.correlation));
        end
    otherwise
        error('pipelineStage:stage', 'Unknown stage "%s".', stage);
end
S.done.(stage) = true;
end

% ---------------------------------------------------------------------
function [S, m] = demodulateAndMeasure(S)
cfg = S.cfg; sig = S.sig;
m = struct('modulation', upper(cfg.modulation), 'snrSet', cfg.snrDb, ...
    'snrMeasured', S.noise.snrMeasured, 'ebn0Measured', S.noise.ebn0Measured, ...
    'snrAfterFilter', S.snrAfterFilter, 'BER', NaN, 'accuracy', NaN, 'SER', NaN, ...
    'bitErrors', NaN, 'numBits', NaN, 'MSE', NaN, 'RMSE', NaN, 'outputSNR', NaN, 'correlation', NaN);
if sig.digital
    switch upper(cfg.modulation)
        case 'ASK'
            [rx, sI, sQ] = askDemodulation(S.filtered, sig, cfg);
            [~, nI, nQ] = askDemodulation(S.noisy, sig, cfg);
            idealI = sig.bitsPad + (1 - sig.bitsPad)*cfg.askLow; idealQ = zeros(size(idealI));
        case 'BPSK'
            [rx, sI, sQ] = bpskDemodulation(S.filtered, sig, cfg);
            [~, nI, nQ] = bpskDemodulation(S.noisy, sig, cfg);
            idealI = 2*sig.bitsPad - 1; idealQ = zeros(size(idealI));
        case 'QAM'
            [rx, sI, sQ] = qamDemodulation(S.filtered, sig, cfg);
            [~, nI, nQ] = qamDemodulation(S.noisy, sig, cfg);
            idealI = S.symbols.I; idealQ = S.symbols.Q;
    end
    [m.BER, m.bitErrors, m.accuracy] = calculateBER(sig.bits, rx(1:sig.nb));
    m.numBits = sig.nb;
    symErr = any(reshape(rx ~= sig.bitsPad, sig.k, []), 1);
    m.SER = mean(symErr);
    m.MSE = calculateMSE(idealI, sI) + calculateMSE(idealQ, sQ);   % soft-symbol error
    m.RMSE = sqrt(m.MSE);
    S.demod = struct('bits', rx, 'softI', sI, 'softQ', sQ, 'noisyI', nI, 'noisyQ', nQ, ...
                     'idealI', idealI, 'idealQ', idealQ, 'symbolError', symErr, ...
                     'errorIdx', find(rx(1:sig.nb) ~= sig.bits));
    S.recovered = repelem(rx, sig.spb);
else
    if strcmpi(cfg.modulation, 'AM')
        [S.recovered, S.demodInfo] = amDemodulation(S.filtered, sig, cfg);
    else
        [S.recovered, S.demodInfo] = fmDemodulation(S.filtered, sig, cfg);
    end
    N = sig.N; idx = floor(0.05*N)+1 : ceil(0.95*N);     % skip filter edges
    m.MSE = calculateMSE(sig.msg(idx), S.recovered(idx));
    m.RMSE = calculateRMSE(sig.msg(idx), S.recovered(idx));
    m.outputSNR = calculateSNR(sig.msg(idx), S.recovered(idx));
    m.correlation = calculateCorrelation(sig.msg(idx), S.recovered(idx));
end
end

function S = clearLater(S, stage)
order = {'generate', 'modulate', 'noise', 'fft', 'filter', 'demodulate'};
if strcmp(stage, 'fft'), return; end
i = find(strcmp(order, stage));
for k = i+1:numel(order)
    if isfield(S.done, order{k}), S.done = rmfield(S.done, order{k}); end
end
end

function requireStage(S, prereq)
if ~stageDone(S, prereq)
    error('pipelineStage:order', 'Run the "%s" stage first.', prereq);
end
end

function S = addLog(S, stage, text)
S.log{end+1} = sprintf('[%s] %s', stage, text);
end

function out = ternary(c, a, b)
if c, out = a; else, out = b; end
end
