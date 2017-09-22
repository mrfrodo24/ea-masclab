function [ filledFlake ] = FillFlake ( flake, linefill, res )
%FILLEDFLAKE Fills the edge detection for a cropped flake
%
%   INPUTS:
%       flake - array output from imread for the cropped flake image.
%       linefill - the minimum flake size, for blurring internal complexities.
%       res - the camera resolution (microns per pixel)
%
%   OUTPUTS:
%       filledFlake - A logical array, where 1 indicates flake area.
%

se0 = strel('line', floor(1.5*linefill)/res, 0); %horz
se90 = strel('line', floor(1.5*linefill)/res, 90); %vert

flakeEdge = edge(flake,'Sobel',0.008); %edge detection algorithm
flakeDilated = imdilate(flakeEdge, [se0 se90]); %dilates edges
flakedFilled = imfill(flakeDilated,'holes'); %fills in dilated edgy image
filledFlake = imerode(flakedFilled,[se0 se90]); %filled cross-section

end

