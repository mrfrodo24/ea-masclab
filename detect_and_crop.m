function [ fList, good_count, count] = detect_and_crop( arr, settings )
%DETECT_AND_CROP Open function for full documentation
%   
%   SUMMARY:
%       This function accepts an image array and a struct of settings as
%       its inputs and has several outputs. First and foremost, the
%       function identifies "objects" or flakes in the image (commonly
%       referred to throughout MASC Analytics as "subflakes" since there
%       are potentially many flakes in one image).
%
%   INPUTS:
%       arr - The image array (produced by imread).
%       settings - A struct of settings. These come from cache/gen_params/last_parameters.mat.
%                  The following fields are used in this function
%           1: backgroundThresh
%           2: minFlakePerim
%           3: minCropWidth
%           4: avgFlakeBrightness
%           5: maxEdgeTouch
%           6: filterFocus - Specify whether to calculate and use focus for filtering.
%           7: focusThreshold - Accept objects with at least this focus value.
%
%   OUTPUTS:
%       fList - Cell with several columns of useful output...
%           col. 1: Label matrix for the identified flake
%           col. 2: Minimum row in the original image of the flake's
%                   bounding box
%           col. 3: Maximum row in the original image of the flake's
%                   bounding box
%           col. 4: Minimum column in the original image of the flake's
%                   bounding box
%           col. 5: Maximum column in the original image of the flake's
%                   bounding box
%           col. 6: Whether it is a "good" flake (i.e. passed the inner
%                   filters of this function. There are three, and you can
%                   see where they are in the code by searching for "%
%                   Filter")
%           col. 7: Perimeter of the flake.
%       good_count - Number of "good" flakes found.
%       count - Total number of flakes found.
%

%% New Matlab Image Processing Toolbox Implementation

% Ensure outer edge of array is all zeroes
arr(1,:) = 0;
arr(end,:) = 0;
arr(:,1) = 0;
arr(:,end) = 0;

% Get the edges
edges = edge(arr > settings.backgroundThresh);

% Fill in gaps in the edges (Code from http://www.peterkovesi.com/matlabfns/index.html#edgelink)
bw = filledgegaps(edges,1); % Default gap size is 1 pixel

% Get the connected components (i.e. whole objects)
CC = bwconncomp(bw);

% Get the areas (really perimeter) of each connected component
stats = regionprops(CC,'Area');
% Get components to remove, based on the perimeter
toRemove = find([stats.Area] < settings.minFlakePerim);

% Remove the components from the list
CC.PixelIdxList(toRemove) = [];
CC.NumObjects = CC.NumObjects - length(toRemove);

% Construct label matrix (uses different label for each boundary)
L = labelmatrix(CC);
% Refresh stats
stats = regionprops(CC,'Area');

% Now, loop through the labels and extract the boundary for each one.
% While doing so, check if object encloses or is enclosed by any other
% objects.  Enclosed objects will not make it through this.
count = 0;
good_count = 0;
fList = cell(CC.NumObjects, 7);
minRows = [];
minCols = minRows; maxRows = minRows; maxCols =  minRows;
i = 1;
while i <= CC.NumObjects
    inds = find(L == i);
    [row, col] = ind2sub(size(L), inds);
    minRows(count+1) = min(row); minCols(count+1) = min(col); %#ok<AGROW>
    maxRows(count+1) = max(row); maxCols(count+1) = max(col);
    
    % Check if the rectangle enclosing this object is inside another rectangle.
    if insideRectangle(count+1)
        minRows(count+1) = []; maxRows(count+1) = []; minCols(count+1) = []; maxCols(count+1) = []; %#ok<AGROW>
        i = i + 1;
        continue;
    end
    
    % Check if the rectangle enclosing this object encloses any other rectangle(s).
    enclosed_objects = enclosedRectangles(count+1);
    if ~isempty(enclosed_objects)
        minRows(enclosed_objects) = []; maxRows(enclosed_objects) = []; %#ok<AGROW>
        minCols(enclosed_objects) = []; maxCols(enclosed_objects) = [];
        fList(enclosed_objects, :) = [];
        count = count - length(enclosed_objects);
    end
    
    count = count + 1;
    fList{count,1} = L(minRows(count):maxRows(count),minCols(count):maxCols(count));
    fList{count,2} = minRows(count);
    fList{count,3} = maxRows(count);
    fList{count,4} = minCols(count);
    fList{count,5} = maxCols(count);
    fList{count,6} = 0;
    fList{count,7} = stats(i).Area;
    
    i = i + 1;
end

% FILTERS
for i = CC.NumObjects:-1:1
    if isempty(fList{i,1})
        fList(i, :) = []; 
        continue;
    end
    
    inds = find(L == i);
    [row, col] = ind2sub(size(L), inds);
    
    minR = fList{i,2}; minC = fList{i,4};
    maxR = fList{i,3}; maxC = fList{i,5};    
    good_flake = 1;
    
    % Filter rectangle
    if (maxR - minR < settings.minCropWidth) || (maxC - minC < settings.minCropWidth)
        good_flake = 0;
    end
    
    % Filter intensity
    if good_flake && nanmean(nanmean(arr(minR:maxR,minC:maxC))) < settings.avgFlakeBrightness
        good_flake = 0;
    end
    
    % Filter on max length that flake can be touching image frame
    if good_flake && sum(row == 1 | row == size(arr,1)) > settings.maxEdgeTouch || ...
       sum(col == 1 | col == size(arr,2)) > settings.maxEdgeTouch
        good_flake = 0;
    end
    
    % Filter focus
    focus = fmeasure(arr(minR:maxR,minC:maxC),'VOLA');
    if good_flake && settings.filterFocus && focus < settings.focusThreshold
        good_flake = 0;
    end
    
    % Filter for lens flares
    if good_flake
        % MAGIC VALUE - Threshold lens flares at 120 alpha
        lens_stats = regionprops(arr(minR:maxR,minC:maxC) > 120);
        if length(lens_stats) == 1
            lens_flare = lens_stats.BoundingBox;
        end
        if length(lens_stats) == 1 && ...
           2*lens_flare(3) + 2*lens_flare(4) < settings.minFlakePerim
            good_flake = 0;
        end
    end
    
    % Signal good flakes for further processing
    if good_flake
        fList{i,6} = 1;
        good_count = good_count + 1;
    end
    
end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SUMMARY:
    %   Returns indices of other objects that the object referenced by input 'idx'
    %   encloses.
    %
    function [indices] = enclosedRectangles(idx)
        indices = [];
        if CC.NumObjects <= 1
            return;
        end
        
        % Find minRows this rectangle (idx) is less than
        indices = find(minRows(idx) < minRows);
        if isempty(indices) 
            return; end
        
        % Find maxRows this rectangle (idx) is greater than that match indices
        indices = intersect(indices, find(maxRows(idx) > maxRows)); %#ok<*EFIND>
        if isempty(indices)
            return; end
        
        % Find minCols this rectangle (idx) is less than that match indices
        indices = intersect(indices, find(minCols(idx) < minCols));
        if isempty(indices)
            return; end
        
        % Find maxCols this rectangle (idx) is greater than that match indices
        indices = intersect(indices, find(maxCols(idx) > maxCols));
        
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SUMMARY:
    %   Returns 0 or 1.
    %   1 if object referenced by input 'idx' is inside any other object.
    %   Otherwise, 0.
    %
    function [is_inside] = insideRectangle(idx)
        is_inside = 0;
        if CC.NumObjects <= 1
            return;
        end
        
        % Find minRows less than this rectangle (idx)
        indices = find(minRows < minRows(idx));
        if isempty(indices)
            return; end
        
        % Find maxRows greater than this rectangle (idx)
        indices = intersect(indices, find(maxRows > maxRows(idx)));
        if isempty(indices)
            return; end
        
        % Find minCols less than this rectangle (idx)
        indices = intersect(indices, find(minCols < minCols(idx)));
        if isempty(indices)
            return; end
        
        % Find maxCols greater than this rectangle (idx)
        indices = intersect(indices, find(maxCols > maxCols(idx)));
        if ~isempty(indices)
            is_inside = 1; end
        return;
    end

% Clear everything that isn't being returned
clearvars -except fList good_count count;


%% OLD TRACING FUNCTIONALITY
% Originally also returned snowList and tBound

%     % Ensure outer edge of array is all zeroes
%     arr(1,:) = 0;
%     arr(end,:) = 0;
%     arr(:,1) = 0;
%     arr(:,end) = 0;
%     
%     [m, n] = size(arr);
%     processed = zeros(m, n);
%     tBound = zeros(m, n);
%     fList = {};
%     count = 1;
%     good_count = 1;
%     snowList = +(arr > backgroundThresh);
%     i = 1;
%     while i < m 
%         j = 1;
%         % Skip a row if it's all zeroes
%         if sum(snowList(i,:)) == 0
%             processed(i,:) = 1;
%             i = i + 1;
%             continue;
%         end
%         % Otherwise, have to traverse it to look for a flake
%         while j < n
%             if( snowList(i, j + 1) == 1) && processed(i, j + 1) ~= 1
%                 boundList = zeros(m, n);
%                 d = 0;
%                 direction = 1; % dir 1 = right
%                 minR = i;
%                 maxR = i;
%                 minC = j;
%                 maxC = j;
%                 initR = i - 1;
%                 initC = j + 1;
%                 boundList(initR, initC) = 1;
%                 tBound(initR, initC) = 1;
%                 R = initR;
%                 C = initC;
%                 boundList(R, C) = 1;
%                 tBound(R, C) = 1;
%                 % Give it a push in the right direction
%                 pushInRightDirection
%                 % if going right
%                 while( R ~= initR || C ~= initC)
%                     if( direction == 1 )
%                         if( snowList( R, C + 1) == 1)
%                             direction = 2; % dir 2 = up
%                           
%                         elseif (snowList( R + 1, C + 1) == 1)
%                             direction = 1;
%                             C = C + 1;
%                             if ( C > maxC )
%                                 maxC = C;
%                             end
%                             boundList( R, C) = 1;
%                             tBound(R, C) = 1;
%                             d = d + 1;
%                         else
%                             direction = 3; % dir3 = down
%                             R = R + 1;
%                             C = C + 1;
%                             boundList( R, C) = 1;
%                             tBound(R, C) = 1;
%                             d = d + 1;
%                         end
%                         if ( C > maxC )
%                            maxC = C;
%                         end
%                     end
%                     % if going up
%                     if (direction == 2)
%                         if( snowList( R - 1, C) == 1)
%                             direction = 4; %left
%                            
%                         elseif( snowList( R - 1, C + 1 ) == 1)
%                             R = R - 1;
%                             boundList( R, C) = 1;
%                             tBound(R, C) = 1;
%                             d = d + 1;
%                         else
%                             C = C + 1;
%                             R = R - 1;
%                             direction = 1;
%                             boundList( R, C ) = 1;
%                             tBound(R, C) = 1;
%                             d = d + 1;
%                         end
%                         if( R < minR )
%                             minR = R;
%                         end
%                     end
% 
%                     if(direction == 3)
%                         if( snowList( R + 1, C ) == 1 )
%                             direction = 1;
%                          
%                         elseif snowList( R + 1, C - 1 ) == 1
%                             R = R + 1;
%                             boundList(R, C ) = 1;
%                             tBound(R, C) = 1;
%                             d = d + 1;
%                         else
%                             direction = 4;
%                             R = R + 1;
%                             C = C - 1;
%                            % disp('here');
%                             boundList( R, C) = 1;
%                             tBound(R, C) = 1;
%                             d = d + 1;
%                         end
%                         if( R > maxR) 
%                             maxR = R;
%                         end
%                     end
%                    
%                     if(direction == 4) 
%                         if( snowList( R, C - 1) == 1)
%                            direction = 3;
%                          
%                         elseif (snowList(R - 1, C - 1) == 1)
%                            C = C - 1;
%                            boundList( R, C) = 1;
%                            tBound(R, C) = 1;
%                            d = d + 1;
%                         else
%                            direction = 2;
%                            R = R - 1;
%                            C = C - 1;
%                            boundList( R, C) = 1;
%                            tBound(R, C) = 1;
%                            d = d + 1;
%                         end
%                         if( C < minC)
%                            minC = C;
%                         end
%                     end
%                 end
%                 processed(minR:maxR,minC:maxC) = ...
%                     +(processed(minR:maxR,minC:maxC) | imfill(boundList(minR:maxR,minC:maxC),'holes'));
%                 
%                 % Do the innerFilter (inner because it's within the
%                 % detect_and_crop function). This will help us remove
%                 % spurious flakes immediately, thus giving us more memory
%                 % to work with (and less processing to do later). Also
%                 % added a second innerfilter to handle determining which
%                 % flakes will likely be the good ones. TODO: Maybe expand
%                 % upon this second filter later on.
%                 
%                 % THE VALUES HERE ARE THE PRODUCT OF TESTING. THEY ARE
%                 % SUBJECT TO CHANGE, BUT SHOULD BE TAKEN AS FAIRLY OPTIMAL
%                 % GIVEN THE AMOUNT OF TESTING.
%                 if (d > 10 && innerFilter)
%                     % If innerFilter returns true (1), then include flake
%                     
%                     % Don't save the boundList for the WHOLE image, just crop
%                     % it to the bounds of the flake (for memory purposes).
%                     fList{count, 1} = boundList(minR:maxR,minC:maxC);
%                     fList{count, 2} = minR;
%                     fList{count, 3} = maxR;
%                     fList{count, 4} = minC;
%                     fList{count, 5} = maxC;
%                     % THE VALUES HERE ARE THE PRODUCT OF TESTING. THEY ARE
%                     % SUBJECT TO CHANGE, BUT SHOULD BE TAKEN AS FAIRLY OPTIMAL
%                     % GIVEN THE AMOUNT OF TESTING.
%                     if (d > 20 && innerFilter)
%                         fList{count, 6} = 1;
%                         good_count = good_count + 1;
%                     else
%                         fList{count, 6} = 0;
%                     end
%                     fList{count, 7} = d; % Perimeter!
%                     count = count + 1;
%                 else
%                     % Otherwise, remove it from tBound and don't store the
%                     % flake
%                     tBound(logical(boundList)) = 0;
%                 end
%             else
%                 processed(i, j) = 1;
%                 j = j + 1;
%                  
%             end
%         end
%         i = i + 1;
%     end
%     count = count - 1;
%     good_count = good_count - 1;
% 
%     % Sub-function for searching where to go next
%     function pushInRightDirection
%         if (snowList( R + 1, C + 1) == 1)
%             direction = 1;
%             C = C + 1;
%             if ( C > maxC )
%                 maxC = C;
%             end
%             boundList( R, C) = 1;
%             tBound(R, C) = 1;
%         else
%             direction = 3; % dir3 = down
%             R = R + 1;
%             C = C + 1;
%             boundList( R, C) = 1;
%             tBound(R, C) = 1;
%         end
%         if ( C > maxC )
%            maxC = C;
%         end
%     end
% 
%     function [include_flake] = innerFilter
%         R = maxR - minR;
%         C = maxC - minC;
%         distR = minwidth; % Filter flake size to be 40x40 pixels (experimental)
%         distC = minwidth;
%         avgIn = avgBrightnessThresh; % Filter average intensity > 10 (experimental)
%         % Initially assume flake will be included
%         include_flake = 1;
% 
%         if( R < distR && C < distC )
%             include_flake = 0; % Do not include flake
%         else 
%             pcount = 0;
%             avg = 0;
%             for u = minR : maxR
%                 for v = minC : maxC
%                    if snowList(u, v) == 1
%                         avg = avg + double(arr(u, v));
%                         pcount = pcount + 1;
%                    end
%                 end
%             end
%             avg = avg / pcount;
%             if( avg < avgIn )
%                 include_flake = 0;
%             end
%         end
%     end

end