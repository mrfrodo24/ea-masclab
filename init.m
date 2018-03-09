% Create default cache directory and gen_params sub-dir
mkdir('cache')
mkdir('cache/gen_params')

% Run pre_processing for first time to set parameters
pre_processing

% Instructions for using suite
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('Command to run suite: ea_interactive_masclab')
fprintf('\n')
