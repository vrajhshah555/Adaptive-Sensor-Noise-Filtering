clear;
clc;
close all;

%% =========================================================
% ULTRASONIC SENSOR - PROBABILITY AND RANDOM PROCESSES
% 1000 REAL SENSOR READINGS
% CURRENT READING DISPLAY
% COMPLETE STATISTICAL AND NOISE ANALYSIS
%% =========================================================

%% 1. SETTINGS

port = "COM6";
baudRate = 9600;
numberOfSamples = 1000;
maxWaitTime = 180;

%% 2. CONNECT TO ARDUINO

s = serialport(port, baudRate);
configureTerminator(s, "LF");

pause(2);
flush(s);

fprintf('\n============================================\n');
fprintf(' ULTRASONIC SENSOR DATA ACQUISITION\n');
fprintf('============================================\n');

fprintf('Serial port       : %s\n', port);
fprintf('Baud rate         : %d\n', baudRate);
fprintf('Required readings : %d\n', numberOfSamples);

%% 3. INITIALIZE ARRAYS

distance = zeros(numberOfSamples, 1);
time = zeros(numberOfSamples, 1);

sampleCount = 0;
startTime = tic;

fprintf('\nCollecting real sensor readings...\n\n');

%% 4. ACQUIRE REAL SENSOR DATA
% Arduino must send plain numerical values using Serial.println()
% Example: 30.25

while sampleCount < numberOfSamples && toc(startTime) < maxWaitTime

    if s.NumBytesAvailable > 0

        try
            data = strtrim(readline(s));
            value = str2double(data);

            % Accept valid HC-SR04 measurements
            if ~isnan(value) && isfinite(value) && ...
                    value >= 2 && value <= 400

                sampleCount = sampleCount + 1;

                distance(sampleCount) = value;
                time(sampleCount) = toc(startTime);

                % Display every current reading
                fprintf('Reading %4d/%4d | Time: %7.2f s | Current Distance: %7.2f cm\n', ...
                    sampleCount, numberOfSamples, ...
                    time(sampleCount), value);

            end

        catch
            % Ignore invalid serial lines
        end

    else
        pause(0.001);
    end

end

%% 5. CLOSE SERIAL CONNECTION

clear s;

% Keep only readings actually collected
distance = distance(1:sampleCount);
time = time(1:sampleCount);

if sampleCount < 2
    error(['Insufficient valid readings received. ', ...
        'Check the Arduino, COM port, and baud rate.']);
end

N = sampleCount;

fprintf('\n============================================\n');
fprintf(' MEASUREMENT COMPLETED\n');
fprintf('============================================\n');

fprintf('Valid readings collected : %d\n', N);
fprintf('Acquisition time         : %.2f seconds\n', time(end));

if N < numberOfSamples
    warning('Only %d of %d requested readings were collected.', ...
        N, numberOfSamples);
end

%% 6. DESCRIPTIVE STATISTICS

meanDistance = mean(distance);
medianDistance = median(distance);
modeDistance = mode(distance);

varianceDistance = var(distance);
stdDistance = std(distance);

minimumDistance = min(distance);
maximumDistance = max(distance);
rangeDistance = maximumDistance - minimumDistance;

RMSDistance = sqrt(mean(distance.^2));

% Quartiles using linear interpolation
sortedDistance = sort(distance);

Q1 = interp1(1:N, sortedDistance, 1 + 0.25*(N-1));
Q3 = interp1(1:N, sortedDistance, 1 + 0.75*(N-1));

IQRDistance = Q3 - Q1;

% Mean absolute deviation
meanAbsoluteDeviation = mean(abs(distance - meanDistance));

%% 7. DISTANCE REFERENCE AND MEASUREMENT NOISE

% Use the overall sample mean as the statistical reference
reference = meanDistance * ones(N, 1);

% Noise = measured reading - mean reference
noise = distance - reference;

meanNoise = mean(noise);
varianceNoise = var(noise);
stdNoise = std(noise);

noiseRMS = sqrt(mean(noise.^2));

minimumNoise = min(noise);
maximumNoise = max(noise);
rangeNoise = maximumNoise - minimumNoise;

% Median absolute deviation
MADNoise = median(abs(noise - median(noise)));

% Robust estimate of noise standard deviation
robustNoiseStd = 1.4826 * MADNoise;

%% 8. STANDARD ERROR AND 95% CONFIDENCE INTERVAL

standardError = stdDistance / sqrt(N);

% Approximate 95% confidence interval
CI_lower = meanDistance - 1.96 * standardError;
CI_upper = meanDistance + 1.96 * standardError;

%% 9. NOISE DISTRIBUTION PARAMETERS

if stdNoise > 0

    skewnessNoise = mean(noise.^3) / stdNoise^3;

    excessKurtosisNoise = mean(noise.^4) / stdNoise^4 - 3;

else

    skewnessNoise = NaN;
    excessKurtosisNoise = NaN;

end

% Noise percentiles
sortedNoise = sort(noise);

noisePercentile2_5 = interp1(1:N, sortedNoise, ...
    1 + 0.025*(N-1));

noisePercentile97_5 = interp1(1:N, sortedNoise, ...
    1 + 0.975*(N-1));

%% 10. DISPLAY DISTANCE STATISTICS

fprintf('\n============================================\n');
fprintf(' DISTANCE STATISTICS\n');
fprintf('============================================\n');

fprintf('Number of readings        : %d\n', N);
fprintf('Mean / estimated distance : %.4f cm\n', meanDistance);
fprintf('Median                    : %.4f cm\n', medianDistance);
fprintf('Mode                      : %.4f cm\n', modeDistance);
fprintf('Sample variance           : %.6f cm^2\n', varianceDistance);
fprintf('Standard deviation        : %.6f cm\n', stdDistance);
fprintf('RMS distance              : %.6f cm\n', RMSDistance);
fprintf('Minimum distance          : %.4f cm\n', minimumDistance);
fprintf('Maximum distance          : %.4f cm\n', maximumDistance);
fprintf('Range                     : %.4f cm\n', rangeDistance);
fprintf('First quartile (Q1)       : %.4f cm\n', Q1);
fprintf('Third quartile (Q3)       : %.4f cm\n', Q3);
fprintf('Interquartile range       : %.4f cm\n', IQRDistance);
fprintf('Mean absolute deviation   : %.6f cm\n', meanAbsoluteDeviation);

fprintf('\nStandard error of mean    : %.6f cm\n', standardError);
fprintf('Approx. 95%% CI lower      : %.4f cm\n', CI_lower);
fprintf('Approx. 95%% CI upper      : %.4f cm\n', CI_upper);

%% 11. DISPLAY NOISE STATISTICS

fprintf('\n============================================\n');
fprintf(' MEASUREMENT NOISE STATISTICS\n');
fprintf('============================================\n');

fprintf('Mean reference            : %.4f cm\n', meanDistance);
fprintf('Mean noise                : %.6f cm\n', meanNoise);
fprintf('Noise variance            : %.6f cm^2\n', varianceNoise);
fprintf('Noise standard deviation  : %.6f cm\n', stdNoise);
fprintf('Noise RMS                 : %.6f cm\n', noiseRMS);
fprintf('Minimum noise             : %.6f cm\n', minimumNoise);
fprintf('Maximum noise             : %.6f cm\n', maximumNoise);
fprintf('Noise range               : %.6f cm\n', rangeNoise);
fprintf('Median absolute deviation : %.6f cm\n', MADNoise);
fprintf('Robust noise std estimate : %.6f cm\n', robustNoiseStd);
fprintf('Noise skewness             : %.6f\n', skewnessNoise);
fprintf('Noise excess kurtosis      : %.6f\n', excessKurtosisNoise);
fprintf('Noise 2.5th percentile     : %.6f cm\n', noisePercentile2_5);
fprintf('Noise 97.5th percentile    : %.6f cm\n', noisePercentile97_5);

%% 12. FINAL ESTIMATED DISTANCE

finalDistance = meanDistance;

fprintf('\n============================================\n');
fprintf(' FINAL ESTIMATED DISTANCE\n');
fprintf('============================================\n');
fprintf('Mean measured distance : %.4f cm\n', finalDistance);
fprintf('============================================\n');

%% 13. SAVE READINGS AND NOISE TO CSV

sampleNumber = (1:N)';

resultsTable = table( ...
    sampleNumber, ...
    time, ...
    distance, ...
    reference, ...
    noise, ...
    'VariableNames', { ...
    'SampleNumber', ...
    'Time_s', ...
    'Distance_cm', ...
    'ReferenceMean_cm', ...
    'Noise_cm'});

writetable(resultsTable, 'ultrasonic_noise_data.csv');

fprintf('\nAll readings and noise saved to:\n');
fprintf('ultrasonic_noise_data.csv\n');

%% 14. GRAPH 1: RAW SENSOR READINGS

figure;

plot(time, distance, 'b-', 'LineWidth', 1);
hold on;

plot([time(1), time(end)], ...
    [meanDistance, meanDistance], 'r--', 'LineWidth', 1.5);

xlabel('Time (s)');
ylabel('Distance (cm)');
title('Real Ultrasonic Sensor Measurements');

legend('Measured distance', 'Mean distance', ...
    'Location', 'best');

grid on;

%% 15. GRAPH 2: CURRENT MEASUREMENT NOISE

figure;

plot(time, noise, 'b-', 'LineWidth', 1);
hold on;

plot([time(1), time(end)], [0, 0], ...
    'r--', 'LineWidth', 1.5);

xlabel('Time (s)');
ylabel('Noise (cm)');
title('Measurement Noise Versus Time');

legend('Measurement noise', 'Zero-noise level', ...
    'Location', 'best');

grid on;

%% 16. GRAPH 3: NOISE PROBABILITY DISTRIBUTION

figure;

histogram(noise, 30, 'Normalization', 'pdf');
hold on;

if stdNoise > 0

    noiseAxis = linspace(min(noise), max(noise), 400);

    % Gaussian PDF based on measured noise mean and standard deviation
    gaussianPDF = (1 / (stdNoise * sqrt(2*pi))) .* ...
        exp(-0.5 * ((noiseAxis - meanNoise) / stdNoise).^2);

    plot(noiseAxis, gaussianPDF, 'r-', 'LineWidth', 2);

    legend('Measured noise distribution', ...
        'Gaussian reference curve', 'Location', 'best');

end

xlabel('Noise (cm)');
ylabel('Probability density');
title('Probability Distribution of Measurement Noise');

grid on;

%% 17. GRAPH 4: DISTANCE PROBABILITY DISTRIBUTION

figure;

histogram(distance, 30, 'Normalization', 'pdf');

xlabel('Distance (cm)');
ylabel('Probability density');
title('Probability Distribution of Measured Distance');

grid on;

%% 18. GRAPH 5: NOISE AUTOCORRELATION

centeredNoise = noise - mean(noise);

maxLag = min(50, N-1);
autocorrelation = NaN(maxLag + 1, 1);

denominator = sum(centeredNoise.^2);

if denominator > 0

    for lag = 0:maxLag

        autocorrelation(lag + 1) = ...
            sum(centeredNoise(1:N-lag) .* ...
            centeredNoise(1+lag:N)) / denominator;

    end

    figure;

    stem(0:maxLag, autocorrelation, 'filled');

    xlabel('Lag (samples)');
    ylabel('Normalized autocorrelation');
    title('Autocorrelation of Measurement Noise');

    grid on;

else

    fprintf('\nNoise is constant; autocorrelation is undefined.\n');

end

%% 19. GRAPH 6: BOX PLOT OF MEASUREMENTS

figure;

boxplot(distance);

ylabel('Distance (cm)');
title('Box Plot of Ultrasonic Sensor Measurements');

grid on;

%% 20. FINAL SUMMARY

fprintf('\n============================================\n');
fprintf(' PROJECT SUMMARY\n');
fprintf('============================================\n');

fprintf('Real readings collected  : %d\n', N);
fprintf('Estimated distance       : %.4f cm\n', finalDistance);
fprintf('Noise standard deviation : %.6f cm\n', stdNoise);
fprintf('Noise variance           : %.6f cm^2\n', varianceNoise);

fprintf('\nGenerated graphs:\n');
fprintf('1. Raw distance versus time\n');
fprintf('2. Noise versus time\n');
fprintf('3. Noise probability distribution\n');
fprintf('4. Distance probability distribution\n');
fprintf('5. Noise autocorrelation\n');
fprintf('6. Measurement box plot\n');

fprintf('\nDataset: ultrasonic_noise_data.csv\n');
fprintf('============================================\n');
%% =========================================================
% 21. ADAPTIVE NOISE CHARACTERIZATION AND SMART SENSOR FILTERING
% Added after the original code. Sections 1-20 above remain unchanged.
%% =========================================================

%% 21A. ADAPTIVE FILTER SETTINGS

% The rolling window estimates how much recent readings fluctuate.
% R is adapted from this estimate; Q is kept fixed for this stationary-wall test.
windowSize = 25;
minimumR = 0.01;       % Minimum measurement-noise variance (cm^2)
maximumR = 25;         % Maximum measurement-noise variance (cm^2)
Q_process = 0.01;      % Process-noise variance (cm^2); tune using experiments

if N < 2
    error('At least two readings are required for adaptive filtering.');
end

%% 21B. ADAPTIVE NOISE ESTIMATION + SCALAR KALMAN FILTER

adaptiveNoiseVariance = zeros(N, 1);
adaptiveNoiseStd = zeros(N, 1);
kalmanGainAdaptive = zeros(N, 1);
filteredDistance = zeros(N, 1);

% Initialize state estimate from the first real measurement
stateEstimate = distance(1);
estimateVariance = 1;

for k = 1:N

    % Causal rolling window: current reading and up to windowSize-1
    % previous readings. This does not use future samples.
    firstWindowIndex = max(1, k - windowSize + 1);
    recentReadings = distance(firstWindowIndex:k);

    % Robust local spread estimate using median absolute deviation (MAD)
    localMedian = median(recentReadings);
    localMAD = median(abs(recentReadings - localMedian));
    localNoiseStd = 1.4826 * localMAD;

    % Adaptive measurement-noise variance R (bounded for numerical stability)
    R_adaptive = localNoiseStd^2;
    R_adaptive = max(minimumR, min(R_adaptive, maximumR));

    adaptiveNoiseVariance(k) = R_adaptive;
    adaptiveNoiseStd(k) = sqrt(R_adaptive);

    % Prediction step: stationary-distance model
    predictedState = stateEstimate;
    predictedVariance = estimateVariance + Q_process;

    % Measurement update
    gain = predictedVariance / (predictedVariance + R_adaptive);
    stateEstimate = predictedState + gain * (distance(k) - predictedState);
    estimateVariance = (1 - gain) * predictedVariance;

    filteredDistance(k) = stateEstimate;
    kalmanGainAdaptive(k) = gain;
end

%% 21C. CHARACTERIZE FILTERED OUTPUT AND COMPARE RESULTS

filteredMean = mean(filteredDistance);
filteredMedian = median(filteredDistance);
filteredVariance = var(filteredDistance);
filteredStd = std(filteredDistance);
filteredMinimum = min(filteredDistance);
filteredMaximum = max(filteredDistance);
filteredRange = filteredMaximum - filteredMinimum;
filteredRMS = sqrt(mean(filteredDistance.^2));

% These are deviations from each series' own mean, for variability comparison.
% They are not errors relative to the true physical distance.
rawCenteredDeviation = distance - mean(distance);
filteredCenteredDeviation = filteredDistance - mean(filteredDistance);

rawDeviationStd = std(rawCenteredDeviation);
filteredDeviationStd = std(filteredCenteredDeviation);

if rawDeviationStd > 0
    standardDeviationReductionPercent = ...
        100 * (1 - filteredDeviationStd / rawDeviationStd);
else
    standardDeviationReductionPercent = NaN;
end

fprintf('\n============================================\n');
fprintf(' ADAPTIVE NOISE CHARACTERIZATION\n');
fprintf('============================================\n');
fprintf('Rolling window size          : %d readings\n', windowSize);
fprintf('Mean adaptive noise std      : %.6f cm\n', mean(adaptiveNoiseStd));
fprintf('Minimum adaptive noise std   : %.6f cm\n', min(adaptiveNoiseStd));
fprintf('Maximum adaptive noise std   : %.6f cm\n', max(adaptiveNoiseStd));
fprintf('Mean adaptive noise variance : %.6f cm^2\n', mean(adaptiveNoiseVariance));
fprintf('Minimum adaptive R           : %.6f cm^2\n', min(adaptiveNoiseVariance));
fprintf('Maximum adaptive R           : %.6f cm^2\n', max(adaptiveNoiseVariance));

fprintf('\n============================================\n');
fprintf(' KALMAN FILTER PERFORMANCE\n');
fprintf('============================================\n');
fprintf('Raw mean distance             : %.6f cm\n', meanDistance);
fprintf('Filtered mean distance        : %.6f cm\n', filteredMean);
fprintf('Raw variance                  : %.6f cm^2\n', varianceDistance);
fprintf('Filtered variance             : %.6f cm^2\n', filteredVariance);
fprintf('Raw standard deviation        : %.6f cm\n', stdDistance);
fprintf('Filtered standard deviation   : %.6f cm\n', filteredStd);
fprintf('Raw range                     : %.6f cm\n', rangeDistance);
fprintf('Filtered range                : %.6f cm\n', filteredRange);
fprintf('Standard deviation reduction : %.2f%%\n', standardDeviationReductionPercent);
fprintf('Mean Kalman gain              : %.6f\n', mean(kalmanGainAdaptive));
fprintf('============================================\n');

%% 21D. SAVE ORIGINAL AND ADDED RESULTS TO A NEW CSV

% The original ultrasonic_noise_data.csv created in section 13 is untouched.
% This second CSV contains the original measurements plus filter outputs.
AdaptiveResultsTable = table( ...
    sampleNumber, time, distance, reference, noise, ...
    filteredDistance, rawCenteredDeviation, filteredCenteredDeviation, ...
    adaptiveNoiseStd, adaptiveNoiseVariance, kalmanGainAdaptive, ...
    'VariableNames', {'SampleNumber', 'Time_s', 'RawDistance_cm', ...
    'OriginalReferenceMean_cm', 'OriginalNoise_cm', ...
    'KalmanFilteredDistance_cm', 'RawCenteredDeviation_cm', ...
    'FilteredCenteredDeviation_cm', 'AdaptiveNoiseStd_cm', ...
    'AdaptiveMeasurementVariance_cm2', 'KalmanGain'});

writetable(AdaptiveResultsTable, 'ultrasonic_adaptive_filter_results.csv');
fprintf('\nExtended results saved to: ultrasonic_adaptive_filter_results.csv\n');
fprintf('Original file ultrasonic_noise_data.csv was not changed.\n');

%% 21E. GRAPH 7: RAW VS ADAPTIVELY FILTERED DISTANCE

figure;
plot(time, distance, 'DisplayName', 'Raw sensor readings');
hold on;
plot(time, filteredDistance, 'LineWidth', 1.5, ...
    'DisplayName', 'Adaptive Kalman filtered');
yline(meanDistance, '--', 'Raw mean');
xlabel('Time (s)');
ylabel('Distance (cm)');
title('Raw vs Adaptive Kalman Filter Output');
legend('Location', 'best');
grid on;

%% 21F. GRAPH 8: ADAPTIVE NOISE LEVEL OVER TIME

figure;
plot(time, adaptiveNoiseStd, 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('Estimated local noise standard deviation (cm)');
title('Adaptive Characterization of Local Measurement Noise');
grid on;

%% 21G. GRAPH 9: ADAPTIVE MEASUREMENT VARIANCE R

figure;
plot(time, adaptiveNoiseVariance, 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('Adaptive measurement-noise variance R (cm^2)');
title('Measurement-Noise Variance Used by the Kalman Filter');
grid on;

%% 21H. GRAPH 10: RAW VS FILTERED VARIABILITY

figure;
bar([stdDistance, filteredStd]);
set(gca, 'XTick', 1:2, 'XTickLabel', {'Raw', 'Filtered'});
ylabel('Standard deviation (cm)');
title('Measurement Variability Before and After Filtering');
grid on;

%% 21I. GRAPH 11: RAW VS FILTERED DISTRIBUTIONS

figure;
histogram(distance, 30, 'Normalization', 'pdf', ...
    'DisplayName', 'Raw readings');
hold on;
histogram(filteredDistance, 30, 'Normalization', 'pdf', ...
    'DisplayName', 'Filtered estimates');
xlabel('Distance (cm)');
ylabel('Probability density');
title('Raw and Filtered Distance Distributions');
legend('Location', 'best');
grid on;

%% 21J. FINAL INTERPRETATION REMINDER

fprintf('\nInterpretation notes:\n');
fprintf('- Adaptive R is estimated from recent reading variability using MAD.\n');
fprintf('- Q_process is fixed; only the measurement-noise estimate R adapts.\n');
fprintf('- Lower filtered standard deviation means smoother output, not necessarily higher accuracy.\n');
fprintf('- To assess accuracy, compare raw and filtered values with an independently measured wall distance.\n');
fprintf('- The filter assumes the wall distance is approximately stationary.\n');
