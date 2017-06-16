function [ outputs ] = ConcaveNumber( ~, bounds, ~, ~)
%CONCAVENUMBER ConcaveNumber module summary enclosed
%   
%   SUMMARY:
%       As defined in Nurzynska et. al. 2013 (Shape parameters for ...),
%       this module calculates the "concavity" of the flake object.  In the
%       paper, and in this module, the Concave # is the difference between
%       the pixel area of the convex hull that encloses the flake object
%       and the pixel area of the flake object.  The idea is that more
%       rounded flakes will have a smaller Concave #.
%
%   INPUTS: None
%
%   OUTPUTS:
%       1: The # of pixels in the convex hull of the flake that aren't in
%       the flake itself.
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Determine concave number
stats = regionprops(bounds, 'ConvexImage', 'MajorAxisLength');
if length(stats) > 1
    % Erroneous edges detected, pick the best (i.e. biggest) edge...
    allSizes = [stats.MajorAxisLength];
    whichBound = find( allSizes == max(allSizes), 1, 'first' );
    stats = stats(whichBound);
end
hull_px = sum(sum(stats.ConvexImage));
filled_bounds = imfill(bounds, 'holes');
flake_px = sum(sum(filled_bounds));
concavity = abs(hull_px - flake_px);

% Write outputs
outputs{1} = concavity;
% Clear all variables except outputs
clearvars -except outputs


end % Function end

