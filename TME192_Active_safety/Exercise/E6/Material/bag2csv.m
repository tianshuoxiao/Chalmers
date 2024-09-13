function bag2csv(file_to_convert)

% Author
% Christian-Nils Boda (boda@chalmers.se)
% Alberto Morando (morando@chalmers.se)
% Date
% 2018-09-11
% Description
% Convert lidarscans to csv files for TME192  data collection exercise. 
% Input: file to be converted
% Output: file's path information of the converted file

% Write the csv file
[filepath, filename, ext] = fileparts(file_to_convert);

ext_output = '.csv';
filename_output = [filename, ext_output];

fprintf('Converting %s%s to %s.\nThis may take a while...\n', filename, ext, filename_output)

% Load the rosbag object and extract the lidar messages
bag = rosbag(file_to_convert);
lidarData = bag.select('Topic', '/scan').readMessages;

% Save the time when the recording started
timeStart = lidarData{1}.Header.Stamp.Sec + lidarData{1}.Header.Stamp.Nsec*10^-9;

% Append a matrix with the data
M = nan(size(lidarData, 1), size(lidarData{1}.Header.Stamp.Sec, 1) + size(lidarData{1}.Ranges, 1)); % add one column for the timestamp

for r = 1:size(M, 1)
    if mod(r, round(size(M, 1)/100)) == 0
        fprintf('.')
    end

    if mod(r, round(size(M, 1)/10)) == 0
        fprintf('%3.0f%%\n', r/size(M, 1) * 100)
    end
    
    M(r, :) = [double([lidarData{r}.Header.Stamp.Sec + lidarData{r}.Header.Stamp.Nsec*10^-9 - timeStart, lidarData{r}.Ranges'])];

%     M = [M; double([lidarData{r}.Header.Stamp.Sec + lidarData{r}.Header.Stamp.Nsec*10^-9 - timeStart, lidarData{r}.Ranges'])];
end

fprintf('Writing %s\n', filename_output)
csvwrite(fullfile(filepath, filename_output), M);

end