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
abs_v = inputs{1};

% zeros of radius array, begin parsing
    radius = nan(1, 360);
    for r = 1 : size(bounds, 1)
        for c = 1 : size(bounds, 2)
            if bounds(r,c) ~= 0
                cent = abs_v;
                %convert bounds into polar
                [the, rho] = cart2pol( c - cent(2), cent(1) - r);
                the = rad2deg(the);
                the = ceil(the);
                % Convert degrees to unsigned degrees
                if the < 0
                    the = the + 360;
                end
                the = the + 1;
                if( radius(1, the) ~= 0 )
                    radius(1, the) = rho;
                elseif radius(1, the) < rho 
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