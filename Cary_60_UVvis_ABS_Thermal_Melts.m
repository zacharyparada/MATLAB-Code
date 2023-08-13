tic;
clc; 
clear; 
close all;


% Define file name and range
filename = 'filename.csv';
temperature_begin = 10;
temperature_end = 100;
temperature_interval = 0.5;
file_notes = 'filenotes'; %this will go on export file name
number_samples = 6;
wavelength = 295;
derivative = false;
% Oligo Names
oligoNames = {
'oligo1',
'oligo2', 
'oligo3',
'oligo4', 
'oligo5', 
'oligo6'
};

% Generate variable names
numColumns = 48;
variableNames = arrayfun(@(i) sprintf('Var%d', i), 1:numColumns, 'UniformOutput', false);

% Import the data
temperature_data_points = (length(temperature_begin:temperature_interval:temperature_end) + 2);
opts = delimitedTextImportOptions('NumVariables', numColumns);
opts.VariableNames = variableNames;
opts.VariableTypes(:) = {'double'};
data = readtable(filename, opts);
data = data(3:temperature_data_points, 1:numColumns);
data = table2array(data);

% Initialization
temperature_range = temperature_begin:temperature_interval:temperature_end;
temperature_range_length = length(temperature_range);

% Data Organization
temp = array2table(data(:, 1), 'VariableNames', {'Temperature'});
h1 = array2table(data(:, 2:2:12), 'VariableNames', strcat('h1_', cellstr(num2str((1:6)'))));
c1 = array2table(flip(data(:, 14:2:24)), 'VariableNames', strcat('c1_', cellstr(num2str((1:6)'))));
h2 = array2table(data(:, 26:2:36), 'VariableNames', strcat('h2_', cellstr(num2str((1:6)'))));
c2 = array2table(flip(data(:, 38:2:48)), 'VariableNames', strcat('c2_', cellstr(num2str((1:6)'))));
data = [temp, h1, c1, h2, c2];

% Oligo Data Extraction
oligoData = cell(6, 1);
for i = 1:6
    oligoData{i} = data(:, i+1:6:end);
    oligoData{i}.Properties.VariableNames = strcat(oligoNames{i}, {' H1', ' C1', ' H2', ' C2'});
end

% Get the current date and format
formatted_date = strrep(datestr(now, 'yyyy-mm-dd'), '-', '_');

% Export results
export_table = [temp, oligoData{:}];
export_table_name = sprintf('%s_ABS_MELT_%s.xlsx', formatted_date, file_notes);
writetable(export_table, export_table_name);



%%% DERIVATIVE OUTPUT %%%
if derivative == true
% Load the data
% Assuming 'export_table' is already loaded into MATLAB workspace

% Get the number of columns and column names
[numRows, numCols] = size(export_table);
columnNames = export_table.Properties.VariableNames;

% Initialize the first_derivative table and the min_derivative table
first_derivative = table();
min_derivative = table();

% Define the smoothing method
% Options: 'moving_average', 'savitzky_golay', 'gaussian'
smoothing_method = 'moving_average';

% Set the desired number of lowest y-points to consider
num_lowest_points = 7;
% Get the number of columns in the export_table
numCols = size(export_table, 2);
% Loop through the y-variables (column 2 to the end)
for i = 2:numCols
    % Get the current y-data
    y_data = export_table{:, i};

    % Apply the selected smoothing method
    switch smoothing_method
        case 'moving_average'
            window_size = 3; % Adjust the window size as needed
            y_data_smoothed = movmean(y_data, window_size);

        case 'savitzky_golay'
            sgolay_order = 2; % Adjust the order as needed
            sgolay_frame = 3; % Adjust the frame size as needed (must be odd)
            y_data_smoothed = sgolayfilt(y_data, sgolay_order, sgolay_frame);

        case 'gaussian'
            window_size = 5; % Adjust the window size as needed
            gaussian_std = 1; % Adjust the standard deviation as needed
            y_data_smoothed = imgaussfilt(y_data, gaussian_std, 'FilterSize', window_size);

        otherwise
            error('Invalid smoothing method selected.');
    end

    % Compute the 1st derivative of smoothed y-data
    x_data = export_table{:, 1};
    dy_dx = diff(y_data_smoothed) ./ diff(x_data);

    % Compute the average x-points for each dy_dx value
    x_data_avg = (x_data(1:end-1) + x_data(2:end)) / 2;

    % Remove the last row from x_data_avg and dy_dx
    x_data_avg(end) = [];
    dy_dx(end) = [];

    % Add the x and y (derivative) columns to the first_derivative table
    if i == 2
        first_derivative = addvars(first_derivative, x_data_avg, dy_dx, 'NewVariableNames', {'Temp_DER', columnNames{i}});
    else
        first_derivative = addvars(first_derivative, dy_dx, 'NewVariableNames', columnNames(i));
    end

    % Find the indices of the num_lowest_points lowest y-values
    [~, lowest_indices] = mink(first_derivative{:, i}, num_lowest_points);

    % Get the corresponding x-values
    lowest_x_values = x_data_avg(lowest_indices);

    % Calculate the midpoint of the x-range
    x_range_midpoint = (min(lowest_x_values) + max(lowest_x_values)) / 2;

    % Add the row to the min_derivative table
    min_derivative = [min_derivative; {columnNames{i}, x_range_midpoint, mean(first_derivative{lowest_indices, i})}];
end
% Set the column names for the min_derivative table
min_derivative.Properties.VariableNames = {'Sample', 'X_Range_Midpoint', 'Avg_Y-value'};

%%% Export Data %%%
export_table_name = sprintf('%s_ABS_DERIVATIVE_%s.xlsx',formatted_date,file_notes);

% Write the first_derivative table
writetable(first_derivative, export_table_name, 'Sheet', 1);

% Write the min_derivative table
writetable(min_derivative, export_table_name, 'Sheet', 2);

end




% Stop the timer and calculate elapsed time in seconds
elapsed_time = toc;
% Calculate minutes and seconds without decimal places
minutes = floor(elapsed_time / 60);
seconds = mod(round(elapsed_time), 60);
% Display the elapsed time in minutes and seconds
if minutes > 0
    fprintf('\nABS Script Complete \nRun time: %d min %d seconds\n\n', minutes, seconds);
else
    if seconds == 1
        fprintf('\nABS Script Complete \nRun time: %d second\n\n', seconds);
    else
        fprintf('\nABS Script Complete \nRun time: %d seconds\n\n', seconds);
    end
end