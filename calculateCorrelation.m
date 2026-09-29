function rho = calculateCorrelation(x, y)
%CALCULATECORRELATION Pearson correlation coefficient (no toolbox needed).
x = x(:) - mean(x); y = y(:) - mean(y);
rho = sum(x.*y) / sqrt(sum(x.^2) * sum(y.^2));
end
