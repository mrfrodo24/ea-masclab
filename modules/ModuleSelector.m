function [modules] = ModuleSelector ( modules, settings )
% MODULESELECTOR Allow user to select the modules they wish to run in EA MascLab.
%
%   SUMMARY:
%       Let users pick the modules they want to run.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Module Selection

fprintf(['You will now be shown each available module... For each one,\n' ...
    '\tindicate whether you would like to run it on the flakes within the\n' ...
    '\tdate range you specified in pre-processing:\n\n']);
disp('%%% MODULES %%%')
% Loop backwards through modules cell array so we can remove elements from
% the array as we go whenever user says they don't want to run a module.
i = 1;
while i <= length(modules)
    s = input(['Would you like to run "', modules{i}, '" (y/n): '], 's');
    while s ~= 'y' && s ~= 'n'
        disp('Invalid input...')
        s = input(['Would you like to run "', modules{i}, '" (y/n): '], 's');
    end
    if s == 'n'
        % User does not want to run the module, so remove it from the list
        modules(i) = [];
    else
        i = i + 1;
    end
end

%% Module Dependency Check
% Essentially, we'll check if we need to reorder the module execution
% order, which we would want to do so that modules which depend on another
% are run after the other.

disp('Checking module dependencies defined in ModuleInputHandler')
% Load the first goodSubFlakes, just to see if some data is already there
load([settings.pathToFlakes 'cache/data0_goodflakes.mat'], 'goodSubFlakes')

i = length(modules);
while i > 0
    [~,dependencies,~] = ModuleInputHandler(modules{i},0,0,2);
    if isempty(dependencies)
        i = i - 1;
        continue;
    end
    for j = 1 : length(dependencies)
        % First see if module dependent is in modules. If so, then user
        % inevitably wants to use the data from the child module in this
        % run, so we'll move the child module ahead if necessary
        foundModule = 0;
        for k = 1 : length(modules)
            if strcmp(modules{k}, dependencies{j})
                % Found module
                if k > i
                    % Dependee module moved ahead of dependent
                    modules = [modules(1:i-1) modules(k) modules(i:k-1) modules(k+1:end)];
                    % Keep index on dependent
                    i = i + 1;
                else
                    % Module loaded and does not need to be moved
                end
                foundModule = 1;
                break;
            end
        end
        if ~foundModule
            % Module was not loaded by user...
            
            % First, check if module has been executed before... To do
            % this we'll have to call ModuleOutputHandler to get the child
            % module's columns in goodSubFlakes so we can check if they are
            % empty.
            module_output_indices = ModuleOutputHandler(dependencies{j}, 0);
            [verified,~,~] = ModuleInputHandler(dependencies{j},0,0,1);
            
            % Check that module is supported
            if isempty(module_output_indices) || ~verified
                % If not, then the referenced dependent module is
                % incorrect. Tell the user to fix the problem and then try
                % running the module again later.
                disp('! Error !')
                fprintf(['\tYou declared %s MODULE''s output as a dependency of %s\n' ...
                        '\tMODULE. However, %s MODULE was not verified according\n' ...
                        '\tto module handlers. Please make sure you set the output\n' ...
                        '\tcolumns for the module in ModuleOutputHandler (and initGoodSubFlakes),\n' ...
                        '\tor verify that you set the correct dependency. Removing module from\n' ...
                        '\tqueue and continuing...'], ...
                        dependencies{j}, modules{i}, dependencies{j});
                modules(i) = [];
                clear verified
                
            % Module is verified, so check if it's been run (i.e. if we
            % have some cached data from the module that could be used for
            % this module run)
            else
                clear verified
                moduleBeenRun = 0;
                % Check if goodSubFlakes has data for module
                % dependency, that way user can optionally not run the
                % dependency if dependency already has data.
                if exist('goodSubFlakes','var')
                    if ~isempty(goodSubFlakes{1,module_output_indices(1)}) %#ok<NODEF>
                        moduleBeenRun = 1;
                    end
                end
                
                if ~moduleBeenRun
                    % If the child module hasn't been run and the user didn't
                    % select it, we'll simply ask the user if they want to
                    % add dependencies(j) to just before modules(i) OR ELSE
                    % remove modules(i) entirely
                    disp('! Warning - Action Required !')
                    s = '';
                    fprintf(['\tYou did not select %s MODULE, which is required for %s MODULE.\n' ...
                            '\tWould you like to run %s MODULE just before %s MODULE (Y), or\n' ...
                            '\tnot run either of the MODULEs (n)?\n'], ...
                            dependencies{j}, modules{i}, dependencies{j}, modules{i});
                    while isempty(s) || (s ~= 'Y' && s ~= 'n')
                        if ~isempty(s)
                            fprintf('\tInvalid input!\n');
                        end
                        fprintf('\t')
                        s = input('Enter (Y) for yes or (n) for no: ', 's');
                    end
                    
                    if s == 'Y'
                        % User chose to run dependency before module(s)
                        modules = [modules(1:i-1) dependencies(j) modules(i:end)];
                        i = i + 1;
                    else
                        % User chose to remove module from list
                        modules(i) = [];
                    end
                    
                else
                    % If child module has been run before, just tell user
                    % that they didn't select the module dependency and ask
                    % them if they would like to.
                    disp('! Alert !')
                    s = '';
                    fprintf(['\tYou did not select %s MODULE, which is required for %s MODULE.\n' ...
                            '\tHowever, it seems that you have run %s MODULE before. So,\n' ...
                            '\twould you like to run %s MODULE just before %s MODULE (1), or\n' ...
                            '\tcontinue as is and let %s MODULE use the cached data from a\n' ...
                            '\tprevious run (2)?\n'], ...
                        dependencies{j}, modules{i}, dependencies{j}, ...
                        dependencies{j}, modules{i}, modules{i});
                    
                    while isempty(s) || (s ~= '1' && s ~= '2')
                        if ~isempty(s)
                            fprintf('\tInvalid input!\n');
                        end
                        fprintf('\t')
                        s = input('Enter 1 or 2 to indicate your selection: ', 's');
                    end
                    
                    if s == '1'
                        % User chose to add the dependency
                        modules = [modules(1:i-1) dependencies(j) modules(i:end)];
                        i = i + 1;
                    else
                        % User chose to let the module use the old cached
                        % data from a previous run of the dependency.
                    end
                    
                end
                        
            end
        end
    end
    i = i - 1;
end
% Finished checking dependencies
disp('Finished processing dependencies!')
clear goodSubFlakes

fprintf('\n');