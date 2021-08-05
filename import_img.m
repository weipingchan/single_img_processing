function corimg = import_img(file)
%Import images and rotate it if the position is incorrect.
    img = imread(file);
    corimg = img;
    [imheight, imwidth, imchannel]=size(img);
    if imheight>imwidth
        corimg=imrotate(corimg, 90);
    end
end