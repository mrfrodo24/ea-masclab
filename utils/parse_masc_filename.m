function [ masc ] = parse_masc_filename( filename )
%PARSE_MASC_FILENAME Get datenum, image, particle, and camera id of a MASC
%image filename
%
%   OUTPUTS:
%       masc - Matlab struct with fields for the image filename parsed:
%           .date (serial datenum)
%           .site (string)
%           .station (string)
%           .imageId (int)
%           .particleId (int)
%           .camId (int)

%% Find the timestamp in the filename
dstartId = 1;
while 1
    try
        masc.date = datenum(filename(dstartId : dstartId + 18), 'yyyy.mm.dd_HH.MM.SS');
        break;
    catch
        dstartId = dstartId + 1;
        if dstartId >= length(filename)
            error('Could not find timestamp in filename.')
        end
    end
end

%% Get site and station from filename (if applicable)
if dstartId > 1
    if filename(dstartId - 1) == filesep
        % No site_stn prefix
        masc.site = '';
        masc.station = '';
    else
        % Make sure we don't get any directory path in the site/station
        fileStart = 1;
        if contains(filename, filesep)
            fileStart = find(filename == filesep,1,'last') + 1;
        end
        filename = filename(fileStart : end);
        siteEnd = strfind(filename, '_'); siteEnd = siteEnd(1) - 1;
        masc.site = filename(1 : siteEnd);

        stnStart = siteEnd + 2;
        stnEnd = strfind(filename(stnStart : end), '_'); stnEnd = stnStart + stnEnd(1) - 2;
        masc.station = filename(stnStart : stnEnd);
    end
end

%% Get MASC ids
imageIdStart = strfind(filename, 'flake_') + 6;
imageIdEnd = imageIdStart + strfind(filename(imageIdStart:end), '_') - 2;
imageIdEnd = imageIdEnd(1);
if strfind(filename(imageIdStart:imageIdEnd), '.')
    particleIdEnd = imageIdEnd;
    imageIdEnd = imageIdStart + strfind(filename(imageIdStart:imageIdEnd), '.') - 2;
    particleIdStart = imageIdEnd + 2;
    masc.particleId = str2double(filename(particleIdStart:particleIdEnd));
else
    masc.particleId = 0;
end
masc.imageId = str2double(filename(imageIdStart:imageIdEnd));

camIdStart = strfind(filename, 'cam_') + 4;
camIdEnd = camIdStart + strfind(filename(camIdStart:end), '.') - 2;
masc.camId = str2double(filename(camIdStart:camIdEnd));

end

