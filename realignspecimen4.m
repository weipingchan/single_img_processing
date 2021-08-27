function realignedcropedimgs=realignspecimen4(cropedimgs,refno,pauseornot)
%realign all bands to the reference band. Note that this is easily failed
%when the background is bright with shadows

[geolen,imgn]=size(cropedimgs);
imgDiffDistThreshold=10; %This value is derived from acceptable transformation results

disp('Start to align different images (bands) of a specimen');
realignedcropedimgs=cell(geolen,imgn);
for in=1:geolen
   fixedin=cropedimgs{in,refno};  %The reference img should always be 940
    
    %%%%%%%%%%%%%%% 740 nm%%%%%%%%%%%%%%%%%%%%%%%%%
    im=1;
    movingin=cropedimgs{in,im}; 
    movingorigin=movingin;
    fixedin=grayImg(fixedin); 
    movingAdj = imadjust(grayImg(movingin)); %Adjust the image for registration only 
    [movingRegisteredAffineWithIC,~]=reRegisterAdv(movingorigin,movingAdj, fixedin); %Derive the transform matrix
    realignedcropedimgs{in,im}=movingRegisteredAffineWithIC;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %%%%%%%%%%%%%%% 940 nm%%%%%%%%%%%%%%%%%%%%%%%%%
    im=2;
    realignedcropedimgs{in,im}=cropedimgs{in,im};
    
    disp(['Band 1-2 in specimen No. ',num2str(in),' is aligned.']);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %%%%%%%%%%%%%%%UV, UVF, UVinRGB, UVFinRGB%%%%%%%%%%%%%%%%%%%%%%%%%
    UVseriesimgOverlap=cell(1,2);
    UVseriesimgDiffDist=cell(1,2);
    UVseriesimgtform=cell(1,2);
    for im=3:4
        movingin=cropedimgs{in,im}; 
        movingorigin=movingin;
        Idouble = im2double(grayImg(movingin)); 
        avg = mean2(Idouble);
        fixedin=grayImg(fixedin); 

        %%%%%%%%%%%%
        SingleBandOverlap=cell(1,3);
        SingleBandDiffDist=cell(1,3);
        SingleBandtform=cell(1,3);
        for treat=1:4
            disp(['treat ',num2str(treat)]);
            if treat==1
                movingAdj = imadjust(adapthisteq(grayImg(movingin)),[0, avg],[],1.2); %Adjust the image for registration only 
            elseif treat==2
                movingAdj = imadjust(grayImg(movingin),[0, avg],[],1.2); %Adjust the image for registration only 
            elseif treat==3
                movingAdj = imadjust(grayImg(movingin)); %Adjust the image for registration only 
            else
                movingAdj = grayImg(movingin); %Adjust the image for registration only 
            end

            [movingRegisteredAffineWithIC,tformSpecimenUVseries]=reRegisterAdv(movingorigin,movingAdj, fixedin); %Derive the transform matrix from UVF for FinRGB
            imgDiffDist=checkImgDiffDist(movingin,movingRegisteredAffineWithIC);
            WimgOverlap=checkImgOverlap(fixedin,movingRegisteredAffineWithIC);
            SingleBandOverlap{treat,1}=WimgOverlap;
            SingleBandDiffDist{treat,1}=imgDiffDist;
            SingleBandtform{treat,1}=tformSpecimenUVseries;
        end
        [~,MinOverlapIdx]=min(cell2mat(SingleBandOverlap));        
        
        UVseriesimgOverlap{im-2,1}=SingleBandOverlap{MinOverlapIdx};
        UVseriesimgDiffDist{im-2,1}=SingleBandDiffDist{MinOverlapIdx};
        UVseriesimgtform{im-2,1}=SingleBandtform{MinOverlapIdx};
    end
    [~,UVMinOverlapIdx]=min(cell2mat(UVseriesimgOverlap));
    
    
    if (UVseriesimgDiffDist{1,1}< imgDiffDistThreshold  && UVMinOverlapIdx==1)      %UV band is the top priority for alignment
        UVfixedin=cropedimgs{in,3};
        UVFmovingin=cropedimgs{in,4}; 
        UVFmovingAdj = imadjust(grayImg(UVFmovingin)); %Adjust the image for registration only 
        [UVFmovingRegisteredAffineWithIC,tformSpecimenUVF]=reRegisterAdv(UVFmovingin,UVFmovingAdj, UVfixedin);

        Rfixed = imref2d(size(UVfixedin));
        RfixedRef= imref2d(size(fixedin));
        UVFmovingRegisteredAffineWithIC2 = imwarp(UVFmovingRegisteredAffineWithIC,UVseriesimgtform{1,1},'OutputView',RfixedRef); %Use the trasformation of UV

        UVmovingRegisteredAffineWithIC2 = imwarp(UVfixedin,UVseriesimgtform{1,1},'OutputView',RfixedRef); %Use the trasformation of UV

        UVinRGBmovingRegisteredAffineWithIC2 = imwarp(cropedimgs{in,imgn-1},UVseriesimgtform{1,1},'OutputView',RfixedRef); %Use the trasformation of UV

        UVFinRGBmovingRegisteredAffineWithIC = imwarp(cropedimgs{in,imgn},tformSpecimenUVF,'OutputView',Rfixed); %Use the trasformation of UVF
        UVFinRGBmovingRegisteredAffineWithIC2 = imwarp(UVFinRGBmovingRegisteredAffineWithIC,UVseriesimgtform{1,1},'OutputView',RfixedRef); %Use the trasformation of UV
                
        disp(['The minimal DiffDist is ',num2str(UVseriesimgDiffDist{1,1}),' < DiffDistThreshold (',num2str(imgDiffDistThreshold),'); transformation is firstly applied to UV bands.']);
    elseif UVseriesimgDiffDist{2,1}< imgDiffDistThreshold  && UVMinOverlapIdx==2             %UVF band is the second choice for alignment
        UVFfixedin=cropedimgs{in,4};
        UVmovingin=cropedimgs{in,3}; 
        UVmovingAdj = imadjust(grayImg(UVmovingin)); %Adjust the image for registration only 
        [UVmovingRegisteredAffineWithIC,tformSpecimenUV]=reRegisterAdv(UVmovingin,UVmovingAdj, UVFfixedin);

        Rfixed = imref2d(size(UVFfixedin));
        RfixedRef= imref2d(size(fixedin));
        UVmovingRegisteredAffineWithIC2 = imwarp(UVmovingRegisteredAffineWithIC,UVseriesimgtform{2,1},'OutputView',RfixedRef); %Use the trasformation of UVF

        UVFmovingRegisteredAffineWithIC2 = imwarp(UVFfixedin,UVseriesimgtform{2,1},'OutputView',RfixedRef); %Use the trasformation of UVF

        UVinRGBmovingRegisteredAffineWithIC = imwarp(cropedimgs{in,imgn-1},tformSpecimenUV,'OutputView',Rfixed); %Use the trasformation of UV
        UVinRGBmovingRegisteredAffineWithIC2 = imwarp(UVinRGBmovingRegisteredAffineWithIC,UVseriesimgtform{2,1},'OutputView',RfixedRef); %Use the trasformation of UV

        UVFinRGBmovingRegisteredAffineWithIC2 = imwarp(cropedimgs{in,imgn},UVseriesimgtform{2,1},'OutputView',RfixedRef); %Use the trasformation of UV
        disp(['The minimal DiffDist is ',num2str(UVseriesimgDiffDist{2,1}),' < DiffDistThreshold (',num2str(imgDiffDistThreshold),'); transformation is firstly applied to UVF bands.']);
    else             %If realignment doesn't work, use the original image
        UVmovingRegisteredAffineWithIC2=cropedimgs{in,3};
        UVFmovingRegisteredAffineWithIC2=cropedimgs{in,4};
        UVinRGBmovingRegisteredAffineWithIC2=cropedimgs{in,imgn-1};
        UVFinRGBmovingRegisteredAffineWithIC2=cropedimgs{in,imgn};
    end

    realignedcropedimgs{in,3}=UVmovingRegisteredAffineWithIC2;
    realignedcropedimgs{in,4}=UVFmovingRegisteredAffineWithIC2;
    realignedcropedimgs{in,imgn-1}=UVinRGBmovingRegisteredAffineWithIC2;
    realignedcropedimgs{in,imgn}=UVFinRGBmovingRegisteredAffineWithIC2;
    
    disp(['Band 3, 4, 8, 9 in specimen No. ',num2str(in),' is aligned.']);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%white, whitePo1, whitePo2%%%%%%%%%%%%%%%%%%%%%%%%%
    WhiteseriesimgOverlap=cell(1,3);
    WhiteseriesimgDiffDist=cell(1,3);
    Whiteseriesimgtform=cell(1,3);
    for im=5:imgn-2
        movingin=cropedimgs{in,im}; 
        movingorigin=movingin;
        Idouble = im2double(grayImg(movingin)); 
        avg = mean2(Idouble);
        fixedin=grayImg(fixedin); 
        RfixedRef= imref2d(size(fixedin));
        
        SingleBandOverlap=cell(1,3);
        SingleBandDiffDist=cell(1,3);
        SingleBandtform=cell(1,3);
        for treat=1:3 
            disp(['treat ',num2str(treat)]);
            if treat==1
                movingAdj = imadjust(grayImg(movingin),[0, avg],[],1.5); %Adjust the image for registration only 
            elseif treat==2
                movingAdj = grayImg(movingin); %Adjust the image for registration only 
            else
                nColors = 3;
                ab = im2uint16(movingin);
                % repeat the clustering 3 times to avoid local minima
                pixel_labels =imsegkmeans(ab,nColors); %Use image pixel clustering method to find better segments. This function is available in only V.2018b
                movingAdj=imadjust(pixel_labels);
            end

            [movingRegisteredAffineWithIC,tformSpecimenWhiteSeries]=reRegisterAdv(movingorigin,movingAdj, fixedin); %Derive the transform matrix from UVF for FinRGB
            WimgDiffDist=checkImgDiffDist(movingin,movingRegisteredAffineWithIC);
            WimgOverlap=checkImgOverlap(fixedin,movingRegisteredAffineWithIC);
            SingleBandOverlap{treat,1}=WimgOverlap;
            SingleBandDiffDist{treat,1}=WimgDiffDist;
            SingleBandtform{treat,1}=tformSpecimenWhiteSeries;
        end
        [~,MinOverlapIdx]=min(cell2mat(SingleBandOverlap));        
        
        WhiteseriesimgOverlap{im-4,1}=SingleBandOverlap{MinOverlapIdx};
        WhiteseriesimgDiffDist{im-4,1}=SingleBandDiffDist{MinOverlapIdx};
        Whiteseriesimgtform{im-4,1}=SingleBandtform{MinOverlapIdx};
    end    
        [~,WhiteMinOverlapIdx]=min(cell2mat(WhiteseriesimgOverlap)); %Find the best template index out of 3 RGB images
                        
        imgDiffDist=WhiteseriesimgDiffDist{WhiteMinOverlapIdx};
        Whitetform=Whiteseriesimgtform{WhiteMinOverlapIdx};
        
        remainingList=[[6,7];[5,7];[5,6]];
    if imgDiffDist<imgDiffDistThreshold
        WhiteFixedin=cropedimgs{in,WhiteMinOverlapIdx+4}; %Use the best RGB image as the registration template to register the rest
        RfixedRef= imref2d(size(WhiteFixedin));
        movingRegisteredAffineWithIC= imwarp(WhiteFixedin,Whitetform,'OutputView',RfixedRef); 
        realignedcropedimgs{in,WhiteMinOverlapIdx+4}= movingRegisteredAffineWithIC;
        disp(['The minimal DiffDist is ',num2str(imgDiffDist),' < DiffDistThreshold (',num2str(imgDiffDistThreshold),'); transformation is applied to RGB bands.']);
                
        forList=remainingList(WhiteMinOverlapIdx,:);
        for imd=1:size(forList,2)
            movingin=cropedimgs{in,forList(imd)};
            [tmpWhiteMovingRegisteredAffineWithIC,~]=reRegisterAdv(movingin,grayImg(movingin),grayImg(WhiteFixedin)); %First realign the import image with the White template
            WhiteMovingRegisteredAffineWithIC= imwarp(tmpWhiteMovingRegisteredAffineWithIC,Whitetform,'OutputView',RfixedRef); %Then use the transform matrix of that template to realign the image
            realignedcropedimgs{in,forList(imd)}= WhiteMovingRegisteredAffineWithIC;
        end   
    else
        for im=5:imgn-2
            realignedcropedimgs{in,im}=cropedimgs{in,im};   
        end
    end
    
    %further align polarized image to Polarized 0
    WhitePolFixedin=realignedcropedimgs{in,6}; %Use the Po0 as the registration template to register the Po1
    movingin=realignedcropedimgs{in,7};
    [WhitePolMovingRegisteredAffineWithIC,~]=reRegisterAdv(movingin,grayImg(movingin),grayImg(WhitePolFixedin));
    realignedcropedimgs{in,7}= WhitePolMovingRegisteredAffineWithIC;
    
    disp(['Band 5-7 in specimen No. ',num2str(in),' is aligned.']);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if pauseornot==1
        pause(90) %Prevent CPU from overheating. Turn off while running the script on clusters
    end
    disp(['Specimen No. ',num2str(in),' out of ',num2str(geolen),' is aligned.']);
end
disp('Different images (bands) of a specimen are aligned');


function gray=grayImg(inimg)
    [~, ~, chab]=size(inimg);
    if chab>1
        gray=rgb2gray(inimg);
    else
        gray=inimg;
    end
end

end