function [ outputs ] = Perimeter( ~, ~, ~, inputs )
%PERIMETER Perimter module summary...
%
%   SUMMARY:
%       Converts the pixel perimeter of the flake to mm.
%
%   INPUTS:
%       1: Perimeter of flake (in pixels)
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
perim_pixels = inputs{1};
camFOVs = inputs{2};
cam_id = inputs{3};

% Convert perimeter pixels to mm
perim_mm = perim_pixels * (1 / camFOVs(cam_id + 1));

% Write outputs
outputs{1} = perim_mm;
% Clear all variables except outputs
clearvars -except outputs


end % Function end