function [ selection_id, selection_path ] = user_select_cachedpath()
%USER_SELECT_CACHEDPATH Prompt user to selected a cached path for processing/analysis
%   @return <int> The integer of the selected cached path, or -1 if no
%       selection or error.

%% Necessary constant / function
NUM_CACHEDPATHS = length(dir('cache/cached_paths_*'));
    function [isValid] = validate_selection(s)
        sid = str2double(s);
        isValid = 1;
        if isempty(sid), isValid = 0;
        elseif sid < 1, isValid = 0;
        elseif sid > NUM_CACHEDPATHS, isValid = 0;
        end
    end

%% Main
disp('Enter the number next to the path you want to select for processing.')
disp('Cached Paths:')
cached_paths = cell(NUM_CACHEDPATHS,1);
for i = 1 : NUM_CACHEDPATHS
    cached_paths{i} = get_cachedpath(i);
    fprintf('(%i) "%s"\n', i, cached_paths{i});
end
s = input('Type your selection and hit enter: ', 's');
while ~validate_selection(s)
    disp(['Invalid input. Must be between 1 and ' num2str(NUM_CACHEDPATHS) '.'])
    s = input('Type your selection and hit enter: ', 's');
end

%% Return
selection_id = str2double(s);
selection_path = cached_paths{selection_id};

end

