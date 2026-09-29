function p = theoreticalBER(modulation, ebn0Lin, cfg)
%THEORETICALBER Coherent-detection BER for AWGN.
%   BPSK, 4-QAM : Q(sqrt(2 Eb/N0))
%   ASK (levels 1 and L) : Q(sqrt(Eb/N0 * (1-L)^2 / (1+L^2)))   (OOK: Q(sqrt(Eb/N0)))
%   16-QAM (Gray) : 3/8 erfc(sqrt(0.4 Eb/N0))
Qf = @(x) 0.5*erfc(x/sqrt(2));
switch upper(modulation)
    case 'BPSK', p = Qf(sqrt(2*ebn0Lin));
    case 'ASK',  L = cfg.askLow; p = Qf(sqrt(ebn0Lin*(1-L)^2/(1+L^2)));
    case 'QAM'
        if cfg.qamOrder == 4, p = Qf(sqrt(2*ebn0Lin));
        else, p = 0.375*erfc(sqrt(0.4*ebn0Lin)); end
    otherwise, p = nan(size(ebn0Lin));
end
end
