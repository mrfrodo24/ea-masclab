function [ outputs ] = Complexity( img, ~, ~, inputs )
%COMPLEXITY Complexity module summary...
%
%   SUMMARY:
%       Module for calculating Tim Garrett's "complexity" parameter. The
%       formula for complexity is defined in Garrett, Yuter, et. al. 2014.
%
%   INPUTS:
%       1: Flake perimeter (mm, from Perimeter module)
%       2: Flake area equivalent radius (mm, from EquivalentRadius module)
%       3: Background threshold (from settings)
%       4: The filled flake cross-section
%
%   OUTPUTS:
%       1: Complexity measure, as defined in Garrett, Yuter, et. al. 2014
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Read inputs
perim = inputs{1};
req = inputs{2};
backgroundThresh = inputs{3};
filledFlake = inputs{4};

% Load image
img_fullpath = img;
img = imread(img_fullpath);

% Get flakemask
stats = regionprops(filledFlake, 'PixelIdxList', 'MajorAxisLength');
if length(stats) > 1
    % Erroneous edges detected, pick the best (i.e. biggest) edge...
    allSizes = [stats.MajorAxisLength];
    whichBound = find( allSizes == max(allSizes), 1, 'first' );
    stats = stats(whichBound);
end
areamask = [stats.PixelIdxList];
flakemask = areamask(img(areamask) > backgroundThresh);
% Compute rangeintensity of flake
rangearray = rangefilt(img);
rangeintens = mean(rangearray(flakemask)) / 255; % Mean interpixel brightness

% Compute complexity
complexity = (perim / (2*pi*req)) * (1 + rangeintens);

% Write outputs
outputs{1} = complexity;
% Clear all variables except outputs
clearvars -except outputs


end % Function end