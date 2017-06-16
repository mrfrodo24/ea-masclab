% This utility is used to refresh the goodflakes data with that from
% allflakes data.
%
% !!!!!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% Using this script will overwrite any module output stored in the
% goodflakes data files. Only do this if you are trying to start your
% goodflakes data from scratch, but don't want to go back and re-run 
% SCAN & CROP

% Will use the pathToFlakes in last_parameters (if none, then exit)

% Then, loop through allflakes files, copying "good" records to a new cell
% array, saving off that cell array when it gets >= 10000 records

if ~exist('cache/gen_params/last_parameters.mat','file')
    fprintf(['Could not refresh goodflakes data because the cached parameters\n' ...
        '\tfrom PRE-PROCESSING could not be found. Please run <strong>pre_processing</strong>\n' ...
        '\tand make sure that the parameters you specify are cached.\n']);
    disp('Exiting...')
    return;
end

MAX_GOODSUBFLAKES = 10000;
load('cache/gen_params/last_parameters.mat')

% Check if user wants to refresh the goodflakes from allflakes or actually double
% check the flakes in allflakes to re-determine if they are good.
fprintf(['Do you want to go back through all objects detected and redetermine\n' ...
    '\tgood flakes too? This is a longer operation since it will also delete\n' ...
    '\tcropped flake images that are no longer deemed good and create cropped\n' ...
    '\tflake images for those now deemed good.\n'])
s = input('Redetermnine good flakes? (y/n): ', 's');
while s ~= 'y' && s ~= 'n'
    s = input('Redetermine good flakes? (y/n): ', 's');
end
if s == 'y', settings.recheck_good = 1;
else settings.recheck_good = 0;
end

goodSubFlakes = initGoodSubFlakes([]);
goodSubCounter = 0;
goodSubIndex = 1;

hasPrevFlakes = 0;
allFlakesCounter = 0;
curFlakeId = 0;
changedFlakeId = 0;
goodCount = 0;
acceptedCount = 0;
while exist([settings.pathToFlakes 'cache/data' num2str(allFlakesCounter) '_allflakes.mat'],'file')
    var = load([settings.pathToFlakes 'cache/data' ...
        num2str(allFlakesCounter) '_allflakes.mat'], 'subFlakes');
    allFlakes = var.subFlakes;
    % Support for old version of allflakes
    if size(allFlakes,2) < 8
        allFlakes = [allFlakes cell(size(allFlakes,1), 8 - size(allFlakes,2))]; %#ok<AGROW>
    end
    clear var
    
    i = 1;
    fprintf(['Searching for good flakes in cache/data' num2str(allFlakesCounter) '_allflakes.mat...\n'])
    while ~isempty(allFlakes{i,1})
        
        % Go through "good" flake checks
        if settings.recheck_good
            % Derived from detect_and_crop function
            filename = allFlakes{i,1};
            matches = regexp(filename, settings.mascImgRegPattern, 'match');
            timestampAndIds = matches{1};
            timestamp = datenum(timestampAndIds(1:13),'yyyy.mm.dd_HH');
            flakeIdStart = strfind(timestampAndIds, 'flake_') + 6;
            flakeEnd1 = strfind(timestampAndIds(flakeIdStart:end), '.');
            flakeEnd2 = strfind(timestampAndIds(flakeIdStart:end), '_');
            flakeIdEnd = flakeIdStart + min(flakeEnd1(1), flakeEnd2(1)) - 2;
            flakeId = str2num(timestampAndIds(flakeIdStart:flakeIdEnd)); %#ok<*ST2NM>
            
            % This really means that we are on the next original image
            if flakeId ~= curFlakeId
                if hasPrevFlakes
                    % Update end of prevAllFlakes and up to i in allFlakes
                    for j = prevChangedFlakeId:size(prevAllFlakes,1)
                        prevAllFlakes{j,7} = acceptedCount; %#ok<SAGROW>
                        prevAllFlakes{j,8} = goodCount; %#ok<SAGROW>
                    end
                    % Save prevAllFlakes to cache
                    subFlakes = prevAllFlakes;
                    fprintf(['Pausing search for good flakes to save batch ' num2str(allFlakesCounter-1) ...
                        ' of all flakes to cache/data' num2str(allFlakesCounter-1) '_allflakes.mat...'])
                    save([settings.pathToFlakes 'cache/data' num2str(allFlakesCounter-1) '_allflakes.mat'], ...
                        'subFlakes', 'settings', '-v7.3')
                    fprintf('done.\n')
                    fprintf('Still searching for good flakes...\n')
                    hasPrevFlakes = 0;
                    clear subFlakes prevAllFlakes;
                    
                    % If not on the first index of allFlakes, update 1 to i-1
                    if i > 1
                        for j = 1:i-1
                            allFlakes{j,7} = acceptedCount;
                            allFlakes{j,8} = goodCount;
                        end
                    end
                elseif changedFlakeId > 0
                    % Update everything from changedFlakeId to i - 1
                    for j = changedFlakeId:i-1
                        allFlakes{j,7} = acceptedCount;
                        allFlakes{j,8} = goodCount;
                    end
                end
                changedFlakeId = i;
                curFlakeId = flakeId;
                acceptedCount = 1; % Start this at 1 since won't increment acceptedCount in this loop
                goodCount = 0;
                
                % Try to read original image
                try
                    datepath = 0;
                    yearpath = [settings.pathToFlakes datestr(timestamp,'yyyy/mm/dd/HH/') allFlakes{i,1}];
                    monthpath = [settings.pathToFlakes datestr(timestamp,'mm/dd/HH/') allFlakes{i,1}];
                    daypath = [settings.pathToFlakes datestr(timestamp,'dd/HH/') allFlakes{i,1}];
                    hourpath = [settings.pathToFlakes datestr(timestamp,'HH/') allFlakes{i,1}];
                    rawpath = [settings.pathToFlakes allFlakes{i,1}];
                    if exist(yearpath, 'file'), datepath = 'yyyy/mm/dd/HH/';
                    elseif exist(monthpath, 'file'), datepath = 'mm/dd/HH/';
                    elseif exist(daypath, 'file'), datepath = 'dd/HH/';
                    elseif exist(hourpath, 'file'), datepath = 'HH/';
                    else found_img = 0;
                    end
                    if datepath || exist(rawpath, 'file')
                        if ~datepath, datepath = ''; end
                        cameraSubstr = timestampAndIds(strfind(timestampAndIds, '_cam_'):end);
                        img_arr = imread([settings.pathToFlakes datestr(timestamp,datepath) timestampAndIds]);
                        found_img = 1;
                    end
                catch err
                    found_img = 0;
                end
                
            else
                % If flake ID stayed the same, increment acceptedCount
                acceptedCount = acceptedCount + 1;
            end
            
            if found_img
                inds = find(allFlakes{i,5} > 0);
                flakeSize = size(allFlakes{i,5});
                [row, col] = ind2sub(flakeSize, inds);

                minC = allFlakes{i,3}; minR = allFlakes{i,4};
                maxC = minC + flakeSize(2) - 1; maxR = minR + flakeSize(1) - 1;
                good_flake = 1;

                if flakeSize(1) < settings.minCropWidth || flakeSize(2) < settings.minCropWidth
                    good_flake = 0;
                end

                % Filter intensity
                if good_flake && nanmean(nanmean(img_arr(minR:maxR,minC:maxC))) < settings.avgFlakeBrightness
                    good_flake = 0;
                end

                % Filter on max length that flake can be touching image frame
                if good_flake && sum(row == 1 | row == size(img_arr,1)) > settings.maxEdgeTouch || ...
                   sum(col == 1 | col == size(img_arr,2)) > settings.maxEdgeTouch
                    good_flake = 0;
                end

                % Filter focus
                focus = fmeasure(img_arr(minR:maxR,minC:maxC),'VOLA');
                if good_flake && settings.filterFocus && focus < settings.focusThreshold
                    good_flake = 0;
                end

                % Filter for lens flares
                if good_flake
                    % MAGIC VALUE - Threshold lens flares at 120 alpha
                    lens_stats = regionprops(img_arr(minR:maxR,minC:maxC) > 120);
                    if length(lens_stats) == 1
                        lens_flare = lens_stats.BoundingBox;
                    end
                    if length(lens_stats) == 1 && ...
                       2*lens_flare(3) + 2*lens_flare(4) < settings.minFlakePerim
                        good_flake = 0;
                    end
                end
                fprintf('\nGood Before = %i', allFlakes{i,2})
                fprintf('\nGood After  = %i', good_flake)
                
                % Set processing parameter ("good" flake indicator)
                % In doing so, check whether flake used to be good
                if allFlakes{i,2} && ~good_flake
                    % Remove cropped img and change file reference to original image
                    yearpath = [settings.pathToFlakes datestr(timestamp,'yyyy/mm/dd/HH/') allFlakes{i,1}];
                    monthpath = [settings.pathToFlakes datestr(timestamp,'mm/dd/HH/') allFlakes{i,1}];
                    daypath = [settings.pathToFlakes datestr(timestamp,'dd/HH/') allFlakes{i,1}];
                    hourpath = [settings.pathToFlakes datestr(timestamp,'HH/') allFlakes{i,1}];
                    rawpath = [settings.pathToFlakes allFlakes{i,1}];
                    if exist(yearpath, 'file'), delete(hourpath);
                    elseif exist(monthpath, 'file'), delete(monthpath);
                    elseif exist(daypath, 'file'), delete(daypath);
                    elseif exist(hourpath, 'file'), delete(hourpath);
                    elseif exist(rawpath, 'file'), delete(rawpath);
                    end
                    subFlakeIdEnd = flakeIdEnd + strfind(timestampAndIds(flakeIdEnd:end), '_cam_') - 2;
                    subFlakeId = timestampAndIds(flakeIdEnd+2 : subFlakeIdEnd);
                    timestampAndIds = strrep(timestampAndIds, ...
                        ['flake_' num2str(flakeId) '.' subFlakeId '_cam'], ...
                        ['flake_' num2str(flakeId) '_cam']);
                    allFlakes{i,1} = timestampAndIds;
                
                elseif ~allFlakes{i,2} && good_flake
                    % Write cropped img and define reference
                    timestampAndIds = strrep(timestampAndIds, ...
                        ['flake_' num2str(flakeId) '_cam'], ...
                        ['flake_' num2str(flakeId) '.' num2str(acceptedCount) '_cam']);
                    yearpath = [settings.pathToFlakes datestr(timestamp,'yyyy/mm/dd/HH') '/CROP_CAM'];
                    monthpath = [settings.pathToFlakes datestr(timestamp,'mm/dd/HH') '/CROP_CAM'];
                    daypath = [settings.pathToFlakes datestr(timestamp,'dd/HH') '/CROP_CAM'];
                    hourpath = [settings.pathToFlakes datestr(timestamp,'HH') '/CROP_CAM'];
                    rawpath = [settings.pathToFlakes 'CROP_CAM'];
                    camdir = 0;
                    if exist(yearpath, 'dir'), camdir = yearpath;
                    elseif exist(monthpath, 'dir'), camdir = monthpath;
                    elseif exist(daypath, 'dir'), camdir = daypath;
                    elseif exist(hourpath, 'dir'), camdir = hourpath;
                    elseif exist(rawpath, 'dir'), camdir = rawpath;
                    end
                    
                    if camdir
                        imwrite(img_arr(minR:maxR,minC:maxC), [camdir '/' timestampAndIds]);
                        allFlakes{i,1} = ['CROP_CAM/' timestampAndIds];
                    end
                end
                
                allFlakes{i,2} = good_flake;
            end
        end
        
        % If record in allflakes is good, then save to good flakes
        if allFlakes{i,2}
            % Flake is a good one
            goodSubFlakes(goodSubIndex,1:6) = allFlakes(i,1:6);
            goodSubFlakes(goodSubIndex,27) = allFlakes(i,7);
            goodSubFlakes(goodSubIndex,28) = allFlakes(i,8);
            goodSubIndex = goodSubIndex + 1;
            goodCount = goodCount + 1;
            
            if goodSubIndex > MAX_GOODSUBFLAKES
                % Save goodSubFlakes
                fprintf(['Saving good flakes to cache/data' num2str(goodSubCounter) '_goodflakes.mat...'])
                save([settings.pathToFlakes 'cache/data' num2str(goodSubCounter) '_goodflakes.mat'], ...
                    'goodSubFlakes', 'settings', '-v7.3')
                fprintf('done.\n')
                fprintf('Still searching for good flakes...\n')
                % Reset goodSubFlakes
                goodSubFlakes(:) = {[]};
                goodSubCounter = goodSubCounter + 1;
                goodSubIndex = 1;
            end
                
        end
        i = i + 1;      
    end
    prevAllFlakes = allFlakes;
    prevChangedFlakeId = changedFlakeId;
    changedFlakeId = 0;
    hasPrevFlakes = 1;
    allFlakesCounter = allFlakesCounter + 1;
end

% Save final batch of allFlakes if rechecked good
if settings.recheck_good
    % Update end of prevAllFlakes and up to i in allFlakes
    for j = prevChangedFlakeId:i-1
        allFlakes{j,7} = acceptedCount;
        allFlakes{j,8} = goodCount;
    end

    % Save prevAllFlakes to cache
    subFlakes = allFlakes;
    fprintf(['Saving last batch of all flakes to cache/data' num2str(allFlakesCounter-1) '_allflakes.mat...'])
    save([settings.pathToFlakes 'cache/data' num2str(allFlakesCounter-1) '_allflakes.mat'], ...
        'subFlakes', 'settings', '-v7.3')
    fprintf('done.\n')
end

% Check if there is data in goodSubFlakes (if so, save it)
if goodSubIndex > 1
    fprintf(['Saving good flakes to cache/data' num2str(goodSubCounter) '_goodflakes.mat...'])
    save([settings.pathToFlakes 'cache/data' num2str(goodSubCounter) '_goodflakes.mat'], ...
        'goodSubFlakes', 'settings', '-v7.3')
    fprintf('done.\n')
end

clear