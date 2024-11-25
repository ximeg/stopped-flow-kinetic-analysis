disp("---- MATLAB: combine_traces ----")

s = load(CRITERIA);
options.outFilename = OUTPUT;
loadPickSaveTraces(INPUT, s.criteria, options);

disp("---- END MATLAB ----")
clear all;
