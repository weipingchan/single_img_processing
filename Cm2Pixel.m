function [cmscale,GscaleUR,GscaleLL] = Cm2Pixel(img,scaleBox)
%Extract the scale bar based on the scence image and the box indicating the
%location of the scale bar
xLeft = min(scaleBox(:, 1));
xRight = max(scaleBox(:, 1));
yTop = min(scaleBox(:, 2));
yBottom = max(scaleBox(:, 2));
height = abs(yBottom - yTop);
width = abs(xRight - xLeft);
imgScale = imcrop(img, [xLeft, yTop, width, height]);

%Use scales as reference to generate unit convertion
imgScalebw=imbinarize(imadjust(rgb2gray(imgScale)));
imgScalebwBlur=bwareaopen(imerode(imdilate(imcomplement(bwareaopen(imcomplement(imgScalebw),round(length(imgScale)/20)^2)),strel('disk',15)),strel('disk',10)),round(length(imgScale)/20)^2);

imgscale=imerode(bwpropfilt(bwpropfilt(imcomplement(imgScalebwBlur),'Area',5,'largest'),'Area',4,'smallest'),strel('disk',5));

[scaB,scaL] = bwboundaries(imgscale,'noholes');
scaStats = regionprops(scaL,'Centroid','MajorAxisLength','Orientation');

%%convert the property of morphology into array
scaleMatrix = reshape([scaStats.MajorAxisLength], 1, []).';
cmscale=mean(scaleMatrix)*5/sqrt(32);
scaleCentroid=scaStats(2).Centroid;
scaleOri=scaStats(2).Orientation;

%Derive the location of a unit scale bar
ptscalelen=[cmscale*cosd(-scaleOri),cmscale*sind(-scaleOri)]/2;
scaleUR=scaleCentroid+ptscalelen;
scaleLL=scaleCentroid-ptscalelen;

GscaleUR=[scaleUR(1),scaleUR(2)]+[xLeft,yTop];
GscaleLL=[scaleLL(1),scaleLL(2)]+[xLeft,yTop];

end