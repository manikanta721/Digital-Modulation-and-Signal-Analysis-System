function rmse = calculateRMSE(reference, estimate)
%CALCULATERMSE Root mean squared error.
rmse = sqrt(calculateMSE(reference, estimate));
end
