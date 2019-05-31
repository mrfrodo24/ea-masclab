%% Documentation
% Author: Levi Lovell
% Created: 7/28/2018
% Last modified: 7/28/2018 by Levi Lovell
% 
% Purpose: This function is meant to rescale images to a consistent and
%          standard value while only using the information stored in the 
%          image filename.
%
% Inputs:
%       flakeopenDirectory: Need directory (folder) of flake images to 
%                           open. This will allow for all of the flake 
%                           images of interest to be read in via the imread 
%                           function. 
%                               Example: 'Collage Flakes'
%       flakesaveDirectory: Need directory (folder) of flake images to 
%                           save. This will allow for all of the flake 
%                           images of interest to be read in via the imread 
%                           function. 
%                               Example: 'Resized Collage Flakes'
%       targetScale: Need target scale value in pixel/mm. This can be any
%                    value greater than the pixel/mm value of any
%                    individual camera. This is necessary because we do not
%                    wish to degrade any of the images. 
%                       Example: 100
%       scalebarLength: Need length of desired scalebar in mm. A scalebar
%                       length of 3 is highly recommended. 
%                           Example: 3
%       varargin:
%           (1) integer if set to 1, then new images will have the
%               following suffix appended to their original image file name.
%           (2) site of image

function imageResize(flakeopenDirectory, flakesaveDirectory, targetScale, scalebarLength, varargin)

screenReport = 0; 
mascSite = '';
appendSuffixToNewFile = 1;
if length(varargin) >= 1, screenReport = varargin{1}; end
if length(varargin) >= 2, mascSite = varargin{2}; end
if length(varargin) >= 3, appendSuffixToNewFile = varargin{1}; end

% Obtain information about all files in collage image
% directory, and read in images
filelist = dir([flakeopenDirectory filesep '*.png']);
sz = length(filelist);

if screenReport, fprintf('Resizing %d images\n',sz); end

i = 1;
while i <= length(filelist)
    try
        filelist(i).image = imread([flakeopenDirectory filesep filelist(i).name]);
        i = i + 1;
    catch 
        %stop=1;
        fprintf('ERROR: File %s could not be read\n',filelist(i).name);
        filelist(i)=[]; % will remove the element that failed
        continue;
    end
end
% reset sz length of filelist
sz = length(filelist);

% Loop through filenames to extract the year, site, and cam ID
years = zeros(sz,1);
cameraID = zeros(sz,1);
for n = 1:sz
    masc = parse_masc_filename(filelist(n).name);
    years(n) = year(masc.date);
    if ~isfield(masc,'site')
        site{n} = mascSite;
    else
        site{n} = masc.site;
    end
    %site(n) = sprintf('%s',masc.site);
    cameraID(n) = masc.camId;
end

% List of camera specs from each camera at each location (Note: unit is
% pixel/mm)
sbucam02 = 30.683; 
sbucam1 = 51.813;
alta2013cam0 = 39.03;
alta2013cam1 = 74.18;
alta2013cam2 = 29.27;
altacam02 = 39.03;
altacam1 = 39.49;
asucam0 = 30.395;
asucam1 = 32.051;
asucam2 = 33.113;

% Loop through collage table to assign scale to each of the flakes based on
% the location, year (only alta), and camera
for o = 1:sz
    if strcmpi(site{o}, 'sbu')
        if cameraID(o) == 1
            filelist(o).scale = sbucam1;
        else
            filelist(o).scale = sbucam02;
        end
    elseif strcmpi(site{o}, 'alta')
        if years(o) == 2013
            if cameraID(o) == 0
                filelist(o).scale = alta2013cam0;
            elseif cameraID(o) == 1
                filelist(o).scale = alta2013cam1;
            else
                filelist(o).scale = alta2013cam2;
            end
        else
            if cameraID(o) == 1
                filelist(o).scale = altacam1;
            else
                filelist(o).scale = altacam02;
            end
        end
    elseif strcmpi(site{o}, 'asu')
        if cameraID(o) == 0
            filelist(o).scale = asucam0;
        elseif cameraID(o) == 1
            filelist(o).scale = asucam1;
        else
            filelist(o).scale = asucam2;
        end
    else
        fprintf('%s', filelist(o).name);
        keyboard
        error('The site does not match one of our recognized sites.') 
    end
end

% Generate list of conversion factors to be used in resizing
for r = 1:sz
    filelist(r).conversionfactor = targetScale/filelist(r).scale;
end

% Resize images using imresize with the scale being the conversion factor
% determind above and show the images using imshow 
resizedImages = cell(sz,1);
for t = 1:sz
    resizedImages{t,1} = imresize(filelist(t).image,filelist(t).conversionfactor);
    if appendSuffixToNewFile
        newFilePath = [flakesaveDirectory filesep filelist(t).name(1:end-4) '_resized_' num2str(targetScale) 'pixelpermm.png'];
    else
        newFilePath = [flakesaveDirectory filesep filelist(t).name];
    end
    imwrite(resizedImages{t,1}, newFilePath);
end

% imshow(quarter)
% hold on
% PixelSize = 0.01333333333; %mm/pixel
% ScalebarLength = 3; %mm 
% x_location = 1530;
% y_location = 1730;
% q = quiver(x_location,y_location,ScalebarLength/PixelSize,0);
% q.ShowArrowHead = 'off';
% q.Color = 'white';
% t = text(1585,1750,'3 mm');
% t.Color = 'white';
% hold off

% Generate scalebar image based on target scale value and scalebar length.
% This will be saved in the same folder as the resized images. 
blankImage = ones(250,250,'uint8');
blankImage(:,:,:) = 0;
imshow(blankImage)
pixelSize = 1/targetScale; %mm/pixel
xLocation = 25;
yLocation = 125;
hold on
q = quiver(xLocation,yLocation,scalebarLength/pixelSize,0);
q.ShowArrowHead = 'off';
q.Color = 'white';
t = text(110,135,'3 mm');
t.Color = 'white'; 
hold off
%export_fig([flakesaveDirectory '\scalebar_' num2str(targetScale) 'pixelpermm.png'],'-nocrop')
% fixed 8/8/2018 SEY and SR
% print(gcf,[flakesaveDirectory '\scalebar_' num2str(targetScale) 'pixelpermm.png'],'-dpng')
end

