% Read variables from the base workspace
input_file = evalin('base', 'INPUT');   % Cell array of input file paths
output_file = evalin('base', 'OUTPUT'); % Output file path
text = evalin('base', 'TXT');           % Text to append

disp(input_file);
disp(output_file);
disp(text);


% Initialize an empty string to hold the combined content
combined_text = "";

% Loop through each input file and read its content
for i = 1:length(input_file)
    % Read the content of the current input file
    current_text = fileread(input_file{i});
    % Append the content to the combined text
    combined_text = combined_text + newline + current_text;
end

% Append the text from TXT to the combined content
combined_text = combined_text + newline + text;

% Write the combined content to the output file
fid = fopen(output_file, 'w');
if fid == -1
    error('Failed to open output file for writing.');
end

fprintf(fid, '%s', combined_text);
fclose(fid);

disp(['Combined text saved to ', output_file]);
