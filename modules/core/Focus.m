function [ outputs ] = Focus( img, ~, ~, ~ )
%FOCUS Computes a focus parameter using F_voll4 (Santos1997)
%
%   SUMMARY:
%       Uses the Focus Measure function obtained from the Matlab File
%       Exchange to get a measure of focus. 
%
%       The one used here is the VOLA operator:
%           ** When the VOLA value is:
%               > 20 => Almost always pretty good focus
%               < 10 => Almost always out of focus
%           ** RANGE
%               The value does go much higher than 20.
%               It does not go lower than 0.
%
%   INPUTS: None
%
%   OUTPUTS:
%       vola - The VOLA focus measure of the img
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Load the image
img_fullpath = img;
img = imread(img_fullpath);

% TIM GARRETT VERSION...
% rangeintens = nanmean(nanmean(rangefilt(img))) / 255;
% intens = nanmean(nanmean(img)) / 255;

% Current best -> BREN, LAPE
% Others tried -> GLVA, GLLV, GLVN, GDER, DCTE, ACMO
vola = fmeasure(img,'VOLA');
% M1 = img(1:end-1,:);
% M2 = img(2:end,:);
% M3 = img(:,1:end-1);
% M4 = img(:,2:end);
% diff1 = abs(M1 - M2);
% diff2 = abs(M3 - M4);
% vola = mean([diff1(M1 > 0 | M2 > 0); diff2(M3 > 0 | M4 > 0)]);

% Write outputs
outputs{1} = vola;
% Clear all variables that aren't the outputs
clearvars -except outputs


end