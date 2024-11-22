% combine_traces.m
input_files = evalin('base', 'INPUT_FILES'); % Cell array of input file paths
output_file = evalin('base', 'OUTPUT_FILE'); % Output file path
selection_criteria = evalin('base', 'CRITERIA');

load(selection_criteria);
options.outFilename = output_file;
loadPickSaveTraces(input_files, criteria, options);
