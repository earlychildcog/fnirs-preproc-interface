function [h, p1, p2] = plot_line(p1, p2, k, ax)
% simple function to plot line between points $p1 and $p2
% with optional parameter $k to remove a $k proportion of the line
% around the two end points

if ~exist('ax','var') || isempty(ax)
    ax = gca;
end

if ~exist('k','var') || isempty(k)
    k = 0;
end

p1_0 = p1;
p2_0 = p2;

p1 = p1_0 + k*(p2_0 - p1_0);
p2 = p2_0 - (p1 - p1_0);
h = line(ax, [p1(1), p2(1)], [p1(2), p2(2)]);

