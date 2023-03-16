function T = isoThreshold(img)
    minV = min(img(:));
    maxV = max(img(:));
    step = (maxV - minV)/256;
    start = minV + step/2;
    
    bins = zeros(256,1);
    for i = 1:256
        bins(i) = start + (i - 1) * step;
    end
    
    [n,xout] = hist(img, bins);
    
    counts = zeros(256,1);
    for i = 1:256
        counts(i) = sum(n(i,:));
    end
    
    movingIndex = 1;
    while true
        sum1 = 0;
        sum2 = 0;
        for i = 1:movingIndex
            sum1 = sum1 + counts(i) * i;
            sum2 = sum2 + counts(i);
        end
        sum3 = 0;
        sum4 = 0;
        for i = (movingIndex+1):256
            sum3 = sum3 + counts(i) * i;
            sum4 = sum4 + counts(i);
        end
        newIndex = (sum1/sum2 + sum3/sum4)/2;
        if ((newIndex - round(newIndex) > 0.48) && (newIndex - round(newIndex) < 0.5))
            newIndex = newIndex + 0.02;
        end
    
        if((movingIndex+1) > round(newIndex)) || (movingIndex >= 256)
            break;
        end
        movingIndex = movingIndex + 1;
    end
    
    T = round(xout(movingIndex) + 5*step/6);
end