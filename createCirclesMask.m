function Cmask = createCirclesMask(panel, centers, radii)
[xDim,yDim] = size(panel);
xc = centers(:,1);
yc = centers(:,2);
[xx,yy] = meshgrid(1:yDim,1:xDim);
Cmask = false(xDim,yDim);
for ii = 1:numel(radii)
	Cmask = Cmask | hypot(xx - xc(ii), yy - yc(ii)) <= radii(ii);
end
end