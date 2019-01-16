function [ dates ] = get_cached_flakes_dates( pathToFlakes, whichFiles )
%GET_CACHED_FLAKES_DATES Look through the cache directory in a specified
%pathToFlakes for all cached mat files and return the dates as serial datenums
%   
%   INPUTS:
%       pathToFlakes - the path to the MASC images (see pathToFlakes in
%           pre_processing.m)
%       whichFiles - which mat files to search through. acceptable values
%           are 'good' or 'all'. most of the time these lists will be the
%           same though. if anything, may be less days with good flakes.
%       
%
%   OUTPUTS:
%       dates - list of serial datenums for each cached mat file in pathToFlakes

% ensure trailing slash
if pathToFlakes(end) ~= filesep, pathToFlakes = [pathToFlakes filesep]; end

if ~isfolder([pathToFlakes 'cache'])
    error('No cache folder in pathToFlakes.');
end

switch whichFiles
    case 'good', suffix = 'goodflakes.mat';
    otherwise  , suffix = 'allflakes.mat';
end

files = dir([pathToFlakes 'cache' filesep 'data_*_' suffix]);

dates = nan(length(files),1);

for i = 1:length(files)
    
    dates(i) = datenum(files(i).name(6:13), 'yyyymmdd');
    
end

dates = sort(dates);

end

