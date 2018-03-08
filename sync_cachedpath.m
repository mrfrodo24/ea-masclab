function [ imgsAdded ] = sync_cachedpath( cachedPath, settings )
%SYNC_CACHEDPATH Used to synchronize the original images in a cached path
%
%   SUMMARY:
%       Looks in the path that corresponds to the cachedPath input
%       (given by cache/cached_paths.txt).
%       Sorts the current set of images in the cached path (just in the
%       cache txt files, i.e. cache/cached_paths_X/f*.txt).
%       Gets the set of images in the pathToFlakes to cross-reference
%       with what's already in the cache txt files.
%   
%   NOTES:
%       - Won't overwrite any cropped images
%       - Will update folder references within the pathToFlakes
%           (e.g. If you processed some images and updated the directory
%               structure afterwards, you could resync the cached path
%               to update the folder references in the cache txt files.)
%
%   INPUTS:
%       path - The # of the cached path to sync
%       settings - Must contain mascImgRegPattern
%
%   OUTPUTS:
%       status - 0 on success, 1 on failure
%

%% Masc comparison function
% Returns -1 if s2 comes before s1. 1 if s1 comes before s2. 0 if equal.
function [cmp] = mascCmp(s1, s2)
    if s2.date < s1.date || ...
       s2.imageId < s1.imageId || ...
       (s2.imageId == s1.imageId && s2.camId < s1.camId) 
        cmp = -1;
    elseif s2.date == s1.date && ...
           s2.camId == s1.camId && ...
           s2.imageId == s1.imageId && ...
           s2.particleId == s1.particleId
        cmp = 0;
    else
        cmp = 1;
    end
end

%% Change path to the full path to the cached_paths_* folder
cachedPath = ['cache' filesep 'cached_paths_' num2str(cachedPath) filesep];

%% SORT CACHED PATHS
disp('Preparing old set of images in cached path for syncing')

% For this algorithm to work correctly, both the old set of f*.txt files
% and the list of new images should be sorted.
maxListLength = 1000000;
oldList = cell(maxListLength,1);
oldDirectories = cell(maxListLength,1);
oldCache = cell(maxListLength,6);
oldCounter = 1;
numCacheFiles = length(dir([cachedPath 'f*.txt']));
for i = 1:numCacheFiles
    fprintf(['Fetching from f' num2str(i) '.txt...']);
    fid = fopen([cachedPath 'f' num2str(i) '.txt']);
    fileList = textscan(fid, '%s %s %s %s %s %s');
    fclose(fid);

    filepathList = fileList{1};
    for j = 1:length(filepathList)
        thisFile = filepathList{j};
        filename = regexp(thisFile, settings.mascImgRegPattern, 'match'); filename = filename{1};
        oldDirectories{oldCounter} = thisFile(1:strfind(thisFile,filename)-2);
        oldList{oldCounter} = parse_masc_filename(filename);
        if mod(oldCounter, maxListLength) > maxListLength
            oldList = [oldList; cell(maxListLength,1)]; %#ok<AGROW>
            oldCache = [oldCache; cell(maxListLength,6)]; %#ok<AGROW>
        end
        oldCounter = oldCounter + 1;
    end
    
    listEnd = length(fileList{1});
    for k = 1:6
        oldCache(oldCounter:listEnd,k) = fileList{k}(:);
    end
    fprintf('\n');
end
fprintf('Sorting old image set...');
% Slim down the list to just the non-empty cells, converted to an array (of structs)
unsortedOldList = cell2mat(oldList(~cellfun('isempty', oldList)));
% Now sort it
[oldList, sortedOldIdx] = sort_masc_images(unsortedOldList);
disp('done!')

%% Get list of files
imgFilter = @(d) isempty(regexp(d.name,'CROP_CAM')) && isempty(regexp(d.name,'UNCROP_CAM')) && isempty(regexp(d.name,'TRIPLETS')) && isempty(regexp(d.name,'REJECTS')); 
disp(['Searching for PNGs in ' settings.pathToFlakes ' ...']);
files = rdir([settings.pathToFlakes '**' filesep '*.png'], imgFilter, settings.pathToFlakes);
newList = cell(length(files),1);
newDirectories = cell(length(files),1);
for i = 1:length(files)
    newf = regexp(files(i).name, settings.mascImgRegPattern, 'match');
    if length(newf) ~= 1
        disp(['Corrupted file name: ' files(i).name])
        continue;
    else
        newf = newf{1};
    end
    newDirectories{i} = files(i).name(1:strfind(files(i).name,newf)-2);
    newList{i} = parse_masc_filename(newf);
end
fprintf('Sorting new image set...');
unsortedNewList = cell2mat(newList(~cellfun('isempty', newList)));
[newList, sortedNewIdx] = sort_masc_images(unsortedNewList);
disp('done!')

%% Open new file sync.txt
fid_sync = fopen([cachedPath 'sync.txt'], 'w');

%% Sync
disp('Syncing current image set with cached path image set...')
totalWritten = 0;
filesWritten = 0;
imgsAdded = 0;
numCacheFiles = length(dir([cachedPath 'f*.txt']));
for i = 1:numCacheFiles
    movefile([cachedPath 'f' num2str(i) '.txt'], [cachedPath 'sync_bak_f' num2str(i) '.txt']);
end
oldListLength = length(oldList);
i = 1; % iterator for old/processed image set
j = 1; % iterator for new image set
while i <= oldListLength
    if ~mod(i/oldListLength, 0.1)
        disp([num2str(round(i/oldListLength*100)) '% complete...']);
    end
    ia = sortedOldIdx(i);
    ja = sortedNewIdx(j);
    
    if j <= length(files)
        newf_s = newList{ja};
        newf_dir = newDirectories{ja};
    end
    oldf_s = oldList{ia};
    oldf_dir = oldDirectories{ia};
    
    cmp = mascCmp(newf_s, oldf_s);
    if j > length(files) || cmp <= 0
        % Write the old line so it can catch up to new files
        if j <= length(files) && ~strcmp(newf_dir, oldf_dir)
            % Refresh path in line
            oldCache{ia,1} = strrep(oldCache{ia,1}, oldf_dir, newf_dir);
        end
        fprintf(fid_sync, '%s\t%s\t%s\t%s\t%s\t%s\n', oldCache{ia,:});
        % Also advance j if they were the same, avoids duplicates
        if cmp == 0
            j = j + 1; 
        end
        i = i + 1;
    elseif cmp > 0
        % Brand new file, need to catch up to old files
        newf = regexp(files(ja).name, settings.mascImgRegPattern, 'match'); newf = newf{1};
        fprintf(fid_sync, '%s\t1\t0\t0\t0\t0\n', [newf_dir filesep newf]);
        imgsAdded = imgsAdded + 1;
        j = j + 1;
    else
        totalWritten = totalWritten - 1;
    end
    totalWritten = totalWritten + 1;

    % End the file if it's getting too big
    if totalWritten >= 2500
        fclose(fid_sync); pause(1);
        filesWritten = filesWritten + 1;
        movefile([cachedPath 'sync.txt'], [cachedPath 'f' num2str(filesWritten) '.txt']);
        fid_sync = fopen([cachedPath 'sync.txt'], 'w');
        totalWritten = 0;
    end
end

while j <= length(files)
    ja = sortedNewIdx(j);
    newf = regexp(files(ja).name, settings.mascImgRegPattern, 'match'); newf = newf{1};
    newf_dir = newDirectories{ja};
    fprintf(fid_sync, '%s\t1\t0\t0\t0\t0\n', [newf_dir filesep newf]);
    totalWritten = totalWritten + 1;
           
    % End the file if it's getting too big
    if totalWritten >= 1000
        fclose(fid_sync); pause(1);
        filesWritten = filesWritten + 1;
        movefile([cachedPath 'sync.txt'], [cachedPath 'f' num2str(filesWritten) '.txt']);
        fid_sync = fopen([cachedPath 'sync.txt'], 'w');
        totalWritten = 0;
    end
    imgsAdded = imgsAdded + 1;
    j = j + 1;
end

fclose('all'); pause(1);
if totalWritten > 0
    filesWritten = filesWritten + 1;
    movefile([cachedPath 'sync.txt'], [cachedPath 'f' num2str(filesWritten) '.txt']);
end
    
end

