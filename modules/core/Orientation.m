function [ outputs ] = Orientation( ~, bounds, ~, ~ ) 
%ORIENTATION Orientation module summary...
%
%   SUMMARY:
%       Determines the orientation of the flake in the img.
%
%   INPUTS: None
%
%   OUTPUTS:
%       1: Estimated orientation
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Compute orientation
stats = regionprops(bounds, 'Orientation');

% Write outputs
outputs{1} = stats.Orientation;
% Clear all variables except outputs
clearvars -except outputs


end % Function end