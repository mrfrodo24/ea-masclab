function [ indices ] = ModuleOutputHandler( whichModule, verifyModuleHandler )
%UNTITLED2 Summary of this function goes here
%
%   SUMMARY:
%
%   INPUTS:
%
%   OUTPUTS:
%       indices - This is an array of indices that tell ModuleRunner into
%                 which columns of goodSubFlakes the output(s) from your 
%                 Module will go 

% When your module is implemented, you may add it as a conditional here so
% that it is accepted by CP3G Masc Analytics. Remember that you'll also
% have to do this in ModuleOutputHandler, once the module is implemented
% there as well.
if verifyModuleHandler
    if strcmp(whichModule, 'Center') || ...
       strcmp(whichModule, 'Pores') || ...
       strcmp(whichModule, 'Radial') || ...
       strcmp(whichModule, 'SonicNumber') || ...
       strcmp(whichModule, 'Fallspeed') || ...
       strcmp(whichModule, 'Focus') || ...
       strcmp(whichModule, 'AspectRatio') || ...
       strcmp(whichModule, 'AvgIntensity') || ...
       strcmp(whichModule, 'CrossSection') || ...
       strcmp(whichModule, 'EquivalentRadius') || ...
       strcmp(whichModule, 'MaxDiameter') || ...
       strcmp(whichModule, 'Perimeter') || ...
       strcmp(whichModule, 'Complexity') || ...
       strcmp(whichModule, 'Roughness') || ...
       strcmp(whichModule, 'CornerNumber') || ...
       strcmp(whichModule, 'ConcaveNumber')

        moduleVerified = 1;
    else
        moduleVerified = 0;
    end
    indices = moduleVerified;
    return;
end

% Determine which module we'll need to handle outputs for...
% Then, handle the outputs appropriately...
switch whichModule
    case 'AspectRatio'
        indices = [21];
        
    case 'AvgIntensity'
        indices = [13];
        
    case 'Center'
        indices = [7 8];
        
    case 'Complexity'
        indices = [20];
        
    case 'ConcaveNumber'
        indices = [25];
        
    case 'CornerNumber'
        indices = [24];

    case 'CrossSection'
        indices = [18];

    case 'EquivalentRadius'
        indices = [19];
        
    case 'Fallspeed'
        indices = [26];

    case 'Focus'
        indices = [15];

    case 'MaxDiameter'
        indices = [16];

    % DEPRECATED
    case 'ParticleCrossSection'
        indices = [19];

    case 'Perimeter'
        indices = [17];

    case 'Pores'
        indices = [9 10];

    case 'Radial'
        indices = [11 12];
        
    case 'Roughness'
        indices = [22 23];

    case 'SonicNumber'
        indices = [14]; %#ok<*NBRAK>
    
    otherwise
        % Throw error, unrecognized module, can't process with module
        indices = [];
    
end

end

