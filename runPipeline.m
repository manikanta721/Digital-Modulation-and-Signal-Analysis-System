function S = runPipeline(cfg)
%RUNPIPELINE Complete chain: generate -> modulate -> AWGN -> FFT -> filter
%   -> demodulate -> reconstruct -> metrics -> FFT of all signals.
%   Throws a readable error if the configuration is invalid.
[errs, warns] = validateConfig(cfg);
if ~isempty(errs)
    error('runPipeline:config', 'Invalid configuration:\n  - %s', strjoin(errs, '\n  - '));
end
S = newPipeline(cfg);
S.warnings = warns;
for stage = {'generate', 'modulate', 'noise', 'fft', 'filter', 'demodulate', 'fft'}
    S = pipelineStage(S, stage{1});
end
end
