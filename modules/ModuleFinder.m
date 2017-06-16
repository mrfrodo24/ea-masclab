function [ modules ] = ModuleFinder
%MODULEFINDER This function searches the core for all registered modules.
%
%   SUMMARY:
%       In addition to finding all the modules in core, it will also then
%       look for the registered modules in ModuleInputHandler and
%       ModuleOutputHandler. If it does not find the module in one of
%       those, the module will not be returned as a runnable module.
%
%   INPUTS: None
%
%   OUTPUTS:
%       modules - Cell array of strings of the modules that can be ran
%

% Initialize modules
modules = {};

% Get files in core directory
files = dir('modules/core/');
counter = 1;
for i = 1 : length(files)
    filename = files(i).name;
    if strcmp(filename, '.') || strcmp(filename, '..') || ...
       strcmp(filename, 'ModuleInterface.m') || ...
       isempty(strfind(filename(end-1:end), '.m')) || files(i).isdir
        % Don't add files that satisfy these conditions, not a module
        continue;
    end
    moduleName = strrep(filename, '.m', '');
    
    % Verify the module is supported in ModuleInputHandler and
    % ModuleOutputHandler
    [verified,~,~] = ModuleInputHandler(moduleName,0,0,1);
    if ~verified
        fprintf(['MODULE - "%s" is not supported in ModuleInputHandler. ' ...
            'Not authorized for running.\n'], moduleName);
        continue;
    elseif ~ModuleOutputHandler(moduleName, 1)
        fprintf(['MODULE - "%s" is not supported in ModuleOutputHandler. ' ...
            'Not authorized for running.\n'], moduleName);
        continue;
    end
    
    % Add file to modules
    modules{counter} = strrep(filename, '.m', ''); %#ok<AGROW>
    counter = counter + 1;
end

end