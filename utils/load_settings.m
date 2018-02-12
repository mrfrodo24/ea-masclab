function [ settings, selection, define ] = load_settings()
%LOAD_SETTINGS load cp3g-masclab settings
%
%   Prompts user to select a cached path to load settings from/into
%
settings = struct;
define = 0;
[selection_id, selection_path] = user_select_cachedpath();
last_params = ['cache/cached_paths_' num2str(selection_id) '/last_parameters.mat'];
if ~exist(last_params, 'file')
    fprintf(['WARNING! Parameters need to be defined!\n' ...
        'The file %s was not found.\n'], ...
        last_params);
    define = 1;
else
    load(last_params)
    fprintf('Selected path to flakes: %s\n\n', settings.pathToFlakes);
end

selection.id = selection_id;
selection.path = selection_path;

end