function [movingRegisteredAffineWithIC,tformSpecimen]=reRegisterAdv(movingorigin,movingAdj, fixedin)
    %transform the image in order to align with another one
    moving=movingAdj;
    fixed=fixedin;
    [optimizer,metric] = imregconfig('multimodal');

    try
        %These two parameters can be changed if needed
        optimizer.InitialRadius = optimizer.InitialRadius/2.5;
        optimizer.MaximumIterations = 100;

        tformSimilarity = imregtform(moving,fixed,'similarity',optimizer,metric);

        tformSpecimen = imregtform(moving,fixed,'affine',optimizer,metric,...
        'InitialTransformation',tformSimilarity);
    catch
        tformSpecimen = affine2d([1,0,0; 0,1,0; 0,0,1]);
    end
    Rfixed = imref2d(size(fixed));
    movingRegisteredAffineWithIC = imwarp(movingorigin,tformSpecimen,'OutputView',Rfixed);
end