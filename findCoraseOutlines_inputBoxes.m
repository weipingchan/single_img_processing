function [geometry_osize,specimenLabelList]=findCoraseOutlines_inputBoxes(ref,template,drawerlist,labelfile,drawerInspectionDir,Code_directory)
    %Find the corresponding labels and match with thenumber of specimens
    %Create temporary one if cannot find one
    subtemplate0=strsplit(template,'_');
    subtemplate1=strjoin(subtemplate0(1:end-1),'_');
    drawerID = find(all(ismember(drawerlist,subtemplate1),2));

    %read the manually defined boxes
    boxInfoDir='manual_boxes';
    boxinname=fullfile(Code_directory,boxInfoDir,[template,'_Boxes.mat']);
    boxmat0=load(boxinname);
    geometry_osize=boxmat0.geometry_osize;
    sppamounts=size(geometry_osize,1);
    
    if isempty(drawerID)
        disp('CANNOT find corresponding drawer information.');
        specimenLabelList=createTemporaryLabel(subtemplate1,sppamounts);
    else
        disp('Find the corresponding drawer information.');
        specimenLabelList0=table2cell(labelfile(drawerID,:));
        specimenLabelList0(cellfun(@(specimenLabelList0) any(isnan(specimenLabelList0)),specimenLabelList0)) = []; %Remove NaN from the cell array
        specimenLabelList0=specimenLabelList0(~cellfun('isempty',specimenLabelList0));%remove empty cells
        specimenLabelList=specimenLabelList0(2:end);
        labelsppno=length(specimenLabelList);
        %If the number of labels in the list cannot match the image number, use
        %temporary label instead.
        if labelsppno ~= sppamounts
            disp(['Numbers of labels ' ,num2str(labelsppno),' still DOESNT MATCH ',num2str(sppamounts),' (number of specimens found).']);
            specimenLabelList=createTemporaryLabel(subtemplate1,sppamounts);
        end
    end
        
    %Save an image for drawer inspection
    %resizeRatio=1/4;
    drawervisoutname=fullfile('Drawer_result',drawerInspectionDir,[template,'_drawerSpecimenBoxes.jpg']);
    figout=figure('visible', 'off');
    %imresize(Wbalance{im},resizeRatio);
    imshow(imadjust(ref));
    hold on;
    for spp=1:size(geometry_osize,1)
        original_box=geometry_osize{spp};
        position_box=[original_box(3), original_box(1), original_box(4)-original_box(3), original_box(2)-original_box(1)];
        rectangle('Position', position_box, 'EdgeColor','r', 'LineWidth', 1);
    end
    hold off;
    saveas(figout, drawervisoutname);
    close(figout);
    disp('An image with identified boxes of specimens has been saved.');
end