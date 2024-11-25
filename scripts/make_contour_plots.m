disp("---- MATLAB: make_contour_plots ----")
titles = trimtitles(INPUT);
options.contour_length = single(N_FRAMES)
makeplots(INPUT, titles, options)

saveas(gcf, OUTPUT{1});
saveas(gcf, OUTPUT{2});
close(gcf);

disp("---- END MATLAB ----")
clear all;