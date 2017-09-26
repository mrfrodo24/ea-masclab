function [ outputs ] = Complexity( ~, ~, ~, inputs )
%COMPLEXITY Complexity module summary...
%
%   SUMMARY:
%       Module for calculating Tim Garrett's "complexity" parameter. The
%       formula for complexity is defined in Garrett, Yuter, et. al. 2014.
%
%   INPUTS:
%       1: Flake perimeter (mm, from Perimeter module)
%       2: Flake area equivalent radius (mm, from EquivalentRadius module)
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

% Compute complexity
complexity = perim / (2*pi*req);

% Write outputs
outputs{1} = complexity;
% Clear all variables except outputs
clearvars -except outputs


end % Function end