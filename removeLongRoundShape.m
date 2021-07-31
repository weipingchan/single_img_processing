function selectedImg=removeLongRoundShape(panel_ff,shapethreshold)
[subedB,subedL,subedN] = bwboundaries(panel_ff,'noholes');
statsed_ff = regionprops(subedL,'Area','MajorAxisLength','MinorAxisLength','BoundingBox','Perimeter');
%figure,imshow(ref_thumbnail); hold on;

% Get areas and perimeters of all the regions into single arrays.
allAreas = [statsed_ff.Area];
allPerimeters = [statsed_ff.Perimeter];
allLength=[statsed_ff.MajorAxisLength];
allWidth=[statsed_ff.MinorAxisLength];

% Compute circularities.
circularities = (4*pi*allAreas) ./ allPerimeters.^2;

% Compute aspect ratio.
aspect = allLength ./ allWidth;

keeperBlobs = circularities < shapethreshold & aspect < 3;
% Get actual index numbers instead of a logical vector
% so we can use ismember to extract those blob numbers.
wantedObjects = find(keeperBlobs);
% Compute new binary image with only the small, round objects in it.
selectedImg = ismember(subedL, wantedObjects) > 0;
end