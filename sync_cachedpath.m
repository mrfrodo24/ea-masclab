function [ imgsAdded ] = sync_cachedpath( cachedPath, settings )
%SYNC_CACHEDPATH Summary of this function goes here
%
%   INPUTS:
%       path - The # of the cached path to sync
%       settings - Must contain mascImgRegPattern
%
%   OUTPUTS:
%       status - 0 on success, 1 on failure
%

%% Change path to the full path to the cached_paths_* folder
cachedPath = ['cache/cached_paths_' num2str(cachedPath) '/'];

%% Get list of files
imgFilter = @(d) isempty(regexp(d.name,'CROP_CAM')) && isempty(regexp(d.name,'UNCROP_CAM')) && isempty(regexp(d.name,'TRIPLETS')) && isempty(regexp(d.name,'REJECTS')); 
disp('Searching for PNGs...')
if strfind(settings.pathToFlakes, '\')
    files = rdir([settings.pathToFlakes '**\*.png'], imgFilter, settings.pathToFlakes);
else
    files = rdir([settings.pathToFlakes '**/*.png'], imgFilter, settings.pathToFlakes);
end

%% Open new file sync.txt
fid_sync = fopen([cachedPath 'sync.txt'], 'w');

%% Loop through current set of cached images
j = 1; % iterator for `files`
totalWritten = 0;
filesWritten = 0;
imgsAdded = 0;
numCacheFiles = length(dir([cachedPath 'f*.txt']));
for i = 1:numCacheFiles
    movefile([cachedPath 'f' num2str(i) '.txt'], [cachedPath 'sync_bak_f' num2str(i) '.txt']);
end
for i = 1:numCacheFiles
    disp(['Going through f' num2str(i) '.txt ...'])
    fid_old = fopen([cachedPath 'sync_bak_f' num2str(i) '.txt']);
    oldLine = fgets(fid_old);
    while oldLine ~= -1
        if j <= length(files)
            % Check if old row matches current img file.
            % If not, add new file to sync.txt and go to next file
            % Otherwise, add oldLine to sync.txt and go to next line and next file
            newf = regexp(files(j).name, settings.mascImgRegPattern, 'match');
            if length(newf) ~= 1
                disp(['Corrupted file name: ' files(j).name])
                j = j + 1;
                continue;
            else
                newf = newf{1};
            end
            oldf = regexp(oldLine, settings.mascImgRegPattern, 'match'); oldf = oldf{1};
            oldf_s = parse_masc_filename(oldf);
            newf_s = parse_masc_filename(newf);
        end
        
        if j > length(files) ...
           || newf_s.date > oldf_s.date ...
           || (newf_s.date == oldf_s.date ...
               && newf_s.imageId >= oldf_s.imageId ...
               && newf_s.camId >= newf_s.camId)
       
            % Write the old line so it can catch up to new files
            if j <= length(files) && length(settings.pathToFlakes) < length(files(j).folder)
                % Refresh path in line
                oldPath = oldLine(1:strfind(oldLine,newf)-2);
                newPath = files(j).folder(length(settings.pathToFlakes)+1:end);
                oldLine = strrep(oldLine, oldPath, newPath);
                clear oldPath newPath;
            end
            fprintf(fid_sync, '%s', oldLine);
            % Also advance newf if they were the same, avoids duplicates
            if newf_s.date == oldf_s.date ...
               && newf_s.imageId == oldf_s.imageId ...
               && newf_s.camId == newf_s.camId
                j = j + 1; 
            end
            oldLine = fgets(fid_old);
            
        elseif newf_s.date < oldf_s.date ...
           || (newf_s.date == oldf_s.date ...
               && newf_s.imageId <= oldf_s.imageId ...
               && newf_s.camId < oldf_s.camId)
       
            % append directory to imgf, if nec.
            if length(settings.pathToFlakes) < length(files(j).folder)
                newf = [files(j).folder(length(settings.pathToFlakes)+1:end) '/' newf]; %#ok<AGROW>
            end
            fprintf(fid_sync, '%s\t1\t0\t0\t0\t0\n', newf);
            imgsAdded = imgsAdded + 1;
            j = j + 1;
        end
        
        totalWritten = totalWritten + 1;
           
        % End the file if it's getting too big
        if totalWritten == 2500
            fclose(fid_sync); pause(1);
            filesWritten = filesWritten + 1;
            movefile([cachedPath 'sync.txt'], [cachedPath 'f' num2str(filesWritten) '.txt']);
            fid_sync = fopen([cachedPath 'sync.txt'], 'w');
            totalWritten = 0;
        end
    end
    fclose(fid_old);
end

while j <= length(files)
    % append directory to imgf, if nec.
    if length(settings.pathToFlakes) < length(files(j).folder)
        newf = [files(j).folder(length(settings.pathToFlakes)+1:end) '/' newf]; %#ok<AGROW>
    end
    fprintf(fid_sync, '%s\t1\t0\t0\t0\t0\n', newf);
    imgsAdded = imgsAdded + 1;
    j = j + 1;
    
    totalWritten = totalWritten + 1;
           
    % End the file if it's getting too big
    if totalWritten == 1000
        fclose(fid_sync);
        movefile([cachedPath 'sync.txt'], [cachedPath 'f' num2str(i) '.txt']);
        fid_sync = fopen([cachedPath 'sync.txt'], 'w');
        totalWritten = 0;
    end
end

if totalWritten > 0
    fclose(fid_sync);
    movefile([cachedPath 'sync.txt'], [cachedPath 'f' num2str(numCacheFiles) '.txt']);
end

end

