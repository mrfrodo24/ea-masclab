function cachedDataToFLAKEtxt( settings )
%CACHEDDATATOFLAKETXT Read goodSubFlakes to FLAKE txt files for Snowflake DB
%   
%   SUMMARY:
%       The Snowflake Database (Snowflake DB/SDB) is a software product
%       created by the CP3G research group to compile data from multiple
%       meteorological instruments into one centralized database. The
%       records from the various instruments can be cross-referenced
%       according to datetime. Currently, the supported data sources are
%       MET, MicroRain Radar (MRR), and the MASC. The MASC data is divided
%       into two separate tables, MASC and FLAKE. FLAKE data consists of
%       all the image processing statistics gathered for each snowflake
%       image.
%
%       The purpose of this function is to write out a txt file of the FLAKE
%       data which can be parsed by the SDB server app and ingested into
%       the database.
%
%   INPUTS:
%       settings - A struct of all the settings defined in pre-processing
%
%   OUTPUTS: None
%

% IMPORTANT: This is the list of identifiers for the columns that are 
% written to the FLAKE txt file for ingesting into the SDB.
% 
% This may change as modules are added or modified...
%
FLAKE_WRITE_STRING = [ ...
    '%s\t' ... % DateTime (yyyy-mm-dd HH:MM:SS)
    '%s\t' ... % Milliseconds (FFF)
    '%s\t' ... % Site Name
    '%s\t' ... % Station Name
    '%s\t' ... % Fall Speed
    '\\N\t' ... % Mass
    '%s\t' ... % Max Diameter
    '%s\t' ... % Equivalent Radius
    '%s\t' ... % Perimeter
    '%s\t' ... % Cross Section
    '%s\t' ... % Aspect Ratio
    '%s\t' ... % Complexity
    '\\N\t' ... % Flake Angle
    '%s\t' ... % Focus
    '\\N\t' ... % Focus Variability
    '\\N\t' ... % Max Area Focus
    '\\N\t' ... % High Focus
    '\\N\t' ... % Accepted Flakes
    '\\N\t' ... % Total Particles
    '\\N\t' ... % Range Intensity
    '\\N\t' ... % Habit
    '\\N\t' ... % Location of flake from bottom
    '\\N\t' ... % Good Velocity
    '\\N\t' ... % # of Cameras that Pass
    '\\N\t' ... % No Flakes
    '\\N\t' ... % Pretty Flakes
    '\\N\t' ... % Part Area
    '\\N\t' ... % Part Cross-Section
    '\\N\t' ... % Three Good Images
    '\\N\t' ... % Flake Angle Variability
    '\\N\t' ... % Aspect Ratio Variability
    '\\N\t' ... % Flake Height Variability
    '\\N\t' ... % Low Total Flakes
    '\\N\t' ... % Volume
    '%s\t' ... % Total Pores
    '%s\t' ... % Mean Pore Area
    '%s\t' ... % Symmetry
    '%s\t' ... % Frac
    '%s\t' ... % Mean Intensity
    '%s\t' ... % Solidity
    '%s\t' ... % Radial Variance
    '%s\t' ... % Roughness (Col. 23)
    '%s\t' ... % Corners
    '%s\t' ... % Concave Number
    '\n' ... % END LINE
];

% CONSTANTS
% Some constants that should really never change
IMAGE_DATE_FORMAT = 'yyyy.mm.dd_HH.MM.SS';
LENGTH_IMAGE_DATE = length(IMAGE_DATE_FORMAT);
path = [settings.pathToFlakes 'cache/FLAKEtxt/'];
if ~isdir(path)
    mkdir(path);
end

% Check for required settings
if ~isfield(settings, 'siteName') || isempty(settings.siteName)
    disp('Could not export Flake txt file:')
    fprintf('\tsiteName either missing or undefined in general parameters.\n\n');
    return;
   
elseif ~isfield(settings, 'cameraName') || isempty(settings.cameraName)
    disp('Could not export Flake txt file:')
    fprintf('\tcameraName either missing or undefined in general parameters.\n\n');
    return;
end

% Use this to track which hourly text file we're on
curdate = 0;
fwid = -1;

% Loop through goodflakes, printing daily txt files where the day is within
% the specified date range
goodFlakesCounter = 0;
while exist([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'],'file')
    
    % Load the goodSubFlakes
    fprintf('Loading data from file data%i_goodflakes.mat in cache...', goodFlakesCounter);
    load([settings.pathToFlakes 'cache/data' num2str(goodFlakesCounter) '_goodflakes.mat'], ...
        'goodSubFlakes')
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
            fprintf('Setting date of record to 0 so it''s not processed...\n');
            dates(j) = 0;
            continue;
        else
            timestampAndIds = timestampAndIds{1};
        end
                
        % Add date
        dates(j) = datenum(timestampAndIds(1 : LENGTH_IMAGE_DATE - 1), ...
            IMAGE_DATE_FORMAT);

    end
    clear timestampAndIds 
    
    numFlakesToProcess = length(find(dates >= settings.datestart & ...
                                 dates <= settings.dateend));
    % Check if no flakes in date range to process
    if numFlakesToProcess == 0
        fprintf(['No flakes in the loaded data that are within the specified\n' ...
            'date range. Skipping to next good flake data...\n']);
        goodFlakesCounter = goodFlakesCounter + 1;
        continue;
    end
    
    % If code makes it here, then it has some flakes within date range that
    % will be output to a daily text file...
    
    for j = 1 : length(dates)
        if settings.datestart <= dates(j) && dates(j) <= settings.dateend
            % dates(j) is within date range
            if ~strcmp(datestr(curdate,'yyyymmdd'), datestr(dates(j),'yyyymmdd'))
                % Need to start a new daily text file
                curdate = dates(j);
                if fwid > 0
                    % File currently open, so close it
                    fclose(fwid);
                end
                % Open new hourly text file
                fwid = fopen([path 'particle_' settings.siteName '_' ...
                    datestr(curdate, 'yyyymmdd') '.txt'], 'w');
                fprintf('Writing txt file for %s\n', datestr(curdate,'yyyy/mm/dd'));
            end
            
            % Have to load variables first to check if they're NaN or empty
            num_pores = goodSubFlakes{j,9};
            solidity = goodSubFlakes{j,10};
            radial_variance = goodSubFlakes{j,11};
            mean_intens = goodSubFlakes{j,13};
            fractured = goodSubFlakes{j,14};
            focus = goodSubFlakes{j,15};
            max_diam = goodSubFlakes{j,16};
            perim = goodSubFlakes{j,17};
            xsec = goodSubFlakes{j,18};
            req = goodSubFlakes{j,19};
            complexity = goodSubFlakes{j,20};
            aspectratio = goodSubFlakes{j,21};
            roughness = goodSubFlakes{j,23};
            corners = goodSubFlakes{j,24};
            concave_num = goodSubFlakes{j,25};
            fallspeed = goodSubFlakes{j,26};
            
            if isempty(num_pores) || isnan(num_pores)
                num_pores = '\N';
            end
            if isempty(solidity) || isnan(solidity)
                solidity = '\N';
            end
            if isempty(radial_variance) || isnan(radial_variance)
                radial_variance = '\N';
            end
            if isempty(mean_intens) || isnan(mean_intens)
                mean_intens = '\N';
            end
            if isempty(fractured) || isnan(fractured)
                fractured = '\N';
            end
            if isempty(focus) || isnan(focus)
                focus = '\N';
            end
            if isempty(max_diam) || isnan(max_diam)
                max_diam = '\N';
            end
            if isempty(perim) || isnan(perim)
                perim = '\N';
            end
            if isempty(xsec) || isnan(xsec)
                xsec = '\N';
            end
            if isempty(req) || isnan(req)
                req = '\N';
            end
            if isempty(complexity) || isnan(complexity)
                complexity = '\N';
            end
            if isempty(aspectratio) || isnan(aspectratio)
                aspectratio = '\N';
            end
            if isempty(roughness) || isnan(roughness)
                roughness = '\N';
            end
            if isempty(corners) || isnan(corners)
                corners = '\N';
            end
            if isempty(concave_num) || isnan(concave_num)
                concave_num = '\N';
            end
            if isempty(fallspeed) || isnan(fallspeed)
                fallspeed = '\N';
            end
            
            % Print to file
            fprintf(fwid, FLAKE_WRITE_STRING, ...
                datestr(dates(j), 'yyyy-mm-dd HH:MM:SS'), ...
                datestr(dates(j), 'FFF'), ...
                settings.siteName, ...
                settings.cameraName, ...
                num2str(fallspeed, '%.3f'), ...
                num2str(max_diam, '%.3f'), ...
                num2str(req, '%.3f'), ...
                num2str(perim, '%.3f'), ...
                num2str(xsec, '%.3f'), ...
                num2str(aspectratio, '%.3f'), ...
                num2str(complexity, '%.3f'), ...
                num2str(focus, '%.3f'), ...
                num2str(num_pores), ...
                '\N', ... % No mean pore area
                '\N', ... % No symmetry
                num2str(fractured, '%.3f'), ...
                num2str(mean_intens, '%.3f'), ...
                num2str(solidity, '%.3f'), ...
                num2str(radial_variance, '%.3f'), ...
                num2str(roughness, '%.3f'), ...
                num2str(corners, '%.0f'), ...
                num2str(concave_num, '%.3f'));
        end
    end
                
    goodFlakesCounter = goodFlakesCounter + 1;

end

fclose('all'); % Make sure all files are closed

