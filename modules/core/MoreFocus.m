function [ outputs ] = MoreFocus( img_fullpath, ~, ~, ~ )
%MOREFOCUS Computes several Focus values to be analyzed with machine
%learning
%
%   SUMMARY:
%       Computes several Focus values.  Unknown which will perform best, so
%       will use machine learning with a large training set to identify
%       best focus measures and threshold(s).
%
%       All of the measures computed herein are housed in utils/fmeasure.m
%
%   INPUTS: None
%
%   OUTPUTS:
%       vola_revised - Revised F_voll4 measure
%       f_norvar - Normalized variance of grey-level intensities
%       f_var - Variance of grey-level intensities
%       f_gaussdiff - Avg. difference of grey-level intensities between
%           original and gaussian filtered image
%       f_gaussdiff_volarev - Abs. difference between revised F_voll4
%           measures of original and gaussian filtered image
%       

numOutputs = 5;
outputs = cell(1,numOutputs);

img = imread(img_fullpath);
% Get rid of high specular reflections
maxval = prctile(img(:),99);
img(img > maxval) = maxval;

% Compute measures
outputs{1} = fmeasure(img, 'VOLA_RHODES');
outputs{2} = fmeasure(img, 'NORVAR');
outputs{3} = fmeasure(img, 'VAR');
outputs{4} = fmeasure(img, 'GAUSSDIFF');
outputs{5} = abs(outputs{1} - fmeasure(imgaussfilt(img,3),'VOLA_RHODES'));

clearvars -except outputs


end

