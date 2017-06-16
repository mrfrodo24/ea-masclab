%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script was built to allow running of Scan & Crop functionality in  %
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

% Specify an additional settings field that will tell Scan & Crop to stop
% after processing 20 cache files
if ~isfield(settings, 'resume')
    settings.resume = 1;
end
settings.pause = 1;

% Call Scan & Crop
try
    status = detect_crop_filter_original(settings);
catch err
    keyboard; % Fatal error occurred, so wait for user to come back and see
              % what went wrong before continuing
end

% Increment resume
settings.resume = settings.resume + 20;

% Save the settings with new "resume", but not "pause"
settings = rmfield(settings, 'pause'); %#ok<*NASGU>
clearvars -except settings
save('cache/gen_params/last_parameters.mat')

% Now, quit matlab to release control back to calling script
quit
