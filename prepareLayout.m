function t = prepareLayout(parent, rows, cols, name)
%PREPARELAYOUT Tiled layout in a new figure, or inside a GUI panel.
if isempty(parent)
    parent = figure('Name', name, 'Color', 'w', 'NumberTitle', 'off');
else
    delete(parent.Children);
end
t = tiledlayout(parent, rows, cols, 'TileSpacing', 'compact', 'Padding', 'compact');
end
