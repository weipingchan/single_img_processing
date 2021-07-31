function [cen1, rad1,cen0, rad0, refscale0] = findRef(img,threshold)
ref1=imerode(imdilate(imfill(imclearborder(bwareaopen(imbinarize(imadjust(rgb2gray(img)),0.8),round(length(img)/20)^2)),'holes'),strel('disk',20)),strel('disk',20));
ref0=imerode(imdilate(imclearborder(bwareaopen(imbinarize(imcomplement(imadjust(rgb2gray(img))),0.95),round(length(img)/20)^2)),strel('disk',100)),strel('disk',150));

[cen1,rad1]=find1Ref(ref1,threshold);
[cen0,rad0]=find1Ref(ref0,threshold);
refscale0=rad1*5/4*2;

if (rad0<4/5*rad1) || (rad0>6/5*rad1) 
    cen0=[0,0];
    rad0=0;
    disp('Find only WHITE standard reference.');
else
    disp('Find WHITE and BLACK standard references.');
end

function [center,radii] = find1Ref(img,threshold)
[refB,refL] = bwboundaries(img,'noholes');
stats = regionprops(refL,'Area','Centroid','MajorAxisLength','MinorAxisLength');

if isempty(refB)
    center = [0,0];
    radii = 0;
else
% loop over the boundaries
for k = 1:length(refB)

  % obtain (X,Y) boundary coordinates corresponding to label 'k'
  boundary = refB{k};

  % compute a simple estimate of the object's perimeter
  delta_sq = diff(boundary).^2;    
  perimeter = sum(sqrt(sum(delta_sq,2)));
  
  % obtain the area calculation corresponding to label 'k'
  area = stats(k).Area;
  
  % compute the roundness metric
  metric = 4*pi*area/perimeter^2;
  
  if (metric > threshold) && (area>round(length(img)/20)^2)
    center = stats(k).Centroid;
    diameters = mean([stats(k).MajorAxisLength stats(k).MinorAxisLength],2);
    radii = diameters/2*4/5;
  end
  
end
end
if exist('center')==0
    center = [0,0];
    radii = 0;
end

end
end
