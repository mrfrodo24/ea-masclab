function [ outputs ] = Pores( img, ~, ~, inputs )
%PORES
%
%   SUMMARY:
%
%   INPUTS:
%       img_array - default
%       ~ (masked out bounds since this function doesn't need it)
%       ~ (masked out topLeftCoords since this function doesn't need it)
%       varargin - See ModuleInputHandler

% OLD CODE
%     im = +(img_array > varargin{1});
%     im = imclearborder(im, 8);
%     holes = regionprops(im, 'EulerNumber');
%     holes = holes.EulerNumber;
%     area = regionprops( im, 'Area');
%     cArea = regionprops( im, 'FilledArea');
%     cArea = cArea.FilledArea;
%     area = area.Area;
%     solidity = regionprops( im, 'Solidity');
%     solidity = solidity.Solidity;
    
% Read inputs
backgroundThresh = inputs{1};

% Load image
img_fullpath = img;
img = imread(img_fullpath);
img = +(img > backgroundThresh);
img = imclearborder(img, 8);

% Get holes and solidity
stats = regionprops(img, 'EulerNumber', 'Solidity', 'MajorAxisLength');
if length(stats) > 1
    % Erroneous edges detected, pick the best (i.e. biggest) edge...
    allSizes = [stats.MajorAxisLength];
    whichBound = find( allSizes == max(allSizes), 1, 'first' );
    stats = stats(whichBound);
elseif isempty(stats)
	% Bad flake, return NaN
	outputs{1} = NaN;
	outputs{2} = NaN;
	clearvars -except outputs
	return;
end
holes = abs(stats.EulerNumber - 1);
solidity = stats.Solidity;

% Write outputs
outputs{1} = holes;
outputs{2} = solidity;

clearvars -except outputs
    
end