function [com, mainAxis,secAxis]=findSymetricAxes(inImg)
if size(inImg,3)>1, inImg=rgb2gray(inImg); end
imd=transpose(inImg);
[nx,ny] = size(imd);
Range_ny=1:ny;
Range_nx=1:nx;
%points = sortrows(transpose(combvec(Range_nx,Range_ny)),[1,2],{'ascend','descend'}); %works for 2017a
points = sortrows(transpose(combvec(Range_nx,Range_ny)),[1, -2]); %for 2016b and 2017a
weights =  transpose(reshape(imd.',1,[]));
mass = sum(weights);
com = sum(points .* weights) ./ mass;
pointsCom = horzcat(points(:,1)-com(1) , points(:,2)-com(2)) .* weights;
diag=sum(pointsCom(:,1) .* pointsCom(:,2));

inertia=zeros(2,2);
for i=1:2
    for j=1:2 
if i==j, kronecker=1; else, kronecker=0; end
        inertia(i,j)=kronecker*diag - sum(pointsCom(:,i) .* pointsCom(:,j));
    end
end

[symAxes,~] = eig(inertia);
mainAxis=symAxes(2,:);
secAxis=symAxes(1,:);
end