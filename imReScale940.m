function imgRescale940 = imReScale940(img, blackStd, whiteStd )
%rescale the pixel velue according to the pixel value at 0 and 1
%reflectance, so the value will then represent the reflectance
    redres = mat2gray(img(:,:,1), [blackStd(1), whiteStd(1)]);
    greenres = mat2gray(img(:,:,2), [blackStd(2), whiteStd(2)]);
    blueres = mat2gray(img(:,:,3), [blackStd(3), whiteStd(3)]);

    % Add separate color channels into an gray image.
    imgRescale940 = mat2gray(imadd(imadd(redres,greenres),blueres));
end