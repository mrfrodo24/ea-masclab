% DEPRECATED

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script was built to allow running of Module functionality in a     %
% way such that you can stop the process at any time and resume it        %
% seamlessly when restarting Matlab.                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
% Make sure all necessary paths are added
addpath(genpath('./cache'))
addpath(genpath('./utils'))

% SET AN EMAIL ADDRESS TO GET AN EMAIL IF A FATAL ERROR OCCURS (TODO)
email = 'spencer.rhodes2@gmail.com';

% First load settings
load('cache/gen_params/last_parameters.mat')

% Specify an additional settings field that will tell ModuleRunner to stop
% after processing 20 cache files.
% Also, select the modules you're looking to process.
if ~isfield(settings, 'resume_module_proc')
    settings.resume_module_proc = 0;
    settings.remember_modules = ModuleSelector(ModuleFinder);
end

% Call ModuleRunner
try
    settings = ModuleRunner(settings.remember_modules, settings);
catch err
    fprintf('An error occurred. Type ''err'' in the command line to see the exception. Use ''dbcont'' to continue execution, ''dbquit'' to exit execution.')
    keyboard; % Fatal error occurred, so wait for user to come back and see
              % what went wrong before continuing
end

% Increment resume
if isfield(settings, 'resume_module_proc')
    settings.resume_module_proc = settings.resume_module_proc + 2;
    clearvars -except settings
    save('cache/gen_params/last_parameters.mat')
% Otherwise, function is done so quit with 0 status code
else
    exit(0)
end

% Now, quit matlab to release control back to calling script
exit(1)
