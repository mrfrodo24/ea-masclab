function [ outputs ] = SonicNumber( img, ~, ~, varargin )
%SONICNUMBER
%
%   SUMMARY:
%
%   INPUTS:
%       img - default
%       ~ (masked out bounds since this function doesn't need it)
%       ~ (masked out topLeftCoords since this function doesn't need it)
%       varargin - See ModuleInputHandler

    img_fullpath = img;
    img = imread(img_fullpath);
    snow = +(img > 40);
    A = bwdist(~snow);
    sum_dist = sum(sum(A));
    stats = regionprops( snow, 'Area', 'MajorAxisLength');
    if length(stats) > 1
        % Erroneous edges detected, pick the best (i.e. biggest) edge...
        allSizes = [stats.MajorAxisLength];
        whichBound = find( allSizes == max(allSizes), 1, 'first' );
        stats = stats(whichBound);
    elseif isempty(stats)
        % Bad flake, skip it, return NaN
        outputs{1} = NaN;
        clearvars -except outputs
        return;
    end
    stats = stats.Area;
    sonic = sum_dist / stats^1.2;
    
    % TEST CODE
%     sonic2 = (sum_dist / nanmean(nanmean(A)) / area);
%     sonic3 = numel(A) / area;
% %     sonic = 1 - (1 / (sum_dist / nanmean(nanmean(A)) / area));
%     figure(1)
%     imshow(img_array)
%     figure(2)
%     imshow(A,[])
    % END TEST CODE
    
    outputs{1} = sonic;
    clearvars -except outputs
    
end