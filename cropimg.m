function cropedimgs=cropimg(wbimg0s,geometry_osize)
[geolen,~]=size(geometry_osize);
[imgn,~]=size(wbimg0s);
cropedimgs=cell(geolen,imgn);
% Crop the object and write to ObjCell
for in=1:geolen
    bounding=geometry_osize{in};
    for im = 1: imgn
        if bounding(1)-ceil((bounding(2)-bounding(1))/5)<1 upbond=1; else upbond=bounding(1)-ceil((bounding(2)-bounding(1))/5);, end;
        if bounding(2)+ceil((bounding(2)-bounding(1))/15)>size(wbimg0s{im},1) lowbond=size(wbimg0s{im},1);, else lowbond=bounding(2)+ceil((bounding(2)-bounding(1))/15);, end;
        if bounding(3)-ceil((bounding(4)-bounding(3))/20)<1 leftbond=1;, else leftbond=bounding(3)-ceil((bounding(4)-bounding(3))/20);, end;
        if bounding(4)+ceil((bounding(4)-bounding(3))/20)>size(wbimg0s{im},2) rightbond=size(wbimg0s{im},2);, else rightbond=bounding(4)+ceil((bounding(4)-bounding(3))/20);, end;
      cropedimgs{in,im}= wbimg0s{im}(upbond:lowbond,leftbond:rightbond,:);
      %disp(['in: ',num2str(in),' and im: ',num2str(im),' is done.']);
    end
end
end