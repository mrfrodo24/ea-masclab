%% resize_cropped_images.m

%% VERY IMPORTANT! 
% Run Scan and Crop before attempting to resize images.
%

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
refdir = rdir([settings.pathToFlakes '**\CROP_CA*'], imgFilter);

if length(refdir) < 1
    fprintf('You must run Scan and Crop before attempting to resize images.\n');
    fprintf('Exiting program\n');
    return;
end

% turn off warnings about trying to make a directory that already exists
warning('off', 'MATLAB:MKDIR:DirectoryExists')
mkdir(pathToResizedImgs)

%% Main

textprogressbar('Makeing resized images. ', length(refdir));

for i = 1:length(refdir)
    textprogressbar(i);
    fullCropPath = refdir(i).name;
    cropCamSubDir = erase(fullCropPath, settings.pathToFlakes);
    resizedImgDir = [pathToResizedImgs filesep cropCamSubDir];
    mkdir(resizedImgDir);
    
    % pass the full path of cropped images and the directory that resized
    % images will be placed in to 'imageResize'
    
    imageResize(fullCropPath, resizedImgDir, targetScale, scaleBar, 0, settings.siteName);
    
end 

%% Original functionality 

% dates = get_cached_flakes_dates(settings.pathToFlakes, 'good');
% 
% textprogressbar('Making resized images for each day with flakes... ', length(dates));
% 
%     
% for i = 1:length(dates)
%     textprogressbar(i);
%     for h = 0:23
%         hStr = num2str(h);
%         if h < 10, hStr = ['0' hStr]; end %#ok<AGROW> not a problem
%         cropCamSubDir = [datestr(dates(i),'mm/dd/') hStr '/CROP_CAM'];
%         cropCamDir = [settings.pathToFlakes cropCamSubDir];
%         f = dir(cropCamDir);
%         
%         if ~isempty(f)
%             % Pass this CROP_CAM directory to imageResize
%             resizedImgDir = [pathToResizedImgs filesep cropCamSubDir];
%             mkdir(resizedImgDir);
%             imageResize(cropCamDir, resizedImgDir, targetScale, scaleBar, 0, settings.siteName);
%         end
%     end
% end 

textprogressbar(' done!');

warning('on', 'MATLAB:MKDIR:DirectoryExists')