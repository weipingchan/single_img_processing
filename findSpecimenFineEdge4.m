function [realignedcropedsymimgs,sppmask,sppedge,finalCentroidList]=findSpecimenFineEdge4(realignedcropedimgs,darkThreshold)
disp('Start to find fine edges and convert the results into storage format.');
%darkThreshold=0.4; %Default dark threshold which is derived from experiences
disp(['Use dark threshold: ',num2str(darkThreshold)]);
[sppamounts,~]=size(realignedcropedimgs);
sppedge=cell(sppamounts,0);
sppmask=cell(sppamounts,0);
realignedcropedsymimgs=cell(sppamounts,0);
finalCentroidList=zeros(sppamounts,2);
for in=1:sppamounts
    sppimgs=realignedcropedimgs(in,:);

    %Find the symetric centroid and axis for each bands and averaged them
    for im=1:length(sppimgs)
        symimg=sppimgs{im};
        if size(symimg, 3)==1 %test 20180401
            symimg=imclearborder(symimg); %test 20180401
        else %test 20180401
            symimg=cat(3,imclearborder(symimg(:,:,1)),imclearborder(symimg(:,:,2)),imclearborder(symimg(:,:,3))); %test 20180401
        end %test 20180401
        
        [com, mainAxis,~]=findSymetricAxes(symimg);
        centroidCandidates(im,:)=com;
        symAxisCandidates(im,:)=mainAxis;
    end
        %centroidCandidates2 = centroidCandidates(all(~isnan(centroidCandidates),2),:); %remove NaN
        originalCentroid=[mean(removeoutliers(centroidCandidates(:,1))),ceil(size(sppimgs{2},1)*8/15)]; %If the size of box is changed, this have to be adjusted
%    originalCentroid=[mean(removeoutliers(centroidCandidates(:,1))),mean(removeoutliers(centroidCandidates(:,2)))];
%    originalSymAxis=[mean(removeoutliers(symAxisCandidates(:,1))),mean(removeoutliers(symAxisCandidates(:,2)))];
%    symOrtho=reshape(null(originalSymAxis(:).'),1,[]); %Calculate the orthogonal vector, which will be used to compare with horizontal line

%    hor = [1, 0];
%    CosTheta = dot(symOrtho,hor)/(norm(symOrtho)*norm(hor));
%    ThetaInDegrees = acosd(CosTheta);
    %Make sure the vector is point to the head direction
%    if symOrtho(1)<0
%        ThetaInDegrees = ThetaInDegrees+180;
%    end
    
%    if cosd(ThetaInDegrees)< cosd(20) %if the symetric axis indicates that the image has to be rotated over 20 degree, it should be asymmetrical.
%        disp(['Specimen No. ',num2str(in),' has to rotate ', num2str(acosd(cosd(ThetaInDegrees))),' degree, whcih is highly asymmetrical, so was not rotated.']);
%        ThetaInDegrees=0;
%    end
    
%    ThetaInDegrees=0; %This line is only used for images before March, 2018; all other images should turn off this line
    
%    tform = affine2d([cosd(ThetaInDegrees) -sind(ThetaInDegrees) 0; sind(ThetaInDegrees) cosd(ThetaInDegrees) 0; 0 0 1]); %Create rotating matrix

%    [~, ref] = imwarp(sppimgs{2},tform);
%    [x1,y1]=transformPointsForward(tform,originalCentroid(1),originalCentroid(2));
%    correctedCentroid=zeros(1,2);
%    correctedCentroid(1) = x1 - ref.XWorldLimits(1);
%    correctedCentroid(2) = y1 - ref.YWorldLimits(1);
    
    correctedCentroid=originalCentroid;
    %Save the centroid
    finalCentroidList(in,:)=correctedCentroid;
    
    symsppimgs=cell(length(sppimgs),0);
    for im=1:length(sppimgs)
%    [symsppimgs{im}, ~] = imwarp(sppimgs{im},tform); %Make the rotation to correct the image
        symsppimgs{im} = sppimgs{im}; %Make the rotation to correct the image
    end
    
    %put the cell results into right format
    for im=1:length(symsppimgs)
        realignedcropedsymimgs{in,im}=symsppimgs{im};
    end
    
    
    %Use RGB image to determine if process dark handling
    mask_ex = zeros(size(sppimgs{2}));
    %mask_ex(ceil(size(mask_ex,1)/3):end-ceil(size(mask_ex,1)/3),ceil(size(mask_ex,2)/3):end-ceil(size(mask_ex,2)/3)) = 1;
        if ceil(correctedCentroid(1)-size(mask_ex,1)/6)<1 upbond=1; else upbond=ceil(correctedCentroid(1)-size(mask_ex,1)/6);, end;  %test 20180408
        if ceil(correctedCentroid(1)+size(mask_ex,1)/6)>size(mask_ex,1) lowbond=size(mask_ex,1);, else lowbond=ceil(correctedCentroid(1)+size(mask_ex,1)/6);, end;  %test 20180408
        if ceil(correctedCentroid(2)-size(mask_ex,2)/6)<1 leftbond=1;, else leftbond=ceil(correctedCentroid(2)-size(mask_ex,2)/6);, end;  %test 20180408
        if ceil(correctedCentroid(2)+size(mask_ex,2)/6)>size(mask_ex,2) rightbond=size(mask_ex,2);, else rightbond=ceil(correctedCentroid(2)+size(mask_ex,2)/6);, end;  %test 20180408
    mask_ex(upbond:lowbond,leftbond:rightbond) = 1; %test 20180408
    dark_test0=imadjust(rgb2gray(sppimgs{5}));
    dark_test1=imadjust(sppimgs{2});
    dark_ratio=nnz(imbinarize(immultiply(imclearborder(dark_test0)+imclearborder(dark_test1),mask_ex)))/nnz(mask_ex);
    disp(['Dark ratio of specimen No. ',num2str(in),' is ',num2str(dark_ratio)]);
    %If the currecnt dark threshold trigered normal process and the normal process cnanot provide acceptable outline
    %autoomatically use dark handling procedure
        %Select between normal process or the dark handling
%         if dark_ratio > darkThreshold
%             [sB1,sL1,panel_ff1]= findSpecimenEdge11(symsppimgs,correctedCentroid);
%         else
%             disp('Start to use dark handling to find fine edges.');
%             [sB2,sL2,panel_ff2]= findSpecimenEdge21(symsppimgs,correctedCentroid);
%         end
%             if length(sB1)==1
%                 if length(sB2)==1
%                     shape1=im2shapeContext(panel_ff1);
%                     shape2=im2shapeContext(panel_ff2);
%                     cor1=corrcoef(shape1,shapetemplate);
%                     cor2=corrcoef(shape2,shapetemplate);
%                     overlap1=checkImgOverlap(imadjust(sppimgs{2}),panel_ff1);
%                     overlap2=checkImgOverlap(imadjust(sppimgs{2}),panel_ff2);
%                     corOverIdx1=(1-(overlap1)/(overlap1+overlap2)).*cor1(1,2);
%                     corOverIdx2=(1-(overlap2)/(overlap1+overlap2)).*cor2(1,2);
%                     if corOverIdx1>=corOverIdx2
%                         specimenB=sB1;
%                         specimenL=sL1;
%                     else
%                         specimenB=sB2;
%                         specimenL=sL2;
%                     end
%                 else
%                     disp('Acceptable outline is found.');
%                      specimenB=sB1;
%                     specimenL=sL1;
%                 end
%             elseif length(sB2)==1
%                 disp('Acceptable outline is found based on the negative image.');
%                 specimenB=sB2;
%                 specimenL=sL2;
%             else                
%                 specimenB=sB1;
%                 specimenL=sL1;
%             end
    try
         [specimenB,specimenL,panel_ff]= findSpecimenEdge_new4(symsppimgs);
        %[specimenB,specimenL]= bwboundaries(panel_ff,'noholes');

        if length(specimenB)~=1
            %if dark_ratio > darkThreshold
                %disp('The outline is UNACCEPTABLE.Force to use dark handling to find fine edges.');
                %[specimenB,specimenL]= findSpecimenEdge2(symsppimgs,correctedCentroid);
            %else
                %if dark handling cannot find an acceptable result, provide
                %a temporary outline box in order to prevent the errors in
                %other processes
                mask_fake = zeros(size(symsppimgs{2}));
                mask_fake(ceil(size(mask_fake,1)/10):end-ceil(size(mask_fake,1)/10),ceil(size(mask_fake,2)/10):end-ceil(size(mask_fake,2)/10)) = 1;
                [specimenB,specimenL]=bwboundaries(mask_fake,'noholes');
                disp('CANNOT find an acceptable outline even with dark handling, so provide a temporary outline.');
            %end
        end
    catch
        mask_fake = zeros(size(symsppimgs{2}));
        mask_fake(ceil(size(mask_fake,1)/10):end-ceil(size(mask_fake,1)/10),ceil(size(mask_fake,2)/10):end-ceil(size(mask_fake,2)/10)) = 1;
        [specimenB,specimenL]=bwboundaries(mask_fake,'noholes');
        disp('Something went wrong in edge detectation, so provide a temporary outline.');
    end
    sppmask{in}=specimenL;
    sppedge{in}=specimenB;
    disp(['No. ',num2str(in),' out of ',num2str(sppamounts),' is outlined.']);
end
disp('Outlines of all specimens are converted into storage format.');
end