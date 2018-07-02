function [ indices ] = ModuleOutputHandler( whichModule, verifyModuleHandler )
%MODULEOUTPUTHANDLER Get the index (or indices) into the Flake array for a module.
%
%   SUMMARY:
%       This function is called by ModuleRunner so it knows what indices of the
%       flakes array the outputs from a Module belong to.
%
%   INPUTS:
%       whichModule - The module
%       verifyModuleHandler - Treat the function as module verification
%
%   OUTPUTS:
%       indices - This is an array of indices that tell ModuleRunner into
%                 which columns of goodSubFlakes the output(s) from your 
%                 Module will go 

% When your module is implemented, you may add it as a conditional here so
% that it is accepted by EA Masc Analytics. 
if verifyModuleHandler
    if strcmp(whichModule, 'AspectRatio') || ...
       strcmp(whichModule, 'AvgIntensity') || ...
       strcmp(whichModule, 'Center') || ...
       strcmp(whichModule, 'Complexity') || ...
       strcmp(whichModule, 'ConcaveNumber') || ...
       strcmp(whichModule, 'CornerNumber') || ...
       strcmp(whichModule, 'CrossSection') || ...
       strcmp(whichModule, 'EquivalentRadius') || ...
       strcmp(whichModule, 'Fallspeed') || ...
       strcmp(whichModule, 'Focus') || ...
       strcmp(whichModule, 'MaxDiameter') || ...
       strcmp(whichModule, 'MoreFocus') || ...
       strcmp(whichModule, 'Orientation') || ...
       strcmp(whichModule, 'Perimeter') || ...
       strcmp(whichModule, 'Pores') || ...
       strcmp(whichModule, 'Radial') || ...
       strcmp(whichModule, 'Roughness') || ...
       strcmp(whichModule, 'SonicNumber')

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
        
    case 'MoreFocus'
        indices = [30 31 32 33 34];

    case 'MaxDiameter'
        indices = [16];
        
    case 'Orientation'
        indices = [29];

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

