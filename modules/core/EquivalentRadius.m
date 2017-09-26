function [ outputs ] = EquivalentRadius( img, ~, ~, inputs )
%EQUIVALENTRADIUS EquivalentRadius module summary
%
%   SUMMARY:
%       Compute the area equivalent radius of the flake in mm.
%
%   INPUTS:
%       1: Flake cross-section (mm^2, from CrossSection)
%
%   OUTPUTS:
%       1: The area equivalent radius (mm)
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Read inputs
xsec = inputs{1};
backgroundThresh = inputs{2};
filledFlake = inputs{3};

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
partialarea = length(flakemask) / length(areamask); % Fraction of enclosedc area that
                                                    % exeeds background.

% Compute radius
req = sqrt(partialarea * xsec / pi);

% Write outputs
outputs{1} = req;
% Clear all variables except outputs
clearvars -except outputs;


end % Function end