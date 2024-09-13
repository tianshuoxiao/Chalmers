% Student template script for TME192 LIDAR exercise
        % Group number: [Group 5]
        % Group member: [Yahui Wu]
        % Group member: [Tianshuo Xiao]
        % Group member: [Nishanth Suresh]
% Load the data if not available. you may have to set specific path
if ~exist('oData')
    load('oData')
end


% Initiate a plot
fig=figure(1);

% Set the coordinates for what to show
fPlotCoordsX=[6407050,6407120];
fPlotCoordsY=[1276550,1276650];

% Initiate an AVI. 
% STUDENT: YOU HAVE TO CHANGE THE PATH!
aviobj = VideoWriter(['C:\Users\13906\OneDrive - Chalmers\Y2P1\TME192\Exercise\1' datestr(now,30) '.avi'],'MPEG-4');
open(aviobj);

% Loop through all times in the Sensor Fused data
for iIndex=1:length(oData.iTimeSF)


   % Get the specific time for this index from Sensor Fusion data		
   time=oData.iTimeSF(iIndex);
   
   % Find the closest LIDAR time corresponding to the Sensor Fusion time 
   iLIDARIndex=find(oData.iLidarTime>time,1);

   
   %% FROM HERE ON STUDENT CODE - The code within this is what should be
   % Read the LIDAR coordinates data
   x_Lidar = oData.fLIDAR_X{1, iIndex};
   y_Lidar = oData.fLIDAR_Y{1, iIndex};
   
   % Translate the position of LIDAR sensor to the GPS antennas mounting
   % position, then add the GPS position
   x_LidartoGPS = x_Lidar+oData.fLIDARposX-oData.fGPSposX;
   y_LidartoGPS = y_Lidar+oData.fLIDARposY;
   
   % Coordinate conversion
   a = asin(y_LidartoGPS.*sqrt(x_LidartoGPS.^2+y_LidartoGPS.^2).^-1);
   
   for ae = 1:length(a)    
      if x_LidartoGPS(ae) < 0
        a(ae) = pi - a(ae);
      end
   end
   
   % Add the two angles together: alpha + theta
   theta = a + oData.fHeadingSF(iIndex);

   y_GPS = sin(theta).*sqrt(x_LidartoGPS.^2+y_LidartoGPS.^2)+oData.fYRT90SF(iIndex);
   x_GPS = cos(theta).*sqrt(x_LidartoGPS.^2+y_LidartoGPS.^2)+oData.fXRT90SF(iIndex);
   % pasted into the "[fXechoGlobal, fYechoGlobal] = coordinateProjection(oData, iIndex)" function
   
   % Do the translations and coordinate transformations to extract the
   %   LIDAR reflections in the coordinate system of RT90 (GPS antenna
   %   mounting position)
    
   % Add the RT90 position (global coordinates from GPS), but in order to 
   %  be able to add them vehicle data it will have to be projected on the 
   %  RT90 coordinate system using the heading.

   % Add to the RT90 cartesian coordinate system. When the code for
   % the two global coordinates is ready, the output should be in 
   % these two variables. They should be the final output pasted 
   % into the function in the Matlab Grader. If you have multiple
   % lines of code to create the two variables, all should be
   % pasted into Matlab Grader.

   % Note you do NOT need to add a time loop - it is already here (iIndex
   % above)
       
   fXechoGlobal = x_GPS;
   fYechoGlobal = y_GPS;

   %% END OF STUDENT CODE (if you want, more can be added)

   % Plot the lidar in RT90 coodrinate system	   
   plot(fXechoGlobal,fYechoGlobal,'.')

   % Plot the vehicle position (the GPS antenna) too
   plot(oData.fXRT90SF(iIndex),oData.fYRT90SF(iIndex),'.r','MarkerSize',30)

   % Add your name to the plot
   %%% STUDENT: You should change this (X) should be your group number
   text(6407050,1276560,'Group 5 Yahui Wu Tianshuo Xiao Nishanth Suresh')
   
   % Set the axis of the plot
   axis([fPlotCoordsX fPlotCoordsY])
   hold on;
   
   % Get it as an avi-frame
   F = getframe(fig);
   % Add the frame to the avi
   writeVideo(aviobj,F);
   %aviobj = addframe(aviobj,F);
   
end

% % Close the AVI from Matlab
 close(aviobj);
