function WimgOverlap=checkImgOverlap(fixedin,movingRegisteredAffineWithIC)
    if size(movingRegisteredAffineWithIC,3)>1
        checkImg2=imbinarize(grayImg(imadjustn(movingRegisteredAffineWithIC)-cat(3,fixedin,fixedin,fixedin)),0.05);
    else
        checkImg2=imbinarize(movingRegisteredAffineWithIC-fixedin,0.05);
    end
    WimgOverlap=length(checkImg2(checkImg2~=0) );
end