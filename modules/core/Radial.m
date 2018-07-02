function [ outputs ] = Radial( ~, bounds, ~, inputs )
%RADIAL
% 
%   SUMMARY:
%       Function which calculates radial properties and return polar
%       coordinate array around center of object
%
%   INPUTS:
%       ~ (masked out img since this function doesn't need it)
%       bounds - default
%       ~ (masked out topLeftCoords since this function doesn't need it)
%       varargin:
%           {1} - unweighted center (given by Center module)
%
%   OUTPUTS:
%       1: abs_v, "absolute" variance, variance / mean. This
%           will help to compare variance across object of different size.
%       2: polar coordinate array around center of object (may contain
%           NaNs)
%
%   DEPENDENCIES:
%       MODULE - Center
%

% Load inputs
cent = inputs{1};

% zeros of radius array, begin parsing
radius = nan(1, 360);
for r = 1 : size(bounds, 1)
    for c = 1 : size(bounds, 2)
        if bounds(r,c) ~= 0
            %convert bounds into polar
            [the, rho] = cart2pol( c - cent(1), cent(2) - r);
            the = ceil(rad2deg(the));
            % Convert degrees to unsigned degrees
            if the <= 0
                the = the + 360;
            end
            if isnan(radius(the)) || radius(the) < rho
                radius(1, the) = rho;
            end
        end
    end
end
mea = nanmean(radius);
variance = nanvar(radius);
abs_v = variance/mea;


outputs{1} = abs_v;
outputs{2} = radius;
clearvars -except outputs


end