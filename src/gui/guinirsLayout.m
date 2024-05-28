classdef guinirsLayout < handle
    properties
        panel           matlab.ui.container.Panel
        parent          guinirsClass
        linesChannels
        link            = []     % s-d pairs; third column is accepted/rejected; fourth column is active (visible) or not
        posSrc
        posDet
    end
    methods
        function obj = guinirsLayout(parent)
            obj.parent = parent;
        end
        function updateLink(obj)
            % link data (source-detector pairs and rejections)
            obj.link = obj.parent.layout.link{:,:};
            % active list (sources detectors pairs)
            obj.link(:,4) = 0;
            obj.link(obj.parent.channelsToPlot,4) = 1;
        end
        function init(obj, panel)
            obj.panel = panel;
            obj.panel.BackgroundColor = [1 1 1];
            obj.updateLink;
            obj.posDet = obj.parent.probe.detectorPos2D;
            obj.posSrc = obj.parent.probe.sourcePos2D;
        end
        function  plotChannelLayout(obj)
            panel_layout = obj.panel;
            % MeasList = SD.MeasList;
            % link    = MeasList(MeasList(:,1)>0 & MeasList(:,4)== 1,[1 2 3]);
            mlN = length(obj.link); %cw6info.displayLambda);
            

            s = obj.posSrc;
            d = obj.posDet;
            % if size(obj.ActList,2) == 2
            %     ActID = zeros(1,size(obj.ActList,1));
            %     for c = 1:size(obj.ActList,1)
            %         chan = obj.ActList(c,:);
            %         f = find(sum(abs(obj.link(:,1:2) - chan),2) == 0);
            %         if ~isempty(f)
            %             ActID(c) = f;
            %         end
            %     end
            % elseif size(obj.ActList,2) == 1
            %     obj.link(obj.ActList == 1,4) = 1;
            %     ActID = find(obj.ActList == 1);
            % elseif ~isempty(obj.ActList)
            %     warning("no acticated channels, fix sth")
            % end
            ActID = find(obj.link(:,4) == 1);
            if ismac() || islinux()
            	fs = 14;
            else
            	fs = 8;
            end

            ax = axes(panel_layout,'Position', [0 0 1 1]);
            hold on
            % Draw all channels
            userdata = struct('rejected', 0, 'selected',0,'iChan',0, 'source', 0, 'detector', 0, 'colour', [0 0 0], 'guilayout', obj);
            hCh = repmat(line, 1, mlN);
            for iChan = 1:mlN
                hCh(iChan) = plot_line(obj.posSrc(obj.link(iChan,1),:), obj.posDet(obj.link(iChan,2),:), 0.125);
                set(hCh(iChan), 'userdata', userdata)
                hCh(iChan).UserData.iChan = iChan;
                hCh(iChan).UserData.source = obj.link(iChan,1);
                hCh(iChan).UserData.detector = obj.link(iChan,2);
                hCh(iChan).UserData.colour = obj.parent.guiSteps.colourmap(iChan,:);
                col = obj.parent.guiSteps.colourmap(iChan,:);
                if ismember(iChan,ActID)
                    hCh(iChan).UserData.selected = 1;
                    % col = [0 1 0] * 0.85;
                    col(4) = 1;
                else
                    col(4) = 0.1;
                end
                lstyle = '-';
                lwidth = 6;
                set(hCh(iChan), 'color', col, 'linewidth', lwidth, 'linestyle', lstyle);
            end

            nSrcs = size(s,1);
            nDets = size(d,1);
            % ADD SOURCE AND DETECTOR LABELS
            hSD = zeros(nSrcs+nDets,1);
            edgecol = 'none';

            for idx1 = 1:nSrcs
                if ~isempty(find(obj.link(:,1)==idx1)) %#ok<*EFIND>
                    hSD(idx1) = text( obj.posSrc(idx1,1), obj.posSrc(idx1,2), sprintf('%d', idx1), 'fontsize',fs, 'fontweight','bold', 'color','r' );
                    set(hSD(idx1), 'horizontalalignment','center', 'edgecolor',edgecol, 'Clipping', 'on');
                end
            end
            for idx2 = 1:nDets
                if ~isempty(find(obj.link(:,2)==idx2))
                    hSD(idx2+idx1) = text( obj.posDet(idx2,1), obj.posDet(idx2,2), sprintf('%d', idx2), 'fontsize',fs, 'fontweight','bold', 'color','b' );
                    set(hSD(idx2+idx1), 'horizontalalignment','center', 'edgecolor',edgecol, 'Clipping', 'on');
                end
            end

            % mark active channels
            % rescaleAxes( ax, s, d )
            set(ax,'Visible','off');
            hold off
            obj.linesChannels = hCh;
            % set(g,'color',0.75*[1 1 1]);
        % function rescaleAxes( ax, s, d )
            % axes(axis_handle)

            axis(ax,'equal');

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

            axis(ax,[xl yl])
            set(ax.Toolbar, 'Visible','off')
            setAllowAxesZoom(zoom, ax, false)       % disable zoom
            set(ax, "ButtonDownFcn", {@callback.layout.zoomoff, obj.parent})
            % h = zoom(ax);
            % h.ActionPostCallback = @callback.layout.zoomwarning;
            axis(ax,'off')
        % end
        end
        function rerenderRejected(obj)
            % get link from layout data structure in main object
            obj.link(:,1:3) = obj.parent.layout.link{:,["source" "detector" "incl"]};
            set(obj.linesChannels(obj.link(:,3) == 0), 'linestyle', ':')
            set(obj.linesChannels(obj.link(:,3) == 1), 'linestyle', '-')
        end

    end
end