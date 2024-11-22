% Open traces file and do idealization
traces = loadTraces('../data/A/traces/6uM.traces')
exp_time = traces.time(2) - traces.time(1)
model = QubModel('../data/A/config/idealization.model');
[idl, model, LL] = skm(traces.fret, exp_time, model, struct());

% Save result to file
csvwrite("../data/A/combined_traces/6uM_idl.csv", idl);
