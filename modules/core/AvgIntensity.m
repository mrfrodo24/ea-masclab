function [ outputs ] = AvgIntensity( img, ~, ~, ~ )
%AVGINTENSITY Summary of this function goes here
%   Detailed explanation goes here

img_fullpath = img;
img = imread(img_fullpath);

img(img == 0) = NaN;
outputs{1} = nanmean(nanmean(img));

clearvars -except outputs


end

