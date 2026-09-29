function mse = calculateMSE(reference, estimate)
%CALCULATEMSE Mean squared error between two equal-length signals.
e = reference(:) - estimate(:);
mse = mean(e.^2);
end
