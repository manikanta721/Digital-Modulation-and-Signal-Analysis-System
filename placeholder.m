function placeholder(ax, ttl, msg)
%PLACEHOLDER Empty tile with an instruction for a stage that has not run yet.
title(ax, ttl);
text(ax, 0.5, 0.5, msg, 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Color', [0.4 0.4 0.4]);
set(ax, 'XTick', [], 'YTick', []); box(ax, 'on');
end
