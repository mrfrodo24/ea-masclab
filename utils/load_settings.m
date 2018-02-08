function [ settings, CACHED_PATH_SELECTION ] = load_settings()
%LOAD_SETTINGS load cp3g-masclab settings
%
% Use optional setting to pre-select a cached path for processing
settings = struct;
if exist('CACHED_PATH_SELECTION', 'var')
    load(['cache/cached_paths_' num2str(CACHED_PATH_SELECTION) '/last_parameters.mat']) %#ok<NODEF>
else
    load('cache/gen_params/last_parameters.mat')
    if exist('CACHED_PATH_SELECTION', 'var')
        load(['cache/cached_paths_' num2str(CACHED_PATH_SELECTION) '/last_parameters.mat']) %#ok<NODEF>
    else
        CACHED_PATH_SELECTION = -1;
    end
end

fprintf('Selected path to flakes: %s\n\n', settings.pathToFlakes);

end