classdef SignalPlotter < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        H_mainWindow
        H_graphContainer
        H_cursor
        H_signal
        
        parentObj
        currentFrame
        Nframes
    end
    
    methods
        function SP = SignalPlotter(VC)
            SP.parentObj = VC;
            
            SP.currentFrame = VC.currentFrame; 
            SP.Nframes = VC.eventLength_frames;
            
            addlistener(VC, 'updateFrame_global_forward', @SP.c_moveForward);
            addlistener(VC, 'updateFrame_global_backward', @SP.c_moveBackward);
 
            InitGUI(SP)
            
        end
        
        function InitGUI(SP)
            SP.H_mainWindow = figure('units', 'pixel',...
                'position', [200, 200, 400, 300],...
                'resize', 'on',...
                'MenuBar','none',...
                'NumberTitle', 'off',...
                'name', 'Signal plotter',...
                'tag','Signal plotter',...
                'WindowScrollWheelFcn',@SP.scrollFrameWheel,...
                'visible', 'off',...
                'closeRequestFcn', []);
            
            SP.H_graphContainer = axes('parent', SP.H_mainWindow,...
                'units', 'normalized',...
                'xlim',[1 SP.Nframes], ...
                'xtick', [],...
                'Box', 'on',...
                'position', [0.1 0.1 0.8 0.8], ...
                'visible', 'on',...
                'xgrid', 'on',...
                'ygrid', 'on');
            
           SP.H_signal = line( nan,...[1 : SP.Nframes]',...
               nan,...
               'parent', SP.H_graphContainer, ...
               'Color', [0, 0, 0.8],...
               'Linewidth', 1.5);
            
           SP.H_cursor = line('XData', SP.currentFrame,... % The current frame in the annotation is normalized with respect to the event length
               'YData', 0,...
               'parent', SP.H_graphContainer, ...
               'Color', [0, 0, 0.8],...
               'Marker', '.',...
               'Markersize', 20,...
               'Linewidth', 1);    
            
            
        end
        
        function scrollFrameWheel(SP, ~, eventData)               
            if eventData.VerticalScrollCount > 0      
               SP.parentObj.notify_frame_changed_forward
            else
               SP.parentObj.notify_frame_changed_backward
            end
        end
        
        function c_moveForward(SP, ~,~)             
            if isvalid(SP)
                currentPosition = SP.parentObj.currentFrame;
                 %set(SP.H_cursor, 'XData', currentPosition);
                 set(SP.H_cursor, 'XData', currentPosition);
                 SP.H_cursor.YData = SP.H_signal.YData(currentPosition); 
            end
        end
        
        function c_moveBackward(SP, ~,~)
            if isvalid(SP)
                currentPosition = SP.parentObj.currentFrame;
                 set(SP.H_cursor, 'XData', currentPosition);
                 SP.H_cursor.YData = SP.H_signal.YData(currentPosition); 
            end
        end
    end
    
end

