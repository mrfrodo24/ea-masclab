function [s, idx] = sort_masc_images(s)
%SORT_MASC_IMAGES Take a list of masc structs and sort them
%
%	INPUTS:
%		s - Array of structs, produced by utils/parse_masc_filename.m
%
%	OUTPUTS:
%		s - Sorted array of structs
%		idx - Indices of sorted structs into old array
%

% The sorting algorithm we'll use here is rudimentary, but will perform well
% given the typical setup of the data we'll be dealing with.

% Since the MASC images are usually in temporal order anyway, the only
% deviations that we should see are small and owing to edge cases,
% such as when two images are taken in the same second and the first one
% has a flake id whose first digit is greater than the next (e.g. 99 -> 100).

% Any major deviations from a mostly chronological order would be a sign
% of a weird initial directory structure, and should probably be re-scanned completely
% as a new cached path.

%% Masc comparison function
% Returns -1 if s2 comes before s1. Otherwise 0.
function [cmp] = mascCmp(s1, s2)
	cmp = 0;
	if s2.date < s1.date || ...
	   (s2.date == s1.date && s2.imageId < s1.imageId) || ...
	   (s2.imageId == s1.imageId && s2.camId < s1.camId) 
		cmp = -1;
	% elseif s2.date == s1.date && ...
	%        s2.camId == s1.camId && ...
	%        s2.imageId == s1.imageId && ...
	%        s2.particleId == s1.particleId
 %    	cmp = 0;
 %    else
 %    	cmp = 1;
    end
end

%% Sorting
idx = [1:length(s)]';
for i = 2:length(s)
	cmp = mascCmp(s(i-1), s(i));
    if cmp < 0
		goBack = i - 2;
        if goBack < 1
			s(1:i) = [s(i); s(1:i-1)];
			idx(1:i) = [idx(i); idx(1:i-1)];
			continue;
        end
		while mascCmp(s(goBack), s(i)) < 0
			goBack = goBack - 1;
		end
		s(goBack:i) = [s(goBack); s(i); s(goBack+1:i-1)];
		idx(goBack:i) = [idx(goBack); idx(i); idx(goBack+1:i-1)];
    end
end


end