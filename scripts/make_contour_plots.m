disp("---- MATLAB: make_contour_plots ----")
titles = trimtitles(INPUT);
options.contour_length = single(N_FRAMES)
makeplots(INPUT, titles, options)

saveas(gcf, OUTPUT);
close(gcf);

disp("---- END MATLAB ----")
clear all;