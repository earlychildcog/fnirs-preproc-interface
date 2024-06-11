classdef guinirsSteps < handle
    properties
        panel       matlab.ui.container.Panel
        parent      guinirsClass
        lines       matlab.graphics.chart.primitive.Line
        lines_      cell
        lines_artifact_channel  matlab.graphics.chart.primitive.Line
        lines_artifact_full  matlab.graphics.chart.primitive.Line
        lines_cut   matlab.graphics.chart.decoration.ConstantLine
        lines_stim  matlab.graphics.primitive.Patch
        tabgroup    matlab.ui.container.TabGroup
        buttons
        colourmap
            
        axis_stim
        axesTable       table       % to implement?
        cm
        labelAxes string
        presentation string {mustBeMember(presentation, ["parallel" "centered" "original"])} = "parallel"

    end
    properties (Access = private)
        iProc       = 0;
        linestyles = ["-" ":";"-." "--"]; % linestyles for accepted-rejected (rows) and datatype 1- datatype 2 (columns)
    end
    methods
        function obj = guinirsSteps(parent, panel)
            obj.parent = parent;
            obj.panel = panel;
            obj.getcolours;
            obj.cm = uicontextmenu;
            uimenu(obj.cm,'Text','remove stim','UserData',[0 0],'MenuSelectedFcn',{@callback.stim.remove, obj.parent});
        end
        function init(obj)
            % TOO SKETCHY
            x = [obj.panel.Children(:).Children.Children.Children];
            % y = arrayfun(@(z)reshape(flip(z(1).Children), 2, [])',x(arrayfun(@(z)strcmp(z.Type, 'axes'),x)),'UniformOutput',false);
            % obj.lines = cat(3,y{:}); % a bit sketchy...
            obj.lines_ = cellfun(@flip, {x.Children}, UniformOutput=false);
            set(obj.lines, 'LineWidth', 2)

            % lines for before and end
            [x0, x1] = bounds(obj.parent.data(1).time);
            obj.lines_cut = [arrayfun(@(ax)xline(ax, x0, 'k--','LineWidth', 5, 'Tag','cut_beg','UserData',obj.parent), [obj.lines(1,1,:).Parent]); arrayfun(@(ax)xline(ax, x1, 'k--','LineWidth', 5, 'Tag','cut_end','UserData',obj.parent), [obj.lines(1,1,:).Parent])];
            arrayfun(@(ln)draggable(ln, 'constraint','h','endfcn',@callback.steps.linecut_postdrag),obj.lines_cut)        % make them draggable
            % obj.plotStim;
            obj.plotStim;

        end



        %==================================================================
        function plotDataScalar(obj, hParent)

            dataTabGroup = uitabgroup(...
                uipanel('parent',hParent...
                ,'Position',[0 0.1 1 0.9]));
            obj.tabgroup = dataTabGroup;
            obj.iProc = 0;
            % plot step by step
            nStep = length(obj.parent.data);
            h = zeros(size(obj.parent.layout.link,1), 2, nStep);
            for iStep = 1:nStep
                h(:,:,iStep) = obj.nextproc(dataTabGroup);
            end
            % Link axes and plot segments:
            for i = 1:size(h,3)
                obj.lines(:,:,i) = h(:,:,i);
            end
        end
        function h = nextproc(obj,dataTabGroup)
            % plot each step (meant to be used only once when the figure window is build)

            % a way to determine which step we are on
            if obj.iProc >= length(obj.parent.data)
                obj.iProc = 0;
                return
            end
            obj.iProc = obj.iProc + 1;
            tab = uitab(dataTabGroup...
                ,'Title',obj.parent.steps(obj.iProc).name, 'UserData',obj.iProc);
            objData = obj.parent.data(obj.iProc);
            guiParams = obj.parent.getPlotStyleParams();
            set(tab ...
                ,'BackgroundColor',dataTabGroup.Parent.BackgroundColor+[1 1 1]*0.025);
            ax = axes(tab);
            set(ax ...
                ,guiParams.axesParams{:}...
                ,'ActivePositionProperty', 'outerposition'...
                ,'position', [0.03 0.075 0.965 0.9]);
            ax.XLabel.String = 'time (s)';
            ax.YLabel.String = objData.measurementList(1).dataTypeLabel;
            hold(ax,'on');
            
            % get channel table
            M = tableFromMeaslist(objData.measurementList);
            if isempty(objData.measurementList(1).dataTypeLabel)
                obj.labelAxes(obj.iProc) = "intensity";
            elseif strcmpi(objData.measurementList(1).dataTypeLabel, 'dod')
                obj.labelAxes(obj.iProc) = "dod";
            elseif strcmpi(objData.measurementList(1).dataTypeLabel(1:2), 'hb')
                obj.labelAxes(obj.iProc) = "dc";
            else
                obj.labelAxes(obj.iProc) = "unknown";
            end
            set(ax, 'tag', char(obj.labelAxes(obj.iProc)));
            L = obj.parent.layout.link;
            L.id = (1:size(L,1))';
            M = join(M,L);
            h = zeros(size(L,1),2);

            % run through channels
            for iChan = 1:(size(objData.dataTimeSeries,2)) %obj.liChannels
                if M.type(iChan) == M.type(1)
                    id = M.id(iChan);
                    source_ = M.source(iChan);
                    detector_ = M.detector(iChan);
                    if ~M.incl(iChan)
                        rejected = 1;
                        thisLineStyle1 = obj.linestyles(2,1);
                        thisLineStyle2 = obj.linestyles(2,2);
                        addprop = "";
                    else
                        thisLineStyle1 = obj.linestyles(1,1);
                        thisLineStyle2 = obj.linestyles(1,2);
                        addprop = "";
                        rejected = 0;
                    end
                    % find sibling channel
                    channelCoupled = find(M.source == M.source(iChan) & M.detector == M.detector(iChan));
                    % plot channel type 1
                    h1 = plot(ax,objData.time,objData.dataTimeSeries(:, channelCoupled(1)),LineStyle=thisLineStyle1,DisplayName=string(iChan) + "a" + addprop);
                    set(h1, 'Color', obj.colourmap(id,:))
                    set(h1, 'Visible',any(obj.parent.channelsToPlot == id) && M.incl(iChan));
                    set(h1, 'UserData', struct('iChan', id, 'datatype', 1, 'source', source_, 'detector', detector_, 'rejected', rejected, 'selected', any(obj.parent.channelsToPlot == id)))
                    h(M.id(iChan),1) = h1;
                    % plot channel type 2
                    if length(channelCoupled) == 2
                        h2 = plot(ax,objData.time,objData.dataTimeSeries(:, channelCoupled(2)),LineStyle=thisLineStyle2, Color=h1.Color,DisplayName=string(iChan) + "b" + addprop);
                        set(h2, 'Color', obj.colourmap(id,:))
                        set(h2, 'UserData', struct('iChan', id, 'datatype', 2, 'source', source_, 'detector', detector_, 'rejected', rejected, 'selected', any(obj.parent.channelsToPlot == id)))
                        set(h2, 'Visible',any(obj.parent.channelsToPlot == id) &&  M.incl(iChan));
                        h(M.id(iChan),2) = h2;
                    else
                        warning("no sibling channel")
                    end
                end
            end
        end




        function addbuttons(obj)
            pan = obj.panel;
            pix = getpixelposition(obj.lines(1).Parent.Parent.Parent);
            obj.buttons.buttonZoomIn = uicontrol(pan, "Style","togglebutton","String","+", "Units","pixel", "Position",[25, pix(4)-60, 20, 20]);
            set(obj.buttons.buttonZoomIn, "Callback", @callback.steps.buttonZoom)
            % set(buttonZoomIn)
            obj.buttons.buttonZoomOut = uicontrol(pan, "Style","togglebutton","String","-", "Units","pixel", "Position",[25+25, pix(4)-60, 20, 20]);
            set(obj.buttons.buttonZoomOut, "Callback", @callback.steps.buttonZoom)
            set(obj.buttons.buttonZoomOut, "Max", -1)
            set(obj.buttons.buttonZoomOut, "UserData", obj.buttons.buttonZoomIn)
            set(obj.buttons.buttonZoomIn, "UserData", obj.buttons.buttonZoomOut)
            obj.buttons.reset = uicontrol(pan, "Style","pushbutton","String","r", "Units","pixel", "Position",[25+25+25, pix(4)-60, 20, 20],'Callback',{@callback.steps.reset, obj});
            obj.buttons.fittoscreen = uicontrol(pan, "Style","pushbutton","String","f", "Units","pixel", "Position",[25+25+25+25, pix(4)-60, 20, 20],'Callback',{@callback.steps.fittoscreen, obj});
            
        end
        function getcolours(obj)
            % create AI-powered colourmap
            b = combinations(0:0.1:0.8,0:0.1:0.8,0:0.1:0.8);
            b.sum = sum(b{:,:},2);
            b.diag = max(b{:, 1:3},[],2) == min(b{:, 1:3},[],2);
            colours = b{b.sum < 2.3 & b.sum > 0.4 & ~b.diag, 1:3};
            n = size(colours,1);
            d = @(x,y)sqrt(sum((x-y).^2, 2));    % distance function


            for i = 2:n-1
                % dd = d(colours(i-1,:),colours(i:end,:));
                dd = zeros(n-i+1,i-1);
                for j = 2:i, dd(:,j-1) = d(colours(j-1,:),colours(i:end,:)); end
                minD = sum(dd.*(((1:(i-1))/(i-1))), 2);
                [~, I] = max(minD, [], 1);
                colours([i, I+i-1],:) = colours([I+i-1, i],:);
            end
            obj.colourmap = colours;


        end
        function plotStim(obj)
            % get positions of the axis to match the data plot
            pos1 = obj.lines(1).Parent.Parent.Position;
            pos2 = obj.lines(1).Parent.Position;
            x1 = pos1(1);
            x2_ = pos2(1);
            w1 = pos1(3);
            w2_ = pos2(3);
            x2 = x2_*w1;
            w2 = w2_*w1;
            panel_ = uipanel(obj.panel, 'Position',[0 0 1 0.1]);
            axstim = axes(panel_, 'Position',[x1+x2, 0, w2, 1]);
            obj.axis_stim = axstim;

            obj.updateStim;
            linkaxes(findobj(obj.panel,'Type','Axes'),'x');
        end
        function updateStim(obj)
            % plots stimuli markers on a separate axis. Plots the whole duration.
            axstim = obj.axis_stim;
            axstim.Children.delete();
            obj.lines_stim = repmat(matlab.graphics.primitive.Patch,0,0);
            pause(0.001)
            stim = obj.parent.meta.stim;
            iLine = 0;
            hold(axstim,"on")

            labels = sort(cellfun(@(x)x(1),{stim.name}));
            
            leg_ = cell(1,length(stim));        % for keeping names for stimuli plot's LEGEND 
            for iStim = 1:length(stim)
                iLine = iLine + 1;
                onset = stim(iStim).data(:,1);
                dur = stim(iStim).data(:,2);
                offset = onset + dur;
                thisColour = obj.colourmap(stim(iStim).name(1) == labels, :);       % for now; optimally, a letter should have a colour?
                ls_ = zeros(size(onset));
                for iTrial = 1:length(onset)        % go through trials for the same stim and plot each
                    UserData = struct('name', stim(iStim).name,'iStim',iStim,'iTrial', iTrial);
                    % ls_(iTrial) = plot(axstim, [onset(iTrial) offset(iTrial)], 0.75*[1 1]+(iStim*0),  'LineWidth', 32, 'DisplayName',stim(iStim).name,'color', thisColour,'UserData',UserData...
                        % ,'ButtonDownFcn',{@callback.stim.select, obj.cm.Children});
                    ls_(iTrial) = patch(axstim, [onset(iTrial) onset(iTrial) offset(iTrial) offset(iTrial)], [0.6 0.9 0.9 0.6]+(iStim*0), thisColour, 'DisplayName',stim(iStim).name,'UserData',UserData...
                       ,'ButtonDownFcn',{@callback.stim.select, obj.cm.Children});
                end
                leg_{iStim} = [string(stim(iStim).name) repmat("",1,length(onset)-1)];
                obj.lines_stim = [obj.lines_stim; ls_];
            end
            hold(axstim,"off")
            set(axstim, 'ylim',[0.5 1])
            set(axstim, 'xlim',obj.lines(1).Parent.XLim)
            set(axstim, 'box','on'...
                ,'XGrid','on','XMinorGrid','on'...
                ,'Color',[0.97 0.97 0.97]...
                ,'YGrid','on','YMinorGrid','on');
            axstim.YTickLabel = {};
            
            legend(axstim,cat(2,leg_{:}));      % print marker legend
            set(obj.lines_stim, 'ContextMenu', obj.cm)     % set callback for right-click
        end
        function plotArtifacts(obj, steps)
            if nargin < 2
                steps = 1:length(obj.parent.data);
            end
            obj.lines_artifact_full.delete;
            hold(obj.axis_stim, 'on');
            iArt = 0;
            for iStep = steps
                data = obj.parent.data(iStep);
                if ~isempty(data.tInc) && any(data.tInc{1} == 0)
                    iArt = iArt + 1;
                    t = data.time;
                    inc = data.tInc{1};
                    t(inc == 1) = [];
                    art_full(iArt) = plot(obj.axis_stim ,t, 0.75*ones(size(t)), '.','MarkerSize',6,'Color', [1 0 0]); %obj.colourmap(iStep,:))
                end

            end
            hold(obj.axis_stim, 'off');
            set(obj.axis_stim, 'ylim', [0.5 1])
            if iArt > 0
                obj.lines_artifact_full = art_full;
            end
        end
        function updatePlots(obj,steps2plot)
            if nargin < 2
                steps2plot = 1:length(obj.parent.data);
            end
            link = obj.parent.layout.link;  
            for iStep = steps2plot
                ln_ = obj.lines(:,:,iStep);
                for iLine = 1:numel(ln_)
                    iChan = ln_(iLine).UserData.iChan;
                    source = ln_(iLine).UserData.source;
                    detector = ln_(iLine).UserData.detector;
                    datatype = ln_(iLine).UserData.datatype;
                    incl = link.incl(link.source == source & link.detector == detector);
                    id = source == obj.parent.data(iStep).mTable.source & detector == obj.parent.data(iStep).mTable.detector &  datatype == obj.parent.data(iStep).mTable.type;
                    set(ln_(iLine), 'XData', obj.parent.data(iStep).time, 'Ydata', obj.parent.data(iStep).dataTimeSeries(:,id), 'LineStyle',obj.linestyles(2-incl,datatype));
                end
            end
            pause(0.001)
        end
        function updateLimitsForNewSubj(obj)
            set([obj.lines(1,1,:).Parent], 'XLimMode', 'auto', 'YLimMode', 'auto');
            pause(0.000001);
            set([obj.lines(1,1,:).Parent], 'XLimMode', 'manual', 'YLimMode', 'manual');
            pause(0.000001);
            [x0, x1] = bounds(obj.parent.data(1).time);
            set(obj.lines_cut(1,:), 'Value', x0);
            set(obj.lines_cut(2,:), 'Value', x1);
            pause(0.001);
        end
        function fitLimitsToData(obj)
            % nStep = size(obj.lines,3);
            iStep = find(obj.tabgroup.SelectedTab == obj.tabgroup.Children,1);
            % for iStep = (nStep-1):nStep
            ln_ = obj.lines(:,:,iStep);
            ln_ = ln_(cat(1, ln_.Visible));
            if ~isempty(ln_)    % it may be the case that there are not visible channels eg all channels selected are rejected
                yMax = max(cat(3,ln_.YData),[],'all');
                yMin = min(cat(3,ln_.YData),[],'all');
                set([obj.lines(1,1,iStep).Parent],'YLim', [yMin yMax]);
                % end
                pause(0.000001);
            end
            [x0, x1] = bounds(obj.parent.data(1).time);
            set(obj.lines_cut(1,:), 'Value', x0);
            set(obj.lines_cut(2,:), 'Value', x1);
            pause(0.001);
        end
        function updateVisible(obj)
            % find which are now visible
            ln_ = obj.lines;
            % link = obj.parent.guiLayout.link;
            selected = obj.parent.guiLayout.link(:,4) > 0;
            accepted = obj.parent.guiLayout.link(:,3) > 0 | obj.parent.plotRejected;
            U = [ln_.UserData];
            visible_after = any([U.source] == obj.parent.guiLayout.link(selected & accepted,1) & [U.detector] == obj.parent.guiLayout.link(selected & accepted,2),1);
            visible_before = [ln_.Visible];
            set(ln_(visible_after & ~visible_before), 'Visible', 'on')
            set(ln_(~visible_after & visible_before), 'Visible', 'off')
            obj.updateVisibleArtline();
            pause(0.001)
        end
        function updateVisibleArtline(obj)
            % channel/time artifacts detected
            if ~isempty(obj.lines_artifact_channel)
                for ln = obj.lines_artifact_channel
                    % other = obj.ln.UserData;
                    set(ln, 'visible', ln.UserData.Visible);
                end
            end
        end
        function presentPlotsDifferently(obj,type, steps)
            arguments
                obj guinirsSteps
                type string {mustBeMember(type, ["parallel" "centered" "original" "toggle" "same"])} = "toggle"
                steps = [1:length(obj.parent.data)]
            end
            if type == "toggle"
                if obj.presentation == "parallel"
                    obj.presentation = "centered";
                else
                    obj.presentation = "parallel";
                end
            elseif type == "same"
            else
                obj.presentation = type;
            end
            if obj.presentation == "parallel"
                factor_parallel = 0.15;
                factor_centre   = 0;
            elseif obj.presentation == "centered"
                factor_parallel = 0;
                factor_centre   = 1;
            elseif obj.presentation == "original"
                factor_parallel = 0;
                factor_centre   = 0;
            end
            obj.lines_artifact_channel.delete;
            obj.lines_artifact_channel = repmat(matlab.graphics.chart.primitive.Line, 0, 0);
            lines_artifact_ = zeros(1,10000);       % preallocating memory; let's hope it is not bigger than that?
            iLineArt = 0;
            link = obj.parent.layout.link;  
            for iStep = steps
                ln_ = obj.lines(:,:,iStep);
                if iStep == 1           % the first we always keep as logarithmic scale
                    obj.updatePlots(1);
                    set(ln_(1).Parent, 'YScale', 'log')
                else                    % the others can be parallel or centered
                    [mx, mn] = bounds(obj.parent.data(iStep).dataTimeSeries, 1, 'omitnan'); dchan = mx-mn;
                    % if abs(dchan) > 0.01
                    %     dchan = 1;
                    % else
                    %     dchan = 0.00002;
                    % end
                    dchan = median(abs(dchan));
                    if dchan > 0.001
                        dchan = 0.5;
                    else
                        dchan = dchan*2;
                    end
                    for iLine = 1:numel(ln_)
                        iChan = ln_(iLine).UserData.iChan;
                        source = ln_(iLine).UserData.source;
                        detector = ln_(iLine).UserData.detector;
                        datatype = ln_(iLine).UserData.datatype;
                        incl = link.incl(link.source == source & link.detector == detector);
                        id = source == obj.parent.data(iStep).mTable.source & detector == obj.parent.data(iStep).mTable.detector &  datatype == obj.parent.data(iStep).mTable.type;
                        set(ln_(iLine), 'XData', obj.parent.data(iStep).time, 'Ydata', dchan*double(iChan)*factor_parallel-factor_centre*mean(obj.parent.data(iStep).dataTimeSeries(:,id))+obj.parent.data(iStep).dataTimeSeries(:,id), 'LineStyle',obj.linestyles(2-incl,datatype));
                        % this part below should go to its own component
                        if ~isempty(obj.parent.data(iStep).tIncCh) && any(obj.parent.data(iStep).tIncCh{1}(:,iLine) == 0)
                            iLineArt = iLineArt + 1;
                            I = obj.parent.data(iStep).tIncCh{1}(:,iLine) == 1;
                            if any(~I)
                                t = ln_(iLine).XData;
                                y = ln_(iLine).YData;
                                t(I) = NaN;
                                y(I) = NaN;
                                lines_artifact_(iLineArt) = plot(ln_(iLine).Parent,t,y,'-','linewidth',2*ln_(iLine).LineWidth,'color',[1 0.75 1],'UserData',ln_(iLine),'visible', ln_(iLine).Visible);
                            end
                        end
                    end
                end
            end
            if iLineArt > 0
                obj.lines_artifact_channel = lines_artifact_(1:iLineArt);
            end
        end
        function updateRejectedLinestyle(obj)
            link = obj.parent.layout.link;

            for iStep = 1:size(obj.lines,3)
                ln_ = obj.lines(:,:,iStep);
                for iLine = 1:numel(ln_)
                    % iChan = ln_(iLine).UserData.iChan;
                    source = ln_(iLine).UserData.source;
                    detector = ln_(iLine).UserData.detector;
                    datatype = ln_(iLine).UserData.datatype;
                    incl = link.incl(link.source == source & link.detector == detector);
                    % id = source == obj.parent.data(iStep).mTable.source & detector == obj.parent.data(iStep).mTable.detector &  datatype == obj.parent.data(iStep).mTable.type;
                    set(ln_(iLine), 'LineStyle',obj.linestyles(2-incl,datatype));
                end
            end
        end
    end
end