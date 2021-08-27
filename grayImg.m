function gray=grayImg(inimg)
%convert image to gray scale
    [~, ~, chab]=size(inimg);
    if chab>1
        gray=rgb2gray(inimg);
    else
        gray=inimg;
    end
end