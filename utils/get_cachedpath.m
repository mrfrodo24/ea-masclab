function [ pathToFlakes ] = get_cachedpath( id )
%GET_CACHEDPATH Retrieve the Path associated with the id cached_path
%
%   SUMMARY: 
%       This suite maintains a list of cached_paths in the cache directory.
%       Each cached_path_* directory references some directory on the
%       machine where the raw MASC images/data are located.  The references
%       are held in the cache/cached_paths.txt file.
%
%       This routine will retrieve the path to the raw MASC data associated
%       with the cached_path_{id}.
%
%   @param <int> Which cached_path to get the pathToFlakes
%   @return <string> The path to the raw MASC images/data

pathToFlakes = '';
idStr = num2str(id);
if ~isdir('cache') || ~isdir(['cache/cached_paths_' idStr])
    disp(['Error! cache/ folder or cache/cached_paths_' idStr ' does not exist.'])
    return;
end

fid = fopen('cache/cached_paths.txt');
if fid < 0
    disp('Error! Could not open cache/cached_paths.txt file.')
    return;
end

line = fgetl(fid);
for i = 2:id
    % Takes 3 lines to get to each 'Path = ""' line, but check each
    % time in case we reach EOF
    for j = 1:3
        line = fgetl(fid);
        if line == 1
            disp(['Error! There are only ' num2str(length(dir('cache/cached_paths_*'))) ...
                ' cached paths.'])
            fclose(fid);
            return;
        end
    end
end

fclose(fid);
pathToFlakes = line(9:end-1);

end

