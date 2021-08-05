function [px1, px0, cen1, rad1, cen0, rad0, cmscale,GscaleUR,GscaleLL,scaleBox] = findRefScale(img, shapethreshold, evidence,blackP,whiteP)
%Find the white, balck standard references and the scale according to the
%input image (should be in NIR wavelength band)

%Find white and black reference
[cen1, rad1,cen0, rad0, refscale0] = findRef(img,shapethreshold);

%Extract the scale bar based on the scence image and the box indicating the
%location of the scale bar
[cmscale,GscaleUR,GscaleLL,scaleBox]=findScale(img,evidence);

if cmscale==0
    cmscale=round(10/32*refscale0);
    GscaleUR=[200,200];
    GscaleLL=[200+cmscale,200];
    disp('CANNOT find any scale.');
else
    disp('Find the scale.');
end

px0=refVal(img,cen0,rad0);
px1=refVal(img,cen1,rad1);

%In case no black reference
if (rad1>0) && (mean(px0)<0 || mean(px0)>300)
    px0=refNoBlack(img,cen1,rad1);  %Use the black plastic circcle as black reference
    cen0=zeros(1,2); %reset the BLACK reference to dispearence
    rad0=0;
    disp('The BLACK reference found in the previous step is fake, so it is disgarded.');
end

%extract the reflectance on the standard black and white references and get
%the pixel value for the real 0 and 1 reflectance
if rad0>0 && mean(px0)<300
    [px0(1), px1(1)]=findRealpx0px1(px0(1), blackP, px1(1), whiteP);
    [px0(2), px1(2)]=findRealpx0px1(px0(2), blackP, px1(2), whiteP);
    [px0(3), px1(3)]=findRealpx0px1(px0(3), blackP, px1(3), whiteP);
elseif mean(px0)>0
    %if use black platform as the black reference
    blackPRG=3.7680; %The reflectance for R and G band
    blackPB=2.6149; %The reflectance for B band
    [px0(1), px1(1)]=findRealpx0px1(px0(1), blackPRG, px1(1), whiteP);
    [px0(2), px1(2)]=findRealpx0px1(px0(2), blackPRG, px1(2), whiteP);
    [px0(3), px1(3)]=findRealpx0px1(px0(3), blackPB, px1(3), whiteP);
    disp('Use black platform as the BLACK standard reference.');
    disp(['The reflectance of bands are adjusted to: [RGB]-[',num2str(blackPRG),',',num2str(blackPRG),',',num2str(blackPB),']']);
else
    blackP=0; %if cannot even find a black platform
    [px0(1), px1(1)]=findRealpx0px1(px0(1), blackP, px1(1), whiteP);
    [px0(2), px1(2)]=findRealpx0px1(px0(2), blackP, px1(2), whiteP);
    [px0(3), px1(3)]=findRealpx0px1(px0(3), blackP, px1(3), whiteP);
    disp('Cannot even find a black platform as the BLACK standard reference.');
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
            circleImage = sqrt((cx-cen(1)).^2+(cy-cen(2)).^2)<=rad*5/4*1.1;
            redChannel = img(:,:,1); % Red channel
            greenChannel = img(:,:,2); % Green channel
            blueChannel = img(:,:,3); % Blue channel
            redRef=BT0(redChannel ,circleImage);
            greenRef=BT0(greenChannel ,circleImage);
            blueRef=BT0(blueChannel ,circleImage);
            revV=[redRef, greenRef, blueRef];
        else
            revV=[0, 0, 0];
            disp('Use (0,0,0) as BLACK standard reference.');
        end       
        function peakloc=BT0(channelimg,circleImage)
            midB=mean([min(channelimg(circleImage)),quantile(channelimg(circleImage),0.75)]);
            redB=channelimg(circleImage);
            redBb=redB(redB<midB);
             [counts, binlocation] = imhist(redBb);  %plus whatever option you used for imhist
            [~, indices] = sort(counts,'descend');    %sort your histogram
            peakloc = mean(binlocation(indices(1:3)));  %respective image intensities for these peaks
        end
 end
    
function [reff0, reff1]=findRealpx0px1(sblackStd, blackP, swhiteStd, whiteP)
    lincoef = polyfit([blackP, whiteP], [sblackStd, swhiteStd], 1);
    reff0=lincoef(2);
    reff1=lincoef(1)*100+lincoef(2);
end

end