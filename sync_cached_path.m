function [ imgsAdded ] = sync_cached_path( path, settings )
%SYNC_CACHED_PATH Summary of this function goes here
%
%   INPUTS:
%       path - The # of the cached path to sync
%       settings - Must contain mascImgRegPattern
%
%   OUTPUTS:
%       status - 0 on success, 1 on failure
%

%% Change path to the full path to the cached_paths_* folder
path = ['cache/cached_paths_' num2str(path) '/'];

%% Get list of files
imgFilter = @(d) isempty(regexp(d.name,'CROP_CAM')) && isempty(regexp(d.name,'UNCROP_CAM')) && isempty(regexp(d.name,'TRIPLETS')) && isempty(regexp(d.name,'REJECTS')); 
disp('Searching for PNGs...')
if contains(pwd, '\')
    path = ['cache\cached_paths_' num2str(path) '\'];
    files = rdir([path '**\*.png'], imgFilter, path);
else
    path = ['cache/cached_paths_' num2str(path) '/'];
    files = rdir([path '**/*.png'], imgFilter, path);
end

%% Open new file sync.txt
fid_sync = fopen([path 'sync.txt'], 'w');

%% Loop through current set of cached images
j = 1; % iterator for `files`
numWritten = 0;
imgsAdded = 0;
for i = 1:length(dir([path 'f*.txt']))
    copyfile([path 'f' num2str(i) '.txt'], [path 'sync_bak_f' num2str(i) '.txt']);
    fid_old = fopen([path 'sync_bak_f' num2str(i) '.txt']);
    oldLine = fgets(fid_old);
    while oldLine ~= -1
        % Check if old row matches current img file.
        % If not, add new file to sync.txt and go to next file
        % Otherwise, add oldLine to sync.txt and go to next line and next file
        imgf = regexp(files(j).name, settings.mascImgRegPattern, 'match');
        if length(imgf) ~= 1
            disp(['Corrupted file name: ' files(j).name])
            j = j + 1;
            continue;
        else
            imgf = imgf{1};
        end
        
        % End the file if it's getting too big
        if numWritten == 500
            fclose(fid_sync);
            movefile([path 'sync.txt'], [path 'f' num2str(i) '.txt']);
            fid_sync = fopen([path 'sync.txt'], 'w');
            numWritten = 0;
        end
        
        if ~contains(oldLine, imgf)
            fprintf(fid_sync, '%s\t1\t0\t0\t0\t0\n', imgf);
            imgsAdded = imgsAdded + 1;
        else
            fprintf(fid_sync, '%s', oldLine);
            oldLine = fgets(fid_old);
        end
        numWritten = numWritten + 1;
        j = j + 1;
    end
    fclose(fid_old);
end

end

