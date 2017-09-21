%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUMMARY: Initialize cell arrays for saving all "good" detected      %
% flakes in each image from the MASC.                                 %
%                                                                     %
% We group the good flakes separately so that we have a smaller array %
% that we can access more readily for quick post-processing.          %
%                                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [goodSubFlakes] = initGoodSubFlakes( predefined )
    %% DEFINE goodSubFlakes
    MAX_GOODSUBFLAKES = 10000;
    NUM_COLUMNS = 29;
    goodSubFlakes = cell(MAX_GOODSUBFLAKES, NUM_COLUMNS);
    
    %% DEFAULT goodSubFlake Parameters (derived from SCAN & CROP)
    % Column 1: <STRING> Sub-flake file name
    % Col. 2: <INT> Sub-flake processing flag (0 or 1)
    % Col. 3: <INT> Sub-flake x start location
    % Col. 4: <INT> Sub-flake y start location
    % Col. 5: <ARRAY> Sub-flake bounds (only applies to individual, cropped flakes)
    % Col. 6: <INT>Perimeter (number of pixels around edge)
    
    %% Center MODULE Output Parameters
    % Col. 7: <1x2 ARRAY> Unweighted center of the flake
    % Col. 8: <1x2 ARRAY> Weighted center of the flake
    
    %% Pores MODULE Output Parameters
    % Col. 9: <INT> Number of holes in flake
    % Col. 10: <INT> Solidity of flake
    
    %% Radial MODULE Output Parameters
    % Col. 11: <INT> Normalize radial variance of the flake
    % Col. 12: <1x360 POLAR ARRAY> Polar coordinate array around center of object
    
    %% AvgIntensity MODULE Output Parameters
    % Col. 13: <INT> Average intensity/brightness of the flake
    
    %% SonicNumber MODULE Output Parameters
    % Col. 14: <INT> Sonic (prickley) number. 
    %   Current implementation of sonic number has these results:
    %       Smaller values = Flake is relatively filled in (i.e. moderate 
    %                        to heavily rimed or graupel)
    %       Larger values = Flake has more branches (i.e. prickly, possibly
    %                       aggregate or dendrite)
    %   Reasonable low value, less than threshold: 0.4
    %   Reasonable high value, greater than threshold: 0.5
    
    %% Focus MODULE Output Parameters
    % Col. 15: <FLOAT> Focus number. [0 1]
    
    %% MaxDiameter MODULE Output Parameters
    % Col. 16: <FLOAT> Diameter of flake along major axis (mm)
    
    %% Perimeter MODULE Output Parameters
    % Col. 17: <FLOAT> Perimeter of flake (mm)
    
    %% CrossSection MODULE Output Parameters
    % Col. 18: <FLOAT> Cross section of flake i.e. Area (mm^2)
    
    %% EquivalentRadius MODULE Output Parameters
    % Col. 19: <FLOAT> Area equivalent radius according to particle
    % cross-section (col. 18)
    
    %% Complexity MODULE Output Parameters
    % Col. 20 <FLOAT> Flake complexity, as defined in Garrett, Yuter, et.
    % al. 2014.
    
    %% AspectRatio MODULE Output Parameters
    % Col. 21: <FLOAT> Aspect ratio of the flake (unitless)
    
    %% Roughness MODULE Output Parameters
    % Col. 22: <FLOAT> Diameter of circle with same area as CrossSection
    %          output.
    % Col. 23: <FLOAT> Difference between MaxDiameter output and Col. 22
    
    %% CornerNumber MODULE Output Parameters
    % Col. 24: <INTEGER> Estimated # of corners in flake
    
    %% ConcaveNumber MODULE Output Parameters
    % Col. 25: <INTEGER> Difference between # of pixels in convex hull of
    % flake object and # of pixels in flake object.
    
    %% Fallspeed MODULE Output Parameters
    % Col. 26: <FLOAT> Fallspeed (from MASC, if available)
    %   NOTE: Won't be reliable if there was more than one particle in the
    %   original image...
    
    %% Initial Image Detection Values
    % NOTE: Should have been added with 1st section of parameters from Scan & Crop
    % Col. 27: <INT> # of Accepted Sub-flakes from Original
    % Col. 28: <INT> # of Good Sub-flakes from Original
    
    %% Orientation MODULE Output Parameters
    % Col. 29: <FLOAT> Angle from horizontal of major axis

    %% ADDING A MODULE
    % The goodSubFlakes cell is for tracking the post-processing flake
    % statistics and is designed for relatively quick access.
    % The goodSubFlakes cell will gain additional columns as more
    % MODULES are added. Whenever a module's parameters are to be
    % added/defined here, create a new cell for it in the code (using the
    % double percent signs)
    
    %% CHECKING IF WE NEED TO ADD COLUMNS TO PREDEFINED goodSubFlakes

    % CHECK IF PREDEFINED IS SET
    % If so, we need to check if columns should be added to the predefined
    % cell array of goodSubFlakes (this aspect of initGoodSubFlakes will
    % only be used by ModuleRunner).
    if ~isempty(predefined)
        % Check length of predefined
        if size(predefined,2) < size(goodSubFlakes,2)
            % Missing columns, append them to the end
            for i = size(predefined,2) + 1 : size(goodSubFlakes,2)
                predefined(:,i) = goodSubFlakes(:,i);
            end
        end
        clear goodSubFlakes

        % Return the new predefined goodSubFlakes cell array
        goodSubFlakes = predefined;
    end
    
end