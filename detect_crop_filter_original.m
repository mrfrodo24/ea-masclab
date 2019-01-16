function [ status ] = detect_crop_filter_original(selected_path, settings )
%DETECT_CROP_FILTER_ORIGINAL The Scan & Crop stage of ea-masclab
%   
%   SUMMARY:
%       If user has selected a folder in pre_processing that has not yet
%       been processed, then the original images in the folder and/or its
%       subdirectories must be analyzed using this function to:
%           1. Find flakes
%           2. Filter for "good" ones
%           3. Crop the flakes to a new, cached image
%           4. Store the location and boundary of each flake
%
%   INPUTS:
%       selected_path - Which cached path is going to be scanned
%       settings - The settings for the cached path
%

%% Constants
MAX_SUBFLAKES = 25000; 
% Number of fields in the cache_file
NUM_FILE_FIELDS = 6;
MAX_CACHEFILE_RECORDS = 5000;

%% Steps before running Scan & Crop
status = 0;
% Will read each image by going through the files listed in cached_paths.txt
% for the path specified by the user.

% If a "cache" directory doesn't exist in pathToFlakes, make one
if ~isdir([settings.pathToFlakes 'cache'])
    mkdir([settings.pathToFlakes 'cache'])
end

% Make sure cached path exists
if ischar(selected_path), selected_path = str2num(selected_path); end %#ok<ST2NM>
if isempty(get_cachedpath(selected_path))
    fprintf('Cached path %i does not exist. Exiting...\n', selected_path);
    status = 1; % Error
    return;
end
cache_folder = sprintf('cached_paths_%i', selected_path);

% Use one variable to track the current/new f*.txt cache records
allocatedFiles = cell(MAX_CACHEFILE_RECORDS, NUM_FILE_FIELDS);

% track the date of records being accumulated for
theDate = 0;
% track the dates that have been processed (might end up having to append)
% or that already have mat files.
dates = get_cached_flakes_dates(settings.pathToFlakes, 'all');

% Here, we'll declare a variable subFlakes, which will store ALL pertinent
% statistical data for each cropped snowflake.  We will make it a cell
% array so it's easy to store and/or add anything.
%   subFlakes fields:
%       (1) Relative path to cropped image (from pathToFlakes)
%       (2) To be processed (0 or 1) ==> "Good" flake
%       (3) Start of image (X)
%       (4) Start of image (Y)
%       (5) Flake bounds
%       (6) Perimeter pixels
%       (7) Number of accepted flakes in original
%       (8) Number of good flakes in original
subFlakes = cell(MAX_SUBFLAKES, 8);
subCounter = 0;

% Here, we'll declare a variables goodSubFlakes, which will store 
% ALL MODULE DATA FOR EACH "GOOD" SNOWFLAKE
% See initGoodSubFlakes.m file for details...
goodSubFlakes = initGoodSubFlakes([]);
goodSubCounter = 0;

% Check if resuming Scan & Crop i.e. trying to run in the "mode"
% that allows for pausing every 20 cache files
if isfield(settings, 'pause')
    cache_counter = settings.resume;
else
    cache_counter = 1;
end

%% Scan & Crop
% Go through each sub-cache file
while (isfield(settings, 'pause') && settings.resume + 20 > cache_counter && ...
        exist(['cache/' cache_folder '/f' num2str(cache_counter) '.txt'], 'file')) || ...
      (~isfield(settings, 'pause') && ...
        exist(['cache/' cache_folder '/f' num2str(cache_counter) '.txt'], 'file'))

    % Now open the cache_file, which contains all the files we want to scan
    fid = fopen(['cache/' cache_folder '/f' num2str(cache_counter) '.txt'],'r');
    files = textscan(fid,'%s %u %u %u %u %u\n','Delimiter','\t');
    fclose(fid);

    % Image ID starts at 1
    image_id = 1;
    totalFileRecords = length(files{1});
    count_scans = 0;
    
    % Clear allocatedFiles
    allocatedFiles(:) = {[]};
    % Move files to allocatedFiles
    allocatedFiles(1:totalFileRecords,1) = files{1};
    allocatedFiles(1:totalFileRecords,2) = num2cell(files{2});
    allocatedFiles(1:totalFileRecords,3) = num2cell(files{3});
    allocatedFiles(1:totalFileRecords,4) = num2cell(files{4});
    allocatedFiles(1:totalFileRecords,5) = num2cell(files{5});
    allocatedFiles(1:totalFileRecords,6) = num2cell(files{6});
    clear files;
    totalFlakes = sum(~cellfun(@isempty,allocatedFiles(:,1)));

    % Loop through the images enumerated by the cache file "f(cache_counter)"
    textprogressbar(['Scanning & cropping images in ' cache_folder ' from f' num2str(cache_counter) '.txt... '], totalFlakes);
    while image_id <= totalFlakes && ~isempty(allocatedFiles{image_id,1})

        % Print the status of the loop
        textprogressbar(image_id);
        
        % First check that record in allocatedFiles indicated by image_id is to be
        % scanned:
        if allocatedFiles{image_id,2} == 2
            % If equal to 2 -> Already scanned, optionally scan again...
            if ~settings.rescanOriginal
                % Do not scan this file, move on to next one
                image_id = image_id + 1;
                continue;
            end
        elseif allocatedFiles{image_id,2} == 0
            % If equal to 0 -> Not to be scanned at all
            image_id = image_id + 1;
            continue;
        end

        originalFilename = allocatedFiles{image_id,1};

        % Get original image's file extension
        if contains(originalFilename, '.png', 'IgnoreCase', 1)
            fileExt = 'PNG';
        elseif contains(originalFilename, '.jpg', 'IgnoreCase', 1)
            fileExt = 'JPG';
        elseif contains(originalFilename, '.jpeg', 'IgnoreCase', 1)
            fileExt = 'JPEG';
        else
            fprintf('Unsupported image file extension for file: %s\n', originalFilename);
            image_id = image_id + 1;
            continue;
        end

        % Get flake's id from filename, we'll need it later
        timestampAndIds = regexp(originalFilename, settings.mascImgRegPattern, 'match');
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
            fprintf('Bad filename: %s\n', originalFilename);
            fprintf('From cache file: %s\n', ...
                ['cache/' cache_folder '/f' num2str(cache_counter) '.txt']);
            fprintf('Index of bad record in mat-file: %i\n\n', image_id);
            fprintf('Exiting...\n');
            status = 2;
            return;
        else
            timestampAndIds = timestampAndIds{1};
        end
        mascImg = parse_masc_filename(timestampAndIds);
        origFlakeID = mascImg.imageId;
        origCameraID = mascImg.camId;
        d = datenum(datestr(mascImg.date,'yyyymmdd'),'yyyymmdd');

        try % Read in image
            arr = imread([settings.pathToFlakes originalFilename]);
        catch 
            % Couldn't read image for some reason
            fprintf('\nWARNING - Image %s could not be read. Skipping...\n', originalFilename);
            image_id = image_id + 1;
            continue;
        end

        % Check if image is RGB
        if length(size(arr)) > 2
            % Convert to gray
            arr = rgb2gray(arr);
        end

        % Mask the edges as specified by user
        if ~isempty(find(origCameraID == settings.applyTopDiscardToCams, 1))
            arr(1:settings.topDiscard, :) = 0;
        end
        if ~isempty(find(origCameraID == settings.applyBotDiscardToCams, 1))
            arr(end-settings.bottomDiscard:end, :) = 0;
        end
        if ~isempty(find(origCameraID == settings.applyLeftDiscardToCams, 1))
            arr(:, 1:settings.leftDiscard) = 0;
        end
        if ~isempty(find(origCameraID == settings.applyRightDiscardToCams, 1))
            arr(:, end-settings.rightDiscard:end) = 0;
        end

        % Call detect_and_crop!
        [fList, goodcount, acceptedcount] = detect_and_crop(arr, settings);
            % settings.backgroundThresh -> Minimum brightness for detected flake
            % settings.avgFlakeBrightness -> Minimum average brightness for good flake
            % settings.minFlakePerim -> Minimum perimeter of flake in pixels
            % settings.minCropWidth -> Minimum crop size of flake in pixels
            % settings.maxEdgeTouch -> Max length of flake edge touching image frame

        % Update scanned column to 2 (scanned, but can still be rescanned)
        allocatedFiles{image_id,2} = 2;
        % Update count column in allocatedFiles
        allocatedFiles{image_id,3} = acceptedcount;

        % Get this flakes cropped directory
        lastSlash = find(allocatedFiles{image_id,1} == '\' | allocatedFiles{image_id,1} == '/', 1, 'last');
        if ~isempty(lastSlash)
            cropcamdir = [settings.pathToFlakes originalFilename(1:lastSlash) 'CROP_CAM'];
        else
            cropcamdir = [settings.pathToFlakes 'CROP_CAM'];
            lastSlash = 0;
        end
        % Make the directory if it doesn't exist
        if ~isdir(cropcamdir)
            mkdir(cropcamdir);
        end
        
        % Check if the goodSubFlakes & subFlakes for theDate need to be
        % saved off because we've gotten to a new date
        if theDate ~= d
            saveFlakeMatFiles(theDate, dates);
            theDate = d;
        end
            

        % Print all accepted flakes to cache folder and signify for further
        % processing. newFlakes will be added to allocatedFiles cell to then be used to
        % update cached_paths.txt.
        if ~exist('newFlakes','var') || size(newFlakes,1) < size(fList,1)
            % Need a new newFlakes variable that is larger than previous
            % one
            clear newFlakes;
            newFlakes = cell(size(fList,1), NUM_FILE_FIELDS + 3);
        else
            newFlakes(:) = {[]};
        end

        % Run the loop
        for cropflakeid = 1:size(fList, 1)

            if fList{cropflakeid,6}
                % Write out the cropped flake, only if it's a good flake...
                % DO NOT want to write out every accepted flake. Too many.
                                
                % Get cropped flake's filename
                % NOTE: IF ONE OF SUBDIRECTORIES IN PATHTOFLAKES CONTAINS "flake_",
                % THEN THIS WILL GET MESSED UP...
                newFlakeFilename = strrep(originalFilename(lastSlash+1:end), ...
                    ['flake_' num2str(origFlakeID)], ...
                    ['flake_' num2str(origFlakeID) '.' num2str(cropflakeid)]);
                pathToNewFlake = [ cropcamdir filesep newFlakeFilename ];
                
                % First, pad the top, bottom, left, and right sides with 5
                % rows/columns of pixels...
                if fList{cropflakeid,2} - 5 < 1 || ...
                   fList{cropflakeid,3} + 5 > size(arr,1) || ...
                   fList{cropflakeid,4} - 5 < 1 || ...
                   fList{cropflakeid,5} + 5 > size(arr,2)
                    % If code gets here, then flake's rectangle is close to
                    % the edge, so we can't pad it.
                    new_img = arr(fList{cropflakeid,2}:fList{cropflakeid,3}, fList{cropflakeid,4}:fList{cropflakeid,5});
                else
                    new_img = arr(fList{cropflakeid,2} - 5 : fList{cropflakeid,3} + 5, ...
                                  fList{cropflakeid,4} - 5 : fList{cropflakeid,5} + 5);
                end
                
                % NOTE: Used to pad with black pixels, but now we need to stick
                % with the img array itself because having a solid edge
                % between the padded pixels and an edge of the flake
                % confuses the focus measurement...
                imwrite(new_img, pathToNewFlake, fileExt);

                % Add flake file name with relative path to cell
                newFlakes{cropflakeid,1} = pathToNewFlake(length(settings.pathToFlakes)+1:end);
            else
                % If the sub-flake isn't good enough for processing, still need
                % to maintain some sort of reference to original image. Do so
                % by recording the originalFilename.
                newFlakes{cropflakeid,1} = originalFilename;
            end
            % Set "Scanned" field to 0 (not to be scanned)
            newFlakes{cropflakeid,2} = 0;
            % Set "Accepted flakes" field to acceptedcount from original img
            newFlakes{cropflakeid,3} = acceptedcount;
            % Set "Good flakes" field to goodcount from original img
            newFlakes{cropflakeid,4} = goodcount;
            % Set recommendation for further processing
            newFlakes{cropflakeid,5} = fList{cropflakeid,6};
            % Set flake xstart in original image
            newFlakes{cropflakeid,6} = fList{cropflakeid,4};
            % Set flake ystart in original image
            newFlakes{cropflakeid,7} = fList{cropflakeid,2};

            % Any fields beyond this point SHALL NOT go into cached_paths.
            % These will be statistical fields that will be stored in .mat
            % allocatedFiles or other file types.
            newFlakes{cropflakeid,8} = fList{cropflakeid,1}; % Flake bounds
            newFlakes{cropflakeid,9} = fList{cropflakeid,7}; % Flake perimeter

            % Add newFlakes to allocatedFiles. We'll save allocatedFiles back to cached_paths.txt
            % later...
            allocatedFiles(image_id+1:totalFlakes+1,:) = ...
                allocatedFiles(image_id:totalFlakes,:);
            allocatedFiles{image_id+1,1} = newFlakes{cropflakeid,1};
            allocatedFiles{image_id+1,2} = newFlakes{cropflakeid,2};
            allocatedFiles{image_id+1,3} = newFlakes{cropflakeid,3};
            allocatedFiles{image_id+1,4} = newFlakes{cropflakeid,5};
            allocatedFiles{image_id+1,5} = newFlakes{cropflakeid,6};
            allocatedFiles{image_id+1,6} = newFlakes{cropflakeid,7};

            % Add current newFlake to goodSubFlakes if to be further processed
            if newFlakes{cropflakeid,5}
                updateGoodSubFlakes(cropflakeid);
            end

            % Update total of allocatedFiles records
            totalFlakes = totalFlakes + 1;
            % Update image_id
            image_id = image_id + 1;

        end

        % Add to subFlakes
        updateSubFlakes;

        image_id = image_id + 1;
        count_scans = count_scans + 1;

    end
    textprogressbar(' done!');

    % To store the location and boundary of each flake, we save off the
    % locationX and locationY values to the cache file and the cropped
    % PNG serves as our stored boundary.

    % Save "allocatedFiles" cell back to cache_folder -> f(cache_counter).txt
    disp(['Saving detected flakes to cache/' cache_folder '/f' num2str(cache_counter) '.txt'])
    updateCachedPaths;
    disp(['Previous cache file moved to cache/' cache_folder '/prev_f' num2str(cache_counter) '.txt'])
    
    cache_counter = cache_counter + 1;
    fprintf('\n')
end

% Save the last batch of subflakes
saveFlakeMatFiles(theDate, dates);
% Clear everything in the function
clearvars -except status;

fprintf('\n')
disp('%%% FINISHED SCANNING AND CROPPING %%%')
fprintf('\n')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% TRUE END OF DETECT_CROP_FILTER_ORIGINAL FUNCTION %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Sub-functions

    function updateCachedPaths
        updated_cached_paths_file = ['cache/updated_cached_paths_' num2str(rand * 100) '.txt'];
        while exist(updated_cached_paths_file, 'file')
            updated_cached_paths_file = ['cache/updated_cached_paths_' num2str(rand * 100) '.txt'];
        end
        fwid = fopen(updated_cached_paths_file,'w');
        
        for i = 1:totalFlakes
            fprintf(fwid, '%s\t%u\t%u\t%u\t%u\t%u\n', ...
                allocatedFiles{i,1}, ...
                allocatedFiles{i,2}, ...
                allocatedFiles{i,3}, ...
                allocatedFiles{i,4}, ...
                allocatedFiles{i,5}, ...
                allocatedFiles{i,6});
        end
        
        fclose(fwid);
        
        movefile(['cache/' cache_folder '/f' num2str(cache_counter) '.txt'], ...
                 ['cache/' cache_folder '/prev_f' num2str(cache_counter) '.txt'])
        movefile(updated_cached_paths_file, ...
                 ['cache/' cache_folder '/f' num2str(cache_counter) '.txt'])
        
    end 

    function saveFlakeMatFiles(theDate, dates)
        if theDate ~= 0
            filePrefix = [settings.pathToFlakes 'cache' filesep 'data_' datestr(theDate,'yyyymmdd')];
            allFile = [filePrefix '_allflakes.mat'];
            goodFile = [filePrefix '_goodflakes.mat'];
            if ismember(theDate, dates)
                newSubFlakes = subFlakes;
                newGoodSubFlakes = goodSubFlakes;
                load(allFile, 'subFlakes')
                load(goodFile, 'goodSubFlakes')
                subFlakes = [subFlakes; newSubFlakes]; 
                goodSubFlakes = [goodSubFlakes; newGoodSubFlakes];
            else
                dates = [dates theDate]; %#ok<NASGU> append theDate to dates
            end
            subFlakes = stripEmptyCellRows(subFlakes);
            goodSubFlakes = stripEmptyCellRows(goodSubFlakes);
            save(allFile, 'subFlakes', 'settings', '-v7.3')
            save(goodFile, 'goodSubFlakes', 'settings', '-v7.3')
            subFlakes = cell(MAX_SUBFLAKES, 8);
            goodSubFlakes = initGoodSubFlakes([]);
        end
    end

    function updateSubFlakes
        from = subCounter + 1;
        to = subCounter + size(fList,1);
        numNew = size(fList,1);
        subFlakes(from : to, 1) = newFlakes(1:numNew,1); 
        subFlakes(from : to, 2) = newFlakes(1:numNew,5);
        subFlakes(from : to, 3) = newFlakes(1:numNew,6);
        subFlakes(from : to, 4) = newFlakes(1:numNew,7);
        subFlakes(from : to, 5) = newFlakes(1:numNew,8);
        subFlakes(from : to, 6) = newFlakes(1:numNew,9);
        subFlakes(from : to, 7) = newFlakes(1:numNew,3); % # accepted flakes in orig
        subFlakes(from : to, 8) = newFlakes(1:numNew,4); % # good flakes in orig
        subCounter = subCounter + numNew;
    end

    function updateGoodSubFlakes(id)
        goodSubCounter = goodSubCounter + 1;
        goodSubFlakes(goodSubCounter, 1) = newFlakes(id, 1);
        goodSubFlakes(goodSubCounter, 27) = newFlakes(id, 3); 
        goodSubFlakes(goodSubCounter, 28) = newFlakes(id, 4);
        goodSubFlakes(goodSubCounter, 2) = newFlakes(id, 5);
        goodSubFlakes(goodSubCounter, 3) = newFlakes(id, 6);
        goodSubFlakes(goodSubCounter, 4) = newFlakes(id, 7);
        goodSubFlakes(goodSubCounter, 5) = newFlakes(id, 8);
        goodSubFlakes(goodSubCounter, 6) = newFlakes(id, 9);
    end
    
    function [data] = stripEmptyCellRows(data)
        data(cellfun(@isempty,data(:,1)),:) = [];    
    end

end

