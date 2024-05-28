classdef guinirsSettings < handle
    properties
        panel           matlab.ui.container.Panel
        parent          guinirsClass
        showRejected    logical = false;
        tabs            struct
        controls        = struct;
        tableChannels   matlab.ui.control.Table
    end
    methods
        function obj = guinirsSettings(parent, panel)
            obj.panel = panel;
            obj.parent = parent;

            tabgroup  = uitabgroup(uipanel('parent',obj.panel,'Units','normalized','Position',[0 0 1 1]));
            tabs.pipeline = uitab('Parent',tabgroup,'Title','pipeline','BackgroundColor',[0.9 0.9 0.92]);

            tabs.plots = uitab('Parent',tabgroup,'Title','plots','BackgroundColor',[0.9 0.92 0.9]);
            obj.tabs = tabs;

            obj.tabs.channels = uitab('Parent',tabgroup,'Title','channels','BackgroundColor',[0.92 0.9 0.9]);
            % obj.controls = struct('plots', struct, 'preproc', struct);
            obj.tabs.artifactdetection = uitab('Parent',tabgroup,'Title','artifact detection','BackgroundColor',[0.9 0.9 0.9]);
            obj.tabs.stim = uitab('Parent',tabgroup,'Title','stimuli','BackgroundColor',[0.92 0.92 0.9]);



        end
        function init(obj)
            obj.initPlots;
            obj.initChannels;
            obj.initArtifactdetection;
            obj.initPipeline;
        end
        function initChannels(obj)
            tab = obj.tabs.channels;
            link = obj.parent.layout.link;
            obj.tableChannels = uitable(tab,'Data',link{:,:}, 'ColumnName',link.Properties.VariableNames,'ColumnEditable',[false false false true], 'Units','normalized','Position',[0 0 0.5 1],'CellEditCallback',{@callback.settings.channels.updaterejections, obj.parent},'CellSelectionCallback',{@callback.settings.channels.togglechannelinclusion, obj.parent});
        end
        function updateTableChannels(obj)
            obj.tableChannels.Data = obj.parent.layout.link{:,:};
            incl =  obj.parent.layout.link.incl;
            inout = [[0 1 0];[1 0 0]];
            obj.tableChannels.BackgroundColor = [0.9*ones(length(incl),1), 0.3*ones(length(incl),1), 0.3*ones(length(incl),1)];
            obj.tableChannels.BackgroundColor(incl,1) = 0.3;
            obj.tableChannels.BackgroundColor(incl,2) = 0.9;
            obj.tableChannels.Position = [0 0 0.9 1];
        end
        function initPlots(obj)
            tab = obj.tabs.plots;
            obj.controls.plots.showrejected = uicontrol('Parent',tab,'Style','checkbox','String','Show Rejected Channels','Units','normalized','Position',[0 0 0.2 0.1],'Visible','on','Callback',{@callback.settings.plots.showrejected, obj.parent});
            obj.controls.plots.deselectAll = uicontrol('Parent',tab,'Style','pushbutton','String','Deselect all channels','Units','normalized','Position',[0 0.1 0.1 0.05],'Visible','on','Callback',{@callback.settings.plots.deselectAll, obj.parent});
            obj.controls.plots.selectAll = uicontrol('Parent',tab,'Style','pushbutton','String','Select all channels','Units','normalized','Position',[0 0.2 0.1 0.05],'Visible','on', 'Callback',{@callback.settings.plots.selectAll, obj.parent});
            
            obj.controls.plots.fixaxes = uicontrol('Parent',tab,'Style','checkbox','String','fix axes','Units','normalized','Position',[0 0.5 0.1 0.05],'Visible','on', 'Callback',{@callback.settings.plots.fixaxes, obj.parent});
            
            % plot areas
            areas = {[13,14,15,33,34,47,48,36,37,38,41,42,43,44], [1,2,3,4,28,29,30,10,11,12,31,32,45,46], [5,6,7,18,19,20,21,22,39,40] , [8,9,23,24,25,26,27,50,51,52], [16,17,35,49]};
            for iArea = 1:length(areas)
                thisArea = areas{iArea};
                obj.controls.plots.("selectArea" + iArea) = uicontrol('Parent',tab,'Style','pushbutton','String',"Select area " + iArea ,'Units','normalized','Position',[0.6, 0.2 + 0.06*iArea, 0.1, 0.05],'Visible','on', 'Callback',{@callback.settings.plots.showX, obj.parent, thisArea});

            end
            thisArea = obj.parent.layout.link.id(~obj.parent.layout.link.incl);
            obj.controls.plots.("selectRejected") = uicontrol('Parent',tab,'Style','pushbutton','String',"Select rejected" ,'Units','normalized','Position',[0.6, 0.2 + 0.06*(iArea+3), 0.1, 0.05],'Visible','on', 'Callback',{@callback.settings.plots.showX, obj.parent, thisArea});

        end
        function initArtifactdetection(obj)
            tab = obj.tabs.artifactdetection;
            obj.controls.artifactdetection.removeend = uicontrol('Parent',tab,'Style','pushbutton','String','remove from end','Units','normalized','Position',[0 0.2 0.1 0.05],'Visible','on', 'Callback',{@callback.settings.artifactdetection.removeend, obj.parent});

        end
        function initPipeline(obj)
            fontsize = 10;
            tab = obj.tabs.pipeline;
            delete(tab.Children);

            steps = obj.parent.steps;
            y__y = 0.06;
            x0 = 0.05;

            % plot pipeline steps...
            obj.controls.pipeline.steps = repmat(struct('name', '', 'input', struct), 1, length(steps));
            for iStep = 1:length(steps)
                y0 = (iStep-1)*y__y*1.2;
                thiscolour = obj.parent.guiSteps.colourmap(4+mod(sum(extractBefore([steps(iStep).name ' '],' ')), size(obj.parent.guiSteps.colourmap,1))+1,:);
                obj.controls.pipeline.steps(iStep).plot = uicontrol('Parent',tab,'Style','checkbox','String','','Units','normalized','Position',[0 y0 0.02 y__y],'Visible','on', 'BackgroundColor',thiscolour + (1-thiscolour)/2,'FontSize',fontsize); % ,'Value',steps(iStep).name
                obj.controls.pipeline.steps(iStep).disable = uicontrol('Parent',tab,'Style','checkbox','String','','Units','normalized','Position',[x0/2 y0 0.02 y__y],'Visible','on', 'BackgroundColor',thiscolour + (1-thiscolour)/2,'FontSize',fontsize); % ,'Value',steps(iStep).name
                obj.controls.pipeline.steps(iStep).name = uicontrol('Parent',tab,'Style','text','String',steps(iStep).name,'Units','normalized','Position',[x0 y0 0.15 y__y],'Visible','on', 'BackgroundColor',thiscolour + (1-thiscolour)/2,'FontSize',fontsize); % ,'Value',steps(iStep).name
                if ~isempty(steps(iStep).input)
                    nameInputs = fieldnames(steps(iStep).input);
                    for iInput = 1:length(nameInputs)
                        obj.controls.pipeline.steps(iStep).var(iInput) = uicontrol('Parent',tab,'Style','text','String',nameInputs{iInput},'Units','normalized','Position',[x0+iInput*0.15,y0 , 0.075, y__y],'Visible','on', 'BackgroundColor',thiscolour + (1-thiscolour)*0.65,'FontSize',fontsize); % ,'Value',steps(iStep).(nameInputs{iInput})
                        obj.controls.pipeline.steps(iStep).input.(nameInputs{iInput}) = uicontrol('Parent',tab,'Style','edit','String',mat2str(steps(iStep).input.(nameInputs{iInput})),'Units','normalized','Position',[x0+0.075+iInput*0.15, y0, 0.075, y__y],'Visible','on', 'BackgroundColor',thiscolour + (1-thiscolour)*0.9,'FontSize',fontsize); % ,'Value',steps(iStep).(nameInputs{iInput})
                    end
                end
            end
            % obj.controls.pipeline.runstep = uicontrol('Parent',tab,'Style','pushbutton','String','Run Current','Units','normalized','Position',[0 0.9 0.1 0.1],'Callback',{@callback.settings.currentstep.run, obj.parent ,"current"}, 'FontSize',fontsize);
            % obj.controls.pipeline.runallforward = uicontrol('Parent',tab,'Style','pushbutton','String','Run Forward','Units','normalized','Position',[0.1 0.9 0.1 0.1],'Callback',{@callback.settings.currentstep.run, obj.parent ,"forward"}, 'FontSize',fontsize);
            
            % run button
            obj.controls.pipeline.runthis = uicontrol('Parent',tab,'Style','pushbutton','String','run','Units','normalized','Position',[0.0 0.915 0.075 0.075],'Callback',{@callback.settings.pipeline.run, obj.parent, "current"}, 'FontSize',fontsize,'BackgroundColor',[0.8 1 0.8]);
            
            obj.controls.pipeline.runall = uicontrol('Parent',tab,'Style','pushbutton','String','run all','Units','normalized','Position',[0.9 0.4 0.075 0.075],'Callback',{@callback.settings.pipeline.run, obj.parent, "all"}, 'FontSize',fontsize,'BackgroundColor',[0.8 1 0.8]);
            y_ = 0.9;
            % choose steps
            obj.controls.pipeline.whichstepText = uicontrol('Parent',tab,'Style','text','String',"steps:",'Units','normalized','Position',[0 0.875 0.05 0.05], 'FontSize',fontsize);
            obj.controls.pipeline.whichstep = uicontrol('Parent',tab,'Style','popupmenu','String',["current" "forward" "all"],'Units','normalized','Position',[0 0.875 0.1 0.05],'Callback',{@callback.test}, 'FontSize',fontsize, 'Value', 3);

            % choose subjects
            % obj.controls.pipeline.whichrunText = uicontrol('Parent',tab,'Style','text','String',"runs:",'Units','normalized','Position',[0.25 0.925 0.05 0.05], 'FontSize',fontsize);
            % obj.controls.pipeline.whichrun = uicontrol('Parent',tab,'Style','popupmenu','String',["current" "forward" "all"],'Units','normalized','Position',[0.3 0.925 0.1 0.05],'Callback',{@callback.test}, 'FontSize',fontsize, 'Value', 1);

            % obj.controls.pipeline.allsubjects = uicontrol('Parent',tab,'Style','checkbox','String','Run For All Subjects','Units','normalized','Position',[0.4 0.9 0.2 0.1],'Value',0, 'FontSize',fontsize,'BackgroundColor',tab.BackgroundColor);
            [~, filenames] = fileparts(obj.parent.listFiles);
            obj.controls.pipeline.subjpick = uicontrol('Parent',tab,'Style','listbox','String',filenames,'Units','normalized','Position',[0.9 0.5 0.1 0.5], 'FontSize',fontsize,'BackgroundColor',[1 1 1], 'Callback',{@callback.settings.pipeline.subjpick, obj.parent});
            % obj.controls.pipeline.included = uicontrol('Parent',tab,'Style','','String','included','Units','normalized','Position',[0.9 0.2 0.1 0.05], 'FontSize',fontsize,'BackgroundColor',[1 1 1], 'Callback',{@callback.settings.pipeline.include, obj.parent}, 'Value',obj.parent.meta.included, 'BackgroundColor',[0.8 0.2 0.1]*(~obj.parent.meta.included) + [0.2 0.8 0.1]*obj.parent.meta.included);

            obj.controls.pipeline.included = uibuttongroup(tab,'Units','normalized','Position',[0.8 0.7 0.075 0.3],'BackgroundColor',tab.BackgroundColor,'Title','Inclusion','SelectionChangedFcn',{@callback.settings.pipeline.include, obj.parent});
            uicontrol('Parent',obj.controls.pipeline.included,'Style', 'togglebutton',"String","na", "Position",[0 0 80 20]);
            uicontrol('Parent',obj.controls.pipeline.included,'Style', 'togglebutton',"String","rejected", "Position",[0 20 80 20]);
            uicontrol('Parent',obj.controls.pipeline.included,'Style', 'togglebutton',"String","ambiguous", "Position",[0 40 80 20]);
            uicontrol('Parent',obj.controls.pipeline.included,'Style', 'togglebutton',"String","accepted", "Position",[0 60 80 20]);
            

        end
        % function initStim(obj)
        %     % tab = obj.tabs.stim;
        % 
        % end
    end
end