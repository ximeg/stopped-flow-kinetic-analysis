% Combine all traces matching the pattern together into one file
fileList = dir('../data/A/traces/*6uM_auto_gcorr.traces');
load('../data/A/config/criteria.mat');
options.outFilename = '../data/A/combined_traces/6uM.traces';
loadPickSaveTraces({fileList.name}, criteria, options);

