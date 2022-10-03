function [geometry_osize,sppamounts]=find_specimen2(ref,shapethreshold,maxarea2rectangleratio,gatheringfactor,MinimalObjectSize)
%Search for the location of specimens in an image

disp('Start to find coarse outlines of specimens.');
ref_thumbnail=imresize(ref,1/4,'method','bilinear');
[nrow,ncol]=size(ref);

% Calculate geometric transformation matrix from original image
% to thumbnail, and the inverse matrix
fixpoints_o=[ 1, 1 ; size(ref,2), 1 ; size(ref,2), size(ref,1) ; 1, size(ref,1)];
fixpoints_t=[ 1, 1 ; size(ref_thumbnail,2), 1 ; size(ref_thumbnail,2), size(ref_thumbnail,1) ; 1, size(ref_thumbnail,1)];
tform_ot=MakeTransform('tm',fixpoints_o,fixpoints_t);
tform_to=inv(tform_ot);
clear fixpoints_o fixpoints_tim

disp('Start to use resolution consensus.');
for shrinkBase=1:5
    outImg=spRoughSearching(ref,(1+shrinkBase),shapethreshold,gatheringfactor);
    if shrinkBase==1
    config=outImg;
    else
    config(:,:,shrinkBase)=outImg;    
    end  
end

fig2=imadjust(imclearborder(imadjust(imfill(mean(config, 3)))));
fig3=bwareaopen(imerode(imresize(bwareaopen(imdilate(imbinarize(imclearborder(fig2),0.3),strel('disk',2)),MinimalObjectSize),[nrow,ncol],'method','bilinear'),strel('disk',5)),MinimalObjectSize);

[edB,edL,edN] = bwboundaries(fig3,'noholes');
statsed = regionprops(edL,'Area','Centroid','PixelIdxList','MajorAxisLength','MinorAxisLength','BoundingBox');

geometry=[];
for k = 1:length(edB)
    % obtain (X,Y) boundary coordinates corresponding to label 'k'
    boundary = edB{k};

    % compute a simple estimate of the object's perimeter
    delta_sq = diff(boundary).^2;    
    perimeter = sum(sqrt(sum(delta_sq,2)));

    % obtain the area calculation corresponding to label 'k'
    area = statsed(k).Area;

    % compute the roundness metric
    metric = 4*pi*area/perimeter^2;

    % calculate the maximal and minimal axes length
    len=statsed(k).MajorAxisLength;
    wid=statsed(k).MinorAxisLength;

    % calculate the area of bounding box
    boxl=statsed(k).BoundingBox(3);
    boxw=statsed(k).BoundingBox(4);
    boxarea=boxl*boxw;
    area2boxarea=area/boxarea;

    % 3 situations are avoided: Circle, Rectangle, and long shape since it may be the scale or standard references
    % mark objects above the threshold with a black circle
    if (metric < shapethreshold) && (area2boxarea<maxarea2rectangleratio) && (len/wid<3)
    geometry=[geometry,statsed(k)];
    end
end

%%% 2.4.4 Reindex objects
[~,obj_num]=size(geometry);

if prod(size(geometry))==0
    sppamounts=0; 
    obj_box=[5,5,size(ref,1)-10,size(ref,2)-10]; 
    disp('CANNOT find any specimen. A box approaching image size is provided');
else
    sppamounts=obj_num; 
    if obj_num==1
        obj_box=geometry.BoundingBox;
    else
        obj_box=cat(1,geometry.BoundingBox);

        xb=obj_box(:,1)+obj_box(:,3)/2;
        yb=obj_box(:,2)+obj_box(:,4)/2;
        dxb=mean(obj_box(:,3));
        dyb=mean(obj_box(:,4));

        box_ind=1:obj_num;
        col=zeros(size(xb));
        while sum(~col)
            temp = ( max(xb(~col))-xb ) / dxb;
            temp = temp < 1;
            temp = box_ind(temp);
            col(temp) = col(temp) + 1;
        end
        [ ~, I ] = sort(col+(yb-1)/max(yb));
        geometry=geometry(I);
        clear box_ind col temp I xb yb dxb dyb col

        obj_box=cat(1,geometry.BoundingBox); % obj order is rearranged
    end
end

siz=size(ref);
[geolen,~]=size(obj_box);
% Crop individual objects and store each of them in a cell
geometry_osize=cell(geolen,1);
for i=1:geolen
      % Get the bounding box of the i-th object and offset by 2 pixels in all
      % directions
      bb_i=ceil(obj_box(i,:));
      idx_x=[bb_i(1)-20 bb_i(1)+bb_i(3)+20];
      idx_y=[bb_i(2)-20 bb_i(2)+bb_i(4)+20];
      if idx_x(1)<1, idx_x(1)=1; end
      if idx_y(1)<1, idx_y(1)=1; end
      if idx_x(2)>siz(2), idx_x(2)=siz(2); end
      if idx_y(2)>siz(1), idx_y(2)=siz(1); end
      geometry_osize{i}=[idx_y(1), idx_y(2), idx_x(1), idx_x(2)];
end
disp(['Coarse outlines of ' ,num2str(size(geometry_osize,1)),' specimens are found.']);
end
