function playLidar(varargin)
% GUI to display the LIDAR and video data from a ROS bag file.
% Version: 2020
% Course: TME 192 Active Safety
%         Chalmers
% Author: Alberto Morando - morando@chalmers.se
%         Christian-Nils Boda - boda@chalmers.se
%         Alexander Rasch - arasch@chalmers.se

global H axesLimit_X axesLimit_Y FOVdeg_current FOVdeg_lidar
% close all

ScreenSize = get(0, 'ScreenSize');
FigureSize = [400 550];

H.mainFig = figure('name', 'LIDAR', 'numbertitle', 'off',...
    'Position', [(ScreenSize(3)-FigureSize(1))/2 (ScreenSize(4)-FigureSize(2))/2 FigureSize],...
    'toolbar', 'none',...
    'menubar', 'none',...
    'resize', 'off');

set(H.mainFig, 'KeyPressFcn', {@scrollFrameKey},...
    'Interruptible', 'off',...
    'busyaction', 'cancel',...
    'doublebuffer','off');

axesLimit_X = [-120 120];
axesLimit_Y = [0 120];

axVideo = subplot(2, 1, 1, ...
    'Parent', H.mainFig,...
    'Units', 'normalized', ...
    'TickLength', [0 0], ...
    'XTickLabel', [], ...
    'YTickLabel', [], ...
    'Color', 'None', ...
    'XColor', 'None', ...
    'YColor', 'None');
axLidar = subplot(2, 1, 2, ...
    'Parent', H.mainFig,...
    'Units', 'normalized',...
    'fontsize', 8, ...
    'box', 'on',...
    'xlim', axesLimit_X, ...
    'ylim', axesLimit_Y);

axVideo.Position = [0.2 0.55 0.6 0.4];
axLidar.Position = [0.1 0.15 0.8 0.45];

H.videoAxes = axVideo;
H.lidarAxes = axLidar;

%% SELECT FILES
if isempty(varargin)
    pause(0.5)
    [filename, pathname, filterindex] = uigetfile( ...
       {'*.bag';'*.*'}, ...
       'Select the files to import', ...
       'MultiSelect', 'on');

    if isequal(filename, 0)
       disp('User selected Cancel')
       close(H.mainFig)
       pause(0.1)
       return
    end
else
    filename = varargin;
    pathname = pwd; % assume the file is in the current path
end
    
if ~iscell(filename) || numel(filename) == 1
    nfiles = 1;
    filename = cellstr(filename);
else
    nfiles = numel(filename);
end

    
H.filelist = uicontrol(H.mainFig,...
    'Style', 'popupmenu',...
    'String', filename,...
    'Position', [round(FigureSize(1))/2-100 FigureSize(2)-30 200, 20],...
    'callback', {@loadSelectedFile, pathname});


xlabel(H.lidarAxes, 'Distance [m]')
ylabel(H.lidarAxes, 'Distance [m]')

axis equal;

H.dataSlider = uicontrol(H.mainFig,...
    'Style', 'Slider',...
    'Min', 1,...
    'Value', 1,...
    'SliderStep', [0.1 0.1],...
    'Position', [5 5 FigureSize(1)-175 25],...
    'TooltipString', sprintf('Left / Right arrow: +/- 1 frame\nUp / Down arrow: +/- 10 frames\nHome / End button: beginning / end video'),...
    'callback', @jumpFrameFromSlider);

H.dataResume = uicontrol(H.mainFig,...
    'String', 'Play',...
    'Position', [FigureSize(1)-50 5 50 25],...
    'Callback', @dataResumeCallback);

H.dataCurrentTime = uicontrol(H.mainFig,...
    'Style', 'text',...
    'horizontalalignment', 'right',...
    'background', [1 1 1],...
    'fontsize', 7,...
    'String', num2str(0),...
    'Position', [FigureSize(1)-170 5 120 25]);

H.labelFOV = uicontrol(H.mainFig,...
    'Style', 'text',...
    'background', [1 1 1],...
    'fontsize', 7,...
    'String', sprintf('Set Field Of View [deg]'),...
    'Position', [round(FigureSize(1))/2-145 40 80 25],...
    'Callback', @setFOV);

H.fieldOfView = uicontrol(H.mainFig,...
    'Style', 'edit',...
    'horizontalalignment', 'center',...
    'background', [1 1 1],...
    'fontsize', 7,...
    'String', num2str(0),...
    'Position', [round(FigureSize(1))/2-60 40 55 25],...
    'Callback', @setFOV);

H.dataZoomIn = uicontrol(H.mainFig,...
    'String', 'Zoom IN',...
    'Position', [round(FigureSize(1))/2 40 60 25],...
    'Callback', {@dataZoomCallback,'in'});

H.dataZoomOut = uicontrol(H.mainFig,...
    'String', 'Zoom OUT',...
    'Position', [round(FigureSize(1))/2 + 60 40 60 25],...
    'Callback', {@dataZoomCallback,'out'});

% Get back the proportional property of figure
H.mainFig.Units = 'normalized';

FOVdeg_lidar = 95;
FOVdeg_current = 95;

H.fieldOfView.String = num2str(FOVdeg_current);

initPlot(pathname, filename{1})
end

function initPlot(pathname, filename)
global H DATA

% Load the rosbag object and extract the lidar and video messages
fprintf('Importing %s... ', filename)

DATA.bag = rosbag(fullfile(pathname, filename));
DATA.LidarData = DATA.bag.select('Topic', '/scan').readMessages;
DATA.VideoData = DATA.bag.select('Topic', '/cv_camera/image_raw/compressed').readMessages;

if isempty(DATA.VideoData)
%     axes(H.videoAxes)
%     text(200, 300, 'No video available.');
    cla(H.videoAxes);
    text(H.videoAxes,0.5, 0.5, 'No video data available', 'horizontalalignment', 'center', 'units', 'normalized')
end

fprintf('Done.\n')

H.dataSlider.Max = length(DATA.LidarData);
DATA.currentFrameIndex = 1;
H.dataSlider.Value = DATA.currentFrameIndex;
DATA.playing = false;
gotoframe(1);
end

function deactivateControls()
global H
fn = fieldnames(H);
for i = 1 : numel(fn)
   if isprop(H.(fn{i}),'Enable')
        H.(fn{i}).Enable = 'off';
   end
end
end

function activateControls()
global H
fn = fieldnames(H);
for i = 1 : numel(fn)
   if isprop(H.(fn{i}),'Enable')
        H.(fn{i}).Enable = 'on';
   end
end
end

function loadSelectedFile(src, ~, pathname)
global H

deactivateControls()
cla(H.lidarAxes);
text(H.lidarAxes,0.5, 0.5, 'Loading...', 'horizontalalignment', 'center', 'background', [1 1 1], 'units', 'normalized')
drawnow

filename = src.String{src.Value};

activateControls()
initPlot(pathname, filename)
end

function dataZoomCallback(~, ~, act)
global H axesLimit_X axesLimit_Y

switch act
    case 'in'
        axesLimit_X = axesLimit_X./2;
        axesLimit_Y = axesLimit_Y./2;
    case 'out'
        axesLimit_X(1) = max(axesLimit_X(1)*2, -120);
        axesLimit_X(2) = min(axesLimit_X(2)*2, 120);
        
        axesLimit_Y(1) = 0;
        axesLimit_Y(2) = min(axesLimit_Y(2)*2, 120);
end

H.lidarAxes.XLim = axesLimit_X;
H.lidarAxes.YLim = axesLimit_Y;

end
function dataResumeCallback(~, ~)
global DATA H

DATA.playing = ~DATA.playing;
if strcmpi(H.dataResume.String, 'Pause')
    H.dataResume.String = 'Play';
else
    H.dataResume.String = 'Pause';
end

while DATA.playing && DATA.currentFrameIndex < length(DATA.LidarData)
    gotoframe(DATA.currentFrameIndex);
    drawnow
%     pause(1/10);
    DATA.currentFrameIndex = DATA.currentFrameIndex + 1;
    H.dataSlider.Value = DATA.currentFrameIndex;
end

DATA.playing = false;
H.dataResume.String = 'Play';

end

function setFOV(src, ~)
global FOVdeg_current DATA H FOVdeg_lidar

DATA.playing = false;

FOVdeg_current = str2double(src.String);

FOVdeg_current = max(0, FOVdeg_current);
FOVdeg_current = min(FOVdeg_lidar*2, FOVdeg_current);

H.fieldOfView.String = num2str(FOVdeg_current);

gotoframe(DATA.currentFrameIndex);

end

function [DistancesFOV, AnglesFOV] = extractFOV(Distances, Angles, FOVdegree)

FOV_limits_rad =  deg2rad([-FOVdegree/2, FOVdegree/2]);
IDX_FOVspan = [find(Angles >= FOV_limits_rad(1), 1, 'first') : find(Angles <= FOV_limits_rad(end), 1, 'last')];

% Extract the data in the FOV
DistancesFOV = Distances(IDX_FOVspan);
AnglesFOV = Angles(IDX_FOVspan);

end


function gotoframe(i)

global DATA H axesLimit_X axesLimit_Y FOVdeg_current

lidarData = DATA.LidarData{i};

timeStart = DATA.LidarData{1}.Header.Stamp.Sec + DATA.LidarData{1}.Header.Stamp.Nsec * 10^-9;
TimeToDisplay = double(lidarData.Header.Stamp.Sec + lidarData.Header.Stamp.Nsec * 10^-9 - timeStart);

% Select closest (past) video data frame
videoMsgs = DATA.bag.MessageList(DATA.bag.MessageList.Topic == '/cv_camera/image_raw/compressed', :);
videoDataIdx = find(videoMsgs.Time <= lidarData.Header.Stamp.Sec + lidarData.Header.Stamp.Nsec * 10^-9, 1, 'last');

% Plot the video frame if available
if ~isempty(videoDataIdx)
    videoData = DATA.VideoData{videoDataIdx};
    axes(H.videoAxes)
    videoData.Format = 'bgr8; jpeg compressed bgr8';
    imshow(readImage(videoData));
end

axes(H.lidarAxes)
[X,Y] = pol2cart(lidarData.readScanAngles + pi/2, lidarData.Ranges);

cla(H.lidarAxes);

hold on
plot(H.lidarAxes, X, Y, ':k');

[DistancesFOV, AnglesFOV] = extractFOV(lidarData.Ranges, lidarData.readScanAngles, FOVdeg_current);
[X_fov,Y_fov] = pol2cart(AnglesFOV + pi/2, DistancesFOV);
plot(X_fov, Y_fov, '-k', 'linewidth', 1.2);

[~, closestPointIDX] = min(DistancesFOV);
[x_closest, y_closest] = pol2cart(AnglesFOV(closestPointIDX) + pi/2, DistancesFOV(closestPointIDX));


plot([axesLimit_Y(1) axesLimit_Y(end)] .* sin(AnglesFOV(1)),...
    [axesLimit_Y(1) axesLimit_Y(end)] .* cos(AnglesFOV(1)),...
    ':r', 'linewidth', 1.5)

plot([axesLimit_Y(1) axesLimit_Y(end)] .* sin(AnglesFOV(end)), ...
    [axesLimit_Y(1) axesLimit_Y(end)] .* cos(AnglesFOV(end)), ...
    ':r', 'linewidth', 1.5)



plot(H.lidarAxes, 0, 0, 'r^', 'markersize', 10, 'MarkerFaceColor', 'r');
plot(x_closest, y_closest, 'xb', 'linewidth', 1.2, 'markersize', 8);

hold off
grid on

set(gca, 'xlim', axesLimit_X, ...
    'ylim', axesLimit_Y)

drawnow;

H.dataCurrentTime.String = sprintf('Time: %010.2f \nFrame:%010d ',TimeToDisplay, i);

end

function jumpFrameFromSlider(src, ~)
global DATA
% Stop the player
DATA.playing = false;

% Get the new frame to display from slider position
newFrame = round(src.Value);
DATA.currentFrameIndex = newFrame;
% Display the new frame
gotoframe(DATA.currentFrameIndex);
end

function scrollFrameKey(~, eData)
global DATA H
DATA.playing = false;

switch (eData.Key)
    case 'rightarrow'
        DATA.currentFrameIndex = min(DATA.currentFrameIndex + 1, length(DATA.LidarData));
    case 'leftarrow'
        DATA.currentFrameIndex = max( DATA.currentFrameIndex - 1, 1);
    case 'uparrow'
        DATA.currentFrameIndex = min(DATA.currentFrameIndex + 10, length(DATA.LidarData));
    case 'downarrow'
        DATA.currentFrameIndex = max(DATA.currentFrameIndex - 10, 1);
    case 'home'
        DATA.currentFrameIndex = 1;
    case 'end'
        DATA.currentFrameIndex = length(DATA.LidarData);
end

gotoframe(DATA.currentFrameIndex);
H.dataSlider.Value = DATA.currentFrameIndex;

end