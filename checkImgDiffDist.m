function imgDiffDist=checkImgDiffDist(movingin,movingRegisteredAffineWithIC)
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