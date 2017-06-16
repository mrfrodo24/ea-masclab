function cachedDataToCSV( settings )
%CACHEDDATATOCSV Summary of this function goes here
%   Detailed explanation goes here

% CONSTANTS
% Some constants that should really never change
IMAGE_DATE_FORMAT = 'yyyy.mm.dd_HH.MM.SS';
LENGTH_IMAGE_DATE = length(IMAGE_DATE_FORMAT);
path = [settings.pathToFlakes 'cache/CSVtxt/'];
if ~isdir(path)
    mkdir(path);
end

% We'll go through goodSubFlakes and add each column to the CSV file (AS
% LONG AS THE COLUMN IS A SINGLE VALUE!) The only array that will be
% allowed in the CSV file is going to be a character array (STRING).

% Open a file for writing
fwid = fopen([path 'goodflakes.csv'], 'w');

% Loop through goodflakes, continuing to add to the same CSV file the whole
% time.
goodFlakesCounter = 0;
while exist([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'],'file')
    
    % Load the goodSubFlakes
    fprintf('Loading data from file data%i_goodflakes.mat in cache...', goodFlakesCounter);
    load([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'])
    fprintf('done.\n');
    
    % Make sure goodSubFlakes exists (if not, error)
    if ~exist('goodSubFlakes', 'var')
        % Not a valid goodflakes mat file
        fprintf('Encountered good flakes file without correct variable(s). Skipping...');
        goodFlakesCounter = goodFlakesCounter + 1;
        continue;
    end
    
    % Count the not-empty entries
    for j = 1 : size(goodSubFlakes, 1)  %#ok<USENS>
        if isempty(goodSubFlakes{j,1})
            break;
        end
    end
    numGoodFlakes = j - 1;
    
    % Initialize variable that will hold the timestamp for each flake
    % indexed in goodSubFlakes
    dates = zeros(numGoodFlakes,1);
    
    % Here, we want to go through and calculate a datenum for each of
    % the good flakes. We'll store these datenums in a separate array,
    % which will also hold the flake ID and the reference to the
    % goodSubFlakes array it exists in.
    for j = 1 : numGoodFlakes

        % Add date
        filepath = goodSubFlakes{j,1};
        startindex = find(filepath == '/', 1, 'last');
        if isempty(startindex)
            startindex = find(filepath == '\', 1, 'last');
        end
        dates(j) = datenum(filepath(startindex + 1 : startindex + LENGTH_IMAGE_DATE), ...
            IMAGE_DATE_FORMAT);

    end
    clear d startindex endindex filename
    
    numFlakesToProcess = length(find(dates >= settings.datestart & ...
                                 dates <= settings.dateend));
    % Check if no flakes in date range to process
    if numFlakesToProcess == 0
        fprintf(['No flakes in the loaded data that are within the specified\n' ...
            'date range. Skipping to next good flake data...\n']);
        goodFlakesCounter = goodFlakesCounter + 1;
        continue;
    end
    
    disp('Writing good flake data to CSV')
    for j = 1 : length(dates)
        if settings.datestart > dates(j) || dates(j) > settings.dateend
            % Dates(j) is not inside the date range
            continue;
        end
        
        % First print the good sub flake's filename
        fprintf(fwid, '''%s'', ', goodSubFlakes{j,1});
        
        % Go through columns of goodSubFlakes to print data to CSV file
        % Start with k = 6 since that's the perimeter (as given by
        % scan/crop function)
        for k = 6 : size(goodSubFlakes, 2)
            
            % The following if statements only accept strings or single
            % values
            if ischar(goodSubFlakes{j,k})
                fprintf(fwid, '%s', goodSubFlakes{j,k});
                
            elseif isscalar(goodSubFlakes{j,k})
                fprintf(fwid, '%.4f', goodSubFlakes{j,k});
                
            elseif k == size(goodSubFlakes, 2)
                % goodSubFlakes{j,k} is not acceptable for putting into CSV
                % file. However, if k is the last column, then we need to
                % print \n before we can continue
                fprintf(fwid, '\n');
                continue;
            end
            
            if k == size(goodSubFlakes, 2)
                % End of the line
                fprintf(fwid, '\n');
            else
                % Place a comma and space
                fprintf(fwid, ', ');
            end
            
        end
        
    end
    goodFlakesCounter = goodFlakesCounter + 1;

end

disp('Finished!')
fclose('all');
    
end

