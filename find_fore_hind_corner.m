function forehindCorner=find_fore_hind_corner(mask,nStrongCorners,realCen,symAxis,tarCorner,nSection,boundingBox,beltWpar,beltHpar,slopeSwitch)
%Detect all salinent points
corners = detectHarrisFeatures(mask);
if nStrongCorners<size(corners.Location,1)
    Corners=corners.selectStrongest(nStrongCorners).Location;
else
    Corners=corners.Location;    
end
%%
%Calculate necessary vectors
verVector=symAxis*size(mask,1);
symOrtho=reshape(null(symAxis(:).'),1,[]);
horVector=symOrtho*size(mask,2);

%Derive the vector of the tangent line at left or right side of wings
jud=tarCorner(1)-realCen(1);
if jud<0
    part='L';
elseif jud>0
    part='R';
end

maskf2=bwareafilt(logical(imdilate(imfill(imerode(mask,strel('disk',10)),'hole'),strel('disk',2))),2); %Used for reduced area

if strcmp(slopeSwitch,'cenAxis')
    wingVector=verVector*max(size(maskf2));
    tanRefPt=tarCorner;
    disp('Using central vertical Axis as the vector');
else
    [wingVector, tanRefPt] = findWingVector(maskf2,realCen,boundingBox,verVector,part); %The function to find wind edge vector
    disp('Using automatically detected slope of the wing edge as the vector');
    %disp(['Parameter [wingVector]: ',num2str(beltWpar)]);
    %disp(['Parameter [tanRefPt]: ',num2str(tanRefPt)]);
end

% tt=[realCen+wingVector;realCen-wingVector];
% figure,imshow(maskf2);hold on;
% plot(tt(:,1),tt(:,2),'r');

%%
%Derive the belt information
beltwidth=boundingBox(3)*beltWpar;

%if boundingBox(3)/boundingBox(4)>2
    %beltheight=boundingBox(4)*0.15;
%else boundingBox(3)/boundingBox(4)>0.5
    beltheight=boundingBox(4)*beltHpar;
%end
beltupper=[realCen+[0 +round(beltheight/2)]-horVector ; realCen+[0 +round(beltheight/2)]+horVector];
beltlower=[realCen+[0 -round(beltheight/2)]-horVector ; realCen+[0 -round(beltheight/2)]+horVector];
horBeltRegion=[beltupper;flip(beltlower,1)];


% figure,imshow(maskf2);hold on;
% plot(horBeltRegion(:,1),horBeltRegion(:,2),'r');

%horSolvB=[-horVector(2)/horVector(1);1];
%beltlowerB=dot(beltlower(1,:),horSolvB);
%beltlowerLine=[horVector(2)/horVector(1); beltlowerB];
%%
%Find all edge points
[specimenB,~]=bwboundaries(mask);
sppEdgePt=specimenB{1};
%%
%Adjusting the target corner to prevent serious edge effect (i.e. many corners will be detected)
startAdj=sign(jud)*beltwidth/2;
%%
%Derive vectors of all evenly spaced line
[segPt2UL,~,~] = interparc(nSection,[realCen(1)+startAdj,tanRefPt(1)],[realCen(2),tanRefPt(2)]);
%%
%Derive all intersect points of all evenly spaced line
intersectAll=cell(length(segPt2UL),0);
for ptn=1:length(segPt2UL)
    tmpSegPts=[segPt2UL(ptn,:)-wingVector ; segPt2UL(ptn,:)+wingVector];
    [intersectX,intersectY]= polyxpoly(tmpSegPts(:,1),tmpSegPts(:,2),sppEdgePt(:,2),sppEdgePt(:,1));
    intersectAll{ptn} = [intersectX,intersectY];
end
%%
%Calculate 2 indices for determine the targeted point
%1. Number of segments
%2. If there is candidate points in the belt region
intersectSegCount=zeros(length(intersectAll),0);
intersectDistPtsCount=zeros(length(intersectAll),0);
intersectDistPts=[-1 -1 -1];
for ccc=1:length(intersectAll)
    intersectSegCount(ccc)=length(intersectAll{ccc})/2;
    intersectPts=intersectAll{ccc};
    inPts0 =inpolygon(intersectPts(:,1),intersectPts(:,2),horBeltRegion(:,1),horBeltRegion(:,2));
    inPts=intersectPts(inPts0,:);
    intersectDistPtsCount(ccc)=size(inPts,1);
    cIdx=ccc+zeros(size(inPts,1), 1);
    intersectDistPts=cat(1,intersectDistPts,cat(2,cIdx,inPts));            
end

%If there is candidate points in the belt region
intersectDistPtsCount2=intersectDistPtsCount; %preserve the original result
intersectDistPtsCount2(intersectDistPtsCount2>0)=1; %having value in belt -> 1
intersectDistPtsCount2(1)=0; %first value -> 1 prevent error

% Detect the changing point of Number of segments
intersectSegCountDiff=diff(intersectSegCount);
intersectSegCountDiff2=sign([0,intersectSegCountDiff]);
IdxLinear=findchangepts(intersectSegCount,'MaxNumChanges',6,'Statistic','linear'); %THE NUMBER OF CHANGING PT here is sensitve to damaged wings. 6 is enough in most cases.
IdxStd=findchangepts(intersectSegCount,'MaxNumChanges',6,'Statistic','std'); 
intersectSegCountDiff3=ones( [1,length(intersectSegCount)] );
intersectSegCountDiff3([IdxLinear,IdxStd])=2; %points shows the disconectivity to its neighbor
intersectSegCountDiff4=intersectSegCountDiff2.*intersectSegCountDiff3;
intersectSegCountDiff4(intersectSegCountDiff4<0)=0;

%Use all two indicies to determine the target segment line
intersectLoc=find(intersectDistPtsCount2.*intersectSegCountDiff4>=2, 1 );
if isempty(intersectLoc)
    intersectLoc=find(intersectDistPtsCount2.*intersectSegCountDiff4>=1, 1);
end

intersectLoc2=intersectLoc-1;
forehindCorners=[];
while isempty(forehindCorners)
    %The 2 intersect points on the target segment line
    closest2Pts=intersectDistPts(intersectDistPts(:,1)==intersectLoc2,2:end);
    %%
    %Calculate the vector for final local searching
    block0=[segPt2UL(intersectLoc2-1,:)-wingVector ; segPt2UL(intersectLoc2-1,:)+wingVector];
    block1=[segPt2UL(intersectLoc2,:)-wingVector ; segPt2UL(intersectLoc2,:)+wingVector];

    %Calculate the four corners for final local searching
    try
        fineBox=zeros(4,2);
        [fineBox(1,1),fineBox(1,2)]=polyxpoly(block0(:,1),block0(:,2),beltupper(:,1),beltupper(:,2));
        [fineBox(2,1),fineBox(2,2)]=polyxpoly(block0(:,1),block0(:,2),beltlower(:,1),beltlower(:,2));
        [fineBox(3,1),fineBox(3,2)]=polyxpoly(block1(:,1),block1(:,2),beltlower(:,1),beltlower(:,2));
        [fineBox(4,1),fineBox(4,2)]=polyxpoly(block1(:,1),block1(:,2),beltupper(:,1),beltupper(:,2));
        
        %Pick up all points in the final searching box
        inCorner = inpolygon(Corners(:,1),Corners(:,2),fineBox(:,1),fineBox(:,2));
        forehindCorners=Corners(inCorner,:);
    catch %if segments are not long enough to have intersection, elongate the segments and try again
        try
            beltupper=[realCen+[0 +round(beltheight/2)]-horVector*10^5 ; realCen+[0 +round(beltheight/2)]+horVector*10^5];
            beltlower=[realCen+[0 -round(beltheight/2)]-horVector*10^5 ; realCen+[0 -round(beltheight/2)]+horVector*10^5];

            block0=[segPt2UL(intersectLoc2-1,:)-wingVector*10^5 ; segPt2UL(intersectLoc2-1,:)+wingVector*10^5];
            block1=[segPt2UL(intersectLoc2,:)-wingVector*10^5 ; segPt2UL(intersectLoc2,:)+wingVector*10^5];

            fineBox=zeros(4,2);
            [fineBox(1,1),fineBox(1,2)]=polyxpoly(block0(:,1),block0(:,2),beltupper(:,1),beltupper(:,2));
            [fineBox(2,1),fineBox(2,2)]=polyxpoly(block0(:,1),block0(:,2),beltlower(:,1),beltlower(:,2));
            [fineBox(3,1),fineBox(3,2)]=polyxpoly(block1(:,1),block1(:,2),beltlower(:,1),beltlower(:,2));
            [fineBox(4,1),fineBox(4,2)]=polyxpoly(block1(:,1),block1(:,2),beltupper(:,1),beltupper(:,2));

            %Pick up all points in the final searching box
            inCorner = inpolygon(Corners(:,1),Corners(:,2),fineBox(:,1),fineBox(:,2));
            forehindCorners=Corners(inCorner,:);
        catch
            forehindCorners=[];
        end
    end
     
     if intersectLoc2>intersectLoc+2 || intersectLoc2>length(segPt2UL)
         disp(['[intersectLoc2]: ',num2str(intersectLoc2)]);
         break
     else
        intersectLoc2=intersectLoc2+1;
     end
end

%If the number of closest 2 points less than 2, find the nearest 2 on
%another intersect segment
intersectLoc2=intersectLoc-1;
while size(closest2Pts,1)<2
    %The 2 intersect points on the target segment line
    closest2Pts=intersectDistPts(intersectDistPts(:,1)==intersectLoc2,2:end);
     if intersectLoc2>intersectLoc+2 || intersectLoc2>length(segPt2UL)
%          disp(['[intersectLoc2]: ',num2str(intersectLoc2)]);
         break
     else
        intersectLoc2=intersectLoc2+1;
     end
end


%%
%The point most distant form those two detected points should be our target
if size(forehindCorners,1)>1
    disp(['Find ',num2str(size(forehindCorners,1)),' candidate points; begin refining.']);
    forehindCornerDists=zeros(1,size(forehindCorners,1));
    for fhC=1:size(forehindCorners,1)
        ptX1=[closest2Pts(1,:) ; forehindCorners(fhC,:)];
        ptX2=[closest2Pts(2,:) ; forehindCorners(fhC,:)];
        ttdist=mean([pdist(ptX1,'euclidean'),pdist(ptX2,'euclidean')]);
        forehindCornerDists(fhC)=ttdist;
    end
    [~,maxID]=min(forehindCornerDists);
    forehindCorner=forehindCorners(maxID,:);
else
    forehindCorner=forehindCorners;
end

if ~isempty(forehindCorner)
    disp('Find the key point.');
else
    disp('DID NOT find the key point.');
end
end