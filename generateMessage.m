function sig = generateMessage(cfg)
%GENERATEMESSAGE Sampled message signal.
%   AM/FM : m(t) = Am*sin(2*pi*fm*t)
%   ASK/BPSK/QAM : NRZ waveform of the bit sequence (0/1 levels)
%   The returned struct also carries the time vector and, for digital
%   schemes, the framing information (samples per bit, bit rate, ...).

sig.fs = cfg.fs;
sig.digital = isDigital(cfg.modulation);
if sig.digital
    d = deriveDigital(cfg);
    fn = fieldnames(d);
    for i = 1:numel(fn), sig.(fn{i}) = d.(fn{i}); end
    sig.bits = generateBinaryData(cfg);
    sig.bitsPad = [sig.bits, zeros(1, d.nbp - d.nb)];   % QAM padding
    N = d.N;
    sig.t = (0:N-1) / cfg.fs;
    sig.msg = repelem(sig.bitsPad, d.spb);
    sig.msgNorm = sig.msg;
else
    N = round(cfg.fs * cfg.duration);
    sig.N = N;
    sig.t = (0:N-1) / cfg.fs;
    sig.msgNorm = sin(2*pi*cfg.fm*sig.t);          % normalised message
    sig.msg = cfg.Am * sig.msgNorm;
end
end
