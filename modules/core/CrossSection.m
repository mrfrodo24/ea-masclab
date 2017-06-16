function [ outputs ] = CrossSection( ~, bounds, ~, inputs )
%CROSSSECTION CrossSection module summary...
%
%   SUMMARY:
%       Determines the cross-section of the flake.
%
%   INPUTS:
%       1: List of camera "field-of-view"s. These provide the values that are needed
%           in order to convert pixels into mm for each camera.
%       2: Camera ID (0, 1, or 2)
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

% COMPUTE CROSS SECTIONAL AREA (in mm^2)
pixelperim = sum(sum(bounds));
filled_bounds = imfill(bounds, 'holes');
% Get number of pixels inside the bounds
pixelarea = sum(sum(filled_bounds)) - pixelperim; % Imagine this as square pixels
% Convert that number of pixels to mm^2...
resolution = 1 / camFOVs(cam_id + 1); % mm / pixel
xsec = pixelarea * (resolution ^ 2); % mm^2 (square pixels cancel out)

% Write outputs
outputs{1} = xsec;
% Clear all variables that aren't the outputs
clearvars -except outputs


end % Function end