function imgRescaleUV = imReScaleUV(img, blackStd, whiteStd )
redres = mat2gray(img(:,:,1), [blackStd(1), whiteStd(1)]);
blueres = mat2gray(img(:,:,3), [blackStd(3), whiteStd(3)]);

% Add separate color channels into an gray image.
imgRescaleUV = mat2gray(imadd(redres,blueres));
end