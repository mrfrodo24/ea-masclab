% MIGRATION 20190110 - Refactor subflake mat files to be daily
%
%   This script is only to be run ONCE for a single cached path.
%
%   It will go through the current cached path specified by the
%   CACHED_PATH_SELECTION variable, converting all of the subflake and
%   goodsubflake mat files to daily files.  i.e. each mat file will now
%   encompass all original images and cropped images from a single day.
%
%   If there is no mat file for a day, then there were no images obtained
%   on that day.
%
%   Required vars:
%       CACHED_PATH_SELECTION - integer from 1 to n, specifies where the
%           mat files are to be updated

if ~exist('CACHED_PATH_SELECTION', 'var')
    error('You must specify the cache to migrate using the `CACHED_PATH_SELECTION` variable.')
end

pathToFlakes = get_cachedpath(CACHED_PATH_SELECTION);

matFilePath = [pathToFlakes 'cache' filesep];

numAllFlakeFiles = length(dir([matFilePath 'data*_allflakes.mat']));
numGoodFlakeFiles = length(dir([matFilePath 'data*_goodflakes.mat']));
if numAllFlakeFiles == 0
    disp('No data to migrate.')
    return;
elseif numGoodFlakeFiles == 0
    disp('No good flakes data to migrate.')
end

% Go from data[int]_allflakes.mat to data_[date]_allflakes.mat (same for goodflakes)

%% All flakes
textprogressbar(['Migrating ' num2str(numAllFlakeFiles) ' all flake files... '], numAllFlakeFiles - 1);

allFlakes = {};     % all of the flakes
theDate = 0;        % the current date
dates = [];         % keep a list of all dates with files
firstInD = 1;       % index into allFlakes of first flake in date d
lastInD = 1;        %#ok<NASGU> index into allFlakes of last flake in date d

for i = 0 : numAllFlakeFiles - 1
    textprogressbar(i);
    load([matFilePath 'data' num2str(i) '_allflakes.mat'], 'subFlakes');
    lastFlake = find(~cellfun(@isempty, subFlakes(:,1)), 1, 'last');
    if isempty(lastFlake), continue; end
    if ~isempty(allFlakes)
        % trim allFlakes, only keeping what's in theDate that hasn't
        % been saved yet
        allFlakes = allFlakes(firstInD:end,:);
        firstInD = 1;
        firstFlake = length(allFlakes) + 1;
        allFlakes = [allFlakes; subFlakes(1:lastFlake,:)]; %#ok<AGROW>
        lastFlake = length(allFlakes);
    else
        firstFlake = 1;
        allFlakes = subFlakes;
    end
    clear goodSubFlakes
    for j = firstFlake : lastFlake
        flake = parse_masc_filename(allFlakes{j,1});
        d = datenum(datestr(flake.date,'yyyymmdd'),'yyyymmdd');
        if theDate ~= d
            % Need to make a new file for theDate
            if theDate ~= 0
                % save the data for theDate
                lastInD = j - 1;
                dFile = [matFilePath 'data_' datestr(theDate,'yyyymmdd') '_allflakes.mat'];
                if ismember(theDate, dates)
                    % already a file for theDate, update it
                    load(dFile, 'subFlakes');
                    subFlakes = [subFlakes; allFlakes(firstInD:lastInD,:)]; %#ok<AGROW>
                    save(dFile, 'subFlakes', '-append')
                else
                    % new file for theDate
                    subFlakes = allFlakes(firstInD:lastInD,:);
                    save(dFile, 'subFlakes', 'settings', '-v7.3')
                    dates = [dates theDate]; %#ok<AGROW> append theDate to dates
                end
            end
            theDate = d; % update theDate
            firstInD = j;
        end
    end
end
if theDate ~= 0
    % save the data for the last date
    lastInD = j;
    dFile = [matFilePath 'data_' datestr(theDate,'yyyymmdd') '_allflakes.mat'];
    if ismember(theDate, dates)
        % already a file for last date, update it
        load(dFile, 'subFlakes');
        subFlakes = [subFlakes; allFlakes(firstInD:lastInD,:)];
        save(dFile, 'subFlakes', '-append')
    else
        % new file for last date
        subFlakes = allFlakes(firstInD:lastInD,:);
        save(dFile, 'subFlakes', 'settings', '-v7.3')
        dates = [dates theDate]; %#ok<NASGU> append theDate to dates
    end
end
textprogressbar(' done!');
fprintf('\n');

%% Good Flakes
textprogressbar(['Migrating ' num2str(numGoodFlakeFiles) ' good flake files... '], numGoodFlakeFiles - 1);

goodFlakes = {};    % the good flakes
theDate = 0;        % the current date
dates = [];         % keep a list of all dates with files
firstInD = 1;       % index into goodFlakes of first flake in date d
lastInD = 1;        % index into goodFlakes of last flake in date d

for i = 0 : numGoodFlakeFiles - 1
    textprogressbar(i);
    load([matFilePath 'data' num2str(i) '_goodflakes.mat'], 'goodSubFlakes');
    lastFlake = find(~cellfun(@isempty, goodSubFlakes(:,1)), 1, 'last');
    if isempty(lastFlake), continue; end
    if ~isempty(goodFlakes)
        % trim the goodFlakes, only keeping what's in theDate that hasn't
        % been saved yet
        goodFlakes = goodFlakes(firstInD:end,:);
        firstInD = 1;
        firstFlake = length(goodFlakes) + 1;
        goodFlakes = [goodFlakes; goodSubFlakes(1:lastFlake,:)]; %#ok<AGROW>
        lastFlake = length(goodFlakes);
    else
        firstFlake = 1;
        goodFlakes = goodSubFlakes; 
    end
    clear goodSubFlakes
    for j = firstFlake : lastFlake
        flake = parse_masc_filename(goodFlakes{j,1});
        d = datenum(datestr(flake.date,'yyyymmdd'),'yyyymmdd');
        if theDate ~= d
            % Need to make a new file for theDate
            if theDate ~= 0
                % save the data for theDate
                lastInD = j - 1;
                dFile = [matFilePath 'data_' datestr(theDate,'yyyymmdd') '_goodflakes.mat'];
                if ismember(theDate, dates)
                    % already a file for theDate, update it
                    load(dFile, 'goodSubFlakes');
                    goodSubFlakes = [goodSubFlakes; goodFlakes(firstInD:lastInD,:)]; %#ok<AGROW>
                    save(dFile, 'goodSubFlakes', '-append')
                else
                    % new file for theDate
                    goodSubFlakes = goodFlakes(firstInD:lastInD,:);
                    save(dFile, 'goodSubFlakes', 'settings', '-v7.3')
                    dates = [dates theDate]; %#ok<AGROW> append theDate to dates
                end
            end
            theDate = d; % update theDate
            firstInD = j;
        end
    end
end
if theDate ~= 0
    % save the data for the last date
    lastInD = j;
    dFile = [matFilePath 'data_' datestr(theDate,'yyyymmdd') '_goodflakes.mat'];
    if ismember(theDate, dates)
        % already a file for last date, update it
        load(dFile, 'goodSubFlakes');
        goodSubFlakes = [goodSubFlakes; goodFlakes(firstInD:lastInD,:)];
        save(dFile, 'goodSubFlakes', '-append')
    else
        % new file for last date
        goodSubFlakes = goodFlakes(firstInD:lastInD,:);
        save(dFile, 'goodSubFlakes', 'settings', '-v7.3')
        dates = [dates theDate]; % append theDate to dates
    end
end
textprogressbar(' done!');
fprintf('\n');

% END MIGRATION
disp('Migration complete!')