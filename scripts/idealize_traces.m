input_file = evalin('base', 'INPUT');   % Cell array of input file paths
output_file = evalin('base', 'OUTPUT'); % Output file path
model_file = evalin('base', 'MODEL');

model = QubModel(model_file);

traces = loadTraces(input_file);
exp_time = traces.time(2) - traces.time(1);

[idl, ~, LL] = skm(traces.fret, exp_time, model, struct());
csvwrite(output_file, idl);

