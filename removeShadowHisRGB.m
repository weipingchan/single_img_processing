function newRGBimg=removeShadowHisRGB(rgbImage,backgroundRemovalP)
%Remove the multiple shadows according to the empirical value when the
%background is not dark enough
    % Get mask for outer gray, and inner blue parts of the wheel by doing color segmentations.
    [mask0, ~] = createShadowMaskforHisRGB(rgbImage);
    % Clean up noise by filling holes and taking largest blob only.
    shadowMask = imcomplement(imdilate(bwareaopen(imerode(imfill(mask0, 'holes'),strel('disk',5)),100),strel('disk',6)));
    newRGBimg=rgbImage-immultiply(rgbImage,cat(3,shadowMask,shadowMask,shadowMask))*backgroundRemovalP;
end