function [ user_input ] = CP3G_MascLab_Analytics_Menu
%CP3G_MASCLAB_ANALYTICS_MENU Displays main menu, verifies user input,
%returns command.
%   Detailed explanation goes here

disp('        %%%%%%%%%%%%%%%%%')
disp('      %%%%% Main Menu %%%%%')
disp('        %%%%%%%%%%%%%%%%%')
fprintf('\n');

fprintf('Choose one of the following actions:\n');
fprintf('\t(1) Select module(s) to process\n');
fprintf('\t(2) Run Scan & Crop\n');
fprintf('\t(3) Redefine processing parameters\n');
fprintf('\t(4) Export directory''s statistics\n');
fprintf('\t(5) Resync images in selected cached path\n');
fprintf('\t(6) Save and exit\n');
fprintf('\n');

s = input('Enter the number for your selection: ','s');
% Continue to prompt user until they enter the number of one of the choices
while isempty(str2num(s)) || isempty(find(str2num(s) == [1 2 3 4 5 6], 1)) %#ok<ST2NM>
    s = input('Enter the number for your selection: ','s');
end

switch(str2num(s)) %#ok<ST2NM>
    case 1
        user_input = 'select_modules';
        
    case 2
        user_input = 'run_scan_crop';
        
    case 3
        user_input = 'redefine_processing_params';
        
    case 4
        user_input = 'export_stats';
        
    case 5
        user_input = 'sync_cached_path';
        
    case 6
        user_input = 'save_and_quit';
end

fprintf('\n');


end

