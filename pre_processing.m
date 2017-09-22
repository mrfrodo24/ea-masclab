function pre_processing()
%PRE_PROCESSING Summary of this function goes here
%   Detailed explanation goes here

% ADD ALL NECESSARY PATHS (REQUIRED)
addpath(genpath('./modules'))
addpath(genpath('./data'))
addpath(genpath('./export'))
addpath(genpath('./cache'))
addpath(genpath('./utils'))

% First, try and load existing parameters. These will be in the same
% directory. If they do exist, prompt user to use these values, set new
% ones, or use some of them (i.e. load them, but allow user to re-specify
% any of them)
if exist('cache/gen_params/last_parameters.mat','file')
    s = input(['Found record of previous processing parameters.\n' ...
            'Would you like to (1) load the parameters and continue,\n(2)' ...
            ' load the parameters but change some before continuing, or\n(3)' ...
            ' do not load the parameters and define all of them on your own?' ...
            ' (1,2,3): '], 's');
    while isempty(s) || length(s) > 1 || (s ~= '1' && s ~= '2' && s ~= '3')
        s = input('You must choose option 1, 2, or 3: ', 's');
    end
    
    if s == '1'
        % User chose to do nothing, so just return
        return;
        
    elseif s == '2'
        load('cache/gen_params/last_parameters.mat')
        settingsToVariables
        redefine = 1; %#ok<*NASGU>
        
    else % s == '3'
        define = 1;
        
    end
else
    define = 1;
end
clear s

% Check if user chose to redefine existing parameters, define new ones, or
% has to define new ones because there are no existing parameters
if exist('redefine','var')
    fprintf(['You chose to redefine some of the parameters from the existing\n' ...
        'set that was loaded. You will be prompted to change each of the\n' ...
        'parameters. To keep the current value when prompted, just hit [Enter].\n'])
    disp('%%% RE-DEFINE PARAMETERS %%%')
    define_params
    disp('%%% END RE-DEFINE PARAMETERS %%%')
    clear redefine
    
elseif exist('define','var')
    disp('%%% DEFINE PARAMETERS %%%')
    define_params
    disp('%%% END DEFINE PARAMETERS %%%')
    clear define
    
end
fprintf('\n')

% Show full list of parameters and ask if user is okay with these values and is ready
% to proceed
s = 'n';
while s == 'n'
    disp('%%% FINAL LIST OF PARAMETERS %%%')
    fprintf('       pathToFlakes: %s\n', pathToFlakes)
    fprintf('          datestart: %s\n', datestr(datestart))
    fprintf('            dateend: %s\n', datestr(dateend))
    fprintf('         isCamColor: [%i, %i, %i]\n', isCamColor(1), isCamColor(2), isCamColor(3))
    fprintf('outputProcessedImgs: %s\n', outputProcessedImgs)
    fprintf('             camFOV: [%.2f, %.2f, %.2f]\n', camFOV(1), camFOV(2), camFOV(3))
    fprintf('   backgroundThresh: %.0f\n', backgroundThresh)
    fprintf('         topDiscard: %i\n', topDiscard)
    fprintf(['applyTopDiscardToCams: [' num2str(applyTopDiscardToCams) ']\n'])
    fprintf('      bottomDiscard: %i\n', bottomDiscard)
    fprintf(['applyBotDiscardToCams: [' num2str(applyBotDiscardToCams) ']\n'])
    fprintf('        leftDiscard: %i\n', leftDiscard)
    fprintf(['applyLeftDiscardToCams: [' num2str(applyLeftDiscardToCams) ']\n'])
    fprintf('       rightDiscard: %i\n', rightDiscard)
    fprintf(['applyRightDiscardToCams: [' num2str(applyRightDiscardToCams) ']\n'])
    fprintf('           lineFill: %i\n', lineFill)
    fprintf('      minFlakePerim: %.1f\n', minFlakePerim)
    fprintf('       minCropWidth: %.1f\n', minCropWidth)
    fprintf('       maxEdgeTouch: %.0f\n', maxEdgeTouch)
    fprintf(' avgFlakeBrightness: %.1f\n', avgFlakeBrightness)
    fprintf('        filterFocus: %i\n', filterFocus)
    fprintf('     focusThreshold: %.1f\n', focusThreshold)
    fprintf('internalVariability: %.1f\n', internalVariability)
    fprintf('      flakeBrighten: %s\n', flakeBrighten)
    fprintf('           siteName: %s\n', siteName)
    fprintf('         cameraName: %s\n', cameraName)
    fprintf('     rescanOriginal: %i\n', rescanOriginal)
    fprintf('      skipProcessed: %i\n', skipProcessed)
    fprintf('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n')
    s = input('Would you like to save these parameters and continue [Y], or go back and change some [n]? (Y/n): ', 's');
    while isempty(s) || (length(s) > 1 || (s ~= 'Y' && s ~= 'n'))
        disp('Please type ''Y'' or ''n''.')
        s = input('Save parameters and continue [Y], or go back and change some [n]? (Y/n): ', 's');
    end
    if s == 'n'
        disp('%%% RE-DEFINE PARAMETERS %%%')
        define_params
        disp('%%% END RE-DEFINE PARAMETERS %%%')
    end
end
clear s

% At this point, user has finalized the general processing parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% MASC-SPECIFIC FORMATTING
% The most effective way of getting the image's timestamp, flake ID, and/or
% camera ID from the image filename is using a regular expression.

% This is the current format of images from the MASC:
%   yyyy.mm.dd_HH.MM.SS[.FFF]_flake_(image id)[.(particle id)]_cam_(cam id).png
%       -> where the text in brackets indicates something that may or may
%           not be in the filename, and
%       -> where the text in parentheses indicates a reference to a value
%           will be there

% According to this format, below is the pattern that will pull out the
% string between [prefix_] and [_suffix].
mascImgRegPattern = [ ...
    '\d{4}\.{1}\d{2}\.{1}\d{2}' ...                 % yyyy.mm.dd
    '\_{1}' ...                                     % underscore
    '\d{2}\.{1}\d{2}\.{1}\d{2}(\.{1}\d{1,6})?' ...  % HH.MM.SS[.FFF]
    '\_flake_{1}\d+(\.{1}\d+)?' ...                 % flake_(image id)[.(particle id)]
    '\_cam_{1}[0-2]' ...                            % cam_(cam id)
    '\.[pngjpeg]{3,4}';                             % .png, .jpg, or .jpeg
];

% This can be changed should the format of image filenames from the MASC
% ever change.

%% SAVE FILES IN PATH (IF APPLICABLE)
% Now, we'll check if filesInPath returned from define_params is not empty.
% If it isn't, then we need to add the pathToFlakes to the cached_paths,
% along with the list of files given by filesInPath
if ~isempty(filesInPath)
    fprintf('Caching PNG files for the specified pathToFlakes...');
    % Get number of paths already cached
    if exist('cache/cached_paths.txt', 'file')
        numPaths = length(strfind(fileread('cache/cached_paths.txt'), 'Path = "')) + 1;
    else
        numPaths = 1; % Actually 0, but we set to 1 so the index starts at 1
    end
    
    % Add new path to cached_paths    
    fwid = fopen('cache/cached_paths.txt','a');
    fprintf(fwid, 'Path = "%s"\n', pathToFlakes);
    % Set which txt file the path will point to
    fprintf(fwid, 'Cache Dir = "%s"\n\n', ['cache/cached_paths_' num2str(numPaths)]);
    fclose(fwid);
    
    % Create directory if necessary
    if ~exist(['cache/cached_paths_' num2str(numPaths)], 'dir')
        mkdir(['cache/cached_paths_' num2str(numPaths)])
    end
    
    % Open a new cache file
    numCacheFiles = 1;
    fwid = fopen(['cache/cached_paths_' num2str(numPaths) '/f' num2str(numCacheFiles) '.txt'], 'w');
    for i = 1:length(filesInPath)
        if ~mod(i,500)
            % Start a new cache file every 500 PNGs...
            % Assuming O(100) cropped flakes for each PNG, that would
            % result in O(50,000) records in each txt file.
            fclose(fwid);
            numCacheFiles = numCacheFiles + 1;
            fwid = fopen(['cache/cached_paths_' num2str(numPaths) '/f' num2str(numCacheFiles) '.txt'], 'w');
        end
        fprintf(fwid, '%s\t1\t0\t0\t0\t0\n', filesInPath(i).name);
    end
    fclose(fwid);
    fprintf('done.\n');
    
end
fclose('all');

% Put all parameters into a struct
settings = paramsAsStruct;
clearvars -except settings

% Save current parameters to file for most recent parameters used
disp('Caching these parameters...')
save('cache/gen_params/last_parameters.mat')

    function [settings] = paramsAsStruct
        % Save all parameters to a settings struct for convenient access and
        % passing of the parameters around to other functions.
        settings.pathToFlakes = pathToFlakes;
        settings.datestart = datestart;
        settings.dateend = dateend;
        settings.mascImgRegPattern = mascImgRegPattern;
        settings.isCamColor = isCamColor;
        settings.outputProcessedImgs = outputProcessedImgs;
        settings.camFOV = camFOV;
        settings.backgroundThresh = backgroundThresh;
        settings.topDiscard = topDiscard;
        settings.applyTopDiscardToCams = applyTopDiscardToCams;
        settings.bottomDiscard = bottomDiscard;
        settings.applyBotDiscardToCams = applyBotDiscardToCams;
        settings.leftDiscard = leftDiscard;
        settings.applyLeftDiscardToCams = applyLeftDiscardToCams;
        settings.rightDiscard = rightDiscard;
        settings.applyRightDiscardToCams = applyRightDiscardToCams;
        settings.lineFill = lineFill;
        settings.minFlakePerim = minFlakePerim;
        settings.minCropWidth = minCropWidth;
        settings.maxEdgeTouch = maxEdgeTouch;
        settings.avgFlakeBrightness = avgFlakeBrightness;
        settings.filterFocus = filterFocus;
        settings.focusThreshold = focusThreshold;
        settings.internalVariability = internalVariability;
        settings.flakeBrighten = flakeBrighten;
        settings.siteName = siteName;
        settings.cameraName = cameraName;
        settings.rescanOriginal = rescanOriginal;
        settings.skipProcessed = skipProcessed;
    end

    % When last parameters are loaded at the beginning of this function,
    % need to break them out of settings struct so we can ask user if they
    % want to keep the old value or set a new one.
    function settingsToVariables
        if isfield(settings, 'pathToFlakes')
            pathToFlakes = settings.pathToFlakes;
        end
        if isfield(settings, 'datestart')
            datestart = settings.datestart;
        end
        if isfield(settings, 'dateend')
            dateend = settings.dateend;
        end
        if isfield(settings, 'mascImgRegPattern')
            mascImgRegPattern = settings.mascImgRegPattern;
        end
        if isfield(settings, 'isCamColor')
            isCamColor = settings.isCamColor;
        end
        if isfield(settings, 'outputProcessedImgs')
            outputProcessedImgs = settings.outputProcessedImgs;
        end
        if isfield(settings, 'camFOV')
            camFOV = settings.camFOV;
        end
        if isfield(settings, 'backgroundThresh')
            backgroundThresh = settings.backgroundThresh;
        end
        if isfield(settings, 'topDiscard')
            topDiscard = settings.topDiscard;
        end
        if isfield(settings, 'applyTopDiscardToCams')
            applyTopDiscardToCams = settings.applyTopDiscardToCams;
        end
        if isfield(settings, 'bottomDiscard')
            bottomDiscard = settings.bottomDiscard;
        end
        if isfield(settings, 'applyBotDiscardToCams')
            applyBotDiscardToCams = settings.applyBotDiscardToCams;
        end
        if isfield(settings, 'leftDiscard')
            leftDiscard = settings.leftDiscard;
        end
        if isfield(settings, 'applyLeftDiscardToCams')
            applyLeftDiscardToCams = settings.applyLeftDiscardToCams;
        end
        if isfield(settings, 'rightDiscard')
            rightDiscard = settings.rightDiscard;
        end
        if isfield(settings, 'applyRightDiscardToCams')
            applyRightDiscardToCams = settings.applyRightDiscardToCams;
        end
        if isfield(settings, 'lineFill')
            lineFill = settings.lineFill;
        end
        if isfield(settings, 'minFlakePerim')
            minFlakePerim = settings.minFlakePerim;
        end
        if isfield(settings, 'minCropWidth')
            minCropWidth = settings.minCropWidth;
        end
        if isfield(settings, 'maxEdgeTouch')
            maxEdgeTouch = settings.maxEdgeTouch;
        end
        if isfield(settings, 'avgFlakeBrightness')
            avgFlakeBrightness = settings.avgFlakeBrightness;
        end
        if isfield(settings, 'filterFocus')
            filterFocus = settings.filterFocus;
        end
        if isfield(settings, 'focusThreshold')
            focusThreshold = settings.focusThreshold;
        end
        if isfield(settings, 'internalVariability')
            internalVariability = settings.internalVariability;
        end
        if isfield(settings, 'flakeBrighten')
            flakeBrighten = settings.flakeBrighten;
        end
        if isfield(settings, 'siteName')
            siteName = settings.siteName;
        end
        if isfield(settings, 'cameraName')
            cameraName = settings.cameraName;
        end
        if isfield(settings, 'rescanOriginal')
            rescanOriginal = settings.rescanOriginal;
        end
        if isfield(settings, 'skipProcessed')
            skipProcessed = settings.skipProcessed;
        end
    end

function define_params
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REQUIRED PARAMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('%% REQUIRED PARAMS %%')
    
    %% Var pathToFlakes
    % Prompts user to set pathToFlakes or keep it the same as before. If it
    % is set or changed, will check to see if new path is in
    % cached_paths.txt file. If not, then searches for PNG files in the new
    % path. If no PNGs are found, reprompts for a path with PNG files. If
    % PNGs are found, filesInPath are saved and returned for caching later.
    
    fprintf(['<strong>pathToFlakes</strong>: Where snowflake images are located. The images \n' ...
        '\tdo not need to be in any set directory hierarchy. All PNG images\n' ...
        '\tin the directory will be found. Path MUST be absolute.\n' ...
        '\t<strong>Note</strong>: When this is set, the path will be searched for PNG files. If none are found\n' ...
        '\toutside of the processed image directories (CROP_CAM, UNCROP_CAM, TRIPLETS, REJECTS),\n' ...
        '\tthen you will be asked to provide a different path.\n'])
    if exist('pathToFlakes', 'var')
        s = input(sprintf('var pathToFlakes = %s;\nChange to: ', strrep(pathToFlakes,'\','\\')), 's');
    else
        % Require user to set a path
        s = input('Set pathToFlakes to: ', 's');
    end
    
    while ~isempty(s) && ((s(1) ~= '/' && s(2) ~= ':') || (s(end) ~= '/' && s(end) ~= '\'))
        disp('Invalid path, you must specify an absolute path and include a trailing slash. Please try again.')
        s = input('Set pathToFlakes to: ', 's');
    end
    % Initialize filesInPath variable. If the user provides a path that
    % doesn't exist in cached_paths, we'll need to write out the img file
    % names to cached_paths. Instead of having to traverse to get these
    % files again (since we make sure that path user provides contains
    % PNGs), we'll hold onto this array of file structs.
    filesInPath = [];
    if ~isempty(s)
        % First, check if user provided path is already in cached_paths
        if exist('cache/cached_paths.txt', 'file')
            if ~isempty(strfind(fileread('cache/cached_paths.txt'), ['"' s '"']))
                % Path has been used before, accept this input
                files = 1;
                disp('Path found in cache! Okay to use again. Continuing...')
            else
                files = 0;
            end
        else
            files = 0;
        end
        
        if ~files
            imgFilter = @(d) isempty(regexp(d.name,'CROP_CAM')) && isempty(regexp(d.name,'UNCROP_CAM')) && isempty(regexp(d.name,'TRIPLETS')) && isempty(regexp(d.name,'REJECTS')); 
            disp('Searching for PNGs...')
            if strfind(s, '\')
                files = rdir([s '**\*.png'], imgFilter, s);
            else
                files = rdir([s '**/*.png'], imgFilter, s);
            end
        end
        while ~isempty(s) && isempty(files)
            % While user provides a path with NO PNG files, continue to prompt
            if exist('pathToFlakes', 'var')
                % NOTE: This still allows users to keep the existing pathToFlakes, if it is already set
                disp('Invalid path, the path you specified contained no PNG files. Please try again (or keep the existing pathToFlakes).')
                s = input(sprintf('var pathToFlakes = %s;\nChange to: ', strrep(pathToFlakes,'\','\\')), 's');
            else
                disp('Invalid path, the path you specified contained no PNG files. Please try again.')
                % Require user to set a path
                s = input('Set pathToFlakes to: ', 's');
            end
            
            while isempty(s) || ((s(1) ~= '/' && s(2) ~= ':') || (s(end) ~= '/' && s(end) ~= '\'))
                disp('Invalid path, you must specify an absolute path and include a trailing slash. Please try again.')
                s = input('Set pathToFlakes to: ', 's');
            end
            if ~isempty(s)
                if exist('cache/cached_paths.txt', 'file')
                    if ~isempty(strfind(fileread('cache/cached_paths.txt'), ['"' s '"']))
                        % Path has been used before, accept this input
                        files = 1;
                        disp('Path found in cache! Okay to use again. Continuing...')
                    else
                        files = 0;
                    end
                else
                    files = 0;
                end

                if ~files
                    imgFilter = @(d) isempty(regexp(d.name,'CROP_CAM')) && isempty(regexp(d.name,'UNCROP_CAM')) && isempty(regexp(d.name,'TRIPLETS')) && isempty(regexp(d.name,'REJECTS')); %#ok<*RGXP1>
                    disp('Searching for PNGs...')
                    if strfind(s, '\')
                        files = rdir([s '**\*.png'], imgFilter, s);
                    else
                        files = rdir([s '**/*.png'], imgFilter, s);
                    end
                end
            end
        end
        if ~isempty(s)
            if isstruct(files)
                disp('PNGs found!')
                filesInPath = files;
            end
            pathToFlakes = s;
        else
            disp('Using old pathToFlakes with verified PNG files.')
        end
    else
        disp('Using old pathToFlakes with verified PNG files.')
    end
    pathToFlakes %#ok<NOPRT> % Show user the result of defining pathToFlakes
    
    %% Var datestart
    fprintf(['<strong>datestart</strong>: Start date of snowflakes to process. When setting this,\n' ...
        '\tinput the date as a string of the form "yyyymmdd_HHMM".\n'])
    if exist('datestart', 'var')
        s = input(sprintf('var datestart = %s; Change to: ', datestr(datestart, 'yyyymmdd_HHMM')), 's');
        while ~isempty(s) && ~validate_datestr(s, 0)
            disp('Must enter a valid string ("yyyymmdd_HHMM") for datestart.')
            s = input(sprintf('var datestart = %s; Change to: ', datestr(datestart, 'yyyymmdd_HHMM')), 's');
        end
    else
        % Require user to set datestart
        s = input('Set datestart to: ', 's');
        while isempty(s) || ~validate_datestr(s, 0)
            disp('Must enter a valid string ("yyyymmdd_HHMM") for datestart.')
            s = input('Set datestart to: ', 's');
        end
    end
    if ~isempty(s)
        datestart = datenum(s, 'yyyymmdd_HHMM');
    end
    datestr(datestart) % Show user the result of defining datestart
    
    %% Var dateend
    fprintf(['<strong>dateend</strong>: End date of snowflakes to process. When setting this,\n' ...
        '\tinput the date as a string of the form "yyyymmdd_HHMM".\n'])
    if exist('dateend', 'var')
        s = input(sprintf('var dateend = %s; Change to: ', datestr(dateend, 'yyyymmdd_HHMM')), 's');
        while ~isempty(s) && ~validate_datestr(s, datestart)
            disp('Must enter a valid string ("yyyymmdd_HHMM") for dateend that is after datestart.')
            s = input(sprintf('var dateend = %s; Change to: ', datestr(dateend, 'yyyymmdd_HHMM')), 's');
        end
    else
        % Require user to set dateend
        s = input('Set dateend to: ', 's');
        while isempty(s) || ~validate_datestr(s, datestart)
            disp('Must enter a valid string ("yyyymmdd_HHMM") for dateend that is after datestart.')
            s = input('Set dateend to: ', 's');
        end
    end
    if ~isempty(s)
        dateend = datenum(s, 'yyyymmdd_HHMM');
    end
    datestr(dateend) % Show user the result of defining dateend
    
    %% Var isCamColor
    fprintf(['<strong>isCamColor</strong>: Specifies whether each camera in the MASC takes its pictures\n' ...
        '\tin color. Binary 1x3 array, where the first element corresponds to color for camera 0, second\n' ...
        '\telement corresponds to color camera 1, and third element corresponds to color for camera 2.\n' ...
        '\tValue of 1 signifies camera <strong>DOES</strong> take pictures in color.\n'])
    if exist('isCamColor', 'var')
        % Camera 0
        s = input(sprintf('var isCamColor(1) = %i; Change to (0 or 1): ', isCamColor(1)), 's');
        while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('If changing this value, you must specify 0 or 1')
            s = input(sprintf('var isCamColor(1) = %i; Change to (0 or 1): ', isCamColor(1)), 's');
        end
        if ~isempty(s)
            isCamColor(1) = str2num(s); %#ok<*ST2NM>
        end
        % Camera 1
        s = input(sprintf('var isCamColor(2) = %i; Change to (0 or 1): ', isCamColor(2)), 's');
        while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('If changing this value, you must specify 0 or 1')
            s = input(sprintf('var isCamColor(2) = %i; Change to (0 or 1): ', isCamColor(2)), 's');
        end
        if ~isempty(s)
            isCamColor(2) = str2num(s);
        end
        % Camera 2
        s = input(sprintf('var isCamColor(3) = %i; Change to (0 or 1): ', isCamColor(3)), 's');
        while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('If changing this value, you must specify 0 or 1')
            s = input(sprintf('var isCamColor(3) = %i; Change to (0 or 1): ', isCamColor(3)), 's');
        end
        if ~isempty(s)
            isCamColor(3) = str2num(s);
        end
    else
        % User must specify color (y/n = 1/0) for each camera
        % Camera 0
        s = input('Is camera 0 a color camera (0 = No, 1 = Yes): ', 's');
        while isempty(s) || (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('Invalid input, must specify 0 or 1.')
            s = input('Is camera 0 a color camera (0 = No, 1 = Yes): ', 's');
        end
        isCamColor(1) = str2num(s);
        % Camera 1
        s = input('Is camera 1 a color camera (0 = No, 1 = Yes): ', 's');
        while isempty(s) || (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('Invalid input, must specify 0 or 1.')
            s = input('Is camera 1 a color camera (0 = No, 1 = Yes): ', 's');
        end
        isCamColor(2) = str2num(s);
        % Camera 2
        s = input('Is camera 2 a color camera (0 = No, 1 = Yes): ', 's');
        while isempty(s) || (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('Invalid input, must specify 0 or 1.')
            s = input('Is camera 2 a color camera (0 = No, 1 = Yes): ', 's');
        end
        isCamColor(3) = str2num(s);
    end
    isCamColor %#ok<NOPRT> % Display results of defining isCamColor

    %% Var outputProcessedImgs
    fprintf(['<strong>outputProcessedImgs</strong>: Flag that determines if processed images should be\n' ...
        '\twritten to processed output folders. If 0, images will not be written. Any additional img\n' ...
        '\tprocessing functions may have their own flag for this, but if not, they will inherit this flag.\n'...
        '\t<strong>Note</strong>: This is an important flag because if outputting images, processing\n' ...
        '\t\ttime will be significantly affected. At best, each imwrite takes approx. 0.07 seconds.\n' ...
        '\t\tThis means that an extra <strong>hour</strong> will be added to processing time for each\n' ...
        '\t\t<strong>50,000</strong> flake images. The default for this value is 0 (i.e. NO IMG OUTPUT).\n'])
    if exist('outputProcessedImgs', 'var')
        s = input(sprintf('var outputProcessedImgs = %s; Change to (0 or 1): ', outputProcessedImgs), 's');
        while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('To change this flag, must set to 0 or 1.')
            s = input(sprintf('var outputProcessedImgs = %s; Change to (0 or 1): ', outputProcessedImgs), 's');
        end
        if ~isempty(s)
            outputProcessedImgs = s;
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set outputProcessedImgs to (0 or 1): ', 's');
        while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('To set this flag, must input 0 or 1.')
            s = input('Set outputProcessedImgs to (0 or 1): ', 's');
        end
        if ~isempty(s)
            outputProcessedImgs = s;
        else
            outputProcessedImgs = '0';
        end
    end
    outputProcessedImgs %#ok<NOPRT> % Show user the result of defining outputProcessedImgs

    %% Var camFOV
    fprintf(['<strong>camFOV</strong>: The calculated <strong>pixels/mm</strong> of each image.\n' ...
        '\tThis can be computed by dividing the pixel width of images that the\n' ...
        '\tMASC camera takes by the field-of-view of the camera (in mm).\n' ...
        '\tIt can also be obtained through observation by dropping an object\n' ...
        '\tof known size through the MASC to then see the number of pixels\n' ...
        '\tthe object spans.\n' ...
        '\tIMPORANT: These values must be accurate in order for size measurement\n' ...
        '\t\tmodules to return accurate results.\n'])
    if exist('camFOV', 'var')
        % Camera 0
        s = input(sprintf('var camFOV(1) = %i; Change to: ', camFOV(1)), 's');
        while ~isempty(s) && isnan(str2double(s))
            disp('If changing this value, you must specify a decimal number')
            s = input(sprintf('var camFOV(1) = %i; Change to: ', camFOV(1)), 's');
        end
        if ~isempty(s)
            camFOV(1) = str2double(s);
        end
        % Camera 1
        s = input(sprintf('var camFOV(2) = %i; Change to: ', camFOV(2)), 's');
        while ~isempty(s) && isnan(str2double(s))
            disp('If changing this value, you must specify a decimal number')
            s = input(sprintf('var camFOV(2) = %i; Change to: ', camFOV(2)), 's');
        end
        if ~isempty(s)
            camFOV(2) = str2double(s);
        end
        % Camera 2
        s = input(sprintf('var camFOV(3) = %i; Change to: ', camFOV(3)), 's');
        while ~isempty(s) && isnan(str2double(s))
            disp('If changing this value, you must specify a decimal number')
            s = input(sprintf('var camFOV(3) = %i; Change to: ', camFOV(3)), 's');
        end
        if ~isempty(s)
            camFOV(3) = str2double(s);
        end
    else
        % User must specify FOV decimal value for each camera
        % Camera 0
        s = input('Define FOV for camera 0: ', 's');
        while isempty(s) || isnan(str2double(s))
            disp('Invalid input, must define each FOV as a decimal number.')
            s = input('Define FOV for camera 0: ', 's');
        end
        camFOV(1) = str2double(s);
        % Camera 1
        s = input('Define FOV for camera 1: ', 's');
        while isempty(s) || isnan(str2double(s))
            disp('Invalid input, must define each FOV as a decimal number.')
            s = input('Define FOV for camera 1: ', 's');
        end
        camFOV(2) = str2double(s);
        % Camera 2
        s = input('Define FOV for camera 2: ', 's');
        while isempty(s) || isnan(str2double(s))
            disp('Invalid input, must define each FOV as a decimal number.')
            s = input('Define FOV for camera 2: ', 's');
        end
        camFOV(3) = str2double(s);
    end
    camFOV %#ok<NOPRT> % Display results of defining camFOV
    
    %% Var background threshold (all pixels outside flake should fall below
    % this threshold brightness
    fprintf(['<strong>backgroundThresh</strong>: The brightness threshold for which all pixels outside\n' ...
        '\tthe flake should fall below. Value is on a scale from 0 to 255 in brightness,\n' ...
        '\twith 0 being completely dark and 255 completely white.\n' ...
        '\tIMPORANT: Used in SCAN & CROP!\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 20\n')
    if exist('backgroundThresh', 'var')
        s = input(sprintf('var backgroundThresh = %.0f; Change to (0-255): ', backgroundThresh), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0 || str2double(s) > 255)
            disp('To change this value, must set to a value between 0 and 255, inclusive.')
            s = input(sprintf('var backgroundThresh = %.0f; Change to (0-255): ', backgroundThresh), 's');
        end
        if ~isempty(s)
            backgroundThresh = str2double(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set backgroundThresh to (0-255): ', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0 || str2double(s) > 255)
            disp('To set this value, must input a value between 0 and 255.')
            s = input('Set backgroundThresh to (0-255): ', 's');
        end
        if ~isempty(s)
            backgroundThresh = str2double(s);
        else
            backgroundThresh = 20;
        end
    end
    backgroundThresh %#ok<NOPRT> % Display results of defining backgroundThresh
    
    %% Var topDiscard, bottomDiscard, leftDiscard, rightDiscard, apply*DiscardsToCams    
    fprintf(['<strong>XXXDiscard</strong>: The pixels to crop on each side of the image frame.\n' ...
        '\tYou will be able to specify a value for discarding pixel rows on the top\n' ...
        '\tand bottom of the img frame, as well as pixel columns on the left and right\n' ...
        '\tsides of the img frame. E.g. Specifying 10 for topDiscard would mask out\n' ...
        '\t10 rows of pixels at the top of the image.\n' ...
        '\tIMPORANT: Used in SCAN & CROP!\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 0\n')
    fprintf(['\n<strong>applyXXXDiscardToCams</strong>: Array of camera IDs to apply discards to.\n' ...
        '\tThis variable stipulates which cameras of the MASC you want to apply\n' ...
        '\tthe top/bottom/left/right discard to. The possible options are 0, 1, and 2.\n' ...
        '\tIMPORANT: Used in SCAN & CROP!\n\t'])
    cprintf('_text', 'Default (if discard not set)')
    fprintf(' = []\n\t')
    cprintf('_text', 'Default (if discard > 0)')
    fprintf(' = [0, 1, 2]\n')
    if exist('topDiscard', 'var')
        s = input(sprintf('var topDiscard = %i; Change to: ', topDiscard), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var topDiscard = %i; Change to: ', topDiscard), 's');
        end
        if ~isempty(s)
            topDiscard = str2num(s);
        end
    else
        s = input('Set topDiscard to: ', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set topDiscard to: ', 's');
        end
        if ~isempty(s)
            topDiscard = str2num(s);
        else
            topDiscard = 0;
        end
    end
    if exist('applyTopDiscardToCams', 'var')
        cur = applyTopDiscardToCams;
    else cur = 0; 
    end
    applyTopDiscardToCams = applyDiscardToCams('Top', cur);
    if exist('bottomDiscard', 'var')
        s = input(sprintf('var bottomDiscard = %i; Change to: ', bottomDiscard), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var bottomDiscard = %i; Change to: ', bottomDiscard), 's');
        end
        if ~isempty(s)
            bottomDiscard = str2num(s);
        end
    else
        s = input('Set bottomDiscard to: ', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set bottomDiscard to: ', 's');
        end
        if ~isempty(s)
            bottomDiscard = str2num(s);
        else
            bottomDiscard = 0;
        end
    end
    if exist('applyBotDiscardToCams', 'var')
        cur = applyBotDiscardToCams;
    else cur = 0; 
    end
    applyBotDiscardToCams = applyDiscardToCams('Bot', cur);
    if exist('leftDiscard', 'var')
        s = input(sprintf('var leftDiscard = %i; Change to: ', leftDiscard), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var leftDiscard = %i; Change to: ', leftDiscard), 's');
        end
        if ~isempty(s)
            leftDiscard = str2num(s);
        end
    else
        s = input('Set leftDiscard to: ', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set leftDiscard to: ', 's');
        end
        if ~isempty(s)
            leftDiscard = str2num(s);
        else
            leftDiscard = 0;
        end
    end
    if exist('applyLeftDiscardToCams', 'var')
        cur = applyLeftDiscardToCams;
    else cur = 0; 
    end
    applyLeftDiscardToCams = applyDiscardToCams('Left', cur);
    if exist('rightDiscard', 'var')
        s = input(sprintf('var rightDiscard = %i; Change to: ', rightDiscard), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var rightDiscard = %i; Change to: ', rightDiscard), 's');
        end
        if ~isempty(s)
            rightDiscard = str2num(s);
        end
    else
        s = input('Set rightDiscard to: ', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set rightDiscard to: ', 's');
        end
        if ~isempty(s)
            rightDiscard = str2num(s);
        else
            rightDiscard = 0;
        end
    end
    if exist('applyRightDiscardToCams', 'var')
        cur = applyRightDiscardToCams;
    else cur = 0; 
    end
    applyRightDiscardToCams = applyDiscardToCams('Right', cur);
    
    % Display results of settings discard variables
    topDiscard %#ok<NOPRT>
    applyTopDiscardToCams %#ok<NOPRT>
    bottomDiscard %#ok<NOPRT>
    applyBotDiscardToCams %#ok<NOPRT>
    leftDiscard %#ok<NOPRT>
    applyLeftDiscardToCams %#ok<NOPRT>
    rightDiscard %#ok<NOPRT>  
    applyRightDiscardToCams %#ok<NOPRT>
    
    %% Var lineFill
    fprintf(['<strong>lineFill</strong>: In order to assess the flake area, internal\n' ...
        '\tcomplexities are blurred with the lineFill parameter. This avoids small,\n' ...
        '\tlocal discontinuities to make a single flake. This is essentially a guess\n' ...
        '\tfor the minimum flake size (in microns).\n' ...
        '\tIMPORANT: Used in Module processing!\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 200 (microns) \n')
    if exist('lineFill', 'var')
        s = input(sprintf('var lineFill = %.0f; Change to: ', lineFill), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var lineFill = %.0f; Change to: ', lineFill), 's');
        end
        if ~isempty(s)
            lineFill = str2double(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set lineFill to:', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set lineFill to: ', 's');
        end
        if ~isempty(s)
            lineFill = str2double(s);
        else
            lineFill = 200;
        end
    end
    lineFill %#ok<NOPRT> % Display results of setting lineFill
    
    %% Var minFlakePerim
    fprintf(['<strong>minFlakePerim</strong>: The minimum acceptable perimeter of a flake in pixels.\n' ...
             '\tIMPORANT: Used in SCAN & CROP!\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 250\n')
    if exist('minFlakePerim', 'var')
        s = input(sprintf('var minFlakePerim = %.0f; Change to: ', minFlakePerim), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var minFlakePerim = %.0f; Change to: ', minFlakePerim), 's');
        end
        if ~isempty(s)
            minFlakePerim = str2double(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set minFlakePerim to:', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set minFlakePerim to: ', 's');
        end
        if ~isempty(s)
            minFlakePerim = str2double(s);
        else
            minFlakePerim = 250;
        end
    end
    minFlakePerim %#ok<NOPRT> % Display results of setting minFlakePerim
    
    %% Var minCropWidth
    fprintf(['<strong>minCropWidth</strong>: The minimum acceptable dimensions of the box\n' ...
             '\tthat contains a cropped flake.\n' ...
             '\tIMPORANT: Used in SCAN & CROP!\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 40\n')
    if exist('minCropWidth', 'var')
        s = input(sprintf('var minCropWidth = %.0f; Change to: ', minCropWidth), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var minCropWidth = %.0f; Change to: ', minCropWidth), 's');
        end
        if ~isempty(s)
            minCropWidth = str2double(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set minCropWidth to:', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set minCropWidth to: ', 's');
        end
        if ~isempty(s)
            minCropWidth = str2double(s);
        else
            minCropWidth = 40;
        end
    end
    minCropWidth %#ok<NOPRT> % Display results of setting minFlakePerim
    
    %% Var maxEdgeTouch
    fprintf(['<strong>maxEdgeTouch</strong>: The maximum acceptable length for a flake to touch the\n' ...
        '\timage frame edge. This is used to filter out flakes where a relatively large\n' ...
        '\tportion of the flake is outside of the image frame.\n' ...
        '\tIMPORANT: Used in SCAN & CROP!\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 100\n')
    if exist('maxEdgeTouch', 'var')
        s = input(sprintf('var maxEdgeTouch = %.0f; Change to: ', maxEdgeTouch), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var maxEdgeTouch = %.0f; Change to: ', maxEdgeTouch), 's');
        end
        if ~isempty(s)
            maxEdgeTouch = str2double(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set maxEdgeTouch to:', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set maxEdgeTouch to: ', 's');
        end
        if ~isempty(s)
            maxEdgeTouch = str2double(s);
        else
            maxEdgeTouch = 100;
        end
    end
    maxEdgeTouch %#ok<NOPRT> % Display results of setting maxEdgeTouch
    
    %% Var avgFlakeBrightness
    fprintf(['<strong>avgFlakeBrightness</strong>: The minimum acceptable average pixel brightness.\n' ...
         '\tDarker flakes tend to be out of focus, thus having a slight threshold on\n' ...
         '\tavg pixel brightness of the flakes should eliminate some unuseful flakes.\n' ...
         '\tIMPORANT: Used in SCAN & CROP!\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 10 (Ranges from 0-255, like backgroundThresh)\n')
    if exist('avgFlakeBrightness', 'var')
        s = input(sprintf('var avgFlakeBrightness = %.0f; Change to (0-255): ', avgFlakeBrightness), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0 || str2double(s) > 255)
            disp('To change this value, must set to a value between 0 and 255, inclusive.')
            s = input(sprintf('var avgFlakeBrightness = %.0f; Change to (0-255): ', avgFlakeBrightness), 's');
        end
        if ~isempty(s)
            avgFlakeBrightness = str2double(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set avgFlakeBrightness to (0-255): ', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0 || str2double(s) > 255)
            disp('To set this value, must input a value between 0 and 255.')
            s = input('Set avgFlakeBrightness to (0-255): ', 's');
        end
        if ~isempty(s)
            avgFlakeBrightness = str2double(s);
        else
            avgFlakeBrightness = 10;
        end
    end
    avgFlakeBrightness %#ok<NOPRT> % Display results of defining avgFlakeBrightness
    
    %% Var filterFocus
    fprintf(['<strong>filterFocus</strong>: Whether to filter objects in SCAN & CROP by their\n' ...
         '\tin-focus measure. This uses the same number that''s calculated by the Focus module.\n' ...
         '\tIf enabled, SCAN & CROP will accept objects with at least the value specified by\n' ...
         '\tfocusThreshold OR all of the other conditions satisfied. The focus is used as a condition\n' ...
         '\tto allow objects through SCAN & CROP that otherwise would have been filtered out.\n' ...
         '\tSet this to 1 to enable.\n'...
         '\tIMPORANT: Used in SCAN & CROP!\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 1\n')
    if exist('filterFocus', 'var')
        s = input(sprintf('var filterFocus = %i; Change to: ', filterFocus), 's');
        while ~isempty(s) && s ~= '0' && s ~= '1'
            disp('Must input a 0 or 1.')
            s = input(sprintf('var filterFocus = %i; Change to: ', filterFocus), 's');
        end
        if ~isempty(s)
            filterFocus = str2num(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set filterFocus to:', 's');
        while ~isempty(s) && s ~= '0' && s ~= '1'
            disp('Must input a 0 or 1.')
            s = input('Set filterFocus to: ', 's');
        end
        if ~isempty(s)
            filterFocus = str2num(s);
        else
            filterFocus = 1;
        end
    end
    filterFocus %#ok<NOPRT> % Display results of setting filterFocus
    
    %% Var focusThreshold
    fprintf(['<strong>focusThreshold</strong>: If filterFocus is enabled, this setting is used to\n' ...
        '\tcontrol the minimum acceptable focus measure value.\n' ...
        '\t\tValues < 10 => Almost always out of focus\n' ...
        '\t\tValues <= 20 => Difficult to tell\n' ...
        '\t\tValues > 20 => In-focus or some pixels with high specular reflection\n']);
    cprintf('_text', 'Default ')
    fprintf('= 15\n')
    if exist('focusThreshold', 'var')
        s = input(sprintf('var focusThreshold = %.0f; Change to: ', focusThreshold), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var focusThreshold = %.0f; Change to: ', focusThreshold), 's');
        end
        if ~isempty(s)
            focusThreshold = str2double(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set focusThreshold to:', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set focusThreshold to: ', 's');
        end
        if ~isempty(s)
            focusThreshold = str2double(s);
        else
            focusThreshold = 15;
        end
    end
    focusThreshold %#ok<NOPRT> % Display results of setting focusThreshold    
    
    %% Var internalVariability
    fprintf(['<strong>internalVariability</strong>: Images that only have small irregularities in\n' ...
        '\tthe background or that are out-of-focus will have relatively lower internal\n' ...
        '\tvariability. This threshold specifies the minimum variability an image must\n' ...
        '\thave to be accepted.\n\t'])
    cprintf('_text', 'Default ')
    fprintf('= 5\n')
    if exist('internalVariability', 'var')
        s = input(sprintf('var internalVariability = %.0f; Change to: ', internalVariability), 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input(sprintf('var internalVariability = %.0f; Change to: ', internalVariability), 's');
        end
        if ~isempty(s)
            internalVariability = str2double(s);
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set internalVariability to:', 's');
        while ~isempty(s) && (isnan(str2double(s)) || str2double(s) < 0)
            disp('Must input a non-negative value.')
            s = input('Set internalVariability to: ', 's');
        end
        if ~isempty(s)
            internalVariability = str2double(s);
        else
            internalVariability = 5;
        end
    end
    internalVariability %#ok<NOPRT> % Display results of setting internalVariability
    
    %% Var flakeBrighten
    fprintf(['<strong>flakeBrighten</strong>: Set to 1 if you would like to modify images for\n' ...
        '\timproved display by applying some brightening.\n'])
    if exist('flakeBrighten', 'var')
        s = input(sprintf('var flakeBrighten = %s; Change to (0 or 1): ', flakeBrighten), 's');
        while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('To change this flag, must set to 0 or 1.')
            s = input(sprintf('var flakeBrighten = %s; Change to (0 or 1): ', flakeBrighten), 's');
        end
        if ~isempty(s)
            flakeBrighten = s;
        end
    else
        % Don't require user to set the format (if they don't, default to format 1)
        s = input('Set flakeBrighten to (0 or 1): ', 's');
        while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
            disp('To set this flag, must input 0 or 1.')
            s = input('Set flakeBrighten to (0 or 1): ', 's');
        end
        if ~isempty(s)
            flakeBrighten = s;
        else
            flakeBrighten = '0';
        end
    end
    flakeBrighten %#ok<NOPRT> % Show user the result of defining flakeBrighten
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OPTIONAL PARAMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('\n')
    disp('%% OPTIONAL PARAMS %%')
    fprintf(['%% The following variables are not required for the snowflake image\n' ...
        '%% processing. However, some variables are recommended to be set and will\n' ...
        '%% be indicated as such. If the variable hasn''t been set and you do not\n' ...
        '%% wish to set it, just hit [Enter] when prompted for it. If it has been set,\n' ...
        '%% you will be able to keep the current value, change it, or unset it.\n'])
    
    %% Var siteName
    fprintf('<strong>siteName</strong> (RECOMMENDED): Where the MASC is located.\n')
    if exist('siteName', 'var') && ~isempty(siteName)
        s = input(sprintf(['var siteName = %s; Would you like to\n' ...
            '\t(1) keep it the same,\n' ...
            '\t(2) change it, or\n' ...
            '\t(3) unset it (make it blank) ?\n' ...
            '\tChoose one of the options above (1,2,3): '], siteName), 's');
        while isempty(s) || length(s) > 1 || (s ~= '1' && s ~= '2' && s ~= '3')
            s = input(sprintf('\tChoose one of the options above (1,2,3): '), 's');
        end
        
        if s == '2'
            s = input(sprintf('\tEnter the new site name: '), 's');
            if isempty(s)
                siteName = '';
            else
                siteName = s;
            end
        elseif s == '3'
            siteName = '';
        end
    else
        s = input(sprintf('\tEnter site name (or hit [Enter] to skip): '), 's');        
        if isempty(s)
            siteName = '';
        else
            siteName = s;
        end
    end
    siteName %#ok<NOPRT> % Display results of settings siteName
    
    %% Var cameraName
    fprintf('<strong>cameraName</strong> (RECOMMENDED): Which MASC''s images you are processing.\n')
    if exist('cameraName', 'var') && ~isempty(cameraName)
        s = input(sprintf(['var cameraName = %s; Would you like to\n' ...
            '\t(1) keep it the same,\n' ...
            '\t(2) change it, or\n' ...
            '\t(3) unset it (make it blank) ?\n' ...
            '\tChoose one of the options above (1,2,3): '], cameraName), 's');
        while isempty(s)|| length(s) > 1 || (s ~= '1' && s ~= '2' && s ~= '3')
            s = input(sprintf('\tChoose one of the options above (1,2,3): '), 's');
        end
        
        if s == '2'
            s = input(sprintf('\tEnter the new camera name: '), 's');
            if isempty(s)
                cameraName = '';
            else
                cameraName = s;
            end
        elseif s == '3'
            cameraName = '';
        end
    else
        s = input(sprintf('\tEnter camera name (or hit [Enter] to skip): '), 's');        
        if isempty(s)
            cameraName = '';
        else
            cameraName = s;
        end
    end
    cameraName %#ok<NOPRT> % Display results of setting camerName
    
    %% Var rescanOriginals
    fprintf(['<strong>rescanOriginals</strong>: After pre-processing, system will move on to\n' ...
        '\tscanning, filtering and cropping the original images. If you have done this before,\n' ...
        '\tbut would like to re-scan these images, set this variable to 1. Default is 0.\n'])
    s = input('Enter (0) or (1) for rescanOriginal variable: ', 's');
    while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
        s = input('If specifying rescanOriginal, must be (0) or (1): ', 's');
    end
    if isempty(s) || s == '0'
        rescanOriginal = 0;
    else
        rescanOriginal = 1;
    end
    rescanOriginal %#ok<NOPRT> % Display results of setting rescanOriginal
    
    %% Var skipProcessed
    fprintf(['<strong>skipProcessed</strong>: If there are snowflake images in the\n' ...
        '\tspecified path for the specified date range that have already been\n' ...
        '\tprocessed by this tool, you can set this variable to 1 to skip those\n' ...
        '\timages. Default value is 0.\n'])
    s = input('Enter (0) or (1) for skipProcessed variable: ', 's');
    while ~isempty(s) && (length(s) > 1 || (s ~= '0' && s ~= '1'))
        s = input('If specifying skipProcessed, must be (0) or (1): ', 's');
    end
    if isempty(s) || s == '0'
        skipProcessed = 0;
    else
        skipProcessed = 1;
    end
    skipProcessed %#ok<NOPRT> % Display results of setting skipProcessed
    

end

end

function [isValid] = validate_datestr(s, dstart)
    try
        d = datenum(s, 'yyyymmdd_HHMM');
        if dstart ~= 0 % We are validating dateend, thus need to make sure
                      % that dateend is after datestart
            if d < dstart
                isValid = 0;
            else
                isValid = 1;
            end
        else
            isValid = 1;
        end
    catch %#ok<*CTCH>
        isValid = 0;
    end

end

function [applied_cams] = applyDiscardToCams(type, curSetting)
    if curSetting ~= 0
        invalidList = 1;
        firstInput = 1;
        while invalidList
            if ~firstInput
                fprintf('Invalid element in list.\n');
            else
                firstInput = 0;
            end
            s = input(['var apply' type 'DiscardToCams = [' num2str(curSetting) ']; ' ...
                'Change to (input comma-delimited list, e.g. 0,1,2): '], 's');
            if isempty(s)
                break;
            end
            s = strsplit(s, ',');
            tmp = [];
            for j = 1:length(s)
                if isempty(str2num(s{j}))
                    break;
                end
                tmp(j) = str2num(s{j}); %#ok<AGROW>
                if tmp(j) < 0 || tmp(j) > 2
                    break;
                end
            end
            invalidList = 0;
        end
        if ~invalidList
            applied_cams = tmp;
        else
            applied_cams = curSetting;
        end
    else
        invalidList = 1;
        firstInput = 1;
        while invalidList
            if ~firstInput
                fprintf('Invalid element in list.\n');
            else
                firstInput = 0;
            end
            s = input(['Set apply' type 'DiscardToCams to (input comma-delimited list, e.g. 0,1,2): '], 's');
            if isempty(s)
                break;
            end
            s = strsplit(s, ',');
            tmp = [];
            for j = 1:length(s)
                if isempty(str2num(s{j}))
                    break;
                end
                tmp(j) = str2num(s{j}); %#ok<AGROW>
                if tmp(j) < 0 || tmp(j) > 2
                    break;
                end
            end
            invalidList = 0;
        end
        if ~invalidList
            applied_cams = tmp;
        else
            applied_cams = [];
        end
    end

end