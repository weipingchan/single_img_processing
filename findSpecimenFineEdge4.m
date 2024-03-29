function [realignedcropedsymimgs,sppmask,sppedge,finalCentroidList]=findSpecimenFineEdge4(realignedcropedimgs,darkThreshold)
%automatically detect the silhouette of butterfly specimen with wings spread
disp('Start to find fine edges and convert the results into storage format.');
disp(['Use dark threshold: ',num2str(darkThreshold)]);
[sppamounts,~]=size(realignedcropedimgs);
sppedge=cell(sppamounts,0);
sppmask=cell(sppamounts,0);
realignedcropedsymimgs=cell(sppamounts,0);
finalCentroidList=zeros(sppamounts,2);
for in=1:sppamounts
    sppimgs=realignedcropedimgs(in,:);

    %Find the symmetric centroid and axis for each bands and average them
    for im=1:length(sppimgs)
        symimg=sppimgs{im};
        if size(symimg, 3)==1
            symimg=imclearborder(symimg);
        else
            symimg=cat(3,imclearborder(symimg(:,:,1)),imclearborder(symimg(:,:,2)),imclearborder(symimg(:,:,3)));
        end
        
        [com, mainAxis,~]=findSymetricAxes(symimg);
        centroidCandidates(im,:)=com;
        symAxisCandidates(im,:)=mainAxis;
    end
    originalCentroid=[mean(removeoutliers(centroidCandidates(:,1))),ceil(size(sppimgs{2},1)*8/15)]; %If the size of box is changed, this have to be adjusted
    correctedCentroid=originalCentroid;
    %Save the centroid
    finalCentroidList(in,:)=correctedCentroid;
    
    symsppimgs=cell(length(sppimgs),0);
    for im=1:length(sppimgs)
        symsppimgs{im} = sppimgs{im};
    end
    
    %put the cell results into right format
    for im=1:length(symsppimgs)
        realignedcropedsymimgs{in,im}=symsppimgs{im};
    end
    
    %Find the ideal silhouette or provide a fake one or prevent any error
    try
         [specimenB,specimenL, panel_ff]= findSpecimenEdge_new4(symsppimgs); %The variable panel_ff can be used for debugging purposes
        if length(specimenB)~=1
                mask_fake = zeros(size(symsppimgs{2}));
                mask_fake(ceil(size(mask_fake,1)/10):end-ceil(size(mask_fake,1)/10),ceil(size(mask_fake,2)/10):end-ceil(size(mask_fake,2)/10)) = 1;
                [specimenB,specimenL]=bwboundaries(mask_fake,'noholes');
                disp('CANNOT find an acceptable outline even with dark handling, so provide a temporary outline.');
        end
    catch
        mask_fake = zeros(size(symsppimgs{2}));
        mask_fake(ceil(size(mask_fake,1)/10):end-ceil(size(mask_fake,1)/10),ceil(size(mask_fake,2)/10):end-ceil(size(mask_fake,2)/10)) = 1;
        [specimenB,specimenL]=bwboundaries(mask_fake,'noholes');
        disp('Something went wrong in edge detection, so provide a temporary outline.');
    end
    sppmask{in}=specimenL;
    sppedge{in}=specimenB;
    disp(['No. ',num2str(in),' out of ',num2str(sppamounts),' is outlined.']);
end
disp('Outlines of all specimens are converted into storage format.');
end