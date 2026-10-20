# adaptive-sensor-noise-filtering
Arduino-based ultrasonic distance measurement, statistical noise characterization, and adaptive Kalman filtering using MATLAB.
# Adaptive Noise Characterization and Smart Sensor Filtering

## Overview
An academic project for Probability and Random Processes that studies measurement variability in ultrasonic distance sensing and applies adaptive Kalman filtering to reduce fluctuations in sensor readings.

## Hardware
- Arduino Uno
- HC-SR04 ultrasonic distance sensor
- Stationary target

## Software
- MATLAB
- Arduino IDE

## Methodology
1. Collect repeated distance measurements using the HC-SR04 sensor.
2. Perform statistical analysis of the recorded measurements.
3. Estimate local measurement noise using a rolling window and Median Absolute Deviation (MAD).
4. Apply an adaptive measurement-noise Kalman filter.
5. Compare raw and filtered measurements using statistical metrics and plots.

## Concepts Demonstrated
- Probability and Random Processes
- Statistical noise characterization
- Variance and standard deviation
- Median Absolute Deviation (MAD)
- Autocorrelation
- Adaptive Kalman filtering

## Repository Structure
- `arduino/` — sensor acquisition sketch
- `matlab/` — data analysis and filtering script
- `results/` — selected experimental plots, if included

## Results
The experimental analysis showed a reduction in the standard deviation of the measurements after filtering. Reduced variability does not necessarily imply improved measurement accuracy.

## Reproducibility
Check the serial port, baud rate, sensor connections, and MATLAB configuration before running the code. The hardware setup and acquisition settings should match those used in the experiment.
