function [wingVector,tanRefPt] = findWingVector(maskf2,realCen,boundingBox,verVector,part)
%%This function is used to find the tangent slope at the side of the wing
% through analyzing the minimal bounding triangle multiple times, the slope
% at the side of wings should always be the same, thus the most frequent
% one.

prebeltWparList=[0.15,0.2,0.25,0.3,0.35,0.4,0.5];
vecTriList=[];
for prebeltn=1:length(prebeltWparList)
    prebeltWpar=prebeltWparList(prebeltn);
    beltwidth=boundingBox(3)*prebeltWpar;

    beltR=[realCen+[+round(beltwidth/2) 0]-verVector ; realCen+[+round(beltwidth/2) 0]+verVector];
    beltL=[realCen+[-round(beltwidth/2) 0]-verVector ; realCen+[-round(beltwidth/2) 0]+verVector];

    if part=='L'
        bwline=[size(maskf2,2)+1, size(maskf2,1)+1; size(maskf2,2), -1];
        verBeltRegion=[bwline;flip(beltL,1)];
        sidePt=[size(maskf2,2)/2,1];
    elseif part =='R'
        bwline=[-1, size(maskf2,1)+1; -1, -1 ];
        verBeltRegion=[beltR;flip(bwline,1)];
        sidePt=[size(maskf2,2)/2,size(maskf2,1)];
    end
    verbeltmaskRe= imcomplement(poly2mask(verBeltRegion(:,1),verBeltRegion(:,2),size(maskf2,1),size(maskf2,2)));
    sideMask=bwareafilt(immultiply(maskf2, verbeltmaskRe),2);

    [sideB,~]=bwboundaries(sideMask);
    sppSideEdgePt=sideB{1};

    [sideTrix,sideTriy] = minboundtri(sppSideEdgePt(:,1),sppSideEdgePt(:,2));
    
    triPtList=[sideTrix,sideTriy];

    d1 = point_to_line(sidePt, triPtList(1,:), triPtList(2,:));
    d2 = point_to_line(sidePt, triPtList(2,:), triPtList(3,:));
    d3 = point_to_line(sidePt, triPtList(3,:), triPtList(4,:));
    [~,minLoc]=min([d1,d2,d3]);
    vecTri=diff(sideTriy)./diff(sideTrix);
    
    vecTriList=[vecTriList; [triPtList(minLoc:minLoc+1,:), [vecTri(minLoc:minLoc,:); vecTri(minLoc:minLoc,:)]]]; %Here, prebeltn act as an non-constant value
end
verSlope=verVector(1)/verVector(2);
tmpList=round(vecTriList(:,3),3);
wingSlope0=mode(tmpList(tmpList~=round(verSlope,3))); %FInd the commonest value except verSlope of verVector
pointLoc1=find(round(vecTriList(:,3),3)==wingSlope0, 1, 'first');
pointList=vecTriList(pointLoc1:pointLoc1+1,1:2);
tanRefPt=flip(pointList(1,:));
wingSlope=vecTriList(pointLoc1,3);
wingVector=[1,1/wingSlope]*max(size(maskf2));
end