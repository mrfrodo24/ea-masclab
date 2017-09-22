function [ outputs ] = ParticleCrossSection( img, ~, ~, inputs )
%PARTICLECROSSSECTION ParticleCrossSection module summary...
%
%   SUMMARY:
%       
%
%   INPUTS:
%       1: Flake cross-section (from CrossSection module)
%       2: Background threshold (from settings)
%       3: The filled flake cross-section (array)
%
%   OUTPUTS:
%       1: Estimated particle cross-section
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Load the image
img_fullpath = img;
img = imread(img_fullpath);

% Read inputs
xsec = inputs{1};
backgroundThresh = inputs{2};
filledFlake = inputs{3};

%% COMPUTE PARTICLE CROSS SECTION

stats = regionprops(filledFlake, 'PixelIdxList');
areamask = stats.PixelIdxList;
flakemask = areamask(img(areamask) > backgroundThresh);
partialarea = length(flakemask) / length(areamask);
part_xsec = partialarea * xsec;


%% END COMPUTE

% Write outputs
outputs{1} = part_xsec;
% Clear variables except outputs
clearvars -except outputs


end % Function end