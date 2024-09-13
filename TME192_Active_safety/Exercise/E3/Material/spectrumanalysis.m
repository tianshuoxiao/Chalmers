
function [signal_transformed, freqeuncy_vector] = spectrumanalysis(signal, freq)
%SPECTRUMANALYSIS   Spectrum plot. 
%   SPECTRUMANALYSIS(S,F) plots the spectrum of a signal S collected 
%   with a F sampling frequency.
%
%   [S_T, F_T] = SPECTRUMANALYSIS(S,F) returns the transformed signal S_T
%   and the freqeuncy vector F_T.
%   Author: dozza@chalmers.se, morando@chalmers.se for Chalmers course TME192 Active Safety

period = 1/freq;                     % Sample time
signal_length = numel(signal);                     % Length of signal
t = (0:signal_length-1)*period;                % Time vector

figure('Name', 'Spectrum analysis', 'numbertitle', 'off')
h(1) = subplot(3, 1, 1);
plot(t,signal)
title('Signal Plotted in the Time Domain')
xlabel('time (seconds)')

NFFT = 2^nextpow2(signal_length); % Next power of 2 from length of signal
signal_transformed = fft(signal,NFFT)/signal_length;
freqeuncy_vector = freq/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
h(2) = subplot(3, 1, 2);
semilogx(freqeuncy_vector,2*abs(signal_transformed(1:NFFT/2+1))) 
title('Single-Sided Amplitude Spectrum of Signal(t)')
xlabel('Frequency (Hz)')
ylabel('|Signal Transformed(f)|')


h(3) = subplot(3, 1, 3);
plot(freqeuncy_vector,2*abs(signal_transformed(1:NFFT/2+1))) 
title('Single-Sided Amplitude Spectrum of Signal(t)')
xlabel('Frequency (Hz)')
ylabel('|Signal Transformed(f)|')

set(h, 'LabelFontSizeMultiplier', 1, 'xgrid', 'on', 'ygrid', 'on')
