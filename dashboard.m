function dashboard()
%DASHBOARD Interactive dashboard for the Digital Modulation and Signal Analysis System.
%   Left panel   : signal, modulation, noise and filter parameters
%   Centre panel : modulation selector and one button per pipeline stage
%   Right panel  : time-domain plots, spectrum, constellation, metrics,
%                  SNR sweep and processing log
%   Requires MATLAB R2020b or later (uifigure, uigridlayout, tiledlayout).

d = config();
S = [];            % pipeline state
stale = false;     % true when settings changed after a run

fig = uifigure('Name', 'Digital Modulation and Signal Analysis System', 'Position', [40 40 1500 880]);
root = uigridlayout(fig, [1 3]);
root.ColumnWidth = {320, 230, '1x'};

% ======================= LEFT: configuration ===========================
leftPanel = uipanel(root, 'Title', 'Signal configuration');
lg = uigridlayout(leftPanel, [34 2]);
lg.ColumnWidth = {'1x', 115}; lg.RowHeight = repmat({24}, 1, 34);
lg.RowSpacing = 4; lg.Scrollable = 'on';
row = 0;

addHeader('Signal');
h.fs       = addNum('Sampling frequency (Hz)', d.fs);
h.duration = addNum('Duration (s)', d.duration);
h.N        = addNum('Number of samples', round(d.fs*d.duration));
h.fm       = addNum('Message frequency (Hz)', d.fm);
h.Am       = addNum('Message amplitude', d.Am);
h.fc       = addNum('Carrier frequency (Hz)', d.fc);
h.Ac       = addNum('Carrier amplitude', d.Ac);
addHeader('Modulation settings');
h.mu       = addNum('AM modulation index', d.mu);
h.freqDev  = addNum('FM deviation (Hz)', d.freqDev);
h.askLow   = addNum('ASK level for bit 0', d.askLow);
h.qam      = addDrop('QAM order', {'4', '16'}, '4');
h.bits     = addText('Bit sequence', d.bits);
h.random   = addCheck('Use random bits', d.useRandomBits);
h.nRandom  = addNum('Number of random bits', d.numRandomBits);
h.dataSeed = addNum('Data seed', d.dataSeed);
addHeader('Noise');
h.noiseType = addDrop('Noise type', {'AWGN'}, 'AWGN');
h.noiseMode = addDrop('Set noise by', {'SNR', 'Noise sigma'}, 'SNR');
h.snrRef    = addDrop('SNR reference', {'Sample SNR', 'Eb/N0 (digital)'}, 'Sample SNR');
h.snr       = addNum('SNR (dB)', d.snrDb);
h.sigma     = addNum('Noise sigma', d.noiseSigma);
h.noiseSeed = addNum('Noise seed', d.noiseSeed);
addHeader('Filter');
h.fType  = addDrop('Filter type', {'Low-pass', 'High-pass', 'Band-pass', 'None'}, 'Band-pass');
h.fOrder = addNum('Filter order', d.filterOrder);
h.fCut   = addNum('Cutoff (Hz)', d.cutoff);
h.fLow   = addNum('Band lower edge (Hz)', d.band(1));
h.fHigh  = addNum('Band upper edge (Hz)', d.band(2));
row = row + 1;
b = uibutton(lg, 'Text', 'Use recommended filter', 'ButtonPushedFcn', @(~,~) useRecommended());
b.Layout.Row = row; b.Layout.Column = [1 2];

h.fs.ValueChangedFcn = @(~,~) syncSamples('fs');
h.duration.ValueChangedFcn = @(~,~) syncSamples('duration');
h.N.ValueChangedFcn = @(~,~) syncSamples('N');

% ======================= CENTRE: modulation + pipeline =================
centre = uipanel(root, 'Title', 'Modulation and pipeline');
cg = uigridlayout(centre, [13 1]);
cg.RowHeight = [{22, 30}, repmat({34}, 1, 9), {22, '1x'}];
uilabel(cg, 'Text', 'Modulation technique', 'FontWeight', 'bold');
h.mod = uidropdown(cg, 'Items', {'AM', 'FM', 'ASK', 'BPSK', 'QAM'}, 'Value', 'AM', ...
                   'ValueChangedFcn', @(~,~) modulationChanged());
uibutton(cg, 'Text', 'Generate Signal', 'ButtonPushedFcn', @(~,~) runStage('generate'));
uibutton(cg, 'Text', 'Modulate',        'ButtonPushedFcn', @(~,~) runStage('modulate'));
uibutton(cg, 'Text', 'Add Noise',       'ButtonPushedFcn', @(~,~) runStage('noise'));
uibutton(cg, 'Text', 'Analyze FFT',     'ButtonPushedFcn', @(~,~) runStage('fft'));
uibutton(cg, 'Text', 'Apply Filter',    'ButtonPushedFcn', @(~,~) runStage('filter'));
uibutton(cg, 'Text', 'Demodulate',      'ButtonPushedFcn', @(~,~) runStage('demodulate'));
uibutton(cg, 'Text', 'Run Complete Pipeline', 'FontWeight', 'bold', ...
         'BackgroundColor', [0.12 0.36 0.62], 'FontColor', 'w', 'ButtonPushedFcn', @(~,~) runAll());
uibutton(cg, 'Text', 'Compare All Modulations', 'ButtonPushedFcn', @(~,~) runCompare());
uibutton(cg, 'Text', 'Run SNR Sweep',   'ButtonPushedFcn', @(~,~) runSweep());
uilabel(cg, 'Text', 'Status and messages', 'FontWeight', 'bold');
h.status = uitextarea(cg, 'Editable', 'off', 'Value', {'Ready. Choose a modulation and run the pipeline.'});

% ======================= RIGHT: results ================================
tg = uitabgroup(root);
tTime  = uitab(tg, 'Title', 'Time domain');
tSpec  = uitab(tg, 'Title', 'Spectrum');
tConst = uitab(tg, 'Title', 'Constellation');
tMet   = uitab(tg, 'Title', 'Metrics');
tSweep = uitab(tg, 'Title', 'SNR sweep');
tLog   = uitab(tg, 'Title', 'Processing log');
pTime  = fullPanel(tTime);
pSpec  = fullPanel(tSpec);
pConst = fullPanel(tConst);
mg = uigridlayout(tMet, [4 1]); mg.RowHeight = {22, '1x', 22, '1x'};
uilabel(mg, 'Text', 'Current run', 'FontWeight', 'bold');
h.metrics = uitable(mg, 'ColumnName', {'Metric', 'Value'}, 'Data', cell(0, 2));
uilabel(mg, 'Text', 'Comparison of all modulations (recommended filter each)', 'FontWeight', 'bold');
h.compare = uitable(mg);
sg = uigridlayout(tSweep, [2 1]); sg.RowHeight = {'2x', '1x'};
pSweep = uipanel(sg, 'BorderType', 'none');
h.sweep = uitable(sg);
lgd = uigridlayout(tLog, [1 1]);
h.log = uitextarea(lgd, 'Editable', 'off');
modulationChanged();

% ======================= nested helpers ================================
    function addHeader(txt)
        row = row + 1;
        l = uilabel(lg, 'Text', txt, 'FontWeight', 'bold');
        l.Layout.Row = row; l.Layout.Column = [1 2];
    end
    function f = addNum(label, value)
        row = row + 1;
        l = uilabel(lg, 'Text', label); l.Layout.Row = row; l.Layout.Column = 1;
        f = uieditfield(lg, 'numeric', 'Value', value, 'ValueChangedFcn', @(~,~) markStale());
        f.Layout.Row = row; f.Layout.Column = 2;
    end
    function f = addText(label, value)
        row = row + 1;
        l = uilabel(lg, 'Text', label); l.Layout.Row = row; l.Layout.Column = 1;
        f = uieditfield(lg, 'text', 'Value', value, 'ValueChangedFcn', @(~,~) markStale());
        f.Layout.Row = row; f.Layout.Column = 2;
    end
    function f = addDrop(label, items, value)
        row = row + 1;
        l = uilabel(lg, 'Text', label); l.Layout.Row = row; l.Layout.Column = 1;
        f = uidropdown(lg, 'Items', items, 'Value', value, 'ValueChangedFcn', @(~,~) markStale());
        f.Layout.Row = row; f.Layout.Column = 2;
    end
    function f = addCheck(label, value)
        row = row + 1;
        f = uicheckbox(lg, 'Text', label, 'Value', value, 'ValueChangedFcn', @(~,~) markStale());
        f.Layout.Row = row; f.Layout.Column = [1 2];
    end
    function p = fullPanel(tab)
        g = uigridlayout(tab, [1 1]); g.Padding = [4 4 4 4];
        p = uipanel(g, 'BorderType', 'none');
    end

    function cfg = readCfg()
        cfg = config();
        cfg.modulation = h.mod.Value;
        cfg.fs = h.fs.Value; cfg.duration = h.duration.Value;
        cfg.fm = h.fm.Value; cfg.Am = h.Am.Value; cfg.fc = h.fc.Value; cfg.Ac = h.Ac.Value;
        cfg.mu = h.mu.Value; cfg.freqDev = h.freqDev.Value; cfg.askLow = h.askLow.Value;
        cfg.qamOrder = str2double(h.qam.Value);
        cfg.bits = h.bits.Value; cfg.useRandomBits = h.random.Value;
        cfg.numRandomBits = h.nRandom.Value; cfg.dataSeed = h.dataSeed.Value;
        cfg.noiseType = h.noiseType.Value;
        if strcmp(h.noiseMode.Value, 'SNR'), cfg.noiseMode = 'snr'; else, cfg.noiseMode = 'sigma'; end
        if strcmp(h.snrRef.Value, 'Sample SNR'), cfg.snrReference = 'sample'; else, cfg.snrReference = 'ebn0'; end
        cfg.snrDb = h.snr.Value; cfg.noiseSigma = h.sigma.Value; cfg.noiseSeed = h.noiseSeed.Value;
        types = struct('Low_pass', 'lowpass', 'High_pass', 'highpass', 'Band_pass', 'bandpass', 'None', 'none');
        cfg.filterType = types.(strrep(h.fType.Value, '-', '_'));
        cfg.filterOrder = h.fOrder.Value; cfg.cutoff = h.fCut.Value;
        cfg.band = [h.fLow.Value, h.fHigh.Value];
    end

    function syncSamples(src)
        if strcmp(src, 'N')
            if h.fs.Value > 0, h.duration.Value = h.N.Value / h.fs.Value; end
        else
            h.N.Value = round(h.fs.Value * h.duration.Value);
        end
        markStale();
    end

    function modulationChanged()
        m = h.mod.Value; dig = isDigital(m);
        setEnable({h.fm, h.Am}, ~dig);
        h.mu.Enable = onoff(strcmp(m, 'AM'));
        h.freqDev.Enable = onoff(strcmp(m, 'FM'));
        h.askLow.Enable = onoff(strcmp(m, 'ASK'));
        h.qam.Enable = onoff(strcmp(m, 'QAM'));
        setEnable({h.bits, h.random, h.nRandom, h.dataSeed}, dig);
        if ~dig && strcmp(h.snrRef.Value, 'Eb/N0 (digital)'), h.snrRef.Value = 'Sample SNR'; end
        useRecommended();
    end

    function useRecommended()
        c = recommendedFilter(readCfg());
        map = struct('lowpass', 'Low-pass', 'highpass', 'High-pass', 'bandpass', 'Band-pass');
        h.fType.Value = map.(c.filterType); h.fOrder.Value = c.filterOrder;
        h.fCut.Value = c.cutoff; h.fLow.Value = c.band(1); h.fHigh.Value = c.band(2);
        markStale();
    end

    function markStale()
        if ~isempty(S) && ~stale
            stale = true;
            setStatus({'Settings changed. Run the pipeline again to update the results.'});
        end
    end

    function setStatus(lines)
        h.status.Value = lines(:);
        drawnow limitrate;
    end

    function ok = startNew()
        cfg = readCfg();
        [errs, warns] = validateConfig(cfg);
        msgs = [prefix('ERROR: ', errs), prefix('Warning: ', warns)];
        if ~isempty(errs)
            setStatus(msgs);
            uialert(fig, strjoin(errs, newline), 'Invalid parameters');
            ok = false; return;
        end
        S = newPipeline(cfg); stale = false; ok = true;
        if ~isempty(msgs), setStatus(msgs); end
    end

    function runStage(stage)
        try
            if strcmp(stage, 'generate') || isempty(S) || stale
                if ~startNew(), return; end
                S = pipelineStage(S, 'generate');
                if strcmp(stage, 'generate'), refresh(); return; end
            end
            S = pipelineStage(S, stage);
            refresh();
            if strcmp(stage, 'fft'), tg.SelectedTab = tSpec; end
        catch err
            uialert(fig, err.message, 'Processing error');
        end
    end

    function runAll()
        try
            if ~startNew(), return; end
            for st = {'generate', 'modulate', 'noise', 'fft', 'filter', 'demodulate', 'fft'}
                S = pipelineStage(S, st{1});
            end
            refresh();
        catch err
            uialert(fig, err.message, 'Processing error');
        end
    end

    function runCompare()
        cfg = readCfg();
        errs = validateConfig(cfg);
        if ~isempty(errs), uialert(fig, strjoin(errs, newline), 'Invalid parameters'); return; end
        dlg = uiprogressdlg(fig, 'Title', 'Comparing modulations', 'Indeterminate', 'on');
        try
            h.compare.Data = compareModulations(cfg);
            tg.SelectedTab = tMet;
        catch err
            uialert(fig, err.message, 'Comparison failed');
        end
        close(dlg);
    end

    function runSweep()
        cfg = readCfg();
        dlg = uiprogressdlg(fig, 'Title', 'SNR sweep', 'Message', 'Running every modulation over 0:5:30 dB...', 'Indeterminate', 'on');
        try
            [T, R] = snrExperiment(cfg, false);
            plotPerformance(R, cfg, pSweep);
            h.sweep.Data = T;
            tg.SelectedTab = tSweep;
        catch err
            uialert(fig, err.message, 'Sweep failed');
        end
        close(dlg);
    end

    function refresh()
        plotTimeDomain(S, pTime);
        if stageDone(S, 'noise'), plotFrequencyDomain(S, pSpec); end
        if S.sig.digital && stageDone(S, 'demodulate')
            plotConstellation(S, pConst);
        else
            t = prepareLayout(pConst, 1, 1, '');
            placeholder(nexttile(t), 'Constellation', 'Select ASK, BPSK or QAM and run Demodulate');
        end
        h.metrics.Data = metricsToCell(S);
        h.log.Value = S.log(:);
        order = {'generate', 'modulate', 'noise', 'fft', 'filter', 'demodulate'};
        doneList = order(cellfun(@(s) stageDone(S, s), order));
        msg = sprintf('%s: completed %s.', S.cfg.modulation, strjoin(doneList, ', '));
        setStatus([{msg}, prefix('Warning: ', S_warnings())]);
    end

    function w = S_warnings()
        [~, w] = validateConfig(S.cfg);
    end
end

function s = onoff(tf)
if tf, s = 'on'; else, s = 'off'; end
end

function setEnable(handles, tf)
for i = 1:numel(handles)
    handles{i}.Enable = onoff(tf);
end
end

function out = prefix(p, list)
out = cellfun(@(x) [p x], list, 'UniformOutput', false);
out = reshape(out, 1, []);
end
