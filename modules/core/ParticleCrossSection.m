function [ outputs ] = ParticleCrossSection( img, bounds, ~, inputs )
%PARTICLECROSSSECTION ParticleCrossSection module summary...
%
%   SUMMARY:
%       
%
%   INPUTS:
%       1: Flake cross-section (from CrossSection module)
%       2: Background threshold (from settings)
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

% Check if img and bounds are not the same size (if so, then there's
% padding on the bounds in the cropped image)
if size(img,1) ~= size(bounds,1)
    % Pad top/bottom
    bounds = [zeros(5, size(bounds,2)); bounds; zeros(5, size(bounds,2))];
    % Pad left/right
    bounds = [zeros(size(bounds,1), 5), bounds, zeros(size(bounds,1), 5)];
end

%% COMPUTE PARTICLE CROSS SECTION

stats = regionprops(bounds, 'PixelIdxList');
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