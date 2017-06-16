function [ outputs ] = Roughness( ~, ~, ~, inputs )
%ROUGHNESS Module summary for Roughness
%   
%   SUMMARY:
%       As defined in Nurzynska et. al. 2013 (Shape parameters for ...),
%       this module calculates the "roughness" of a snowflake.  
%       IMPORTANT: In their paper, they state the parameter "This parameter 
%       calculates the diameter of a circle whose perimeter has the same 
%       length as the object's one".  However, based on their formula for
%       the parameter, it seems what they are actually finding is the
%       diameter of a circle whose AREA has the same AREA as the object's
%       one.  This can then be used to compare with the observed max
%       diameter of the object to assess "roughness".
%
%       For our version, we will output both the Roughness value as well as
%       the absolute difference between the max diameter (given by
%       MaxDiameter module) and the diameter determined here.
%
%   INPUTS:
%       1: Maximum diameter of snowflake (given from MaxDiameter) [mm]
%       2: Cross-sectional area of snowflake (given from CrossSection) [mm^2]
%
%   OUTPUTS:
%       1: "Roughness" parameter
%       2: Absolute difference between "roughness" diam & max diam
%

% Declare outputs
numOutputs = 2;
outputs = cell(1,numOutputs);

% Read inputs
max_diam = inputs{1};
xsec_area = inputs{2};

% Get roughness value
roughness = 2 * sqrt( xsec_area / pi );
roughness_diff = abs( roughness - max_diam );

% Write outputs
outputs{1} = roughness;
outputs{2} = roughness_diff;
% Clear all variables that aren't the outputs
clearvars -except outputs


end % Function end

