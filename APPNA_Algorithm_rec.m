% APPNA-EEWS: Automatic P-wave Picker Next-gen Algorithm 
% for Earthquake Early Warning System
%
% Description:
%   This MATLAB script implements the APPNA algorithm for detecting 
%   P-wave arrivals from seismic waveform data in offline (batch) mode. 
% Input:
%   - Folder containing .dat files (single-column numeric arrays).
%
% Output:
%   - pwave_summary_IQR_Weighted_MAD_RMS.csv with detection results.
%   -Diagnostic Plots (per file)
%   -Filtered waveform with vertical line at detected P-wave
%   -Envelope with adaptive threshold and detected P-wave marker
%
%
% Requirements:
%   - MATLAB R2018a or later
%   - Signal Processing Toolbox
%   -Statistics and Machine Learning Toolbox
%   -Curve Fitting Toolbox
%
% License:
%   APPNA-EEWS: Automatic P-wave Picker Next-gen Algorithm 
%   for Earthquake Early Warning System
%   Copyright (C) 2025  Sandeep
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU Affero General Public License as published
%   by the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU Affero General Public License for more details.
%
%   You should have received a copy of the GNU Affero General Public License
%   along with this program.  If not, see <https://www.gnu.org/licenses/>.

% APPNA_EEWS Algorithm for pre Recorded Waveforms

fs = 100; % Sampling Frequency
chunk_size = fs; 
baseline_duration = 30; % in seconds
sustain_time = 0.20; % in seconds
cooldown_time = 20;  % in seconds
N = round(sustain_time * fs);
backtrack_window = round(2 * fs);

folder_path = 'C:\Users\cyril\Documents\MATLAB';
file_list = dir(fullfile(folder_path, '*.dat'));    % waveform File type (e.g. .dat, .txt, .xlsx )
summary_table = table();

% --- Weight configuration for MAD and RMS ---
w_mad = 0.7;
w_rms = 0.3;

for file_idx = 1:length(file_list)
    filename = file_list(file_idx).name;
    filepath = fullfile(folder_path, filename);
    fprintf('\nProcessing file: %s\n', filename);

    try
        signal_data = load(filepath);
        signal_data = signal_data(:);
        num_samples = length(signal_data);
        current_sample = 1;

        signal_buffer = [];
        full_filtered = [];
        full_envelope = [];
        time_vector = [];

        first_p_iqr = NaN;
        last_p_iqr = -Inf;
        noise_level = NaN;

        bpFilt = designfilt('bandpassiir', 'FilterOrder', 4, ...
            'HalfPowerFrequency1', 1, 'HalfPowerFrequency2', 10, ...
            'SampleRate', fs);

        while current_sample <= num_samples
            end_sample = min(current_sample + chunk_size - 1, num_samples);
            new_chunk = signal_data(current_sample:end_sample);
            current_sample = end_sample + 1;

            signal_buffer = [signal_buffer; new_chunk];
            t = ((current_sample - length(signal_buffer)):(current_sample - 1)) / fs;
            current_time = t(end);

            if length(signal_buffer) < max(chunk_size, baseline_duration * fs)
                continue;
            end

            signal_detrended = detrend(signal_buffer);
            signal_filtered = filtfilt(bpFilt, signal_detrended);
            envelope = abs(hilbert(signal_filtered));
            envelope = smooth(envelope, round(0.05 * fs));  % Smooth 50ms window

            full_filtered = [full_filtered; signal_filtered(end - chunk_size + 1:end)];
            full_envelope = [full_envelope; envelope(end - chunk_size + 1:end)];
            time_vector = [time_vector; t(end - chunk_size + 1:end)'];

            baseline_env = envelope(end - baseline_duration * fs + 1:end);

            q1 = quantile(baseline_env, 0.25);
            q3 = quantile(baseline_env, 0.75);
            iqr_val = q3 - q1;

            mad_val = mad(baseline_env, 1);      
            mad_noise = mad_val / 0.6745;          

            rms_noise = rms(baseline_env);         
            noise_level = w_mad * mad_noise + w_rms * rms_noise;

            if noise_level < 0.01
                sensitivity_factor = 2.0;
            elseif noise_level < 0.05
                sensitivity_factor = 2.5;
            elseif noise_level < 0.1
                sensitivity_factor = 3.0;
            elseif noise_level < 0.2
                sensitivity_factor = 3.5;
            else
                sensitivity_factor = 4.0;
            end

            adaptive_k = sensitivity_factor;
            iqr_thresh = q3 + adaptive_k * iqr_val;

            time_since_iqr = current_time - last_p_iqr;
            window_start = length(envelope) - chunk_size + 1;

            if isnan(first_p_iqr) && time_since_iqr >= cooldown_time
                for i = window_start:length(envelope) - N
                    win = envelope(i:i + N);
                    if sum(win > iqr_thresh) > 0.9 * N
                        back_idx = i;

                        start_idx = max(1, back_idx - backtrack_window);
                        env_segment = envelope(start_idx:back_idx);

                        env_diff1 = [0; diff(env_segment)];
                        env_diff2 = [0; diff(env_diff1)];
     
                        norm_slope = (env_diff1 - mean(env_diff1)) / std(env_diff1 + eps);

                        score = norm_slope; 
                        [~, rel_back_idx] = max(score);
                        p_wave_back_idx = start_idx + rel_back_idx - 1;
                        first_p_iqr = t(p_wave_back_idx);
                        break;
                    end
                end
            end
        end

        timestamp = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
        summary_table = [summary_table; table({filename}, ...
            first_p_iqr, iqr_thresh, noise_level, ...
            string(timestamp), ...
            'VariableNames', {'Filename', ...
            'PwaveArrival_iqr', 'Threshold_iqr', 'NoiseLevel', ...
            'Timestamp'})];

        % -------- OPTIONAL: Plot for Visual Inspection --------
figure;

% --- Plot Raw Filtered Waveform ---
subplot(2,1,1);
plot(time_vector, full_filtered);
hold on;
if ~isnan(first_p_iqr)
    xline(first_p_iqr, '--g', 'P-wave');
end
title(sprintf('Raw Waveform: %s', filename), 'Interpreter', 'none');
xlabel('Time (s)');
ylabel('Amplitude');
legend('Filtered Waveform', 'P-wave');
grid on;
hold off;

% --- Plot Envelope with Threshold ---
subplot(2,1,2);
plot(time_vector, full_envelope);
hold on;
yline(iqr_thresh, '--r', 'Threshold');
if ~isnan(first_p_iqr)
    xline(first_p_iqr, '--g', 'P-wave');
end
title(sprintf('Envelope: %s | Noise Level = %.4f', filename, noise_level), 'Interpreter', 'none');
xlabel('Time (s)');
ylabel('Envelope');
legend('Envelope', 'Threshold', 'P-wave');
grid on;
hold off;

    catch ME
        warning('Error processing %s: %s', filename, ME.message);
    end
end

output_csv = fullfile(folder_path, 'pwave_summary_IQR_Weighted_MAD_RMS.csv');
writetable(summary_table, output_csv);
fprintf('\nSummary saved to: %s\n', output_csv);
