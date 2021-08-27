function imgRescale740 = imReScale740(img, blackStd, whiteStd )
    %rescale the pixel velue according to the pixel value at 0 and 1
    %reflectance, so the value will then represent the reflectance
    redres = mat2gray(img(:,:,1), [blackStd(1), whiteStd(1)]);
    greenres = mat2gray(img(:,:,2), [blackStd(2), whiteStd(2)]);

    % Add separate color channels into a gray image.
    imgRescale740 = mat2gray(imadd(redres,greenres));
end