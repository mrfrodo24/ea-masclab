function [ moduleVerified, dependencies, inputs ] = ModuleInputHandler( ...
    whichModule, goodSubFlake, settings, usage )
%ModuleInputHandler Used to define extra inputs for any modules to be used.
%   
%   SUMMARY:
%       This function is called by ModuleRunner. It is used by ModuleRunner
%       to define the inputs for running a module. In order for a Module to
%       be usable, it must have a definition in this function (even if it 
%       doesn't require any additional input). This is to ensure that any  
%       modules created for this system remain consistent with our coding 
%       standards.
%
%   INPUTS:
%       whichModule - Supplied by ModuleRunner, this tells the
%                     ModuleInputHandler which module is being prepped for
%                     running.
%       img_array - The image array (given by imread)
%       goodSubFlake - The cell array of statistics for the flake being
%                       examined. For information on the goodSubFlakes cell
%                       array columns, see README_subflakes.txt.
%       settings - A Matlab struct with fields for all of the parameters
%                  defined in pre-processing.
%       usage - There are three usage types for this function:
%           (1) Usage == 1, Called by ModuleRunner to verify functions
%               found in modules/core
%           (2) Usage == 2, Called by ModuleRunner to get names of modules
%               whose output a module depends on
%           (3) Usage == 3, Called by ModuleRunner to get the inputs prior
%               to executing a module
%  
%   OUTPUTS:
%       outputs - This is a cell array that the function delivers to
%                   ModuleRunner. ModuleRunner uses outputs when it calls
%                   the module to pass into the module being run.
%       dependencies - This is a cell array that is to be used to store the
%                      names of any modules that this module is dependent
%                      upon. YOU SHOULD NOT CALL OTHER MODULES WITHIN A
%                      MODULE! Modules are intended to be standalone, but
%                      you can certainly use their data. We just need to
%                      know if data is coming from another module so that
%                      ModuleRunner can make sure to run that module first.
%
%                      HOWEVER: It should be noted that ModuleRunner will
%                      not force you to run a module before another IF the
%                      child module's output has already been produced.
%       

% Determine which module we're getting inputs for...
% Then fetch the appropriate inputs for the module and add them to
%   outputs. Treat outputs as a cell array...
% IMPORTANT:
%   Default inputs will be set independently of this function in
%   ModuleRunner. 
%   Recall DEFAULT inputs:
%       1. The image array
%       2. The flake's bounds
%       3. The flake's top-left coords in original image=

moduleVerified = 0;
dependencies = {};
inputs = {};

% When your module is implemented, you may add it as a conditional here so
% that it is accepted by EA Masc Analytics. Remember that you'll also
% have to do this in ModuleOutputHandler, once the module is implemented
% there as well.
if usage == 1 
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
    end

% The scenario where usage is set to 2 will be used when ModuleRunner needs
% to get the dependencies of a module. DEPENDENCIES MUST BE DECLARED IF
% THEY EXIST! If they aren't, errors could arise from running modules in an
% incorrect order.
elseif usage == 2
    getModuleDependencies
    
% The scenario where usage is set to 3 will be used when ModuleRunner wants
% the inputs for a module prior to executing it.
elseif usage == 3
    getModuleInputs
end

function getModuleDependencies
    switch whichModule
        case 'AspectRatio'
            dependencies = {};
            
        case 'AvgIntensity'
            dependencies = {};

        case 'Center'
            dependencies = {};
            
        case 'Complexity'
            dependencies{1} = 'Perimeter';
            dependencies{2} = 'EquivalentRadius';
            
        case 'ConcaveNumber'
            dependencies = {};
            
        case 'CornerNumber'
            dependencies = {};

        case 'CrossSection'
            dependencies = {};

        case 'EquivalentRadius'
            dependencies{1} = 'CrossSection';
            
        case 'Fallspeed'
            dependencies{1} = 'Focus';

        case 'Focus'
            dependencies = {};
            
        case 'MoreFocus'
            dependencies = {};

        case 'MaxDiameter'
            dependencies = {};

        case 'Orientation'
            dependencies = {};
            
        % DEPRECATED
        case 'ParticleCrossSection'
            dependencies{1} = 'CrossSection';
            
        case 'Perimeter'
            dependencies = {};

        case 'Pores'
            dependencies = {};

        case 'Radial'
            dependencies{1} = 'Center';
            
        case 'Roughness'
            dependencies{1} = 'MaxDiameter';
            dependencies{2} = 'CrossSection';

        case 'SonicNumber'
            dependencies = {};

        otherwise
            % Throw error, unrecognized module, can't process with module

    end
end


function getModuleInputs
    switch whichModule
        case 'AspectRatio'
            inputs{1} = getFilledFlake;
            
        case 'AvgIntensity'
            inputs = {'none'};

        case 'Center'
            inputs{1} = settings.backgroundThresh;
            
        case 'Complexity'
            inputs{1} = goodSubFlake{17}; % Perimeter
            inputs{2} = goodSubFlake{19}; % EquivalentRadius
            
        case 'ConcaveNumber'
            inputs{1} = getFilledFlake;
            
        case 'CornerNumber'
            inputs{1} = getFilledFlake;

        case 'CrossSection'
            inputs{1} = settings.camFOV;
            inputs{2} = getCamId;
            inputs{3} = getFilledFlake;

        case 'EquivalentRadius'
            inputs{1} = goodSubFlake{18}; % Cross-sectional area (mm^2)
            inputs{2} = settings.backgroundThresh;
            inputs{3} = getFilledFlake;
            
        case 'Fallspeed'
            % Full path to cropped image (so can know where to look for
            % data txt files)
            inputs{1} = [settings.pathToFlakes goodSubFlake{1}]; 
            inputs{2} = settings.mascImgRegPattern;
            inputs{3} = goodSubFlake{2}; % Is good flake?
            inputs{4} = goodSubFlake{28}; % # Good flakes in original img

        case 'Focus'
            inputs = {'none'};
            
        case 'MoreFocus'
            inputs = {'none'};

        case 'MaxDiameter'
            inputs{1} = settings.camFOV;
            inputs{2} = getCamId;
            inputs{3} = getFilledFlake;
            inputs{4} = goodSubFlake{2}; % Is good flake?

        case 'Orientation'
            inputs{1} = getFilledFlake;
            
        % Deprecated
        case 'ParticleCrossSection'
            inputs{1} = goodSubFlake{18}; % Cross-section (mm^2)
            inputs{2} = settings.backgroundThresh;
            inputs{3} = getFilledFlake;

        case 'Perimeter'
            inputs{1} = getFilledFlake;
            inputs{2} = settings.camFOV;
            inputs{3} = getCamId;

        case 'Pores'
            inputs{1} = settings.backgroundThresh;

        case 'Radial'
            inputs{1} = goodSubFlake{7}; % Unweighted center
            
        case 'Roughness'
            inputs{1} = goodSubFlake{16}; % Max diam
            inputs{2} = goodSubFlake{18}; % Cross section

        case 'SonicNumber'
            inputs{1} = settings.backgroundThresh;

        otherwise
        % Throw error, unrecognized module, can't process with module

    end
end

function [filledFlake] = getFilledFlake()
    if isfield(settings, 'filledFlake') && ~isempty(settings.filledFlake)
        filledFlake = settings.filledFlake;
        return;
    end
    flake = imread([settings.pathToFlakes goodSubFlake{1}]);
    resolution = 1000 / settings.camFOV(getCamId+1); % px / mm -> microns / px
    filledFlake = FillFlake(flake, settings.lineFill, resolution);
    % If running on Calibration dataset (e.g. airsoft pellets),
    % need to use flake > 10 instead of FillFlake
end

function [camId] = getCamId()
% GETCAMID Get the camera ID from the image filename...
% To do so we can utilize the reg expression pattern defined by 
%   the field "mascImgRegPattern" in settings.
    filename = goodSubFlake{1};
    matches = regexp(filename, settings.mascImgRegPattern, 'match');
    timestampAndIds = matches{1};
    camId = str2num(timestampAndIds(strfind(timestampAndIds, 'cam_') + 4)); %#ok<ST2NM>
end


end

