function tf = isDigital(modulation)
%ISDIGITAL True for ASK, BPSK and QAM.
tf = any(strcmpi(modulation, {'ASK', 'BPSK', 'QAM'}));
end
