function [panel_tail_ready2, mask_tail]= tailPartMask(panel,panel_seg2,panel_ed5,mask4,mask5)
%Focus on the rear end of the abdomen in order to deal with entangled legs
    panel_body= regionSegTail2(panel,panel_seg2,panel_ed5,mask4);
    panel_body_ready=imerode(imdilate(panel_body,strel('disk',2)),strel('disk',2));
    %Create the mask of tail region
    tail_neg=bwareaopen(immultiply(imcomplement(panel_body_ready),mask5),300);
    stats_tail = regionprops(tail_neg, 'BoundingBox');
    boxes_tail = vertcat(stats_tail(1).BoundingBox);
    lefts_tail = boxes_tail(:,1);
    rights_tail = lefts_tail + boxes_tail(:,3);
    tops_tail = boxes_tail(:,2);
    uppermid_tail=[mean([lefts_tail,rights_tail]),tops_tail];
    Cmask_tail=createCirclesMask(panel, uppermid_tail, boxes_tail(:,3)/6);
    mask_tail=imfill(imerode(imdilate(Cmask_tail+tail_neg,strel('disk',10)),strel('disk',14)),'hole');
    panel_tail_ready2=bwareaopen(immultiply(panel_body_ready,mask_tail),300);
end