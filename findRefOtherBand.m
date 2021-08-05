function [px1, px0] = findRefOtherBand(img, cen1, rad1, cen0, rad0,blackP,whiteP)
%extract the reflectance on the standard black and white references and get
%the pixel value for the real 0 and 1 reflectance
px0=refVal(img,cen0,rad0);
px1=refVal(img,cen1,rad1);

%In case no black reference
if mean(px0)<0
    px0=refNoBlack(img,cen0,rad0);  %Use the black plastic circcle as black reference 
end

%Find the corresponding pixel value for the real 0 and 1 reflectance
if rad0>0
    [px0(1), px1(1)]=findRealpx0px1(px0(1), blackP, px1(1), whiteP);
    [px0(2), px1(2)]=findRealpx0px1(px0(2), blackP, px1(2), whiteP);
    [px0(3), px1(3)]=findRealpx0px1(px0(3), blackP, px1(3), whiteP);
elseif mean(px0)>0
    blackP=11.4519; %the reference platform is used as the black reference; This value is according to the standard reference we used.
    [px0(1), px1(1)]=findRealpx0px1(px0(1), blackP, px1(1), whiteP);
    [px0(2), px1(2)]=findRealpx0px1(px0(2), blackP, px1(2), whiteP);
    [px0(3), px1(3)]=findRealpx0px1(px0(3), blackP, px1(3), whiteP);
else
    blackP=0; %if cannot even find a black platform
    [px0(1), px1(1)]=findRealpx0px1(px0(1), blackP, px1(1), whiteP);
    [px0(2), px1(2)]=findRealpx0px1(px0(2), blackP, px1(2), whiteP);
    [px0(3), px1(3)]=findRealpx0px1(px0(3), blackP, px1(3), whiteP);
end

    function revV=refVal(img,cen,rad)
        if rad>0
        [imgrow, imgcol, ~] = size(img);
        [cx,cy] = meshgrid(1:imgcol, 1:imgrow);
        circleImage = sqrt((cx-cen(1)).^2+(cy-cen(2)).^2)<=rad;
        redChannel = img(:,:,1); % Red channel
        greenChannel = img(:,:,2); % Green channel
        blueChannel = img(:,:,3); % Blue channel
        redRef=mean(redChannel(circleImage));
        greenRef=mean(greenChannel(circleImage));
        blueRef=mean(blueChannel(circleImage));
        revV=[redRef, greenRef, blueRef];
        else
            revV=[-1, -1, -1];
        end
    end

%This function is using the black plastic circcle as black reference 
 function revV=refNoBlack(img,cen,rad)
        if rad>0
        [imgrow, imgcol, ~] = size(img);
        [cx,cy] = meshgrid(1:imgcol, 1:imgrow);
        circleImage = sqrt((cx-cen(1)).^2+(cy-cen(2)).^2)<=rad*1.1;
        redChannel = img(:,:,1); % Red channel
        greenChannel = img(:,:,2); % Green channel
        blueChannel = img(:,:,3); % Blue channel
        
        %maskedImage = bsxfun(@times, img, cast(circleImage,class(img)));
        redRef=BT0(redChannel ,circleImage);
        greenRef=BT0(greenChannel ,circleImage);
        blueRef=BT0(blueChannel ,circleImage);
        revV=[redRef, greenRef, blueRef];
        else
            revV=[-1, -1, -1];
        end
        
        function peakloc=BT0(channelimg,circleImage)
        midB=mean([min(channelimg(circleImage)),max(channelimg(circleImage))]);
        redB=channelimg(circleImage);
        redBb=redB(redB<midB);
         [counts, binlocation] = imhist(redBb);  %plus whatever option you used for imhist
        [~, indices] = sort(counts,'descend');    %sort your histogram
        %peakvalues = sortedcount(1:3);              %highest 3 count in the histogram
        peakloc = mean(binlocation(indices(1:3)));  %respective image intensities for these peaks
        end
    end
    
function [reff0, reff1]=findRealpx0px1(sblackStd, blackP, swhiteStd, whiteP)
lincoef = polyfit([blackP, whiteP], [sblackStd, swhiteStd], 1);
reff0=lincoef(2);
reff1=lincoef(1)*100+lincoef(2);
end

end