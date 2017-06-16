function [ allGoodSubFlakes, goodDatesIndices, ...
    goodFlakeArrays, count_goodflake_arrays ] = loadGoodSubFlakes( settings )
%LOADGOODSUBFLAKES Summary of this function goes here
%   Detailed explanation goes here

fprintf('Loading good flake data...');

% Search cache directory for files ending in "_goodflakes.mat"
files = dir([settings.pathToFlakes 'cache/*_goodflakes.mat']);

% Initialize some very useful variables:

% Maintain all goodSubFlakes loaded from directory cache
allGoodSubFlakes = cell(1, length(files));

% Maintain a list of each flake's timestamp, its index into goodSubFlakes,
% and which of the goodSubFlakes it belongs to in allGoodSubFlakes.
goodDatesIndices = [];

% Maintain the .mat file that was loaded for each of the goodSubFlakes
% cell arrays
goodFlakeArrays = cell(2, length(files));
count_goodflake_arrays = 0;
count_allflakes = 0;

% Loop through goodflakes files
for i = 1 : length(files)

    % Load the goodSubFlakes
    load([settings.pathToFlakes 'cache/' files(i).name])

    % Make sure goodSubFlakes exists (if not, error)
    if ~exist('goodSubFlakes', 'var')
        % Not a valid goodflakes mat file
        fprintf('\n\tEncountered good flakes file without correct variable(s). Skipping...');
        continue;
    end
    % If code makes it here, we can count the good flakes array
    count_goodflake_arrays = count_goodflake_arrays + 1;
    
    % IMPORTANT %
    % Need to check if goodSubFlakes has the same number of columns as
    % defined in initGoodSubFlakes function.
    % IF NOT, then add the missing columns.
    % NOTE: initGoodSubFlakes handles all of this...
    goodSubFlakes = initGoodSubFlakes(goodSubFlakes);
    allGoodSubFlakes{count_goodflake_arrays} = goodSubFlakes;
    goodFlakeArrays{1,count_goodflake_arrays} = files(i).name;
    % We'll use the second row of goodFlakeArrays to mark when a
    % goodSubFlakes array is updated in allGoodSubFlakes
    goodFlakeArrays{2,count_goodflake_arrays} = 0; 

    % Count the not-empty entries
    for j = 1 : size(goodSubFlakes, 1)
        if isempty(goodSubFlakes{j,1})
            break;
        end
    end
    numGoodFlakes = j - 1;
    goodDatesIndices = [goodDatesIndices ; cell(numGoodFlakes, 3)]; %#ok<AGROW>

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
                '\tformat. The format is documented in cp3g_interactive_masclab,\n' ...
                '\twithin the MASC-SPECIFIC FORMATTING cell. No data was modified\n' ...
                '\tduring the course of this action.\n']);
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
        goodDatesIndices{count_allflakes, 1} = d;

        % Add index into goodSubFlakes (which will be stored in allGoodSubFlakes)
        goodDatesIndices{count_allflakes, 2} = j;

        % Add index to cell array within allGoodSubFlakes
        goodDatesIndices{count_allflakes, 3} = count_goodflake_arrays;

    end
    
end
clear d i j startindex endindex filename files numGoodFlakes goodSubFlakes
fprintf('done.\n\n');


end

