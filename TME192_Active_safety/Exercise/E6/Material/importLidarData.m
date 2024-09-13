function [data] = importLidarData(file)

    % Function to import the LIDAR .csv file to MATLAB
    % Version: 2021
    % Course: TME 192 Active Safety
    %         Chalmers
    % Author: Alberto Morando - morando@chalmers.se
    %         Christian-Nils Boda - boda@chalmers.se
    %         Alexander Rasch - arasch@chalmers.se
    %         Pierluigi Olleja - ollejap@chalmers.se

    fprintf('Importing %s...\n', file)

    lidar_fov_deg = 190;

    raw = csvread(file);

    data.Timestamp_s = raw(:, 1);
    data.Angle_rad = deg2rad(linspace(-lidar_fov_deg/2, lidar_fov_deg/2, 1521));
    data.Distance_m = raw(:, 2:end);

end

