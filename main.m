function main(mode)
%MAIN Entry point for the Digital Modulation and Signal Analysis System.
%
%   main            opens the interactive dashboard (default)
%   main('demo')    runs the complete pipeline for all five modulations,
%                   prints a comparison table and opens the figures
%   main('sweep')   runs the SNR experiment (BER / accuracy / MSE vs SNR)
%   main('test')    runs the automated test suite
%
%   Requires MATLAB R2020b or later. No toolboxes are required: the
%   Butterworth filters, zero-phase filtering and all modulators are
%   implemented in this project.

if nargin < 1, mode = 'gui'; end
root = fileparts(mfilename('fullpath'));
addpath(genpath(root));

switch lower(mode)
    case 'gui'
        dashboard();
    case 'demo'
        cfg = config();
        T = compareModulations(cfg);
        disp(T);
        for m = {'AM', 'FM', 'ASK', 'BPSK', 'QAM'}
            c = cfg; c.modulation = m{1}; c = recommendedFilter(c);
            S = runPipeline(c);
            plotTimeDomain(S);
            plotFrequencyDomain(S);
            if S.sig.digital, plotConstellation(S); end
            fprintf('\n%s\n', strjoin(S.log, newline));
        end
    case 'sweep'
        [T, ~] = snrExperiment(config(), true);
        disp(T);
    case 'test'
        runTests();
    otherwise
        error('main:mode', 'Unknown mode "%s". Use gui, demo, sweep or test.', mode);
end
end
