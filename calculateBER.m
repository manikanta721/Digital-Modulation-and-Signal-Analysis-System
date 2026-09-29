function [ber, numErrors, accuracy] = calculateBER(txBits, rxBits)
%CALCULATEBER Bit error rate, error count and bit accuracy (%).
txBits = txBits(:).'; rxBits = rxBits(:).';
if numel(txBits) ~= numel(rxBits)
    error('calculateBER:size', 'Transmitted and received sequences must have the same length.');
end
numErrors = sum(txBits ~= rxBits);
ber = numErrors / numel(txBits);
accuracy = 100 * (1 - ber);
end
