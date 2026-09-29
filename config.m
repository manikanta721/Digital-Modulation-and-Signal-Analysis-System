function cfg = config()
%CONFIG Default parameters for the Digital Modulation and Signal Analysis System.
%   Every value can be changed in the dashboard or by editing the returned
%   struct before calling runPipeline(cfg).

% ---- Modulation --------------------------------------------------------
cfg.modulation    = 'AM';      % 'AM' | 'FM' | 'ASK' | 'BPSK' | 'QAM'

% ---- Signal parameters -------------------------------------------------
cfg.fs            = 20000;     % sampling frequency (Hz)
cfg.duration      = 0.1;       % signal duration (s)
cfg.fm            = 50;        % message frequency (Hz)       [AM, FM]
cfg.Am            = 1;         % message amplitude             [AM, FM]
cfg.fc            = 1000;      % carrier frequency (Hz)
cfg.Ac            = 1;         % carrier amplitude

% ---- Modulation-specific ----------------------------------------------
cfg.mu            = 0.5;       % AM modulation index
cfg.freqDev       = 200;       % FM peak frequency deviation (Hz)
cfg.askLow        = 0;         % ASK amplitude for bit 0 (fraction of Ac)
cfg.qamOrder      = 4;         % 4 or 16

% ---- Digital data ------------------------------------------------------
cfg.bits          = '101101001011';
cfg.useRandomBits = false;
cfg.numRandomBits = 200;
cfg.dataSeed      = 7;
cfg.bitsOverride  = [];        % internal: used by the SNR experiment
cfg.spbOverride   = [];        % internal: samples per bit override

% ---- Noise -------------------------------------------------------------
cfg.noiseType     = 'AWGN';
cfg.noiseMode     = 'snr';     % 'snr' | 'sigma'
cfg.snrReference  = 'sample';  % 'sample' (Ps/Pn) | 'ebn0' (digital only)
cfg.snrDb         = 10;
cfg.noiseSigma    = 0.1;
cfg.noiseSeed     = 42;

% ---- Filter ------------------------------------------------------------
cfg.filterType    = 'bandpass';% 'lowpass' | 'highpass' | 'bandpass' | 'none'
cfg.filterOrder   = 4;
cfg.cutoff        = 1500;      % Hz, low/high-pass
cfg.band          = [850 1150];% Hz, band-pass edges

% ---- SNR experiment ----------------------------------------------------
cfg.snrList       = 0:5:30;
cfg.sweepBits     = 2000;
cfg.sweepAxis     = 'ebn0';    % digital x-axis: 'ebn0' | 'sample'
end
