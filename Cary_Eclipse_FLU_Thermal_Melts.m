tic;
clc; 
clear; 
close all;

%%% Set Variables %%%
derivative = false;
data_location = "datalocation";
temp_top = 100; 
temp_bottom = 4; 
temp_interval = 0.5;
file_notes = "filenotes";
sample_names = {
'oligo1', 
'oligo2', 
'oligo3', 
'oligo4
};

%%% DATA IMPORT %%%
temp = (temp_bottom:temp_interval:temp_top)';
temp = array2table(temp);
datalines = (((temp_top - temp_bottom))/temp_interval)+3;
opts = delimitedTextImportOptions("NumVariables", 32);
opts.DataLines = [3, datalines]; opts.Delimiter = ",";
opts.VariableTypes = repmat("double", 1, 32);
opts.ExtraColumnsRule = "ignore"; opts.EmptyLineRule = "read";
opts = setvaropts(opts, 1:32, "TrimNonNumeric", true);
opts = setvaropts(opts, 1:32, "ThousandsSeparator", ",");

data = readtable(data_location, opts);
data = table2array(data); data = data(:,2:2:end);

%%% Name Preparation and Data organization %%%
export_table = temp;
hc = [" H1", " C1", " H2", " C2"];
for i = 1:length(sample_names)
    sn = sample_names{i};
    sample_data = data(:,i:4:end);
    sample_data = [sample_data(:,1), flip(sample_data(:,2)), sample_data(:,3), flip(sample_data(:,4))];
    sample_data = array2table(sample_data);
    sample_data.Properties.VariableNames = strcat(sn, hc);
    export_table = [export_table, sample_data];
end

% Get the current date
current_date = date;
% Convert to the desired format
formatted_date = datestr(current_date, 'yyyy-mm-dd');
% Replace the hyphen with an underscore
formatted_date(formatted_date == '-') = '_';

%%% Export Data %%%
export_table_name = sprintf('%s_FLU_ECLIPSE_%s.xlsx',formatted_date,file_notes);
writetable(export_table,export_table_name);





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
num_lowest_points = 3;
% Get the number of columns in the export_table
numCols = size(export_table, 2);
% Loop through the y-variables (column 2 to the end)
for i = 2:numCols
    % Get the current y-data
    y_data = export_table{:, i};

    % Apply the selected smoothing method
    switch smoothing_method
        case 'moving_average'
            window_size = 9; % Adjust the window size as needed
            y_data_smoothed = movmean(y_data, window_size);

        case 'savitzky_golay'
            sgolay_order = 2; % Adjust the order as needed
            sgolay_frame = 15; % Adjust the frame size as needed (must be odd)
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
export_table_name = sprintf('%s_FLU_DERIVATIVE_%s.xlsx',formatted_date,file_notes);

% Write the first_derivative table
writetable(first_derivative, export_table_name, 'Sheet', 1);

% Write the min_derivative table
writetable(min_derivative, export_table_name, 'Sheet', 2);

end





%%%% TIMER STOP %%%%
% Stop the timer and calculate elapsed time in seconds
elapsed_time = toc;
% Calculate minutes and seconds without decimal places
minutes = floor(elapsed_time / 60);
seconds = mod(round(elapsed_time), 60);
% Display the elapsed time in minutes and seconds
if minutes > 0
    fprintf('\nFLU Script Complete \nRun time: %d min %d seconds\n\n', minutes, seconds);
else
    if seconds == 1
        fprintf('\nFLU Script Complete \nRun time: %d second\n\n', seconds);
    else
        fprintf('\nFLU Script Complete \nRun time: %d seconds\n\n', seconds);
    end
end