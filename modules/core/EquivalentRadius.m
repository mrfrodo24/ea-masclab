function [ outputs ] = EquivalentRadius( ~, ~, ~, inputs )
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
part_xsec = inputs{1};

% Compute radius
req = sqrt(part_xsec / pi);

% Write outputs
outputs{1} = req;
% Clear all variables except outputs
clearvars -except outputs;


end % Function end