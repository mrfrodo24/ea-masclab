%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% EA INTERACTIVE MASCLAB %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script is the controller for the command-line interface that will be
% used to conduct image processing of snowflakes from MASC cameras.
%
% This script should never need modification to include image processing
% functions or parameters.
%
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('%%%%%%%%%%% WELCOME TO THE EA MASC ANALYTICS SUITE %%%%%%%%%%%')
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
fprintf('\n')
% Ensure that cache and cache/gen_params exist
if ~isdir('cache'), mkdir('cache'); mkdir('cache/gen_params'); 
elseif ~isdir('cache/gen_params'), mkdir('cache/gen_params');
end


%% PRE-PROCESSING
% Call the pre_processing function
disp('%%%%%%%%%%%%%% PRE-PROCESSING %%%%%%%%%%%%%%')
if exist('CACHED_PATH_SELECTION','var')
    preselected = CACHED_PATH_SELECTION;
    if ~isnumeric(preselected), preselected = str2double(preselected); end
else, preselected = -1;
end
[settings, user_selection] = pre_processing(preselected);
CACHED_PATH_SELECTION = user_selection.id;


%% SCAN AND CROP
% Prompts user if they want to run scan/crop
fprintf(['Do you need to run SCAN & CROP? Remember, once you''ve run\n' ...
       '\tthis once on a directory, you do not need to run it again\n' ...
       '\tUNLESS you want to try doing it again with different pre-processing\n' ...
       '\tparameters.\n']);
s = input('Would you like to run SCAN & CROP? (Y/n): ', 's');
while s ~= 'Y' && s ~= 'n'
    s = input(['Please enter [Y] to run SCAN & CROP or [n] to skip to running\n' ...
               'the image processing modules. (Y/n): '], 's');
end
fprintf('\n')
if s == 'n'
    % User chose to skip scan & crop, so just return.
    disp('Skipping to main menu...')
    fprintf('\n');
else
    disp('%%%% SCAN, FILTER, CROP ORIGINAL IMAGES %%%%')
    fprintf('\n');

    % Alert users that this will take a long time. Make sure they have ample 
    % disk space to support the cropped images as well as the subflakes outputs
    % AND that they have ample RAM to perform the scan and crop.
    %   Minimum requirements (based on a sample of 160,000 flakes with several
    %   good storms):
    %       4 GB available RAM (the process itself should not grow much larger
    %           than 1 GB or so...)
    %       16 GB of storage for statistics
    %       TODO...
    status = detect_crop_filter_original(CACHED_PATH_SELECTION, settings);

    if status > 0
        % Error occurred
        disp('Error occurred during SCAN & CROP... Exiting.')
        return;
    end
    
end


%% PROCESSING - MAIN LOOP

% User Control Flow Choices:
%   A) Select a function for processing flakes
%   B) Run default processing on flakes
%   C) Redefine image processing parameter(s)
%   D) Output statistics
%   E) Resync images in selected cached path
%   F) Save and exit program

disp('%%%%%%%%%% EA MASCLAB ANALYTICS %%%%%%%%%%');
fprintf('\n');

user_choice = 'menu';
while 1 % Executes until user choose "Save and Quit" from Menu
    switch(user_choice)
    
    case 'menu'
        user_choice = EA_MascLab_Analytics_Menu;
        
    case 'select_modules'
        disp('%%%%% MODULAR IMAGE PROCESSING %%%%%')
        fprintf('\n')
        
        % Call module finder to get all modules
        modules = ModuleFinder;
        
        % Call module runner to prompt user to select which modules to run
        % and to execute all selected modules on all flakes within date
        % range specified in pre-processing. Also saves all module data to
        % cache if module is successful.
        ModuleRunner(modules, settings);
        
        disp('% FINISHED MODULAR IMAGE PROCESSING %')
        fprintf('\n')
        user_choice = 'menu';
        
    case 'run_scan_crop'
        disp('%%%% SCAN, FILTER, CROP ORIGINAL IMAGES %%%%')
        fprintf('\n');
        
        status = detect_crop_filter_original(CACHED_PATH_SELECTION, settings);
                        
        if status > 0
            % Error occurred
            disp('Error occurred during SCAN & CROP... Exiting.')
            return;
        end
        
        fprintf('\n')
        user_choice = 'menu';
        
    case 'redefine_processing_params'
        % Call the pre_processing function
        disp('%%%%%%%%%% PRE-PROCESSING %%%%%%%%%%')
        [settings, user_selection] = pre_processing();
        CACHED_PATH_SELECTION = user_selection.id;
        
        fprintf('\n')
        user_choice = 'menu';
        
    case 'export_stats'
        disp('%%%%%%%%%%% EXPORT STATS %%%%%%%%%%%')
        fprintf('\n')
        
        % Ask user what they want to export data as
        disp('%%% OPTIONS %%%');
        fprintf(['\t(1) Save good flakes to MASC txt file for SDB.\n' ...
                 '\t(2) Save good flakes to Flake txt file for SDB.\n' ...
                 '\t(3) Save good flakes to CSV file for Machine Learning.\n' ...
                 '\t(4) Back to main menu.\n']);
        s = '';
        while isempty(s) || isempty( find(s == ['1','2','3','4'], 1) )
            if ~isempty(s)
                fprintf('\tInvalid input.\n');
            end
            s = input('Your choice: ', 's');
        end
        
        if s == '1'
            cachedDataToMASCtxt(settings);
        elseif s == '2'
            cachedDataToFLAKEtxt(settings);
        elseif s == '3'
            cachedDataToCSV(settings);
        end
        
        fprintf('\n')
        user_choice = 'menu';
        
    case 'sync_cachedpath'
        disp('%%%%%%%%%%% SYNC UNCROPPED IMAGES %%%%%%%%%%%')
        fprintf('\n');
        
        disp(['About to sync uncropped images in ' settings.pathToFlakes])
        fprintf(['Note: You can always revert a sync afterwards. The old cache files will be\n' ...
            '\tkept in cache/cached_paths_' num2str(CACHED_PATH_SELECTION) '/ with the prefix "sync_bak_" on the old files.\n\n']);

        fprintf('You have 5 seconds to abort... (Ctrl+C)\n'); pause(2); 
        fprintf('3...\n'); pause(1); 
        fprintf('2...\n'); pause(1); 
        fprintf('1...'); pause(1); 
        
        fprintf('\n\nSyncing...\n');
        imgsAdded = sync_cachedpath(CACHED_PATH_SELECTION, settings);
        
        fprintf('\nDone! %i uncropped images were cached', imgsAdded);
        if imgsAdded
            fprintf(' and are ready to be run through Scan & Crop.\n\n');
        else
            fprintf('. Everything up to date.\n\n');
        end
        user_choice = 'menu';
        
    case 'save_and_quit'
        
        break;
    end
end

