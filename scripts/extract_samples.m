input_file = evalin('base', 'INPUT');     % single input file
output_files = evalin('base', 'OUTPUT');  % four output files

disp("---- MATLAB: extract_samples ----")
disp("INPUT:  " + input_file);
disp("OUTPUT: " + output_files);


% Select molecules with positions that are within four quadrants of the
% field of view multiplexed surface patterning experiments. To reduce the
% contribution of non-specifically bound molecules, only the center of each
% spot is selected using a 2D Gaussian fit of molecule locations.
% 
% Files will be saved to paths specified by `output_file`

% Parameters
STD = 1.9;  %max distance from center of printed spot, number of standard deviations
nX = 1152;
nY = 1152;  %defaults for 2x2 binned, full-frame Hamamatsu Fusion cameras.

    
% Load trace data and extract molecule locations
data = loadTraces(input_file);
[p,f,e] = fileparts(input_file);
x = to_row( [data.traceMetadata.donor_x] );
y = to_row( [data.traceMetadata.donor_y] );

if isfield(data.fileMetadata,'nX')
    nX = data.fileMetadata.nX;
    nY = data.fileMetadata.nY;
end

figure; hold on;
title([f e],'Interpreter','none');
%legend( {'Rejected','A','B','C','D'} );
axis([0 nX 0 nY]);


% Split FOV into four quadrants by molecule position.
% Origin is top-lelt corner. order=[A B; C D]
A = selectCenter(data,  y <= floor(nY/2) & x <= floor(nX/2), STD, 'ro' ); % top left
B = selectCenter(data,  y <= floor(nY/2) & x >  floor(nX/2), STD, 'bo' ); % top right
C = selectCenter(data,  y >  floor(nY/2) & x <= floor(nX/2), STD, 'go' ); % bottom left
D = selectCenter(data,  y >  floor(nY/2) & x >  floor(nX/2), STD, 'mo' ); % bottom right

% Save the each subset associated with a quadrant
saveTraces( output_files{1}, A );
saveTraces( output_files{2}, B );
saveTraces( output_files{3}, C );
saveTraces( output_files{4}, D )


axis equal;
saveas(gcf, PLT);
close(gcf);  % Close the figure


disp("---- END MATLAB ----")
clear all;


function output = selectCenter(data, quadrant, STD, color)
    % Select only the center of printed spots

    x = [data.traceMetadata(quadrant).donor_x];
    y = [data.traceMetadata(quadrant).donor_y];
    data = data.getSubset(quadrant);

    pdx = fitdist(x','Normal');
    pdy = fitdist(y','Normal');


    % Define a region that is within some N standard deviations of the
    % center of the density of molecules.
    selected = ((x - pdx.mu)/pdx.sigma).^2 + ((y - pdy.mu)/pdy.sigma).^2 < STD.^2;

    output = data.getSubset(selected);

    fprintf('Selected %d of %d molecules (%0.f%%)\n\n', sum(selected), ...
            numel(selected), 100*sum(selected)/numel(selected) );

    scatter( x(selected),  y(selected),  color );
    scatter( x(~selected), y(~selected), 'ko' );
end
