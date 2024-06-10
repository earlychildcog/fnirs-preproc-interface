classdef guinirsClass < handle
    properties
        filename        char
        filename_currentprocessed char = ''
        listFiles       string
        folderExport    string

        labels          string
        channelsToPlot  double = [1 2 3]
        mlActTable      table
        probe           ProbeClass
        acquired        SnirfClass
        exclusions
        steps           struct
        plotRejected    logical = false
        hFig            matlab.ui.Figure
        % list acquired  for future...
        listAcquired
        ParallelPool        parallel.ProcessPool
        fnPreload       = "prestepRun"

        % process done so far
        subjTable       table
        flagComputed    logical
        savemedium      string {mustBeMember(savemedium, ["disk" "memory"])} = "memory"
        saved
        computing       uint8 = 0
        debuglvl        string = ["log" "debug" "warning"]
        % data modules (subject/run level)
        data            nirsDataClass        % array with raw/dod/dc data, for each step
        layout          nirsLayout
        meta            nirsMeta

        % metadata global
        guimeta

        % gui modules
        guiSettings     guinirsSettings
        guiLayout       guinirsLayout
        guiSteps        guinirsSteps

        guiMenu
    end
    methods
        function gui = guinirsClass(input, channelsToPlot)
            arguments
                input string {mustBeFileOrFolder} = string([])
                channelsToPlot double = []
            end
            % set data filenames
            if ~isempty(input)
                if isfile(input)
                    gui.filename = input;
                    gui.listFiles = string(gui.filename);
                elseif isfolder(input)
                    gui.listFiles = arrayfun(@(x)string(fullfile(x.folder, x.name)), dir(fullfile(input, "*.snirf")));
                    gui.filename = gui.listFiles(1);
                else
                    error("input provided is not a file or a folder")
                end
                if ~isempty(channelsToPlot)
                    gui.init;
                    stepRun(gui);
                    gui.guibuild(channelsToPlot)
                end
            end
        end

        function init(gui)
            arguments
                gui   guinirsClass
            end
            nSubj = length(gui.listFiles);
            assert(nSubj > 0, "No snirf files detected or provided by user.")
            datafolder = fileparts(gui.filename);
            if isempty(gui.folderExport)
                gui.folderExport = fullfile(datafolder, 'processed');
                mkdir(gui.folderExport);
            end
            [~, subj] = fileparts(fileparts(gui.listFiles));
            gui.subjTable = table(gui.listFiles, subj, false(nSubj,1), 'VariableNames',["filename" "run" "processed"]);
            gui.subjload(gui.filename);
            gui.steps = stepConstructor();
            gui.guiLayout = guinirsLayout(gui);
            gui.checkParallelPool;
        end
        function enable(guinirs)
            % USES JAVA OBJECTS WHICH ARE UNDOCUMENTED IN MATLAB
            % disable the gui while preprocessing takes place
            warning off
            jFigPeer = get(handle(guinirs.hFig),'JavaFrame'); 
            jWindow = jFigPeer.fHG2Client.getWindow;
            warning on
            set(handle(jWindow),'Enabled',true)  % or true
        end
        function disable(guinirs)
            % USES JAVA OBJECTS WHICH ARE UNDOCUMENTED IN MATLAB
            % disable the gui while preprocessing takes place
            warning off
            jFigPeer = get(handle(guinirs.hFig),'JavaFrame'); 
            jWindow = jFigPeer.fHG2Client.getWindow;
            warning on
            set(handle(jWindow),'Enabled',false)  % or true
        end
        % load a subject ----> o|o
        function subjload(guinirs, newfilename)
            % guinirs.disable;
            if guinirs.flagComputed     % if we have computed this subject, save it for later
                guinirs.save();
                % parfeval(@parsave, 1, guinirs);
            end
            guinirs.filename = newfilename;
            guinirs.flagComputed = guinirs.subjTable.processed(guinirs.subjTable.filename == string(guinirs.filename));
            if guinirs.savemedium == "disk"
                if ~exist(strrep(guinirs.filename,".snirf",".mat"),'file')
                    guinirs.flagComputed = false;
                    guinirs.subjTable.processed(guinirs.subjTable.filename == string(guinirs.filename)) = false;
                    warning("mat file not found, subject changed to status non-processed")
                else
                    guinirs.flagComputed = true;
                    guinirs.subjTable.processed(guinirs.subjTable.filename == string(guinirs.filename)) = true;
                end
            end
            if guinirs.flagComputed     % if we already have run the preprocessing steps
                guinirs.load
                guinirs.probe = guinirs.acquired.probe;
                guinirs.updateAllPlots
                guinirs.guiSteps.updateLimitsForNewSubj;
            else
                guinirs.acquired = SnirfClass(guinirs.filename);
                try
                    guinirs.acquired = preload.(guinirs.fnPreload)(guinirs.acquired);
                catch err
                    warning(err.identifier ,"[ERROR] Preload script exitted with error:\n\t%s", err.message)
                end
                guinirs.probe = guinirs.acquired.probe;
                guinirs.meta = nirsMeta(guinirs);
                guinirs.meta.stim = guinirs.acquired.stim;
                guinirs.layout = nirsLayout(guinirs);
            end
            if ~isempty(guinirs.guiSettings)
                guinirs.guiSettings.controls.pipeline.included.SelectedObject.String = char(guinirs.meta.included);
                callback.settings.pipeline.include(guinirs.guiSettings.controls.pipeline.included)
                guinirs.guiSettings.updateTableChannels;
            end
            % guinirs.enable;
        end



        % adds the computed data to the "data" structure for plotting xxx
        function addProc(gui, dataobj, iStep, label,opts)
            arguments
                gui guinirsClass
                dataobj DataClass
                iStep = length(gui.data) + 1
                label string = gui.steps(iStep).name
                opts.tIncAutoCh = [];
                opts.tIncAuto = [];
            end
            persistent colour_old           % for visualisation of progress
            colour_new = [1 1 0.75];
            gui.data(iStep) = nirsDataClass(dataobj, opts.tIncAuto, opts.tIncAutoCh);
            gui.labels(iStep) = label;
            % changes colour if figure window is open
            if ~isempty(gui.guiSettings) && ~isempty(gui.hFig) && isvalid(gui.hFig)
                if iStep > 1
                    gui.guiSettings.controls.pipeline.steps(iStep).name.ForegroundColor = [0 0 0];
                    gui.guiSettings.controls.pipeline.steps(iStep).name.FontWeight = 'normal';
                    gui.guiSettings.controls.pipeline.steps(iStep).name.BackgroundColor = colour_old(1,:);
                    if ~all(isnan(colour_old(2,:)))
                        structfun(@(x)set(x, 'BackgroundColor', colour_old(2,:)), gui.guiSettings.controls.pipeline.steps(iStep).input)
                        arrayfun(@(x)set(x, 'BackgroundColor', colour_old(3,:)), gui.guiSettings.controls.pipeline.steps(iStep).var)

                    end
                    pause(0.000001)
                end
                if iStep < length(gui.steps)
                    colour_old(1,:) = gui.guiSettings.controls.pipeline.steps(iStep+1).name.BackgroundColor;
                    s = gui.guiSettings.controls.pipeline.steps(iStep+1).input;
                    fields = fieldnames(s);
                    if ~isempty(fields)
                        ss = s.(fields{1});
                        colour_old(2,:) = ss.BackgroundColor;
                        colour_old(3,:) = gui.guiSettings.controls.pipeline.steps(iStep+1).var(1).BackgroundColor;
                    else
                        colour_old(2:3,:) = nan(2,3);
                    end
                    gui.guiSettings.controls.pipeline.steps(iStep+1).name.ForegroundColor = [1 0.25 0.25];
                    gui.guiSettings.controls.pipeline.steps(iStep+1).name.FontWeight = 'bold';
                    gui.guiSettings.controls.pipeline.steps(iStep+1).name.BackgroundColor = colour_new;
                    structfun(@(x)set(x, 'BackgroundColor', colour_new), gui.guiSettings.controls.pipeline.steps(iStep+1).input)
                    arrayfun(@(x)set(x, 'BackgroundColor', colour_new), gui.guiSettings.controls.pipeline.steps(iStep+1).var)
                    pause(0.000001)
                end
            end
        end
        %==================================================================
        function guibuild(obj, channelsToPlot)
            arguments
                obj     guinirsClass
                channelsToPlot = [13,14,15,33,34,47,48,36,37,38,41,42,43,44]
            end
            % liChannels: channels to plot
            % this function is to be called _after_ the data has been preprocessed
            obj.channelsToPlot = channelsToPlot;
            guinirs.computing = 0;

            % close previous figure if open
            if ~isempty(obj.hFig)
                try
                    close(obj.hFig);
                    delete(obj.hFig);
                catch
                end
            end

            %% Create window
            % Make figure:
            obj.hFig = figure('Color',[1 1 1], "Units", "normalized", "WindowState","maximized", "ToolBar","none","MenuBar","none","Name","fNIRS Preprocessing Tool","NumberTitle","off","SelectionType","extend");
            pause(1)
            obj.guiMenu.file = uimenu(obj.hFig,'Text','File');
            obj.guiMenu.view = uimenu(obj.hFig,'Text','View');
            uimenu(obj.guiMenu.file,'Text','Import');
            uimenu(obj.guiMenu.file,'Text','Export (current)','MenuSelectedFcn',{@callback.menu.file.export1,obj});
            uimenu(obj.guiMenu.file,'Text','Export (all)','MenuSelectedFcn',{@callback.menu.file.exportAll,obj});
            uimenu(obj.guiMenu.view,'Text','Reset');
            % Make panels:
            panel_steps     = uipanel(obj.hFig, "Units", "normalized", "Position",[0 0 1 0.6], "Title","preprocessing steps");
            pause(0.05)
            panel_layout    = uipanel(obj.hFig, "Units", "normalized", "Position",[0 0.6 0.3 0.4], "Title","layout");
            pause(0.05)
            panel_settings  = uipanel(obj.hFig, "Units", "normalized", "Position",[0.3 0.6 0.7 0.4], "Title","settings");
            pause(0.05)
            obj.guiLayout.init(panel_layout);
            obj.guiSettings = guinirsSettings(obj,panel_settings);
            pause(0.05)
            obj.guiSteps = guinirsSteps(obj,panel_steps);
            pause(0.05)
            %% Plotting
            % Plot layout
            obj.guiLayout.plotChannelLayout;
            pause(0.05)
            % Plot Data
            if isempty(obj.data)
                obj.load;
                obj.labels = string({obj.steps.name});
            end
            obj.guiSteps.plotDataScalar(panel_steps);
            obj.guiLayout.rerenderRejected;
            obj.guiSteps.init;
            obj.guiSteps.presentPlotsDifferently("parallel");
            obj.guiSteps.updateVisibleArtline;      % we should sort of regularise all this plotting to use the update functions  (and plot placeholders in the beginning)
            pause(0.05)

            % link axes together
            linkaxes(findobj(obj.guiSteps.panel,'Type','Axes'),'x');
            ax_data = [obj.guiSteps.lines(1,1,:).Parent];
            linkaxes(ax_data(strcmp({ax_data.Tag}, 'dod')),'y');

            % link layout to plot
            arrayfun(@(cLay)set(cLay,'ButtonDownFcn',{@callback.layout.togglechannelvisible, obj.guiSteps.lines(cLay.UserData.iChan,:,:)}), obj.guiLayout.linesChannels);
            obj.guiSteps.addbuttons;
            obj.guiSettings.init;


        end

        function disablezoom(obj)
            zoom off    % in case zoom was on
            obj.guiSteps.buttons.buttonZoomIn.set("Value",0)
            obj.guiSteps.buttons.buttonZoomOut.set("Value",0)
        end
        function updateRejected(obj, onoff)
            if nargin > 1
                obj.plotRejected = onoff;
            end
            % update plotting rejected channels on and off
            set(obj.guiSteps.lines(obj.guiLayout.link(:,3) == 0 & obj.guiLayout.link(:,4) == 1,:,:), 'Visible',obj.plotRejected)
        end

        function updateSteps(guinirs)
            steps_gui = guinirs.guiSettings.controls.pipeline.steps;
            for iStep = 1:length(guinirs.steps)
                if ~isempty(guinirs.steps(iStep).input)
                    listInputs = string(fieldnames(guinirs.steps(iStep).input));
                    for iInput = 1:length(listInputs)
                        guinirs.steps(iStep).input.(listInputs(iInput)) = str2num(steps_gui(iStep).input.(listInputs(iInput)).String); %#ok<ST2NM>
                    end
                end
            end
        end

        function rerun(guinirs, type)
            arguments
                guinirs     guinirsClass
                type        string {mustBeMember(type, ["current", "forward", "all"])} = "all"
            end
            guinirs.updateSteps;        % implement parameter changes from gui
            if type == "all"
                stepRun(guinirs, 1);
            else
                iStep = guinirs.guiSteps.tabgroup.SelectedTab.UserData;     % this is the id of the active tab
                if type == "current"
                    stepRun(guinirs, iStep, true);
                elseif type == "forward"
                    stepRun(guinirs, iStep);
                end
            end
            guinirs.updateAllPlots
            if ~strcmp(guinirs.filename_currentprocessed,guinirs.filename)
                guinirs.guiSteps.updateLimitsForNewSubj;
                % disp(132)
                guinirs.filename_currentprocessed = guinirs.filename;
                % guinirs.guiLayout.rerenderRejected;
            end
            % update gui
        end
        function updateAllPlots(guinirs)
            % set(guinirs.guiSteps.lines, 'Visible','off')
            guinirs.guiLayout.rerenderRejected;
            guinirs.guiSteps.presentPlotsDifferently("same");
            guinirs.guiSteps.updateVisible;
            guinirs.guiSteps.updateStim        % update gui
            guinirs.guiSteps.plotArtifacts;
            pause(0.001)
            % guinirs.guiSteps.updateLimitsForNewSubj;
        end

        %==================================================================
        function plotStyleParams = getPlotStyleParams(obj)
            % getPlotStyleParams Returns plotting style parameters.
            %
            %--------------------------------------------------------------
            % Define plot style:
            plotStyleParams.axesParams         = ...
                {'box','on'...
                ,'XGrid','on','XMinorGrid','on'...
                ,'Color',[0.97 0.97 0.97]...
                ,'YGrid','on','YMinorGrid','on'...
                ,'ActivePositionProperty','outerposition'};
        end

        function addROI(obj, ROI)
            obj.guimeta.roi{end+1} = ROI;
        end


        function checkParallelPool(obj)
            pp = gcp('nocreate');
            if isempty(pp)
                warning("no parallel pool found; consider creating one calling the 'startParallelPool' method")
            elseif isa(pp, 'parallel.ThreadPool')
                warning("you have a threads parallel pool active. HIGHLY RECOMMENDED: Consider closing it down and opening a 'process' parallel pool in order to have parallel processing capabilities with this toolbox. Use the 'startParallelPool' method to do that.")

            elseif isa(pp, 'parallel.ProcessPool')
                obj.ParallelPool = pp;
                return
            end
        end

        function startParallelPool(obj, nCores)
            % start parallel pool with specified number of cores (by default all but 2 of the corse of the computer)
            if nargin < 2 || isempty(nCores)
                maxCores = feature('numcores');
                if maxCores > 4
                    nCores = maxCores-2;
                elseif maxCores > 2
                    nCores = maxCores-1;
                elseif maxCores == 2
                    nCores = maxCores;
                elseif nCores == 1
                    warning("only 1 core detected, consdier updating your computer if possible if you run data intensive tasks")
                else
                    warning("impossible to set parallel pool")
                end
            end
            pp = gcp('nocreate');
            if ~isempty(pp)
                if isa(pp, 'parallel.ThreadPool')
                    pp.delete
                elseif isa(pp, 'parallel.ProcessPool')
                    obj.ParallelPool = pp;
                    return
                else
                    pp.delete       % may give error
                end
            end
            obj.ParallelPool = parpool("Processes",nCores);
        end

        function save(obj)
            obj.print2console("log", "saving subj %s", obj.sessionGet)
            data_ = obj.data;
            layout_ = obj.layout;
            meta_ = obj.meta;
            layout_.parent = [];
            meta_.parent = [];
            acquired_ = obj.acquired;
            if any(obj.savemedium == "disk")
                datafilename = strrep(obj.filename, '.snirf', '.mat');
                % parsave(datafilename, data_, layout_, meta_, acquired_)
                % if ~obj.ParallelPool.Connected
                %     obj.startParallelPool
                % end
                save(datafilename, 'data_', "layout_", "meta_","acquired_");
                pause(0.5)
                % parfeval(obj.ParallelPool, @parsave, 0, datafilename, data_, layout_, meta_, acquired_);   % parallelised
            end
            if any(obj.savemedium == "memory")
                iSubj = find(strcmp(obj.listFiles, obj.filename),1);
                obj.saved{iSubj,1} = data_;
                obj.saved{iSubj,2} = layout_;
                obj.saved{iSubj,3} = meta_;
                obj.saved{iSubj,4} = acquired_;
            end
            obj.print2console("log", "saving complete.")
        end
        function load(obj)
            obj.print2console("log", "loading subj %s", obj.sessionGet)
            if any(obj.savemedium == "memory")
                iSubj = find(strcmp(obj.listFiles, obj.filename),1);
                data_ = obj.saved{iSubj,1};
                layout_ = obj.saved{iSubj,2};
                meta_ = obj.saved{iSubj,3};
                acquired_ = obj.saved{iSubj,4};
            else
                datafilename = strrep(obj.filename, '.snirf', '.mat');
                % Warning: Saved HDF5 identifiers cannot be reloaded in a valid state. 
                warning off
                load(datafilename, 'data_', "layout_", "meta_","acquired_");
                warning on
            end
            layout_.parent = obj;
            meta_.parent = obj;
            obj.data = data_;
            obj.layout = layout_;
            obj.meta = meta_;
            obj.acquired = acquired_;
            obj.filename_currentprocessed = obj.filename;
            obj.print2console("log", "loading complete.")
        end
        function export(guinirs)
            guinirs.print2console("log", "exporting subj %s", guinirs.sessionGet)
            % homer3 methods
            % also save subject!!!
            guinirs.save;
            % load the original data in a new snirf class instance
            S = SnirfClass(guinirs.acquired);
            % load with processed data
            S.data.dataTimeSeries = guinirs.data(end).dataTimeSeries;
            M = innerjoin(guinirs.data(end).mTable, guinirs.layout.link(:,["id" "incl"]));
            S.data.dataTimeSeries(:,~M.incl) = NaN;
            S.data.time = guinirs.data(end).time;
            S.data.measurementList = guinirs.data(end).measurementList;
            S.stim = guinirs.meta.stim;
            % probe is not changed here, right?

            % custom metadata tag
            S.metaDataTags.tags.inclusion = char(guinirs.meta.included);
            % save data
            [~, datafile, ext] = fileparts(guinirs.filename);

            S.Save(char(fullfile(guinirs.folderExport, [datafile ext])));
            guinirs.print2console("log", "export completed")
        end
        function exportAll(guinirs)
            % error("deactivated for now")
            listSubj = string(guinirs.guiSettings.controls.pipeline.subjpick.String);
            nSubj = length(listSubj);
            for iSubj = 1:nSubj
                guinirs.guiSettings.controls.pipeline.subjpick.Value = iSubj;
                guinirs.subjload(guinirs.listFiles(iSubj));
                guinirs.export;
                % if guinirs.meta.included
                %     guinirs.export;
                %     pause(0.001)
                % end
            end
        end
        function print2console(guinirs, debuglvl, message, varargin)
            arguments
                guinirs
                debuglvl string
                message string
            end
            arguments (Repeating)
                varargin
            end
            if ismember(debuglvl, guinirs.debuglvl)
                if debuglvl == "log"
                    debuglvl = string(datetime('now','Format','HH:mm:ss'));
                end
                fprintf('[%s]:', debuglvl)
                fprintf(message, varargin{:}) %#ok<PRTCAL>
                fprintf('\n')
            end
        end
        function session = sessionGet(guinirs)
            session = string(regexp(guinirs.filename, '(\w*)\.snirf','tokens','once'));
        end
        function sqi_result = checkChannelQuality(guinirs, chans)
            % check quality of channels based on SQI (artinis script)
            if length(chans) > 1
                sqi_result = zeros(1,length(chans));
                for iChan = 1:length(chans)
                    sqi_result(iChan) = checkChannelQuality(guinirs, chans(iChan));
                end
            else
                iStep = 1;
                M = guinirs.data(iStep).mTable;
                od = guinirs.data(iStep).dataTimeSeries(:, M.id == chans);
                iStep = 9;
                M = guinirs.data(iStep).mTable;
                dc = guinirs.data(iStep).dataTimeSeries(:, M.id == chans);
                fprintf("channel %d (s%d-d%d): ", chans, M{M.id == chans & M.type == 1, [1 2]});
                sqi_result = SQI(od(:,1)', od(:,2)', dc(:,1)', dc(:,2)', 10);
            end
        end
    end
end