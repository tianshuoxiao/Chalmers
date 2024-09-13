classdef TimeSeriesCoding < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        parentObj
        
        H_mainWindow
        H_annotations
        H_annotationButton
        H_annotation_graph_container
        H_line_annotations
        H_cursor
        
        Nframes
        currentFrame
        
        annotationCategories
        
    end
    
    events
        moveForward
        moveBackward
    end
    
    methods (Access = ?VideoController)
        function TS = TimeSeriesCoding(VC, codingSchema)
            TS.annotationCategories = codingSchema;
            TS.parentObj = VC;
            
            TS.currentFrame = VC.currentFrame;
            TS.Nframes = VC.eventLength_frames;
            
            addlistener(VC, 'updateFrame_global_forward', @TS.c_moveForward);
            addlistener(VC, 'updateFrame_global_backward', @TS.c_moveBackward);
            
            InitGUI(TS)
            
        end
        
        function InitGUI(TS)
            TS.H_mainWindow = figure('units', 'pixel',...
                'position', [200, 200, 800, 200],...
                'resize', 'on',...
                'MenuBar','none',...
                'renderer','painters', ...
                'doublebuffer','off',...
                'GraphicsSmoothing','off',...
                ...'HandleVisibility','callback',...
                ...'Interruptible', 'off',...
                ...'busyaction', 'cancel',...
                'NumberTitle', 'off',...
                'name', 'Video coding',...
                'SizeChangedFcn',[],...
                'WindowScrollWheelFcn',@TS.scrollFrameWheel,...
                'KeyPressFcn', @TS.scrollFrameKey,...
                'visible', 'off', ...
                'DeleteFcn', [],...
                'CloseRequestFcn', []);
            
            TS.H_annotations = uiflowcontainer('v0', 'parent', TS.H_mainWindow,...
                'units', 'norm',...
                'position', [0, 0, 0.2, 1]);
            
            for i = length(TS.annotationCategories):-1:1
                TS.H_annotationButton(i) = uicontrol('parent', TS.H_annotations, ...
                    'String', TS.annotationCategories{i},...
                    'Callback', @TS.annotate,...
                    'userdata', []);
            end
            
            TS.H_annotation_graph_container = axes('parent', TS.H_mainWindow,...
                'units', 'normalized',...
                'xtick', [],...
                'ytick',[0:length(TS.annotationCategories)-1],...
                'XtickLabel', [],...
                'YtickLabel', [], ...
                'xlim',[1 TS.Nframes], ...
                'ylim', [-0.5 length(TS.annotationCategories)- 0.5], ...
                'Box', 'on',...
                'position', [0.22, 0, 0.76, 1], ...
                'visible', 'on',...
                'ygrid', 'on');
            
            TS.H_line_annotations = line('XData', 1:TS.Nframes,...
                'YData', zeros(1, TS.Nframes, 'int8'),... % !!!!! here I can store the annotation data
                'parent', TS.H_annotation_graph_container, ...
                'Color', [0.8, 0, 0],...
                'Linewidth', 1.5);
            
            %TODO% check this normalization. Maybe not be necessary anymore
            TS.H_cursor = line('XData', TS.currentFrame - TS.parentObj.event(1) + 1,... % The current frame in the annotation is normalized with respect to the event length
                'YData', 0,...
                'parent', TS.H_annotation_graph_container, ...
                'Color', [0.8, 0, 0],...
                'Marker', '.',...
                'Markersize', 20,...
                'Linewidth', 1);
            
        end
        
        function annotate(TS, src, ~)
            [~, codeAnnotation] = ismember(src.String,(TS.annotationCategories));
            codeAnnotation = codeAnnotation - 1; % zero is not coded
            if codeAnnotation
                IDX_start = find(TS.H_line_annotations.YData(1:TS.H_cursor.XData) == 0, 1, 'first');
                if isempty(IDX_start) %overwrite single frame
                    IDX_start = TS.H_cursor.XData;
                end
            else % if I press not coded I cancel the current annotation
                IDX_start = find(diff(TS.H_line_annotations.YData(1:TS.H_cursor.XData)),1,'last')+1;
                if isempty(IDX_start)
                    IDX_start = 1;
                end
            end
            
            IDX_end = TS.H_cursor.XData;
            TS.H_line_annotations.YData(IDX_start:IDX_end) = codeAnnotation;
            TS.H_cursor.YData = codeAnnotation;
            
        end
        
        function scrollFrameWheel(TS, ~, eventData)
            if eventData.VerticalScrollCount > 0
                TS.parentObj.notify_frame_changed_forward
            else
                TS.parentObj.notify_frame_changed_backward
            end
        end
        
        function scrollFrameKey(TS, ~, eventData)
            switch (eventData.Key)
                case 'rightarrow'
                    TS.parentObj.notify_frame_changed_forward
                case 'leftarrow'
                    TS.parentObj.notify_frame_changed_backward
            end
        end
        
        function c_moveForward(TS, ~,~)
            if isvalid(TS)
                currentPosition = TS.parentObj.currentFrame;
                set(TS.H_cursor, 'XData', currentPosition);
                TS.H_cursor.YData = TS.H_line_annotations.YData(currentPosition);
            end
        end
        
        function c_moveBackward(TS, ~,~)
            if isvalid(TS)
                currentPosition = TS.parentObj.currentFrame;
                set(TS.H_cursor, 'XData', currentPosition);
                TS.H_cursor.YData = TS.H_line_annotations.YData(currentPosition);
            end
        end
    end
    
end

