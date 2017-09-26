% Goes through goodSubFlakes and outputs array of flake IDs

flakeids = [];
for i = 1:length(goodSubFlakes)
    if isempty(goodSubFlakes{i,1})
        break;
    end
    
    timestampAndIds = regexp(goodSubFlakes{i,1}, settings.mascImgRegPattern, 'match');
    timestampAndIds = timestampAndIds{1};
    
    flakeIdStart = strfind(timestampAndIds, 'flake_');
    flakeIdEnd = strfind(timestampAndIds(flakeIdStart:end), '.') - 2;
    flakeids(i) = str2num(timestampAndIds(flakeIdStart + 6 : flakeIdStart + flakeIdEnd(1)));
end