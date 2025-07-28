clear; clc; close all;

fprintf('DSC Isothermal Crystallization Analysis\n');
fprintf('========================================\n');

material_name = input('Enter material name (for plot titles): ', 's');
if isempty(material_name)
    material_name = 'Unknown Material';
end

num_temps = input('How many target temperatures were tested? ');

while num_temps <= 0 || num_temps ~= round(num_temps)
    num_temps = input('Please enter a valid positive integer: ');
end

target_temps = zeros(num_temps, 1);
file_names = cell(num_temps, 1);

fprintf('\nPlease enter target temperatures and corresponding file names:\n');
for i = 1:num_temps
    fprintf('\n--- Temperature %d ---\n', i);
    target_temps(i) = input(sprintf('Target temperature %d (°C): ', i));
    file_names{i} = input(sprintf('File name for %d°C: ', target_temps(i)), 's');
end

isothermal_start_times = zeros(num_temps, 1);

for i = 1:num_temps

    heating_time = 1650;
    
    hold_300_time = 180;
    
    cooling_time = (300 - target_temps(i)) / 50 * 60;
    
    isothermal_start_times(i) = heating_time + hold_300_time + cooling_time;
    
    fprintf('Temperature %d°C: Isothermal starts at %.1f min\n', ...
            target_temps(i), isothermal_start_times(i)/60);
end

data_sets = cell(num_temps, 1);
isothermal_data = cell(num_temps, 1);
full_isothermal_data = cell(num_temps, 1);
crystallization_times = zeros(num_temps, 1);
crystallization_points = cell(num_temps, 1);

for i = 1:num_temps
    fprintf('\nProcessing file: %s\n', file_names{i});
    
    try
        data = readmatrix(file_names{i}, 'FileType', 'text');
        
        time = data(:, 2);
        heat_flow = data(:, 3);
        temp_sample = data(:, 4);
        
  
        data_sets{i} = struct('time', time, 'heat_flow', heat_flow, 'temp', temp_sample);
        
        iso_start_idx = find(time >= isothermal_start_times(i), 1);
        
        if isempty(iso_start_idx)
            fprintf('Warning: Cannot find isothermal start time for file %s\n', file_names{i});
            continue;
        end
        
        full_iso_end_time = isothermal_start_times(i) + 140*60;
        full_iso_end_idx = find(time >= full_iso_end_time, 1);
        if isempty(full_iso_end_idx)
            full_iso_end_idx = length(time);
        end
        
        full_iso_time = time(iso_start_idx:full_iso_end_idx);
        full_iso_heat_flow = heat_flow(iso_start_idx:full_iso_end_idx);
        full_iso_temp = temp_sample(iso_start_idx:full_iso_end_idx);
        
        full_isothermal_data{i} = struct('time', full_iso_time, 'heat_flow', full_iso_heat_flow, 'temp', full_iso_temp);
        
        search_window = 10 * 60;
        iso_end_search_idx = find(time >= (isothermal_start_times(i) + search_window), 1);
        if isempty(iso_end_search_idx)
            iso_end_search_idx = length(time);
        end
        
        search_time = time(iso_start_idx:iso_end_search_idx);
        search_heat_flow = heat_flow(iso_start_idx:iso_end_search_idx);
        
        smoothed_hf = smoothdata(search_heat_flow, 'movmean', 20);
        
        [min_vals, min_locs] = findpeaks(-smoothed_hf);
        min_vals = -min_vals;
        
        if ~isempty(min_locs)
            min_time = search_time(min_locs(1));
            min_heat_flow = search_heat_flow(min_locs(1));
            fprintf('Found minimum at %.1f min (will use as origin)\n', min_time/60);
        else
            min_time = search_time(1);
            min_heat_flow = search_heat_flow(1);
            fprintf('No minimum found - using isothermal start as origin\n');
        end
        
        min_idx_full = find(time >= min_time, 1);
        max_plot_time = 120 * 60;
        end_idx = find(time >= (min_time + max_plot_time), 1);
        if isempty(end_idx)
            end_idx = length(time);
        end
        
        iso_time = time(min_idx_full:end_idx) - min_time;
        iso_heat_flow = heat_flow(min_idx_full:end_idx) - min_heat_flow;
        iso_temp = temp_sample(min_idx_full:end_idx);
        
        isothermal_data{i} = struct('time', iso_time, 'heat_flow', iso_heat_flow, 'temp', iso_temp);
        
        [cryst_time, cryst_heat_flow] = find_crystallization_time(iso_time, iso_heat_flow);
        crystallization_times(i) = cryst_time;
        
        if cryst_time > 0
            cryst_idx = find(iso_time >= cryst_time, 1);
            crystallization_points{i} = [cryst_time, iso_heat_flow(cryst_idx)];
            fprintf('Crystallization detected at %.2f minutes from origin\n', cryst_time/60);
        else
            fprintf('No crystallization detected within time window\n');
        end
        
    catch ME
        fprintf('Error processing file %s: %s\n', file_names{i}, ME.message);
    end
end

figure('Position', [100, 100, 1200, 1400]);

colors = lines(num_temps);

subplot(3, 1, 1);
hold on;

for i = 1:num_temps
    if ~isempty(full_isothermal_data{i})
        plot_time = (full_isothermal_data{i}.time - isothermal_start_times(i))/60;
        plot_heat_flow = full_isothermal_data{i}.heat_flow;
        
        plot(plot_time, plot_heat_flow, ...
             'Color', colors(i,:), 'LineWidth', 1.5, ...
             'DisplayName', sprintf('%d°C', target_temps(i)));
    end
end

xlabel('Time (minutes)');
ylabel('Heat Flow (W/g)');
title(sprintf('%s - Complete Isothermal Hold (140 minutes)', material_name));
legend('Location', 'best');
grid on;
xlim([0, 140]);
set(gca, 'XTick', 0:10:max(xlim));
grid minor

subplot(3, 1, 2);
hold on;

for i = 1:num_temps
    if ~isempty(isothermal_data{i})
        valid_idx = isothermal_data{i}.time <= 120*60;
        plot_time = isothermal_data{i}.time(valid_idx)/60;
        plot_heat_flow = isothermal_data{i}.heat_flow(valid_idx);
        
        plot(plot_time, plot_heat_flow, ...
             'Color', colors(i,:), 'LineWidth', 2, ...
             'DisplayName', sprintf('%d°C', target_temps(i)));
        
        if ~isempty(crystallization_points{i}) && crystallization_points{i}(1) <= 120*60
            plot(crystallization_points{i}(1)/60, crystallization_points{i}(2), ...
                 'o', 'Color', colors(i,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(i,:), ...
                 'DisplayName', sprintf('Crystallization at %d°C', target_temps(i)));
        end
    end
end

xlabel('Time (minutes)');
ylabel('Relative Heat Flow (W/g)');
title(sprintf('%s - Isothermal Crystallization (0-120 minutes from first minimum)', material_name));
legend('Location', 'best');
grid on;
xlim([0, 120]);
set(gca, 'XTick', 0:10:max(xlim));
grid minor

subplot(3, 1, 3);
hold on;

for i = 1:num_temps
    if ~isempty(isothermal_data{i})
        valid_idx = isothermal_data{i}.time <= 60*60;
        plot_time = isothermal_data{i}.time(valid_idx)/60;
        plot_heat_flow = isothermal_data{i}.heat_flow(valid_idx);
        
        plot(plot_time, plot_heat_flow, ...
             'Color', colors(i,:), 'LineWidth', 2, ...
             'DisplayName', sprintf('%d°C', target_temps(i)));
        
        if ~isempty(crystallization_points{i}) && crystallization_points{i}(1) <= 60*60
            plot(crystallization_points{i}(1)/60, crystallization_points{i}(2), ...
                 'o', 'Color', colors(i,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(i,:), ...
                 'DisplayName', sprintf('Crystallization at %d°C', target_temps(i)));
        end
    end
end

xlabel('Time (minutes)');
ylabel('Relative Heat Flow (W/g)');
title(sprintf('%s - Isothermal Crystallization (Zoomed: 0-60 minutes from first minimum)', material_name));
legend('Location', 'best');
grid on;
xlim([0, 60]);
set(gca, 'XTick', 0:5:max(xlim));
grid minor

fprintf('\n=== ISOTHERMAL CRYSTALLIZATION ANALYSIS RESULTS ===\n');
fprintf('Material: %s\n', material_name);
fprintf('%-12s %-20s %-20s\n', 'Temperature', 'Crystallization Time', 'Crystallization Time');
fprintf('%-12s %-20s %-20s\n', '(°C)', '(seconds)', '(minutes)');
fprintf('%-12s %-20s %-20s\n', '--------', '----------------', '----------------');

for i = 1:num_temps
    if crystallization_times(i) > 0
        fprintf('%-12d %-20.2f %-20.2f\n', target_temps(i), crystallization_times(i), crystallization_times(i)/60);
    else
        fprintf('%-12d %-20s %-20s\n', target_temps(i), 'Not detected', 'Not detected');
    end
end

cryst_table = table(target_temps, crystallization_times, crystallization_times/60, ...
                   'VariableNames', {'Temperature_C', 'Crystallization_Time_s', 'Crystallization_Time_min'});
disp(cryst_table);

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
save_filename = sprintf('dsc_isothermal_results_%s_%s.mat', strrep(material_name, ' ', '_'), timestamp);
save(save_filename, 'isothermal_data', 'full_isothermal_data', 'crystallization_times', 'target_temps', 'cryst_table', 'material_name');
fprintf('\nResults saved to %s\n', save_filename);


function cryst_time = find_crystallization_time(time, heat_flow)
    
    cryst_time = 0;
    
    if length(heat_flow) < 100
        return;
    end
    
    smoothed_hf = smoothdata(heat_flow, 'movmean', 20);
    
    start_idx = find(time > 120, 1);
    if isempty(start_idx)
        start_idx = 50;
    end
    
    [~, min_idx] = min(smoothed_hf(start_idx:end));
    min_idx = min_idx + start_idx - 1;

    cryst_time = time(min_idx);

    if min_idx < length(smoothed_hf) - 100
        post_min_data = smoothed_hf(min_idx:min_idx+100);
        if std(post_min_data) < 0.5
            cryst_time = time(min_idx);
        end
    end
end