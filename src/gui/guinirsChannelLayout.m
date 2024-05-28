function panel_layout = guinirsChannelLayout(SD, panel_layout, ActList)



MeasList = SD.MeasList;
ml    = MeasList(MeasList(:,1)>0 & MeasList(:,4)== 1,[1 2 3]);
mlN = length(ml); %cw6info.displayLambda);

% active list (sources detectors pairs)
ml(:,3) = 0;

if ~exist('ActList','var')
    ActList = [];
end
s = SD.SrcPos;
d = SD.DetPos;
if size(ActList,2) == 2
    ActID = zeros(1,size(ActList,1));
    for c = 1:size(ActList,1)
        chan = ActList(c,:);
        f = find(sum(abs(ml(:,1:2) - chan),2) == 0);
        if ~isempty(f)
            ActID(c) = f;
        end
    end
elseif size(ActList,2) == 1
    ml(ActList == 1,3) = 1;
    ActID = find(ActList == 1);
elseif ~isempty(ActList)
    warning("no acticated channels, fix sth")
end

if ismac() || islinux()
	fs = 14;
else
	fs = 8;
end

if nargin < 2
    panel_layout = figure;
end
ax = axes(panel_layout,'Position', [0 0 1 1]);
hold on
% Draw all channels
for ii = 1:mlN
    hCh(ii) = plot_line(SD.SrcPos(ml(ii,1),:), SD.DetPos(ml(ii,2),:), 0.125);
    if ismember(ii,ActID)
        col = [0 1 0] * 0.85;
    else
        col = [1.00 1.00 1.00] * 0.85;
    end
    lstyle = '-';
    lwidth = 3;
    set(hCh(ii), 'color', col, 'linewidth', lwidth, 'linestyle', lstyle);
end

nSrcs = size(SD.SrcPos,1);
nDets = size(SD.DetPos,1);
% ADD SOURCE AND DETECTOR LABELS
hSD = zeros(nSrcs+nDets,1);
edgecol = 'none';

for idx1 = 1:nSrcs
    if ~isempty(find(MeasList(:,1)==idx1)) %#ok<*EFIND>
        hSD(idx1) = text( SD.SrcPos(idx1,1), SD.SrcPos(idx1,2), sprintf('%d', idx1), 'fontsize',fs, 'fontweight','bold', 'color','r' );
        set(hSD(idx1), 'horizontalalignment','center', 'edgecolor',edgecol, 'Clipping', 'on');
    end
end
for idx2 = 1:nDets
    if ~isempty(find(MeasList(:,2)==idx2))
        hSD(idx2+idx1) = text( SD.DetPos(idx2,1), SD.DetPos(idx2,2), sprintf('%d', idx2), 'fontsize',fs, 'fontweight','bold', 'color','b' );
        set(hSD(idx2+idx1), 'horizontalalignment','center', 'edgecolor',edgecol, 'Clipping', 'on');
    end
end

% mark active channels
rescaleAxes( ax, s, d )
set(gca,'Visible','off');
hold off
% set(g,'color',0.75*[1 1 1]);
end

function rescaleAxes( axis_handle, s, d )
   % axes(axis_handle)

    axis(axis_handle,'equal');
    
    p = [s; d];
    
    xmin = min(p(:,1));
    xmax = max(p(:,1));
    
    ymin = min(p(:,2));
    ymax = max(p(:,2));
        
    xl = [xmin xmax];
    yl = [ymin ymax];
    
    if ~all( [diff(xl) diff(yl)] > 0 )
       xl = xlim;
       yl = ylim;
    end
    
    xl = 1.2*diff(xl)/2*[-1 1]+mean(xl);
    yl = 1.2*diff(yl)/2*[-1 1]+mean(yl);
    
    axis(axis_handle,[xl yl])
    
    axis(axis_handle,'off')
end