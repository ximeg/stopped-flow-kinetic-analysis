SAMPLE = 'A'

%
% Find individual traces and discover available concentration values
%
 
fileDir = sprintf('../data/%s/combined_traces/', SAMPLE)
model = QubModel(sprintf('../data/%s/config/batchkinetics.model', SAMPLE));

filePattern = fullfile(fileDir, '*.traces');
files = dir(filePattern);

% Initialize a structure to store grouped files
groupedFiles = struct();

% Loop through each file and group by concentration
for k = 1:length(files)
    fn = fullfile(files(k).folder, files(k).name);

    % Open traces file and do idealization
    traces = loadTraces(fn)

    exp_time = traces.time(2) - traces.time(1)
    
    [idl, ~, LL] = skm(traces.fret, exp_time, model, struct());
    
    % Save result to file
    [filepath, name, ~] = fileparts(fn);
    outfile = fullfile(filepath, strcat(name, '_idl.csv'));
    csvwrite(outfile, idl);
end

