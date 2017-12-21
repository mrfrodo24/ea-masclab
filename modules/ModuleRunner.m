function [settings] = ModuleRunner( modules, settings )
%MODULERUNNER Executes CP3G MascLab module processing on all cropped flakes.
%   Detailed explanation goes here


%% Declarations
% Some constants that should really never change
IMAGE_DATE_FORMAT = 'yyyy.mm.dd_HH.MM.SS';
LENGTH_IMAGE_DATE = length(IMAGE_DATE_FORMAT);

% OPTIONAL CHECK - RESUME
% Can run this function in pause/resume mode, similar to Scan & Crop.
% Use the utils/module_resume_processing.m function in accordance with
% the utils/module_proc_caller.sh script and you will be able to run
% the modules over 20 cache files at a time.
if ~isfield(settings, 'remember_modules')
    %% 1. Go through list of modules provided and for each one ask if the user
    %      wants to run it. If user selects yes, add the module to a list to
    %      be ran once user has been prompted for all modules. Also verifies
    %      modules have required dependencies.
    modules = ModuleSelector(modules, settings);
end

% Check if modules is empty now, if so then there's nothing to do, just go
% back to the main menu
if isempty(modules)
    fprintf('No modules selected! Redirecting to main menu...\n\n');
    return;
end


%% 2. Go through user-selected list of modules and run them on all the
%       flakes whose date falls between datestart/dateend.
%       FOR EACH FLAKE:
%       a. Call ModuleInputHandler
%       b. Call Module
%       c. Call ModuleOutputHandler -> Just returns the indices of
%           goodSubFlakes to update
%       d. Update goodSubFlakes only if size of output from module matches
%           size of output from ModuleOutputHandler. i.e. We must have an
%           index to goodSubFlake for each output from the module.

% Loop through goodflakes files
if isfield(settings, 'resume_module_proc')
    goodFlakesCounter = settings.resume_module_proc;
else
    goodFlakesCounter = 0;
end
while exist([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'],'file') && ...
        (~isfield(settings, 'resume_module_proc') || goodFlakesCounter < settings.resume_module_proc + 2)

    % Maintain count of all flakes and whether goodSubFlakes gets modified
    modifiedGoodSubFlakes = 0;
    count_allflakes = 0;

    % Load the goodSubFlakes
    fprintf('Loading data from file data%i_goodflakes.mat in cache...', goodFlakesCounter);
    load([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'], ...
        'goodSubFlakes')
    fprintf('done.\n');
    fprintf(['Running selected modules on loaded data that is within\n' ...
        datestr(settings.datestart) ' and ' datestr(settings.dateend) '\n\n']);
    
    % Make sure goodSubFlakes exists (if not, error)
    if ~exist('goodSubFlakes', 'var')
        % Not a valid goodflakes mat file
        fprintf('Encountered good flakes file without correct variable(s). Skipping...');
        goodFlakesCounter = goodFlakesCounter + 1;
        continue;
        
    % As long as it exists, run it through initGoodSubFlakes to check that
    % it has the appropriate amount of columns.
    else
        goodSubFlakes = initGoodSubFlakes(goodSubFlakes);
    end
    
    % Count the not-empty entries
    for j = 1 : size(goodSubFlakes, 1)
        if isempty(goodSubFlakes{j,1})
            break;
        end
    end
    numGoodFlakes = j - 1;
    
    % Initialize variable that will hold the timestamp for each flake
    % indexed in goodSubFlakes
    goodDatesIndices = zeros(numGoodFlakes, 3);
    
    % Here, we want to go through and calculate a datenum for each of
    % the good flakes. We'll store these datenums in a separate array,
    % which will also hold the flake ID and the reference to the
    % goodSubFlakes array it exists in.
    for j = 1 : numGoodFlakes
        % Get the timestamp and ids from the filename
        timestampAndIds = regexp(goodSubFlakes{j,1}, settings.mascImgRegPattern, 'match');
        % 1 and only 1 string should be matched. If we get none, or more
        % than 1, we have a problem with this file.
        if length(timestampAndIds) ~= 1
            % If this error occurs, exit. Do nothing to fix it, don't try
            % to ignore it. If one file is "corrupt" or not MASC
            % compatible, then it's likely there are others.
            fprintf('\nERROR!\n');
            fprintf(['A corrupt filename was detected that does not have the expected\n' ...
                '\tformat. The format is documented in pre_processing, within the\n' ...
                '\tMASC-SPECIFIC FORMATTING cell. No data was modified during the course\n' ...
                '\tof this action.\n']);
            fprintf('Bad filename: %s\n', goodSubFlakes{j,1});
            fprintf('From mat-file: %s\n', ...
                [settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat']);
            fprintf('Index of bad record in mat-file: %i\n\n', j);
            fprintf('Exiting...\n');
            return;
        else
            timestampAndIds = timestampAndIds{1};
        end
        
        count_allflakes = count_allflakes + 1;
        
        % Add date
        d = datenum(timestampAndIds(1 : LENGTH_IMAGE_DATE - 1), ...
            IMAGE_DATE_FORMAT);
        goodDatesIndices(count_allflakes, 1) = d;

        % Add index into goodSubFlakes (which will be stored in allGoodSubFlakes)
        goodDatesIndices(count_allflakes, 2) = j;
        
        % Add camId
        goodDatesIndices(count_allflakes, 3) = str2num(timestampAndIds(strfind(timestampAndIds, 'cam_') + 4)); %#ok<ST2NM>

    end
    clear d startindex endindex filename
    
    dates = goodDatesIndices(:,1);
    numFlakesToProcess = length(find(dates >= settings.datestart & ...
                                 dates <= settings.dateend));
    % Check if no flakes in date range to process
    if numFlakesToProcess == 0
        fprintf(['No flakes in the loaded data that are within the specified\n' ...
            'date range. Skipping to next good flake data...\n']);
        goodFlakesCounter = goodFlakesCounter + 1;
        continue;
    end
        
    % The filled flake cross-section is a commonly used entity for modules,
    % however, it is somewhat expensive to calculate. So we will cache it for
    % multiple module runs.
    filledFlakes = cell(1,length(dates));
    
    % Loop through modules
    for j = 1 : length(modules)
        disp(['Executing "' modules{j} '" MODULE on ' ...
            num2str(length(dates)) ' flake images...'])

        % Initialize some important variables
        countProcdFlakes = 0;
        reverseStr = '';
        error = [];
        % Create the module's expression
        expression = [modules{j} '(img_fullpath, goodSubFlake{5}, ' ...
            '[goodSubFlake{4} goodSubFlake{3}], module_inputs)'];

        % Loop through the good flakes
        for k = 1 : length(dates)

            if dates(k) < settings.datestart || dates(k) > settings.dateend
                % Current flake is outside of date range, so skip it
                continue;
            end

            % Get index of corresponding goodSubFlake array
            flakeIndex = goodDatesIndices(k,2);

            % Fetch goodSubFlake
            goodSubFlake = goodSubFlakes(flakeIndex,:);

            % Set the full path to the image
            % IMPORANT! It used to be that the image would be loaded
            % outside of the module, but instead we'll let delegate that to
            % a per module basis. If a module really needs the raw image,
            % it can load it on its own. But, for the most part, the flake
            % bounds (provided by goodSubFlake{5}) will suffice.
            img_fullpath = [settings.pathToFlakes goodSubFlakes{flakeIndex,1}]; %#ok<NASGU>
            
            % Get the filled flake cross-section
            if isempty(filledFlakes{k})
                flake = imread([settings.pathToFlakes goodSubFlake{1}]);
                resolution = 1000 / settings.camFOV(goodDatesIndices(k,3) + 1); % px / mm -> microns / px
                filledFlakes{k} = FillFlake(flake, settings.lineFill, resolution);
                % If running on Calibration dataset (e.g. airsoft pellets),
                % need to use flake > 10 instead of FillFlake
            end
            settings.filledFlake = filledFlakes{k};

            % Get inputs for module
            [~,~,module_inputs] = ModuleInputHandler(modules{j}, goodSubFlake, settings, 3); %#ok<NASGU>

            % Run current module on the current flake img
            try
                module_output = eval(expression);
            catch err
                % If an error occurs, currently we'll just show what
                % happened and break out of the module loop. Eventually,
                % try to handle errors elegantly/robustly.
                error = err;
                fprintf('%s',reverseStr);
                fprintf('ERROR! Something went wrong while running the module.\n');
                fprintf(['\tIndex of flake in data' num2str(goodFlakesCounter) ...
                    '_goodflakes.mat: ' num2str(k) '\n']);
                fprintf('\tError occurred on line %i in %s MODULE\n', ...
                    error.stack(1).line, error.stack(1).file);
                break;
            end

            % Get indices for module output
            module_output_indices = ModuleOutputHandler(modules{j}, 0);

            % Verify that module_output and module_output_indices are the same
            % length...
            % IF NOT, then we have an error and we can't accept the modules
            % output...
            if length(module_output) ~= length(module_output_indices)
                error = 1;
                fprintf('%s',reverseStr);
                fprintf(['Error! Length of module output did not match the expected output.\n' ...
                    'Verify the expected length of module output in ModuleOutputHandler\n' ...
                    'and check that the module''s output matches the expected output.\n']);
                break;
            end

            % Append allGoodSubFlakes with module_output
            for l = 1 : length(module_output)
                goodSubFlakes{flakeIndex,module_output_indices(l)} = module_output{l}; 
            end

            % Mark the goodSubFlakes in allGoodSubFlakes as modified
            modifiedGoodSubFlakes = 1;
            countProcdFlakes = countProcdFlakes + 1;

            percentDone = 100 * countProcdFlakes / numFlakesToProcess;
            msg = sprintf('%.0f%% complete...', percentDone);
            fprintf('%s%s', reverseStr, msg);
            reverseStr = repmat(sprintf('\b'), 1, length(msg));

        end

        if ~isempty(error)
            % Module had an error, going to next one
            fprintf('Skipping module due to error.\n');
            continue;
        end

        % Module is done!
        fprintf('%s%s\n', reverseStr, '...done.');

    end
    
    % Now that we've gone through the modules for this goodflakes.mat file,
    % we can save it (if necessary)
    if modifiedGoodSubFlakes
        % First, move the old goodSubFlakes (in case user decides they need to
        % revert back to old data).
        movefile([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'], ...
                 [settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_prevgoodflakes.mat']);
        fprintf('\tMoved old good flake data to:\n\t\t%s\n', ...
            [settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_prevgoodflakes.mat']);

        % Now save the new subFlakes
        save([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'], ...
            'goodSubFlakes', ...
            'settings', ...
            '-v7.3')
        fprintf('\tSaved new good flake data to:\n\t\t%s\n', ...
            [settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat']);
    end
    
    clear goodSubFlakes numGoodFlakes goodDatesIndices dates numFlakesToProcess;
    
    goodFlakesCounter = goodFlakesCounter + 1;
        
end

if exist([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'],'file')
    fprintf('Pausing module processing...\n');
elseif isfield(settings, 'resume_module_proc')
    settings = rmfield(settings, 'resume_module_proc');
    settings = rmfield(settings, 'remember_modules');
    clearvars -except settings
    save('cache/gen_params/last_parameters.mat')
    fprintf('Finished all modules on all data! Use Ctrl+C as soon as matlab quits to exit the bash script that is calling Matlab.\n');
    fprintf('Run ''dbcont'' to continue...')
    keyboard
else
    fprintf('Finished All Modules On All Data!\n\n');
end

clear

end

