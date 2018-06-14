% Script to process statistics from all flakes
% Do separate stats for good and all

if ~exist('settings', 'var')
	load('cache/gen_params/last_parameters.mat')
end

%% Number of particles detected per minute
% Compute a value for each camera (0,1,2) and if more than one image in a second, 
% average across images in that second and then sum image count per minute
dates = settings.datestart : (1/1440) : settings.dateend;
goodPerMin = nan(length(dates),3);
allPerMin = goodPerMin;

%% Average particle perimeter per minute
goodPerim = goodPerMin;
allPerim = allPerMin;

%% Particle size distribution per half-hour (maybe just per hour later)
% Store variable with size bins and another 2-D array with columns corresponding
% to bins and rows being the records through time.
bins = 0;


%% RUN STATS
% Loop through all stats first
allflakes_counter = 0;
% var to track the # of particles counted per second in a given minute
temp_particles = zeros(60,3);
% var to track the # of raw images obtained per second in a given minute
temp_raws = zeros(60,3);
% index into dates array for the current minute being summed
minuteId = 0;
% var to track which minute (datenum) we're aggregating
curMinute = settings.datestart - 1;
% used within loop to signal to change curMinute
newMinute = 0;
% used within loop to signal to aggregate the current record with the
% current minute
addToMinute = 0;
% curMasc is used to make sure we don't double count the same raw image
% stats
curMasc.date = settings.datestart - 1;
curMasc.imageId = 0;
curMasc.particleId = 0;
curMasc.camId = -1;
% difference for a minute
epsilon = 59/60/1440;
pathToCacheData = [settings.pathToFlakes 'cache/'];
cacheFile = ['data' num2str(allflakes_counter) '_allflakes.mat'];
while exist([pathToCacheData cacheFile], 'file')

	fprintf('Loading %s...', cacheFile);
	load([pathToCacheData cacheFile])
	fprintf('done!\n');
	fprintf('Computing stats...');

	for i = 1 : length(subFlakes)

        if isempty(subFlakes{i,1})
            break;
        end

		timestampAndIds = regexp(subFlakes{i,1}, settings.mascImgRegPattern, 'match');
		if length(timestampAndIds) ~= 1
			% Skip the incorrectly formatted filename
			continue;
		end
		masc = parse_masc_filename(timestampAndIds{1});

		if abs(curMinute - masc.date) > epsilon
			% Whatever record we're at in subFlakes (i), we know that
			% it's a different minute than what we've been at (curMasc)
			newMinute = 1;

        else
			% Current record is in the same minute

			% Now, within the same minute we need to average by second
			if curMasc.date == masc.date && ...
			   curMasc.camId == masc.camId && ...
			   curMasc.imageId == masc.imageId
			    % From same raw image
			    addToMinute = 0;
			else
				addToMinute = 1;
            end
        end

		if newMinute && sum(temp_raws(:)) > 0 && minuteId > 0
			temp_particle_avg = temp_particles ./ temp_raws;
			temp_particle_avg(isinf(temp_particle_avg)) = NaN;
			allPerMin(minuteId,:) = nansum(temp_particle_avg);
        end
        if newMinute
			temp_particles = zeros(60,3);
			temp_raws = temp_particles;
			curMinute = datenum(datestr(masc.date,'yyyymmddHHMM'),'yyyymmddHHMM');
			minuteId = find(curMinute == dates);
			addToMinute = 1;
            newMinute = 0;
		end
		if addToMinute
			secondId = floor(second(masc.date)) + 1;
			temp_particles(secondId, masc.camId+1) = temp_particles(secondId, masc.camId+1) + subFlakes{i,7};
			temp_raws(secondId, masc.camId+1) = temp_raws(secondId, masc.camId+1) + 1;
			curMasc = masc;
            addToMinute = 0;
		end	

	end

	fprintf('done!\n\n');

	clear subFlakes
	allflakes_counter = allflakes_counter + 1;
	cacheFile = ['data' num2str(allflakes_counter) '_allflakes.mat'];
end

%% Post-processing
% Only get the dates with data
emptyRows = sum(isnan(allPerMin),2) == 3;
dates(emptyRows) = [];
allPerMin(emptyRows,:) = [];
allPerMin(isnan(allPerMin)) = 0;