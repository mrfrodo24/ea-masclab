function [ outputs ] = Center( img, ~, ~, inputs )
%CENTER
%
%   SUMMARY:
%
%   INPUTS:
%       img_array - default
%       ~ (masked out bounds since this function doesn't use it)
%       ~ (masked out topLeftCoords since this function doesn't need it)
%       varargin - See ModuleInputHandler
%
%   OUTPUTS (The variables that go into outputs cell array):
%       weighted - 
%       unweighted - 
    
    % Parse the varargin inputs (if necessary, for this module it is)
    backgroundThresh = inputs{1};

    % Begin the module
    img_fullpath = img;
    img = imread(img_fullpath);
    snowList = +(img > backgroundThresh);

    mass_r = double(0);
    mass_c = double(0);

    mass_count = double(0);

    m_r = 0;
    m_c = 0;
    m_count = 0;

    for r = 1 : size(img, 1)
        for c = 1 : size(img, 2)
            if snowList(r, c) == 1
               mass_r = double(mass_r + double(img(r, c)) * (r));
               mass_count = double(mass_count + double(img(r, c)));
               mass_c = mass_c + double(img(r, c)) * (c);
               m_r = m_r + (r);
               m_count = m_count + 1;
               m_c = m_c + (c);
            end
       end
    end
    weighted = [mass_r / mass_count, mass_c / mass_count];

    unweighted = [m_r / m_count, m_c / m_count]; 
    
    % Parse the output into varargout
    outputs = cell(1,2);
    outputs{1} = unweighted;
    outputs{2} = weighted;
    
end