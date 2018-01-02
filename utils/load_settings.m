% Script to load cp3g-masclab settings
%
% Use optional setting to pre-select a cached path for processing
if exist('CACHED_PATH_SELECTION', 'var')
    load(['cache/cached_paths_' num2str(CACHED_PATH_SELECTION) '/last_parameters.mat'])
else
    load('cache/gen_params/last_parameters.mat')
    if exist('CACHED_PATH_SELECTION', 'var')
        load(['cache/cached_paths_' num2str(CACHED_PATH_SELECTION) '/last_parameters.mat'])
    end
end

fprintf('Selected path to flakes: %s\n\n', settings.pathToFlakes);