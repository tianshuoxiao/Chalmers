classdef DataLoader < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        H_mainWindow
        H_listBox
        H_loadButton
        database
        
        parentObj
        
        toBeLoaded
    end
    
    events
        loadNewData
    end
    
    methods
        function DL = DataLoader(VC)
            DL.parentObj = VC;
            
            Init(DL);
            
            RefreshList(DL);
        end
        
        function Init(DL)
            
%             columnName = {'ID', 'Event', 'Glance', 'Hands', 'Feet'};
%             columnFormat = {'Numeric', 'Char', 'Logical', 'Logical', 'Logical'};
%             columnEditable = [false false false false false];
%             
%             DL.database = {0, 'ND', false, false, false}; 

            columnName = {'Participant ID', 'Event ID'};
            columnFormat = {'Numeric', 'Char'};
            columnEditable = [false false];
            
            DL.database = {0, 'ND'}; 
            
            DL.toBeLoaded = {nan, ' '};
             
            DL.H_mainWindow = figure('units', 'pixel',...
                'position', [DL.parentObj.H_mainWindow.Position(1) + DL.parentObj.H_mainWindow.Position(3) + 20, DL.parentObj.H_mainWindow.Position(2), 140, 150],...
                'resize', 'off',...
                'name', '',...
                'NumberTitle', 'off',...
                'MenuBar','none',...
                'Visible', 'off');
            
            DL.H_listBox = uitable('parent', DL.H_mainWindow, ...
                'units', 'normalized',...
                'position', [0 0.2 1 0.8],...
                'columnName', columnName, ...
                'ColumnFormat', columnFormat,...
                'ColumnEditable', columnEditable,...
                'rowname', [],...
                'CellSelectionCallback', @DL.EventChooser,...
                'data', DL.database);
            
            DL.H_loadButton = uicontrol('parent', DL.H_mainWindow,...
                'units', 'normalized',...
                'position', [0 0 1 0.2],...
                'string', 'LOAD',...
                'callback', @DL.LoadEvent...
                );
            
        end
        
        function RefreshList(DL)
            
            % Read list of participants ID
            filter = '0*';
            D = dir(fullfile(DL.parentObj.Source.dataParticipantsFolder, filter));
            IDs = {D.name};
            
            i = 1;
            IDX_row = 1;
            while i <= length(IDs)
                for j = 1 : length(DL.parentObj.Source.EventType)
                    DL.database{IDX_row, 1} = str2double(IDs(i));
                    DL.database{IDX_row, 2} = DL.parentObj.Source.EventType{j}; 
                    %DL.database(IDX_row, 3:end) = {'false','false','false'};
                    
                    IDX_row = IDX_row + 1;
                end
                i = i + 1;
            end
            DL.H_listBox.Data = DL.database;    
        end
        
        function EventChooser(DL, ~, evnt)
            selected = evnt.Indices(1);
            DL.toBeLoaded = {DL.database{selected,1}, DL.database{selected,2}}; % {ID, EventType}
        end
        
        function LoadEvent(DL, ~, ~)
            DL.parentObj.eventToBeLoaded = DL.toBeLoaded;                        
            notify(DL, 'loadNewData')
        end
        
    end
    

    
end

