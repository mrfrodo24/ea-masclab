function [modules] = ModuleSelector ( modules )
% MODULESELECTOR Summary of this function goes here
%
%   SUMMARY:
%       Let users pick the modules they want to run.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(['You will now be shown each available module... For each one,\n' ...
    '\tindicate whether you would like to run it on the flakes within the\n' ...
    '\tdate range you specified in pre-processing:\n\n']);
disp('%%% MODULES %%%')
% Loop backwards through modules cell array so we can remove elements from
% the array as we go whenever user says they don't want to run a module.
for i = length(modules) : -1 : 1
    s = input(['Would you like to run "', modules{i}, '" (Y/n): '], 's');
    while s ~= 'Y' && s ~= 'n'
        disp('Invalid input...')
        s = input(['Would you like to run "', modules{i}, '" (Y/n): '], 's');
    end
    if s == 'n'
        % User does not want to run the module, so remove it from the list
        modules(i) = [];
    end
end
% What's left in modules cell array at this point are the modules that will
% be run!
fprintf('\n');