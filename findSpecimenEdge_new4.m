function [sB,sL,panel_ff]= findSpecimenEdge_new4(sppimgs)
%%%%
oriB940=sppimgs{2};
%%dark image treatment
AInv740 = imcomplement(sppimgs{1});
BInv740 = imreducehaze(AInv740, 'ContrastEnhancement', 'none');
B740 = imcomplement(BInv740);

AInv940 = imcomplement(sppimgs{2});
BInv940 = imreducehaze(AInv940, 'ContrastEnhancement', 'none');
B940 = imcomplement(BInv940);
[prow, pcol]=size(B940);
%%
actFactor=300;%default value nearly all scripts were developed under this value

%pixel-based segmentation
simplematrix=localcontrast(im2uint16(cat(3,B740,B940,B940)));

nColors = 3;
% repeat the clustering 3 times to avoid local minimum
pixel_labels =imsegkmeans(simplematrix,nColors,'NumAttempts',5);
%figure,imshow(pixel_labels,colormap('lines')); %This line is preserved for debugging
[~,backgroundclass1]=max([nnz(pixel_labels==1),nnz(pixel_labels==2),nnz(pixel_labels==3)]);
cornerSample=[pixel_labels(round(end/10),5),pixel_labels(round(end/10),end-5),pixel_labels(round(end*9/10),5),pixel_labels(round(end*9/10),end-5), ...
    pixel_labels(round(end/10),round(end*1/4)),pixel_labels(round(end/10),round(end*2/4)),pixel_labels(round(end/10),round(end*3/4)),pixel_labels(round(end*9/10),round(end*1/4)), ...
    pixel_labels(round(end*9/10),round(end*2/4)),pixel_labels(round(end*9/10),round(end*3/4))];
backgroundclass2=mode(cornerSample);

if backgroundclass1==backgroundclass2
    specimenMask0 = pixel_labels~= backgroundclass1;
else
    if  nnz(cornerSample==backgroundclass2)/length(cornerSample)<0.7
        backgroundclass3=mode(cornerSample(cornerSample~=backgroundclass2));
        if backgroundclass3~=backgroundclass1   
            specimenMask0 = pixel_labels==backgroundclass1; %not class2 and not class3, so it should be class1
        else
            specimenMask0 = pixel_labels~=backgroundclass2;
        end
    else
        specimenMask0 = pixel_labels~=backgroundclass2;
    end
end

specimenMask1 = imerode(imdilate(specimenMask0,strel('disk',2)),strel('disk',2));
%%
adjsizefactor=2;
%Use the standard deviation of background to filter the foreground image
patchVar = std2(nonzeros(immultiply(B940,imcomplement(imfill(imdilate(specimenMask1,strel('disk',10)),'hole')))))^2;
try
    DoS = 8*patchVar;
    specimenMask2=imbilatfilt(B940,DoS,10);
catch
    DoS = 0.03;
    specimenMask2=imbilatfilt(B940,DoS,10);
end

%Derive the outline of the mask
windowsize=15;
specimenMaskoutline=adaptivethreshold(specimenMask2,windowsize,0.03,0);

specimenMaskCom=immultiply(specimenMask2,specimenMaskoutline);

specimenMask3=medfilt2(imdilate(bwareaopen(medfilt2(imerode(imbinarize(specimenMaskCom*2),strel('disk',2)),[5,5]),round(prow*pcol/4/adjsizefactor^2)),strel('disk',2)),[10,10]);

%%
specimenMask30=bwareaopen(imbinarize(specimenMask2)+specimenMask3,round(prow*pcol/4/adjsizefactor^2));
specimenMask31=imfill(bwareaopen(specimenMask1+imbinarize(specimenMask2)+specimenMask3,round(prow*pcol/4/adjsizefactor^2)),'hole');

specimenMaskDiff=imabsdiff(specimenMask30,specimenMask31);
specimenMaskDiff2=bwareaopen(imdilate(imerode(specimenMaskDiff,strel('disk',2)),strel('disk',2)),50);
if round(mean(oriB940(specimenMaskDiff2)),1)>=0.2
    specimenMask4=specimenMask31;
else
    specimenMask4=specimenMask30;
end
%%
panel0=localcontrast(rgb2gray(simplematrix));

%Create a set of images that were handled by different approaches
panel_sharp0=imsharpen(localcontrast(panel0),'Radius',1,'Amount',3);
panel_ed0=immultiply(imfill(imdilate(im2double(panel_sharp0),strel('disk',2)),'hole'),imfill(imdilate(im2double(panel0),strel('disk',3)),'hole'));
panel=imadjust(immultiply(imfill(panel_ed0),imdilate(imfill(specimenMask1,'hole')+0.2,strel('disk',5))))+imfill(specimenMask1,'hole')*0.3;

%Use the index to judge if the mask is good or not
spMaskInd=nnz(imclearborder(specimenMask4))/(prow*pcol);
[spMaskB,spMaskL] = bwboundaries(specimenMask4,'noholes');
if spMaskInd>0.2 && length(spMaskB)<20
    specimenMask = specimenMask4;
else
    specimenMask = imerode(imfill(medfilt2(imbinarize(panel_ed0),[10,10]),'hole'),strel('disk',1));
end

background0 = imclose(imfill(imopen(panel,strel('disk',5))),strel('disk',5));
background1 = imdilate(imerode(background0,strel('disk',40)),strel('disk',10));


%Begin from two ends to find the most appropriate binerized factor
for binerizedFactor1=0.5:0.02:0.96
    %disp(binerizedFactor); %for debugging
    mask01=bwareaopen(imbinarize(background1,1-binerizedFactor1),200);
    [~,~,mN1]=bwboundaries(bwareaopen(mask01,round(prow*pcol/4/adjsizefactor^2)),'noholes');
    if mN1==1
        break;
    end
end
for binerizedFactor2=0.96:-0.02:0.5
    %disp(binerizedFactor); %for debugging
    mask02=bwareaopen(imbinarize(background1,1-binerizedFactor2),200);
    [~,~,mN2]=bwboundaries(bwareaopen(mask02,round(prow*pcol/4/adjsizefactor^2)),'noholes');
    if mN2==1
        break;
    end
end

binerizedFactor=(binerizedFactor1+binerizedFactor2)/2;
mask0=bwareaopen(imbinarize(background1,1-binerizedFactor),200);
[~,mL,mN]=bwboundaries(bwareaopen(mask0,round(prow*pcol/4/adjsizefactor^2)),'noholes');
if mN~=1
    mask0=bwareaopen(imbinarize(background1,1-binerizedFactor1),200);
    [~,mL,mN]=bwboundaries(bwareaopen(mask0,round(prow*pcol/4/adjsizefactor^2)),'noholes');
    if mN==0
        disp('Cannot detect proper specimen width for following process.');
        mL = zeros(size(panel));
        mL(ceil(prow/5):end-ceil(prow/5),ceil(pcol/5):end-ceil(pcol/5)) = 1;
    end
end
mask= imdilate(mL,strel('disk',10));
panel_seg2 = activecontour(background0,mask,ceil(prow*pcol/560000*actFactor));
stats_mL = regionprops(bwconvhull(panel_seg2), 'Area', 'BoundingBox','Centroid');
sppcen=stats_mL.Centroid;
sppbox=stats_mL.BoundingBox;

%create a mask for dealing with the antennae and body issue
mk2x=[1, 1,ceil(sppcen(2)-sppbox(4)/2),ceil(sppcen(2))+10,ceil(sppcen(2))+10,ceil(sppcen(2)-sppbox(4)/2)];
mk2y=[ceil(sppcen(1)-sppbox(3)*2/5),ceil(sppcen(1)+sppbox(3)*2/5),ceil(sppcen(1)+sppbox(3)*2/5),ceil(sppcen(1)+sppbox(3)/10),ceil(sppcen(1))-ceil(sppbox(3)/10),ceil(sppcen(1)-sppbox(3)*2/5)];
mask2 = poly2mask(mk2y,mk2x,prow,pcol); %for head detection
mk3x=[1, 1,ceil(sppcen(2)-sppbox(4)/2),ceil(sppcen(2))+20,ceil(sppcen(2))+20,ceil(sppcen(2)-sppbox(4)/2)];
mk3y=[ceil(sppcen(1)-sppbox(3)*2/5),ceil(sppcen(1)+sppbox(3)*2/5), ceil(sppcen(1)+sppbox(3)*2/5), ceil(sppcen(1)+sppbox(3)/11),ceil(sppcen(1)-sppbox(3)/11), ceil(sppcen(1)-sppbox(3)*2/5)];
mask3 = poly2mask(mk3y,mk3x,prow,pcol); %for head refine
mask4 = zeros(size(panel));  %for body detection
mask4(ceil(sppcen(2))+10:end,ceil(sppcen(1))-ceil(sppbox(3)/4):ceil(sppcen(1))+ceil(sppbox(3)/4)) = 1;
mask5 = zeros(size(panel));  %for body refine
mask5(ceil(sppcen(2))+20:end,ceil(sppcen(1))-ceil(sppbox(3)/6):ceil(sppcen(1))+ceil(sppbox(3)/6)) = 1;

head_judge=bwareaopen(immultiply(specimenMask,mask3),100);
tail_judge= bwareaopen(immultiply(imfill(specimenMask,'hole')+panel_seg2,mask5),300);
[headB,headL] = bwboundaries(head_judge,'noholes');
[tailB,tailL] = bwboundaries(tail_judge,'noholes');

[~, mask_head]= headPartMask(panel,panel_seg2,imfill(specimenMask,'hole'),mask2,mask3);
panel_head_ready2=bwareaopen(immultiply(specimenMask,mask_head),100);

% If there is any detached part in the tail region
if length(tailB)==1
    stats_tailB = regionprops(tailL, 'EulerNumber');
    if stats_tailB.EulerNumber==1
        panel_body_ready2=tail_judge;
        mask_tail=mask5;
    else
        [panel_body_ready2, mask_tail]= tailPartMask(panel,panel_seg2,imfill(specimenMask,'hole'),mask4,mask5);    
    end
else
    [panel_body_ready2, mask_tail]= tailPartMask(panel,panel_seg2,imfill(specimenMask,'hole'),mask4,mask5);
end
    
%create a negetive mask of body and head
oppmaskHeadTail=imcomplement(mask_head+mask_tail);

%create the final version of wings
panel_ed7=bwareaopen(imfill(imerode(imdilate(imbinarize(panel_seg2+imfill(specimenMask,'hole'),0.4),strel('disk',5)),strel('disk',5)),'hole'),round(prow*pcol/9));
%compose and refine wings and body but not head
panel_WingBody=bwareaopen(imfill(imerode(imdilate(panel_body_ready2+immultiply(panel_ed7,oppmaskHeadTail),strel('disk',2)),strel('disk',2)),'hole'),round(prow*pcol/4/adjsizefactor^2));

%%
%Head module
maskDiff_head=imabsdiff(specimenMask,panel_ed7);
maskDiffSelect_head=immultiply(bwareaopen(imdilate(imerode(maskDiff_head,strel('disk',2)),strel('disk',2)),30),mask3);
[diffL_h,diffN_h] = bwlabel(maskDiffSelect_head);

mask02= imerode(imfill(imdilate(imerode(specimenMask,strel('disk',5)),strel('disk',8)),'hole'),strel('disk',15));
%figure,imshowpair(mask02, specimenMask);  %This line is preserved for debugging
%figure,imshowpair(mask02, maskDiff_head);  %This line is preserved for debugging

oriThreshold=0.2;
deBackMask_head=zeros(prow,pcol);
addBackMask_head=zeros(prow,pcol);
for dn=1:diffN_h
    diffMask=diffL_h==dn;
    if mean(maskDiff_head(diffMask))>0.5 && mean(mask02(diffMask))<0.05 && mean(oriB940(diffMask))<oriThreshold
        deBackMask_head(imdilate(diffMask,strel('disk',1)))=1;
    elseif mean(mask02(diffMask))>0.1
        addBackMask_head(imdilate(diffMask,strel('disk',2)))=1;
    end
end

%Tail module. Try to remove legs
maskDiff_tail=imabsdiff((panel_WingBody+mask_head)>0,bwareaopen(imdilate(imerode(specimenMask,strel('disk',10)),strel('disk',10)),20));
maskDiffSelect_tail=bwpropfilt(bwpropfilt(logical(immultiply(bwareaopen(imdilate(imerode(maskDiff_tail,strel('disk',2)),strel('disk',2)),30),mask5)),'Eccentricity',[0.9 1]),"MinorAxisLength",[0 10]); %Eccentricity=1 is a line
[diffL_t,diffN_t] = bwlabel(maskDiffSelect_tail);
%figure,imshowpair(maskDiff_tail, specimenMask);  %This line is preserved for debugging
%figure,imshowpair(maskDiffSelect_tail, specimenMask);  %This line is preserved for debugging

deBackMask_tail=zeros(prow,pcol);
addBackMask_tail=zeros(prow,pcol);
for dn=1:diffN_t
    diffMask=diffL_t==dn;
    if mean(maskDiffSelect_tail(diffMask))>0.5
        deBackMask_tail(imdilate(diffMask,strel('disk',3)))=1;
    else
        addBackMask_tail(diffMask)=1;
    end
end

%Tail module addition. Try to remove more unpleasant tail parts
maskDiffSelect_tail2=immultiply(bwareaopen(imdilate(imerode(maskDiff_tail,strel('disk',2)),strel('disk',2)),50),mask5);
[dL_t,dN_t] = bwlabel(maskDiffSelect_tail2);
for dn=1:dN_t
    diffMask=dL_t==dn;
    diff_stat=regionprops(diffMask,'Centroid','MinorAxisLength');
    Cmask_diff_t=createCirclesMask(diffMask, diff_stat.Centroid, diff_stat.MinorAxisLength/4);
%    figure,imshowpair(diffMask,Cmask_diff_t);  %This line is preserved for debugging
    if nnz(diffMask(Cmask_diff_t))/nnz(Cmask_diff_t)<0.8
        deBackMask_tail(imdilate(diffMask,strel('disk',3)))=1;
    end
end

deBackMask=(deBackMask_head+deBackMask_tail)>0;
addBackMask=(addBackMask_head+addBackMask_tail)>0;

%pin the head region on
panel_ff0=imfill(bwareaopen(panel_head_ready2+panel_WingBody,round(prow*pcol/4/adjsizefactor^2)),'hole');
panel_ff1=(imfill(panel_ff0+addBackMask,'hole')-deBackMask)>0;
panel_ff1_tail=bwareaopen(imfill(immultiply(panel_ff1,mask5),'hole'),200);

majorObj=imdilate(imerode(panel_ff1,strel('disk',10)),strel('disk',10)); %Used for reduced area
margin=imabsdiff(majorObj,imdilate(majorObj,strel('disk',5)));
margincut=logical(immultiply(margin,(mask3-mask_head)>0)); %margin left between antennae and forewings
%figure,imshowpair(panel_ff1,margin);  %This line is preserved for debugging
%figure,imshowpair(panel_ff1,margincut);  %This line is preserved for debugging
%figure,imshowpair((mask3-mask_head)>0,margin);  %This line is preserved for debugging

panel_ff2=(immultiply(panel_ff1,imcomplement(mask5))+panel_ff1_tail-margincut)>0;
panel_ff3=bwareaopen(panel_ff2,round(prow*pcol/4/adjsizefactor^2));
%%
%detect fore-hind wing gap and improve the accuracy
try
    maskf=panel_ff3;
    %Find the symmetric axis
    [symCentroid,symAxis,~]=findSymetricAxes(maskf);
    disp('The symmetric axis has been found.');
     %Find the center based on regionprop function   
     regioncen0=regionprops(maskf,'Centroid','BoundingBox'); %The center of the bounding box
     regioncen= regioncen0.Centroid;
     boundingBox=regioncen0.BoundingBox;

     %Find the centroid of the eroded central region based on regionprop function   
     cenregion=imerode(maskf,strel('disk',50));
     cenregioncen0=regionprops(uint8(cenregion),'Centroid','BoundingBox'); %The center of the bounding box
     cenregioncen=cenregioncen0.Centroid;
     boundingBoxErosion=cenregioncen0.BoundingBox;

     %Calculated the difference between two centroids
     cenDiff=pdist([regioncen;cenregioncen],'euclidean');

     %Pick the most suitable one
     if cenDiff<50
        realCen= regioncen;
         disp('The centroid of the {entire mask} is used as the real centroid.');
     else
         realCen= cenregioncen;
          disp('The centroid of the {deleted central region} is used as the real centroid.');
     end
     disp('The centroid has been determined.');

    %Derive the coordination of corners
     ulCorner=boundingBox(1:2);
     urCorner=[boundingBox(1)+boundingBox(3),boundingBox(2)];
     llCorner=[boundingBox(1),boundingBox(2)+boundingBox(4)];
     lrCorner=[boundingBox(1)+boundingBox(3),boundingBox(2)+boundingBox(4)];
     allFrameCorners=[ ulCorner; urCorner; llCorner; lrCorner];
    %%
    %Prepare the symmetric axes for plotting
    %create symmetric axes based on eigenvector
    symOrtho=reshape(null(symAxis(:).'),1,[]);
    dim_1=realCen+symAxis*size(maskf,1)/3;
    dim_1plot=[realCen(1),dim_1(1);realCen(2),dim_1(2)];
    dim_2=realCen+symOrtho*size(maskf,1)/9;
    dim_2plot=[realCen(1),dim_2(1);realCen(2),dim_2(2)];

    %%
    %Use erosion mask to prevent the interference of long tail
     if cenDiff>=50
        boundingBoxDV= boundingBoxErosion;
        ulCornerDV=boundingBoxErosion(1:2);
        lrCornerDV=[boundingBoxErosion(1)+boundingBoxErosion(3),boundingBoxErosion(2)+boundingBoxErosion(4)];   
     else
         boundingBoxDV= boundingBox;
         ulCornerDV=boundingBox(1:2);
         lrCornerDV=[boundingBox(1)+boundingBox(3),boundingBox(2)+boundingBox(4)];
     end
    disp('########## Begin to find the corner between fore and hind wings. #########');
    disp('Begin to find the corner between left fore and hing wings.');
    nStrongCornersList=[500,1000,2000,3000,4000];
    nSectionList=[60:-5:20]; %number of elements in the list should be greater than 4. Alternative one: [20:5:50]

    slopeSwitch='wingEdge';
    [conjPt,forehindCorner,~]=findForeHindCorner(nStrongCornersList,nSectionList,maskf,realCen,symAxis,ulCornerDV,boundingBoxDV,slopeSwitch);
    if length(forehindCorner(forehindCorner(:,1)>0))<5
        slopeSwitch='cenAxis';
        [conjPt,forehindCorner,~]=findForeHindCorner(nStrongCornersList,nSectionList,maskf,realCen,symAxis,ulCornerDV,boundingBoxDV,slopeSwitch);
    end
    forehindCornerL=conjPt;
    disp('The corner between left fore and hind wings has been found.');
    disp('Begin to find the corner between right fore and hind wings.');

    slopeSwitch='wingEdge';
    [conjPt,forehindCorner,~]=findForeHindCorner(nStrongCornersList,nSectionList,maskf,realCen,symAxis,lrCornerDV,boundingBoxDV,slopeSwitch);
    if length(forehindCorner(forehindCorner(:,1)>0))<5
        slopeSwitch='cenAxis';
        [conjPt,forehindCorner,~]=findForeHindCorner(nStrongCornersList,nSectionList,maskf,realCen,symAxis,lrCornerDV,boundingBoxDV,slopeSwitch);
    end
    forehindCornerR=conjPt;
    disp('The corner between right fore and hind wings has been found.');
    disp('########## Two corners between fore and hind wings are found. #########');
% This chunk is preserved for debugging
%     figure,imshow(maskf);
%     hold on;
%     plot(forehindCornerR(:,1),forehindCornerR(:,2),'rx','LineWidth', 2);
%     plot(forehindCornerL(:,1),forehindCornerL(:,2),'rx','LineWidth', 2);
%     plot(realCen(:,1),realCen(:,2),'bo','LineWidth', 2);
    
    Cmask_fh_corner_R=createCirclesMask(maskf, forehindCornerR, round(boundingBox(4)/6));
    Cmask_fh_corner_L=createCirclesMask(maskf, forehindCornerL, round(boundingBox(4)/6));

    fh_corner_masks = (Cmask_fh_corner_L+Cmask_fh_corner_R)>0;
    fh_corner_fineMask = immultiply(imfill(specimenMask3,'holes'), fh_corner_masks);
    
    panel_ff4=(immultiply(maskf,imcomplement(fh_corner_masks))+fh_corner_fineMask)>0;
    fh_corner_ring=imdilate(fh_corner_masks,strel('disk',10))-imerode(fh_corner_masks,strel('disk',10));
    fh_corner_ring_smoothMask = imerode(imdilate(immultiply(panel_ff4, fh_corner_ring),strel('disk',20)),strel('disk',20));
    panel_ff=(immultiply(panel_ff4,imcomplement(fh_corner_ring))+fh_corner_ring_smoothMask)>0;
%     figure,imshowpair(panel_ff, panel_ff3);  %This line is preserved for debugging
catch
    panel_ff=panel_ff3;
    disp('No fore-hind wing joint correction');
end

%%
[sB,sL] = bwboundaries(panel_ff,'noholes');
% This chunk is preserved for debugging
% sBpt=sB{1};
% figure,imshow(oriB940);hold on;
% plot(sBpt(:,2),sBpt(:,1),'r');
end