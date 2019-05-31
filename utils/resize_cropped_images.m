%% Documentation Section
% Program: resize_cropped_images.m
% Author: Spencer Rhodes
% Updated: Toby Peele
% Update Date: 05/29/2019
% Description: This program resizes previously 'Scanned and Cropped'
% images. It expects to have a path to flakes already loaded in memory
% from configuration data associated with a given site. One should run the
% program 'ea_interactive_masclab' to load configuration settings before
% running this program. 

%% VERY IMPORTANT! 
% Run Scan and Crop before attempting to resize images.
%
%% test directory on local machine... 
% settings.pathToFlakes = 'C:\Users\toby2399\Documents\MATLAB\201601\';

%% Options and Settings

% Specify place to write out resized images
pathToResizedImgs = [settings.pathToFlakes 'resized_imgs'];

% Specify target scale (in px/mm)
%   - must be larger than camera scale so no resolution is lost
targetScale = 100;

% Length of scale bar (enable this in imageResize and only call it once to
% make the scale bar image)
scaleBar = 3; % mm (3 mm is recommended)

%% Recursively search for all 'CROP_CAM' directories along path

% We need a struct of all paths with 'CROP_SIZE' subdirectories.
% This utility program, 'rdir(ROOT TEST rPATH)' will work nicely.

imgFilter = @(d) isempty(regexp(d.name, 'resized_imgs', 'once'));
refdir = rdir([settings.pathToFlakes '**' filesep 'CROP_CA*'], imgFilter);

if length(refdir) < 1
    fprintf('You must run Scan and Crop before attempting to resize images.\n');
    fprintf('Exiting program\n');
    return;
end

% turn off warnings about trying to make a directory that already exists
warning('off', 'MATLAB:MKDIR:DirectoryExists')
mkdir(pathToResizedImgs)

%% Main

textprogressbar('Making resized images. ', length(refdir));

for i = 1:length(refdir)
    textprogressbar(i);
    fullCropPath = refdir(i).name;
    cropCamSubDir = strrep(fullCropPath, settings.pathToFlakes, '');
    resizedImgDir = [pathToResizedImgs filesep cropCamSubDir];
    mkdir(resizedImgDir);
    
    % pass the full path of cropped images and the directory that resized
    % images will be placed in to 'imageResize'
    
    imageResize(fullCropPath, resizedImgDir, targetScale, scaleBar, 0, settings.siteName, 0);
    
end 

textprogressbar(' done!');

warning('on', 'MATLAB:MKDIR:DirectoryExists')
