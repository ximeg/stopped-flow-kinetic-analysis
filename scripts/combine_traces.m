SAMPLE = 'A'

%
% Find individual traces and discover available concentration values
%
 
fileDir = sprintf('../data/%s/traces/', SAMPLE)

filePattern = fullfile(fileDir, '*_auto_gcorr.traces');
files = dir(filePattern);

% Initialize a structure to store grouped files
groupedFiles = struct();

% Loop through each file and group by concentration
for k = 1:length(files)
    fileName = files(k).name;
    
    % Extract the concentration using a regular expression
    tokens = regexp(fileName, '_(\d+uM)_', 'tokens');
    if ~isempty(tokens)
        rawConcentration = tokens{1}{1}; % Extract raw concentration as a string
        
        % Sanitize the field name by adding a prefix
        fieldName = ['C_' rawConcentration];
        
        % Add the file to the appropriate group
        if ~isfield(groupedFiles, fieldName)
            groupedFiles.(fieldName) = {}; % Initialize if not existing
        end
        groupedFiles.(fieldName){end+1} = fullfile(files(k).folder, fileName);
    end
end

% load selection criteria for autotrace
load(sprintf('../data/%s/config/criteria.mat', SAMPLE));

%
% Combine all traces corresponding to one concentration value together
%

% Process each group separately
concentrationFields = fieldnames(groupedFiles);
for i = 1:length(concentrationFields)
    fieldName = concentrationFields{i};
    rawConcentration = fieldName(3:end); % Remove 'C_' to access original concentration value
    fprintf('Combining traces for concentration: %s\n', rawConcentration);
    
    options.outFilename = sprintf('../data/%s/combined_traces/%s.traces', SAMPLE, rawConcentration);
    % Get the list of files for this concentration
    fileList = groupedFiles.(fieldName);
    
    % Load all traces in the group
    loadPickSaveTraces(fileList, criteria, options);
end