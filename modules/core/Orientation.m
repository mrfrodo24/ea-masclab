function [ outputs ] = Orientation( ~, ~, ~, inputs ) 
%ORIENTATION Orientation module summary...
%
%   SUMMARY:
%       Determines the orientation of the flake in the img.
%
%   INPUTS: 
%       filledFlake - The filled cross-section of the cropped flake.
%
%   OUTPUTS:
%       1: Estimated orientation
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Read inputs
filledFlake = inputs{1};

% Compute orientation
stats = regionprops(filledFlake, 'Orientation', 'MajorAxisLength');
if length(stats) > 1
    % Erroneous edges detected, pick the best (i.e. biggest) edge...
    allSizes = [stats.MajorAxisLength];
    whichBound = find( allSizes == max(allSizes), 1, 'first' );
    stats = stats(whichBound);
end

% Write outputs
outputs{1} = stats.Orientation;
% Clear all variables except outputs
clearvars -except outputs


end % Function end