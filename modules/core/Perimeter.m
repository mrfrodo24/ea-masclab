function [ outputs ] = Perimeter( ~, ~, ~, inputs )
%PERIMETER Perimter module summary...
%
%   SUMMARY:
%       Converts the pixel perimeter of the flake to mm.
%
%   INPUTS:
%       1: The filled flake cross-section (array)
%       2: List of camera "field-of-view"s. These provide the values that
%           are needed in order to convert pixels into mm for each camera.
%       3: Camera ID (0, 1, or 2)
%
%   OUTPUTS:
%       1: Perimeter of flake in mm
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Read inputs
filledFlake = inputs{1};
camFOVs = inputs{2};
cam_id = inputs{3};

% Convert perimeter pixels to mm
stats = regionprops(filledFlake, 'Perimeter', 'MajorAxisLength');
if length(stats) > 1
    % Erroneous edges detected, pick the best (i.e. biggest) edge...
    allSizes = [stats.MajorAxisLength];
    whichBound = find( allSizes == max(allSizes), 1, 'first' );
    stats = stats(whichBound);
end
perim = stats.Perimeter * (1 / camFOVs(cam_id + 1));

% Write outputs
outputs{1} = perim;
% Clear all variables except outputs
clearvars -except outputs


end % Function end