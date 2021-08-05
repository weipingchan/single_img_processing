function [panel_head_ready2, mask_head]= headPartMask(panel,panel_seg2,panel_ed5,mask2,mask3)
    %Focus on the head region in order to take care of the diverse antenna issue
    
    panel_head= panel_ed5;
    %Create the mask of head region
    head_neg=bwareaopen(immultiply(imcomplement(panel_head),mask3),2000);
    
    try
        stats_head = regionprops(head_neg, 'BoundingBox');
        boxes_head = vertcat(stats_head(1).BoundingBox);
    catch
        stats_head = regionprops(mask2, 'BoundingBox');
        boxes_head = vertcat(stats_head(1).BoundingBox);
    end
    
    lefts_head = boxes_head(:,1);
    rights_head = lefts_head + boxes_head(:,3);
    tops_head = boxes_head(:,2);
    bottoms_head = tops_head + boxes_head(:,4);
    lowermid_head=[mean([lefts_head,rights_head]),bottoms_head];

    %Examine the connection between antenna and head
    Cmask_head_fine=createCirclesMask(panel, lowermid_head, boxes_head(:,3)/12);
    [head_fineB,head_fineL] = bwboundaries(bwareaopen(immultiply(panel_head,Cmask_head_fine),150),'noholes');
    stats_head_fineL = regionprops(head_fineL, 'EulerNumber');
    
    % If there is any detached part in the refined head region, rerun the
    % process with refined mask
    if length(head_fineB)==1
        if  stats_head_fineL.EulerNumber>=-1
            panel_head_fine=panel_head; 
        else
            panel_head_fine= regionSegHeadFine(panel,panel_seg2,panel_ed5,Cmask_head_fine);
        end
    else
        panel_head_fine= regionSegHeadFine(panel,panel_seg2,panel_ed5,Cmask_head_fine);
    end
    
    %create a negetive mask of refined head region
    oppCmask_fine=imcomplement(Cmask_head_fine);
    panel_head_ready=imfill(imerode(imdilate(immultiply(panel_head_fine,Cmask_head_fine)+immultiply(panel_head,oppCmask_fine),strel('disk',2)),strel('disk',2)),'hole');
    Cmask_head=createCirclesMask(panel, lowermid_head, boxes_head(:,3)/(7 + (boxes_head(:,3) + 100)/500));
    mask_head=imfill(Cmask_head+head_neg,'hole');
    panel_head_ready2=bwareaopen(immultiply(panel_head_ready,mask_head),300);
end