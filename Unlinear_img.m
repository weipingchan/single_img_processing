function ref=Unlinear_img(ref0)
%rescale images to reach the highest contrast
    redres = imadjust(ref0(:,:,1));
    greenres = imadjust(ref0(:,:,2));
    blueres = imadjust(ref0(:,:,3));
    % Add separate color channels into a gray image.
    ref = mat2gray(imadd(imadd(redres,greenres),blueres));
end