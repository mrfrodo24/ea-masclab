function [ outputs ] = CrossSection( ~, ~, ~, inputs )
%CROSSSECTION CrossSection module summary...
%
%   SUMMARY:
%       Determines the cross-section of the flake.
%
%   INPUTS:
%       1: List of camera "field-of-view"s. These provide the values that are needed
%           in order to convert pixels into mm for each camera.
%       2: Camera ID (0, 1, or 2)
%       3: The filled flake cross-section (array)
%
%   OUTPUTS:
%       1: Estimated cross-section of the flake in the image.
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Read inputs
camFOVs = inputs{1};
cam_id = inputs{2};
filledFlake = inputs{3};

% COMPUTE CROSS SECTIONAL AREA (in mm^2)
pixelarea = sum(sum(filledFlake)); % Imagine this as square pixels
% Convert that number of pixels to mm^2...
resolution = 1 / camFOVs(cam_id + 1); % mm / pixel
xsec = pixelarea * (resolution ^ 2); % mm^2 (square pixels cancel out)

% Write outputs
outputs{1} = xsec;
% Clear all variables that aren't the outputs
clearvars -except outputs


end % Function end