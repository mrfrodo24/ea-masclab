function [ outputs ] = CornerNumber( ~, ~, ~, inputs )
%CORNERNUMBER CornerNumber Module summary enclosed
%   
%   SUMMARY:
%       As first used in Nurzynska et. al. 2013 (Shape parameters for ...),
%       this module attempts to estimate the number of corners of the flake
%       object.  The method used in Nurzynska et. al. uses some weird
%       formulae, so we're going with a Matlab image processing function
%       called "corner".
%
%   INPUTS: 
%       1: The filled flake cross-section
%
%   OUTPUTS: 
%       1: Approximate number of "corners"
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Read inputs
filledFlake = inputs{1};

% Call corner
num_corners = size(corner(filledFlake),1);

% Write outputs
outputs{1} = num_corners;
% Clear all variables except outputs
clearvars -except outputs

end % Function end

