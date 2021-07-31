function WimgOverlap=checkImgOverlapHis(fixedin,movingRegisteredAffineWithIC)
    if size(movingRegisteredAffineWithIC,3)>1
        checkImg1=grayImg(removeShadowHisRGB(imadjustn(movingRegisteredAffineWithIC),0.95)); %Use parameters derived manuallys to remove shadow and background
        checkImg2=imbinarize(grayImg(checkImg1-fixedin),0.05);
    else
        checkImg2=imbinarize(movingRegisteredAffineWithIC-fixedin,0.05);
    end
    WimgOverlap=length(checkImg2(checkImg2~=0) );
end