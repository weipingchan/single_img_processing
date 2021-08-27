function imgRescaleUV = imReScaleUV(img, blackStd, whiteStd )
    %rescale the pixel value according to the pixel value at 0 and 1
    %reflectance, so the value will then represent the reflectance
    redres = mat2gray(img(:,:,1), [blackStd(1), whiteStd(1)]);
    blueres = mat2gray(img(:,:,3), [blackStd(3), whiteStd(3)]);

    % Add separate color channels into a gray image.
    imgRescaleUV = mat2gray(imadd(redres,blueres));
end