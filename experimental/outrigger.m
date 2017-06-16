function [ flag ] = outrigger( snowList, cel, arr, count )
%OUTRIGGER Summary of this function goes here
%   Detailed explanation goes here
temp = count;
i = 1;
while i <= temp
    minR = cel{i, 2};
    maxR = cel{i, 3};
    minC = cel{i, 4};
    maxC = cel{i, 5};
    
    flag = 0;
    R = maxR - minR;
    C = maxC - minC;
    
    a = cel{i, 1};
    
    stage = 0;
    first = 1;
    Onecount = 0;
    height = 0;
    temp = 0;
    widthT = 0;
    avg = 0;
    
    for i = minR:maxR
        width = 10000000000000;
        first = 1;
        init = 0;
        
        for j = minC:maxC
            if ( a(i, j) == 1)
                if( first == 1)
                    first = 0;
                    init = j;
                else
                    if( j - init < width)
                      width = j - init;
                    end
                    first = 1;
                end
            end
        end
        if( stage == 0 )
            if( width > avg * .8 )
                widthT = width + widthT;
                Onecount = Onecount + 1;
                avg = widthT / Onecount;
                height = 0;
            elseif (width < avg * .2) 
                height = height + 1;
            end
            
            if( height > 5 )
                flag = 1;
            end
        end
        
%         if( temp > width)
%             stage = 1;
%         else
%             temp = width;
%         end
%     end
%     maxWidth = temp;
%     widthT = widthT / R;
%      if( stage == 0 )
%             if( temp > width && width > R * .4)
%                 stage = 1;
%             else
%                 temp = width;
%             end
%         end    
%         
%         if( stage == 1 )
%             if( width < nar )
%                 height = height + 1;
%             else
%                 height = 0;
%             end
%             
%             if (height > 10)
%                 stage = 2;
%                 flag = 1;
%             end
    end
end

end

