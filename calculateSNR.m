function snrDb = calculateSNR(reference, estimate)
%CALCULATESNR SNR in dB of an estimate against a clean reference.
%   SNR = 10*log10( sum(reference.^2) / sum((reference - estimate).^2) )
%   Used for the channel SNR (clean vs noisy), the SNR after filtering and
%   the output SNR of the recovered message.
e = reference(:) - estimate(:);
snrDb = 10*log10(sum(reference(:).^2) / sum(e.^2));
end
