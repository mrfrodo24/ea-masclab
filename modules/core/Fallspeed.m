function [ outputs ] = Fallspeed( ~, ~, ~, inputs )
%FALLSPEED Pulls the fallspeed as determined by the MASC from dataInfo.txt
%   
%   SUMMARY:
%       This module looks for a dataInfo.txt file (produced by the MASC) in
%       the directory that contains the parent image of the particle in
%       question.  The dataInfo file has a record for each image obtained
%       by the MASC, and has the fallspeed, as determined by the MASC.
%       While this value is not reliable when there is more than one
%       particle in the image, we are still going to try to fetch it.
%
%   INPUTS:
%       1: Full file path to the particle image (will be in CROP_CAM)
%       2: The reg expression pattern to get the timestamp and IDs out of
%           the image file name given in input 1
%       3: Is a good flake (0|1)
%       4: # of good flakes counted in original image
%
%   OUTPUTS:
%       1: Fallspeed (m/s) | NaN
%

% Declare outputs
numOutputs = 1;
outputs = cell(1,numOutputs);

% Read inputs
pathToFlake = inputs{1};
imgRegPattern = inputs{2};
isgood = inputs{3};
goodcount = inputs{4};

% If flake is not "good" or there was more than one "good" flake in the original,
% do not return a fallspeed (set to NaN)
if ~isgood || goodcount > 1
    outputs{1} = NaN;
    return;
end

% Get potential directory of data txt file
pathToFlake = strrep(pathToFlake,'CROP_CAM/','');
pathToFlake = strrep(pathToFlake,'CROP_CAM\','');
lastSlash = find(pathToFlake == '/' | pathToFlake == '\',1,'last');
pathToTxtFile = pathToFlake(1:lastSlash);

% Check if data text file exists
if ~exist([pathToTxtFile 'dataInfo.txt'],'file')
    outputs{1} = NaN;
    return;
end

% Get the full flake ID so we can search the txt file for the image id that
% goes to the individual particle
timestampAndIds = regexp(pathToFlake, imgRegPattern, 'match');
timestampAndIds = timestampAndIds{1};

file_contents = textscan(timestampAndIds,'%s %s %s %s %s %s','Delimiter','_');
flakeID = file_contents{4}{1};

% Now we just need the Image ID
imageID = flakeID(1:strfind(flakeID,'.')-1);

% Look for record of imageID in txt file
dataTxt = fileread([pathToTxtFile 'dataInfo.txt']);
record_start = strfind(dataTxt, [...
    imageID ...
    sprintf('\t') ...
    datestr(datenum(timestampAndIds(1:10),'yyyy.mm.dd'),'mm.dd.yyyy') ...
]);
if isempty(record_start)
    outputs{1} = NaN;
    return;
end

% Get the fallspeed of the record
if record_start + 200 > length(dataTxt)
    subset = dataTxt(record_start : end);
else
    subset = dataTxt(record_start : record_start + 200);
end
record = subset(1 : find(subset == sprintf('\n'),1,'first')-1);
fields = textscan(record, '%s %s %s %s', 'Delimiter', '\t');
fallspeed = fields{4}{1};

% Convert fallspeed and write to outputs
outputs{1} = str2double(fallspeed);
% Clear all variables except outputs
clearvars -except outputs


end % Function end

