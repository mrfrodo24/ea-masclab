function [ outputs ] = AspectRatio( ~, bounds, ~, ~ ) 
%ASPECTRATIO AspectRatio module summary...
%
%   SUMMARY:
%       Determines the aspect ratio of the flake in the img.
%
%   INPUTS: None
%
%   OUTPUTS:
%       1: Estimated aspect ratio
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Compute aspect ratio
stats = regionprops(bounds, 'MinorAxisLength', 'MajorAxisLength');
if length(stats) > 1
    % Erroneous edges detected, pick the best (i.e. biggest) edge...
    allSizes = [stats.MajorAxisLength];
    whichBound = find( allSizes == max(allSizes), 1, 'first' );
    stats = stats(whichBound);
end
asprat = [stats.MinorAxisLength] / [stats.MajorAxisLength];

% Write outputs
outputs{1} = asprat;
% Clear all variables except outputs
clearvars -except outputs


end % Function end