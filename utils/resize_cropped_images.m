% Specify place to write out resized images
pathToResizedImgs = [settings.pathToFlakes 'resized_imgs'];
% Specify target scale (in px/mm)
%   - must be larger than camera scale so no resolution is lost
targetScale = 100;
% Length of scale bar (enable this in imageResize and only call it once to
% make the scale bar image)
scaleBar = 3; % mm (3 mm is recommended)

if ~isdir(pathToResizedImgs)
    mkdir(pathToResizedImgs)
end

dates = get_cached_flakes_dates(settings.pathToFlakes, 'good');

for i = 1:length(dates)
    
    % TODO - For now, only works if contents of pathToFlakes are
    % directories of mm/dd/HH/CROP_CAM
    
    for h = 0:23
        hStr = num2str(h);
        if h < 10, hStr = ['0' hStr]; end %#ok<AGROW> not a problem
        cropCamSubDir = [datestr(dates(i),'mm/dd/') hStr '/CROP_CAM'];
        cropCamDir = [settings.pathToFlakes cropCamSubDir];
        f = dir(cropCamDir);
        
        if ~isempty(f)
            % Pass this CROP_CAM directory to imageResize
            resizedImgDir = [pathToResizedImgs cropCamSubDir];
            mkdir(resizedImgDir);
            imageResize(cropCamDir, resizedImgDir, targetScale, scaleBar, 0);
        end
    end
    
end