function [cmscale,GscaleUR,GscaleLL,scaleBox] = findScale(img,evidence)
%Identify the scale bar and extract the number of pixels for one centimeter
%according to the scale bar

%Find the location of a scale bar
scaleBox=findScale1(img,evidence);

if sum(sum(scaleBox))>0
%Extract the scale bar based on the drawer image and the box indicating the
%location of the scale bar
    [cmscale,GscaleUR,GscaleLL]=Cm2Pixel(img,scaleBox);
else
    cmscale=0;
    GscaleUR=[0,0];
    GscaleLL=[0,0];
end
function newBoxPolygon = findScale1(img,targetObject)

%Find one scale bar
boxImage = imbinarize(imadjust(rgb2gray(imread(targetObject))));
sceneImage=imadjust(rgb2gray(img));

boxPoints = detectSURFFeatures(boxImage);
scenePoints = detectSURFFeatures(sceneImage);
scenePoints = scenePoints(scenePoints.Location(:,1)<ceil(size(img,2)/3),:); %Restrict the points of interest to 1/3 left side of the board

[boxFeatures, boxPoints] = extractFeatures(boxImage, boxPoints);
[sceneFeatures, scenePoints] = extractFeatures(sceneImage, selectStrongest(scenePoints,ceil(size(scenePoints,1)/3)));

boxPairs = matchFeatures(boxFeatures, sceneFeatures);

matchedBoxPoints = boxPoints(boxPairs(:, 1), :);
matchedScenePoints = scenePoints(boxPairs(:, 2), :);
if (length(boxPairs))>4&&((length(unique(boxPairs(:,1)))/length(unique(boxPairs(:,2)))<2)&&(length(unique(boxPairs(:,1)))/length(unique(boxPairs(:,2)))>0.5))
[tform, inlierBoxPoints, inlierScenePoints,status] = ...
    estimateGeometricTransform(matchedBoxPoints, matchedScenePoints, 'affine');

    if length(inlierBoxPoints)>4 && (length(unique(inlierScenePoints.Location(:,1)))>1&&length(unique(inlierScenePoints.Location(:,2)))>1)
        boxPolygon = [1, 1;...                           % top-left
                size(boxImage, 2), 1;...                 % top-right
                size(boxImage, 2), size(boxImage, 1);... % bottom-right
                1, size(boxImage, 1);...                 % bottom-left
                1, 1];                   % top-left again to close the polygon

        newBoxPolygon = transformPointsForward(tform, boxPolygon);

    else
        empty(1:5,1:2) = 0;
        newBoxPolygon=empty;
    end
else
    empty(1:5,1:2) = 0;
    newBoxPolygon=empty;
end
end
end