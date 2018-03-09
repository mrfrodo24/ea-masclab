function [ outputs ] = ModuleInterface( img_path, bounds, topLeftCoords, varargin )
%ModuleInterface Serves as a model function for all future modules
%   SUMMARY:
%       In the EA MASC Analytics framework, modules are defined as such:
%
%       Q: What is a module?
%       A: A set of instructions for processing a single image of a single
%           flake to determine some statistic with research value.
%
%       Q: Is there support for multi-cam flakes?
%       A: With this module interface, no. A different module interface
%           will be created specifically for that purpose.
%
%       Q: What does a module need?
%       A: Each module is free to do whatever it wants WITH AND ONLY WITH
%           the input parameters. The input parameters MUST be defined
%           within the ModuleInputHandler. There, you will be able to define
%           any inputs your module will require from the goodSubFlakes cell
%           (for information on goodSubFlakes cell, see
%           initGoodSubFlakes.m). These input params will then be
%           available to your module through the varargin parameter
%
%           That being said, by DEFAULT, ModuleRunner will set the
%           first 3 inputs to be:
%               1. The image array (given by imread)
%               2. The flake's bounds (given by goodSubFlakes)
%               3. The flake's top-left coordinates in original image
%                   (given by goodSubFlakes) given as array
%                   [row start, column start]
%           
%           THERE ARE TWO GOALS OF THIS DESIGN (and it's important that you know them):
%               I.   Minimize overhead at all costs (since module is 
%                    called for each good snowflake).
%               II.  Provide an infrastructure that can easily provide 
%                    support for additional modules.
%
%       Q: What can a module output?
%       A: Each module should output AS LITTLE AS POSSIBLE! This is to
%           prevent too much memory usage. Ideally, each module should
%           output a single number. DO NOT MAKE YOUR OUTPUT A CELL! You can
%           make it an array if you want, but please minimize the amount of
%           elements in the array.
%
%           The outputs from a module will need to be saved to the cache
%           for the directory being processed. In order to do this, you
%           will have to modify two files:
%             1) initGoodSubFlakes.m:
%               In this function, we declare the columns that are tracked
%               for good flakes. Whenever you create a module that has
%               output you want to track, you must give it a column. See
%               the documentation in the file for more information.
%             
%             2) ModuleOutputHandler.m:
%               In this function, we declare the indices of the columns in
%               goodSubFlakes that will be used to store the outputs of the
%               module. See the documentation in the file for more
%               information.
%
%       <In your module, document the purpose of the module here under SUMMARY>
%
%   INPUTS:
%       <Document module inputs (varargin) here>
%       DEFAULTS:
%           img_path - The full file path of the image
%           goodSubFlake - The flake's bounds, top-left coords, stats, etc.
%           settings - Matlab struct of parameters defined in pre-processing.
%           varargin:
%               1 - Example input here
%               2 - Example input here
%
%   OUTPUTS:
%       <Document module outputs here>
%       1 - Example output here
%       2 - Example output here
%
%   DEVELOPMENT NOTES:
%       When creating a new module, it is important that you do try to
%       abide by a few coding standards:
%           1. COMMENT CODE! We ask that you please comment as much of your
%               code as possible, including both inline and high-level
%               comments/documentation. The more you comment, the better
%               chance your module will be used by others.
%           2. Other development standards here...
%
%   DEVELOPER CONTACT:
%       Spencer Rhodes - spencer.rhodes2@gmail.com
%       Edward Chan - schan3@ncsu.edu

% This is where all of your module's flake analytics code will go.

% Make sure that you assign the appropriate values to outputs!!! (as you
% defined in ModuleOutputHandler)
numOutputs = 2;
outputs = cell(1,numOutputs);
% Assign outputs...

end

