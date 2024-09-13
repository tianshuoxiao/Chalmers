classdef VideoController < handle
    %VIDEOCONTROLLER is the main class upon which several modules depends.
    %   VIDEOCONTROLLER allows for loading and annotating the simulator
    %   data
    
    properties
        H_mainWindow
        H_playerControlWindow
        H_playButton
        H_stopButton
        H_AnnotationsControlWindow
        H_dataLoadingControl
        H_dataLoadedDisp
        H_Video_feet
        H_Video_hands
        H_rewindButton
        H_annotations
        H_signalPlotter
        H_panelVideoControl
        H_savingControl
        H_save
        H_dataLoader
        H_panelAnnotationControl
        H_UtiWindow
        
        currentFrame = 1;
        vid_Nframes
        vid_FrameRate
        event
        
        FPS
        
        modules
        coding
        eventLength
        eventLength_frames
        
        Source

        eventBeingAnnotated
        eventBeingAnnotated_info = 'Nothing loaded';
        
        eventToBeLoaded 
        
        annotationData = [];
    end
    
    events 
        updateFrame_global_forward
        updateFrame_global_backward
    end
    
    methods %(Access = private)
        
        function VC = VideoController(tmp_Source)
            
            VC.Source = tmp_Source;
            
            VC.coding = loadjson(VC.Source.CodingSchemaFile);
                        
            InitGUI(VC);
            
            VC.modules{1} = DataLoader(VC);
            set(VC.modules{1}.H_mainWindow, 'tag', 'Data loader')
            set(VC.modules{1}.H_mainWindow,'CloseRequestFcn', @VC.openModuleWindow)
            addlistener(VC.modules{1}, 'loadNewData', @VC.loadEvent);
        end
        
        
        function InitGUI(VC)
            % Main window
            ScreenSize = get(0, 'ScreenSize');
            Width = 400;
            Height = 150;
            
            VC.H_mainWindow = figure('units', 'pixels',...
                'position', [20, ScreenSize(4)-Height-75, Width, Height],...
                'resize', 'off',...
                'MenuBar','none',...
                'NumberTitle', 'off',...
                'name', 'MAIN CONTROLLER',...
                'WindowScrollWheelFcn', [],... @VC.scrollFrameWheel,...
                'deletefcn', @VC.closeAllModules);
            
            % Container for the interaction with the video
            
            % Create panel
            VC.H_panelVideoControl = uipanel('Parent', VC.H_mainWindow,...
                'Title','Videos','FontSize',10,...
                'Position',[0, 0.65, 1, 0.35]);
            
            VC.H_playerControlWindow = uiflowcontainer('v0', 'parent', VC.H_panelVideoControl,...
                'units', 'normalized',...
                'position', [0, 0, 1, 1]);
            VC.H_Video_feet = uicontrol('parent', VC.H_playerControlWindow, ...
                'String', 'Video feet',...
                'Enable', 'off',...
                'Callback', @VC.openModuleWindow);
            VC.H_Video_hands = uicontrol('parent', VC.H_playerControlWindow, ...
                'String', 'Video hands',...
                'Enable', 'off',...
                'Callback', @VC.openModuleWindow); 
            VC.H_playButton = uicontrol('parent', VC.H_playerControlWindow, ...
                'String', 'Play',...
                'Enable', 'off',...
                'Callback', @VC.playVideos);
            VC.H_stopButton = uicontrol('parent', VC.H_playerControlWindow,...
                'String', 'Pause',...
                'Enable', 'off',...
                'Callback', @VC.stopVideos, ...
                'UserData', false);
            VC.H_rewindButton = uicontrol('parent', VC.H_playerControlWindow,...
                'String', 'Rewind',...
                'Enable', 'off',...
                'Callback', @VC.rewindVideos, ...
                'UserData', false);
            
            
            VC.H_panelAnnotationControl = uipanel('Parent', VC.H_mainWindow,...
                'Title','Annotations','FontSize',10,...
                'Position',[0, 0.30, 1, 0.35]);
            VC.H_AnnotationsControlWindow = uiflowcontainer('v0', 'parent', VC.H_panelAnnotationControl,...
                'units', 'normalized',...
                'position', [0, 0, 0.8, 1]);
            
            for i = 1 : length(VC.coding.schema)
                VC.H_annotations(i) = uicontrol('parent', VC.H_AnnotationsControlWindow, ...
                    'String', VC.coding.schema{i}.variable,...
                    'Enable', 'off',...
                    'Callback', @VC.openModuleWindow);
            end
            
            VC.H_UtiWindow = uiflowcontainer('v0', 'parent', VC.H_panelAnnotationControl,...
                'units', 'normalized',...
                'position', [0.8, 0, 0.2, 1]);
            
            VC.H_signalPlotter = uicontrol('parent', VC.H_UtiWindow, ...
                'String', 'Signal plotter',...
                'Enable', 'off',...
                'Callback', @VC.openModuleWindow);
            
            VC.H_savingControl = uiflowcontainer('v0', 'parent', VC.H_mainWindow,...
                'units', 'normalized',...
                'position', [0, 0, 0.3, 0.3]);
            VC.H_save = uicontrol('parent', VC.H_savingControl, ...
                'String', 'SAVE',...
                'ForegroundColor', [0, 0.5, 0],...
                'fontweight', 'bold',...
                'fontsize', 15,...
                'Enable', 'off',...
                'Callback', @VC.saveAnnotation);
            
            VC.H_dataLoadingControl = uiflowcontainer('v0', 'parent', VC.H_mainWindow,...
                'units', 'normalized',...
                'position', [0.3, 0, 0.7, 0.3]);
            VC.H_dataLoader = uicontrol('parent', VC.H_dataLoadingControl, ...
                'String', 'Data loader',...
                'Callback', @VC.openModuleWindow);
            VC.H_dataLoadedDisp = uicontrol('parent', VC.H_dataLoadingControl,...
                'units', 'characters', ...
                'style', 'text', ...
                'string', VC.eventBeingAnnotated_info,...
                'backgroundcolor', 'white',...
                'fontsize', 8,...
                'fontname', 'fixedwidth',...
                'callback', []);

        end
        
        function notify_frame_changed_forward(VC, ~, ~) % in this way I allow for changing the frame while scrolling
                                                    % (if a pause is not introduced the events are fired faster 
                                                    % than the frame showing function) and the video player to
                                                    % play at the right framerate
                                                    
            currentFrame_past = VC.currentFrame;
            
            VC.currentFrame = min(VC.currentFrame + 1, VC.event(2));
            if VC.currentFrame ~= currentFrame_past % notify only if the frame has changed                                        
                notify(VC, 'updateFrame_global_forward')
                pause(1/VC.vid_FrameRate)
            end
        end
        
        function notify_frame_changed_backward(VC, ~, ~) 
            currentFrame_past = VC.currentFrame;
            
            VC.currentFrame = max(VC.currentFrame - 1, VC.event(1));
            if VC.currentFrame ~= currentFrame_past % notify only if the frame has changed
                notify(VC, 'updateFrame_global_backward')
                pause(1/VC.vid_FrameRate)
            end
        end
        
        function scrollFrameWheel(VC, ~, eventData)
            if eventData.VerticalScrollCount > 0
                notify_frame_changed_forward(VC);
            else
                notify_frame_changed_backward(VC);
            end
        end
        
        function playVideos(VC, ~, ~)
            
            if VC.H_stopButton.UserData
                VC.H_stopButton.UserData = false;
            end
            
            while VC.currentFrame < VC.eventLength_frames
                if VC.H_stopButton.UserData
                    VC.H_stopButton.UserData = false;
                    break
                end
                
                VC.currentFrame = VC.currentFrame + 1;
                notify_frame_changed_forward(VC);
            end
        end

        function stopVideos(VC, ~, ~)
            if VC.H_stopButton.UserData == false
                VC.H_stopButton.UserData = true;
            end
        end
        
        function rewindVideos(VC, ~, ~)
            VC.currentFrame = 1;
            notify(VC, 'updateFrame_global_backward')
        end
        
        function openModuleWindow(~, src, ~)
            
            try % If the event is from the push button
                match = findobj('tag', src.String);
            catch % if the event comes from the close button in the figure
                match = src;
            end
            
            for i = 1 : length(match)
                if isvalid(match(i))
                    if strcmp(match(i).Visible, 'on')
                        match(i).Visible = 'off';
                    else
                        match(i).Visible = 'on';
                    end
                end
            end
        end
        
        
        function closeAllModules(VC, ~, ~)
            try
                for i = 1 : length(VC.modules)
                    if isvalid(VC.modules{i})
                        set(VC.modules{i}.H_mainWindow,'CloseRequestFcn', @(~,~)closereq)
                        close(VC.modules{i}.H_mainWindow);
                        delete(VC.modules{i});
                    end
                end
                delete(VC)
            catch
                close all force
            end
        end
        
        function saveAnnotation(VC, ~, ~)
            annotations = [];
                        
            for i = 1 : length(VC.modules)
                if isa(VC.modules{i}, 'TimeSeriesCoding') && isvalid(VC.modules{i})
                    annotations.(VC.modules{i}.H_mainWindow.Tag) = VC.modules{i}.H_line_annotations.YData;
                end
            end
            
            fileName = fullfile(VC.Source.dataParticipantsFolder,...
                sprintf('%03d',VC.eventBeingAnnotated{1}),...
                sprintf('annotation_%03d_%s.mat', VC.eventBeingAnnotated{1}, VC.eventBeingAnnotated{2}));            
            
            save(fileName, 'annotations')
            disp([fileName ' is saved'])
        end
        
        function loadEvent(VC, ~, ~)
            
            %recreate modules
            VC.currentFrame = 1;
            VC.annotationData = [];
            
            videoFeet = fullfile(VC.Source.dataParticipantsFolder,...
                sprintf('%03d',VC.eventToBeLoaded{1}),...
                sprintf('feet_%03d_BW_10fps_%s.mp4', VC.eventToBeLoaded{1}, VC.eventToBeLoaded{2}));
            
            videoHands = fullfile(VC.Source.dataParticipantsFolder,...
                sprintf('%03d',VC.eventToBeLoaded{1}),...
                sprintf('steer_%03d_BW_10fps_%s.mp4', VC.eventToBeLoaded{1}, VC.eventToBeLoaded{2}));
            
            dataSILAB = fullfile(VC.Source.dataParticipantsFolder,...
                sprintf('%03d',VC.eventToBeLoaded{1}),...
                sprintf('SILABdata_%03d.mat', VC.eventToBeLoaded{1}));
            
            fileAnnotation = fullfile(VC.Source.dataParticipantsFolder,...
                sprintf('%03d',VC.eventToBeLoaded{1}),...
                sprintf('annotation_%03d_%s.mat', VC.eventToBeLoaded{1}, VC.eventToBeLoaded{2}));
            
            if ~strcmp(VC.eventBeingAnnotated_info, 'Nothing loaded')
                Q = questdlg('Save annotations?', 'Save request', 'Yes', 'No', 'Yes');
                switch Q
                    case 'Yes'
                        saveAnnotation(VC)
                    case 'No'
                        disp('Saving aborted')
                end
                % Once the previous event has been saved, the current event
                % becomes the one to be loaded
            end
            
            VC.eventBeingAnnotated = VC.eventToBeLoaded;

            % close and destroy all the modules (but not the data loader)
            for i = 2 : length(VC.modules)
                if isvalid(VC.modules{i})
                    set(VC.modules{i}.H_mainWindow,'CloseRequestFcn', @(~,~)closereq)
                    close(VC.modules{i}.H_mainWindow);
                    delete(VC.modules{i});
                end
            end
            
            % VIDEO MODULES
            VC.modules{2} = VideoWindow(VC, videoFeet);
            set(VC.modules{2}.H_mainWindow, 'tag', 'Video feet')
            set(VC.modules{2}.H_mainWindow,'CloseRequestFcn', @VC.openModuleWindow)

            VC.vid_Nframes = VC.modules{2}.vid_Nframes;
            VC.vid_FrameRate = VC.modules{2}.vid.FrameRate;
            VC.eventLength_frames = VC.modules{2}.vid_Nframes;
            VC.event = [1 , VC.eventLength_frames];
            
            VC.modules{3} = VideoWindow(VC, videoHands);
            set(VC.modules{3}.H_mainWindow, 'tag', 'Video hands')
            set(VC.modules{3}.H_mainWindow,'CloseRequestFcn', @VC.openModuleWindow)
            
            %% ADD SIGNAL PLOTTER
            VC.modules{4} = SignalPlotter(VC);
            set(VC.modules{4}.H_mainWindow, 'tag', 'Signal plotter')
            
            LOADED_Silab = load(dataSILAB);
            dataToPlotY = [LOADED_Silab.Event.(VC.eventBeingAnnotated{2}).SYNC.Timeseries.EGO_brake_pedal',...
                LOADED_Silab.Event.(VC.eventToBeLoaded{2}).SYNC.Timeseries.EGO_accelerator_pedal'];    
            dataToPlotX = [1:length(dataToPlotY(:,1)); 1:length(dataToPlotY(:,1))]';
            
            %TODO%
            % h = repmat(VC.modules{4}.H_signal, 2, 1)
            VC.modules{4}.H_signal.XData = dataToPlotX(:,1);
            VC.modules{4}.H_signal.YData = dataToPlotY(:,1);

            % TIME SERIES CODING
            for i = 1 : length(VC.coding.schema)
                VC.modules{4 + i} = TimeSeriesCoding(VC, VC.coding.schema{i}.categories);
                set(VC.modules{4 + i}.H_mainWindow, 'tag', VC.coding.schema{i}.variable)
                
                if exist(fileAnnotation, 'file') == 2 % Check if the file exists
                    % save a copy for backup purposes
                    s = strsplit(fileAnnotation, '.mat');
                    backupName = sprintf('%s_%s.mat', s{1}, datestr(now, 30));
                    copyfile(fileAnnotation, backupName)

                    LOADED = load(fileAnnotation);
                    VC.modules{4 + i}.H_line_annotations.YData = LOADED.annotations.(VC.coding.schema{i}.variable);
                end  
            end

            % Customize the close function when one presses the [x]
            for i = 1 : length(VC.modules)
                if isvalid(VC.modules{i})
                    set(VC.modules{i}.H_mainWindow,'CloseRequestFcn', @VC.openModuleWindow)
                end
            end
            
            % enable the controls
            VC.enableControls(VC.H_playerControlWindow);
            VC.enableControls(VC.H_AnnotationsControlWindow);
            VC.enableControls(VC.H_savingControl);
            
            % Display the info of the event loaded
            VC.H_dataLoadedDisp.String = sprintf('Event loaded:\nID = %03d\nEvent = %s', VC.eventToBeLoaded{1}, VC.eventToBeLoaded{2});
            VC.eventBeingAnnotated_info = 'Event loaded';

        end
    end
    
    methods (Static)
        function VC = runInstance(DATAfiles)
            % Control the instances of the class and allows only one to be
            % executed
            persistent instance
            if isempty(instance) || ~isvalid(instance)
                instance = VideoController(DATAfiles);
            end
            VC = instance;
        end
        
        function enableControls(parentContainer)
            set(get(parentContainer, 'children'), 'enable', 'on');
        end
    end
    
end

