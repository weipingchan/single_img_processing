function imgDiffDist=checkImgDiffDist(movingin,movingRegisteredAffineWithIC)
%summarize the distance between the corresponding landmarks in two images
%in order to be provided as an index for alignment
        Idouble = im2double(grayImg(movingin)); 
        avg = mean2(Idouble);        

        checkOri=imdilate(imfill(bwareaopen(imerode(imbinarize(imadjust(grayImg(movingin),[0, 1.2*avg],[])),strel('disk',5)),100),'holes'),strel('disk',10));
        checkTrans=imdilate(imfill(bwareaopen(imerode(imbinarize(imadjust(grayImg(movingRegisteredAffineWithIC),[0, 1.2*avg],[])),strel('disk',5)),100),'holes'),strel('disk',10)); 
        checkImg=abs(checkOri-checkTrans);

        [~,edL,edN] = bwboundaries(checkOri,'noholes');
        stat = regionprops(edL,'Area','Perimeter');
        perimeterList=zeros(1,edN);
        for item=1:edN
            perimeterList(item)=stat(item).Perimeter;
        end
        imgDiffDist=length(checkImg(checkImg~=0) )/sum(perimeterList);
end