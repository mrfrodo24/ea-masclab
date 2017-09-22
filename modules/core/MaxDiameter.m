function [ outputs ] = MaxDiameter( ~, ~, ~, inputs )
%MAXDIAMETER MaxDiameter module summary...
%
%   SUMMARY:
%       Determines the maximum width of the flake, in mm, by getting the BoundingBox
%       from regionprops. Uses the camFOV from input 1 and the camera id that
%       captured the image from input 2 to convert the pixel width into mm.
%       
%   INPUTS:
%       1: List of camera "field-of-view"s. These provide the values that are needed
%           in order to convert pixels into mm for each camera.
%       2: Camera ID (0, 1, or 2)
%       3: The filled flake cross-section (array)
%       3: Is it a good flake?
%
%   OUTPUTS:
%       1: Estimated maximum diameter of the flake
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Read inputs
camFOVs = inputs{1};
cam_id = inputs{2};
filledFlake = inputs{3};
isgood = inputs{4};

% DO NOT PROCESS if NOT "good" flake
if ~isgood
    outputs{1} = NaN;
    return;
end

stats = regionprops(filledFlake, 'MajorAxisLength');
if length(stats) > 1
    % Erroneous edges detected, pick the best (i.e. biggest) edge...
    allSizes = [stats.MajorAxisLength];
    whichBound = find( allSizes == max(allSizes), 1, 'first' );
    stats = stats(whichBound);
end

% Compute max diameter
resolution = 1 / camFOVs(cam_id + 1); % mm / pixel
max_diam = stats.MajorAxisLength * resolution;

% Write outputs
outputs{1} = max_diam;
% Clear all variables that aren't the outputs
clearvars -except outputs


end % Function end