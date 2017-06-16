function [ outputs ] = Complexity( img, bounds, ~, inputs )
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

% Load image
img_fullpath = img;
img = imread(img_fullpath);

% Check if img and bounds are not the same size (if so, then there's
% padding on the bounds in the cropped image)
if size(img,1) ~= size(bounds,1)
    % Pad top/bottom
    bounds = [zeros(5, size(bounds,2)); bounds; zeros(5, size(bounds,2))];
    % Pad left/right
    bounds = [zeros(size(bounds,1), 5), bounds, zeros(size(bounds,1), 5)];
end

% Get flakemask
stats = regionprops(bounds, 'PixelIdxList', 'MajorAxisLength');
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