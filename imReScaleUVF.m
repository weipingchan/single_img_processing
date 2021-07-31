function imgRescale = imReScaleUVF(img, blackStd, whiteStd )
redres = mat2gray(img(:,:,1), [blackStd(1), whiteStd(1)]);
greenres = mat2gray(img(:,:,2), [blackStd(2), whiteStd(2)]);
blueres = mat2gray(img(:,:,3), [blackStd(3), whiteStd(3)]);

% Recombine separate color channels into an gray image.
imgRescale = mean(cat(3, redres, greenres, blueres),3);
end
