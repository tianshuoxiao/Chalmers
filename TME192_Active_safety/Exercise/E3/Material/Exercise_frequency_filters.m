%% ----- Exercise 3 - Frequency and Kalman filters (part A) -----
% Version: 2023
% Course: TME 192 Active Safety
%         Chalmers
% Contacts: Pierluigi Olleja (pierluigi.olleja@chalmers.se)
%           Rahul Rajendra Pai (rahul.pai@chalmers.se)
%           Tianyou Li (tianyou.li@chalmers.se)
%
        % Group number: [Group 5]
        % Group member: [Yahui Wu]
        % Group member: [Tianshuo Xiao]
        % Group member: [Nishanth Suresh]

%% --- INITIALIZATION ---

close all
clear all
clc

% ======== YOUR CODE HERE ========  
%% --- LOAD THE DATA ---
load("signals.mat")

%% --- SAMPLING PARAMETERS ---
f_sampling = 120; % sampling frequency [Hz]

% Create timeseries for plotting the signal in seconds [seconds].
T = 0:1/f_sampling:length(Speed)*(1/f_sampling)-(1/f_sampling);
% ================================  

%% --- DISPLAY THE RAW SIGNAL ---
figure('Name','Raw signals','NumberTitle','off')

subplot(2,1,1); title('Speed')
plot(T, Speed,'-b')
xlabel('Time [s]')
ylabel('Speed [m/s]')
grid on

subplot(2,1,2); title('Acceleration')
plot(T, Acceleration,'-b')
xlabel('Time [s]')
ylabel('Acceleration [m/s^2]')
grid on

%% --- FILTER THE SPEED SIGNAL ---

% ======== YOUR CODE HERE ========  
% Investigate the frequency components of the signals
spectrumanalysis(Speed, 120);

% Design a filter. The "right" filter does what you want considering your data.
filterForSpeed = designfilt('lowpassiir', ... % For example, try to choose between 'lowpassiir' and 'highpassiir'
    'PassbandFrequency', 1, ... % Frequency constraints
    'StopbandFrequency', 10, ...
    'designmethod', 'butter',... % For example, try 'butter'
    'SampleRate', 120);
% ================================  

% Get some information on the filter you have designed
info(filterForSpeed)
fprintf('Your filter is of order: %d\n', filtord(filterForSpeed))
fvtool(filterForSpeed);

% Filter the signal with a zero phase filtering
SpeedFiltered = filtfilt(filterForSpeed, Speed);

% Display the results
figure('Name','Speed filtered','NumberTitle','off')
title('Speed')
hold on

% ======== YOUR CODE HERE ========  
plot(T, Speed, '-b')                   % plot the raw signal
plot(T, SpeedFiltered, '-r', 'linewidth', 1.5) % plot the filtered signal
% ================================  

legend('Raw', 'Filtered')
xlabel('Time [s]')
ylabel('Speed [m/s]')
grid on

%% --- FILTER THE ACCELERATION SIGNAL ---

% ======== YOUR CODE HERE ========  
% Investigate the frequency components of the signals
spectrumanalysis(Acceleration,120);

% Design a filter
filterForAcceleration = designfilt('highpassiir', ... % For example, try to choose betweem 'lowpassiir' and 'highpassiir'
    'PassbandFrequency', 0.1, ... % Frequncy constraints
    'StopbandFrequency', 0.03, ...
    'designmethod', 'butter',... % For example, try 'butter'
    'SampleRate', 120);
% ================================  

% Get some information on the filter you have designed
info(filterForAcceleration)
fprintf('Your filter is of order: %d\n', filtord(filterForAcceleration))
fvtool(filterForAcceleration);

% Filter the signal with a zero phase filtering
accelerationFiltered = filtfilt(filterForAcceleration, Acceleration);

% Display the results
figure('Name','Acceleration filtered','NumberTitle','off')
title('Acceleration')
hold on

% ======== YOUR CODE HERE ========  
plot(T, Acceleration, '-b')                   % plot the raw signal
plot(T, accelerationFiltered, '-r', 'linewidth', 1.5) % plot the filtered signal
% ================================  

legend('Raw', 'Filtered')
xlabel('Time [s]')
ylabel('Acceleration [m/s^2]')
grid on
