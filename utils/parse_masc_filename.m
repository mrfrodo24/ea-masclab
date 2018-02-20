function [ masc ] = parse_masc_filename( filename )
%PARSE_MASC_FILENAME Get datenum, image, particle, and camera id of a MASC
%image filename

masc.date = datenum(filename(1:19), 'yyyy.mm.dd_HH.MM.SS');

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

