function outImg=spRoughSearching(ref,shrinkBase,shapethreshold,gatheringfactor)
% Make thumbnail for initial processing 
ref_thumbnail=imresize(ref,1/shrinkBase,'method','bilinear');
[nrow,ncol]=size(ref);

%%% 2.4 Find objects in thumbnail
%%% 2.4.1 Remove area beyond panel 
panel=imadjust(ref_thumbnail);
panel_sharp=imsharpen(panel,'Radius',1,'Amount',3);

panel_ed=immultiply(imsharpen(imfill(imdilate(panel_sharp,strel('disk',2)),'hole')),panel_sharp);
panel_edm=imclearborder(panel_ed,4);

panel_ed2=3*(imdilate(panel_edm,strel('disk',1))-imerode(panel_edm,strel('disk',1)))+panel_edm;  
%panel_ed3=immultiply(imsharpen(panel_ed2),panel_ed2);
panel_ed3=imfill(imsharpen(panel_ed2));

%panel_ed5=imbinarize(medfilt2(panel_ed3,[3,2]),0.1);
panel_ed5=bwareaopen(imbinarize(medfilt2(panel_ed3,[3,2]),0.1),200);
panel_ed52=imclearborder(removeLongRoundShape(panel_ed5,shapethreshold));
%panel_ed6=imdilate(bwareaopen(imerode(panel_ed5,strel('disk',10)),100),strel('disk',8));
panel_ed6=imdilate(bwareaopen(imerode(panel_ed52,strel('disk',10)),100),strel('disk',8));

background0 = imclearborder(imfill(panel),4);
background1=imclearborder(imerode(imdilate(imfill(adapthisteq(imfill(imclose(background0,strel('disk',ceil(gatheringfactor)))))),strel('disk',gatheringfactor)),strel('disk',ceil(gatheringfactor*3/4))));

[~, threshout]=edge(panel,'sobel');
fudgeFactor=0.5;
panel_edg=edge(panel_ed,'sobel', threshout*fudgeFactor);
panel_edg=imdilate(panel_edg,[strel('line',3,0),strel('line',3,90)]);
panel_edg=imfill(panel_edg,'holes');
panel_edg=bwareaopen(imerode(panel_edg,strel('disk',2)),50);
panel_edg=imclearborder(removeLongRoundShape(panel_edg,shapethreshold));

%panel_f=imclearborder(imbinarize(panel_edg*0.2+panel_ed52*0.2+panel_ed6*0.2+background1*0.6));
panel_f=imclearborder(imbinarize(panel_edg*2+panel_ed52+panel_ed6+background1*3));
panel_ff=imdilate(bwareaopen(imerode(panel_f,strel('disk',2)),ceil(size(panel,1)*size(panel,2)/500)),strel('disk',1));
selectedImg=removeLongRoundShape(panel_ff,shapethreshold);

outImg=imresize(selectedImg,[nrow,ncol]/4,'method','bilinear');
end