function styleAxes(ax, ttl, xl, yl)
%STYLEAXES Title, axis labels and grid for every plot.
title(ax, ttl); xlabel(ax, xl); ylabel(ax, yl);
grid(ax, 'on'); box(ax, 'on');
end
