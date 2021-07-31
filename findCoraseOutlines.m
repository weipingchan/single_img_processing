function [geometry_osize,specimenLabelList]=findCoraseOutlines(ref,template,drawerlist,labelfile,shapethreshold,maxarea2rectangleratio,gatheringfactorlist,MinimalObjectSize,Code_directory,drawerInspectionDir)
    %Find the corresponding labels and match with thenumber of specimens
    %Create temporary one if cannot find one
    subtemplate0=strsplit(template,'_');
    subtemplate1=strjoin(subtemplate0(1:end-1),'_');
    drawerID = find(all(ismember(drawerlist,subtemplate1),2));
    if isempty(drawerID)
        disp('CANNOT find corresponding drawer information.');
        gatheringfactor=5; %if no label record, use 5 as the gatheringfactor
        disp(['Use gatheringfactor: ' ,num2str(gatheringfactor)]);
        [geometry_osize,sppamounts]=find_specimen2(ref,shapethreshold,maxarea2rectangleratio,gatheringfactor,MinimalObjectSize);
        %sppamounts=size(geomtry_osize,1);
        specimenLabelList=createTemporaryLabel(subtemplate1,sppamounts);
    else
        disp('Find the corresponding drawer information.');
        specimenLabelList0=table2cell(labelfile(drawerID,:));
        specimenLabelList0(cellfun(@(specimenLabelList0) any(isnan(specimenLabelList0)),specimenLabelList0)) = []; %Remove NaN from the cell array
        specimenLabelList0=specimenLabelList0(~cellfun('isempty',specimenLabelList0));%remove empty cells
        specimenLabelList=specimenLabelList0(2:end);
        labelsppno=length(specimenLabelList);
        
        
        gatheringresult=zeros(length(gatheringfactorlist),2); %Testing zone 20180401
        
        for loo=1:length(gatheringfactorlist)
            gatheringfactor=gatheringfactorlist(loo); 
            disp(['Try gatheringfactor: ' ,num2str(gatheringfactor)]);
            [geometry_osize,sppamounts]=find_specimen2(ref,shapethreshold,maxarea2rectangleratio,gatheringfactor,MinimalObjectSize);
            %sppamounts=size(geomtry_osize,1);
            if labelsppno ==sppamounts
                disp(['Numbers of labels ' ,num2str(labelsppno),' matches number of specimens found.']);
                break;
            end
            gatheringresult(loo,1)=gatheringfactor; %Testing zone 20180401
            gatheringresult(loo,2)=sppamounts; %Testing zone 20180401
            disp(['Numbers of labels is ' ,num2str(labelsppno),' NOT ',num2str(sppamounts),' (number of specimens found), so retry different gatheringfactor.']);
            if loo==length(gatheringfactorlist)        %test zone 20180401
                [~,minloc]=min(abs(gatheringresult(:,2)-labelsppno));        %test zone 20180401
                if minloc==loo        %test zone 20180401
                    disp(['Since no gatheringfactor can detect the correct number of specimens, the closest one is chose, gatheringfactor: ' ,num2str(gatheringfactor)]);        %test zone 20180401
                    break;        %test zone 20180401
                else        %test zone 20180401
                    gatheringfactor=gatheringresult(minloc,1);        %test zone 20180401
                    disp(['Since no gatheringfactor can detect the correct number of specimens, the closest one is chose, gatheringfactor: ' ,num2str(gatheringfactor)]);        %test zone 20180401
                    [geometry_osize,sppamounts]=find_specimen2(ref,shapethreshold,maxarea2rectangleratio,gatheringfactor,MinimalObjectSize);        %test zone 20180401
                    %sppamounts=size(geomtry_osize,1);        %test zone 20180401
                    disp(['Number of specimens found is: ' ,num2str(sppamounts),' .']);        %test zone 20180401
                end   %test zone 20180401 
            end
        end
        %test zone 20180401
        
        %If the number of labels in the list cannot match the image number, use
        %temporary label instead.
        if labelsppno ~= sppamounts
            disp(['Numbers of labels ' ,num2str(labelsppno),' still DOESNT MATCH ',num2str(sppamounts),' (number of specimens found).']);
            specimenLabelList=createTemporaryLabel(subtemplate1,sppamounts);
        end
    end

    %Save the boxes
    boxInfoDir='manual_boxes';
    if ~exist(fullfile(Code_directory,boxInfoDir), 'dir')
        mkdir(fullfile(Code_directory,boxInfoDir));
    end

    boxoutname=fullfile(Code_directory,boxInfoDir,[template,'_Boxes.mat']);
    save(boxoutname,'geometry_osize');
    disp(['Boxes matrices for drawer: [',template,'] has been saved.']);
    
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