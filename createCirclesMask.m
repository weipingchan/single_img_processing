function Cmask = createCirclesMask(panel, centers, radii)
%Create a circular mask according to the given center location and radii on
%the given canvas (providing the informaiton of the size of canvas)
[xDim,yDim] = size(panel);
xc = centers(:,1);
yc = centers(:,2);
[xx,yy] = meshgrid(1:yDim,1:xDim);
Cmask = false(xDim,yDim);
for ii = 1:numel(radii)
	Cmask = Cmask | hypot(xx - xc(ii), yy - yc(ii)) <= radii(ii);
end
end