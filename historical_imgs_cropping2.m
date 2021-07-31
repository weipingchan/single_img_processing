function [bwboardimgs,bwboardimg0s]=historical_imgs_cropping2(wbimg0s,img0s)
chanel940=wbimg0s{2};

[prow,pcol]=size(chanel940);
panel_board=imdilate(imerode(bwareaopen(imbinarize(imfill(imcomplement(chanel940)),0.7),prow*pcol/4),strel('disk',800)),strel('disk',800));
stats_board = regionprops(panel_board, 'BoundingBox');
bounding=stats_board(1).BoundingBox;
upbond=ceil(bounding(2));
lowbond=floor(bounding(2)+bounding(4));
leftbond=ceil(bounding(1));
rightbond=floor(bounding(1)+bounding(3));

bwboardimgs=cell(size(wbimg0s));
    for im = 1: size(wbimg0s,1)
      bwboardimgs{im}= wbimg0s{im}(upbond:lowbond,leftbond:rightbond,:);
    end
    
bwboardimg0s=cell(size(img0s));
    for in = 1: size(img0s,1)
      bwboardimg0s{in}= img0s{in}(upbond:lowbond,leftbond:rightbond,:);
    end
end