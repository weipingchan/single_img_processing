function savedSpecimenResult2(realignedcropedimgs,sppmask,sppedge,imgtypes,template,sppMatriceDir,sppInspectionDir,specimenLabelList,cmscale,finalCentroidList)
%Determine if there is side information in the file name
dorsalventrallist={'dorsal';'ventral';'unknown'};

if contains(template,dorsalventrallist{1}) || contains(template,dorsalventrallist{2})
    if contains(template,dorsalventrallist{1})
        side=dorsalventrallist{1};
    else
        side=dorsalventrallist{2};
    end
else
    side=dorsalventrallist{3};
end

%Create folders
for  imgtp=1:length(imgtypes)
if ~exist(fullfile('Drawer_result',template,[template,'_visualization'],[template,'_',imgtypes{imgtp}]), 'dir')
    mkdir(fullfile('Drawer_result',template,[template,'_visualization'],[template,'_',imgtypes{imgtp}]));
end
end

disp('Start to save Species centroid information.');
centroidfilename=fullfile('Drawer_result',sppMatriceDir,['Drawername_',template,'_centroid_list.txt']);
fcenid = fopen(centroidfilename,'wt');
[sppamounts,~]=size(realignedcropedimgs);
for sppin=1:sppamounts
    %Create a centroid list for output
    sppcentroid=finalCentroidList(sppin,:);
    sppcentroidrecord=strjoin([specimenLabelList(sppin), ' centroid: [',num2str(sppcentroid(1)), ',',num2str(sppcentroid(2)),']\n']);
    fprintf(fcenid, sppcentroidrecord);
end
fclose(fcenid);
disp('Species centroid information is saved.');

disp('Start to save image data and images for visualization.');
for sppin=1:sppamounts
    %Start to prepare images for output
    sppimgs0=realignedcropedimgs(sppin,:);
    specimenB=sppedge{sppin};

    specimenL=sppmask{sppin};
    
    imgF=sppimgs0{4}-sppimgs0{3};
    imgFinRGB=sppimgs0{9}-sppimgs0{8};
    imgPolarDiff=abs(sppimgs0{6}-sppimgs0{7});
    sppimgs1=[sppimgs0{1:4},{imgF},sppimgs0{5:7},{imgFinRGB},{imgPolarDiff}];
    sppimgs1{size(sppimgs1,2)+1}=specimenL;
    sppimgs=sppimgs1;
    sppimgs{size(sppimgs1,2)+1}=cmscale;
    %The layers in sppimgsmatrice are 740, 940, UV, UVF, F, white,
    %whitePo1, whitePo2, F(RGB),  Polarized Diff (abs), mask, pixels as 1cm

    sppoutname=fullfile('Drawer_result',sppMatriceDir,strjoin([specimenLabelList(sppin),side,'AllBandsMask.mat'],'_'));
    save(sppoutname,'sppimgs', '-v7.3');
    disp(['Data matrices for specimen No. ',num2str(sppin),' out of ',num2str(sppamounts),' are saved.']);
    
    %Create an integrative image for all band including mask
    %nogreenchannel=zeros(size(sppimgs{1},1),size(sppimgs{1},2));
    %imgFinRGB=sppimgs1{end-1};
    
    [spimgl,spimgw]=size(sppimgs1{1});
    sppimgsoverview0=[sppimgs1{1:4}];
    sppimgsoverview0RGB=[cat(3,sppimgsoverview0,sppimgsoverview0,sppimgsoverview0)];
    %sppimgsoverview1RGB=[imgFinRGB,sppimgs1{6:end-3}];
    sppimgsoverview1RGB=[sppimgs1{6:end-3},imgPolarDiff];
    %create scale bar
    scaleline=zeros(50,size(sppimgsoverview0RGB,2),3);
    scaleline(20:30,round(end-100-cmscale):round(end-100),:)=1;
    %combine all image together
    sppimgsoverviewRGB=vertcat(sppimgsoverview0RGB,imresize(sppimgsoverview1RGB,[NaN, size(sppimgsoverview0RGB,2)]),scaleline);
       
    sppvisoutname=fullfile('Drawer_result',template,[template,'_visualization'],strjoin([specimenLabelList(sppin),side,'AllBandsOutline.jpg'],'_'));
    figall=figure('visible', 'off');
    imshow(sppimgsoverviewRGB);
    hold on;
    %repeated plot outlines through all images
    for verpanel=1:2
        for horpanel=1:4            
            plot(specimenB{1}(:,2)+(horpanel-1)*spimgw, specimenB{1}(:,1)+(verpanel-1)*spimgl, 'r', 'LineWidth', 0.5);
        end
    end
    hold off;
    export_fig(figall,sppvisoutname, '-jpg', '-r150');
%     saveas(figall, sppvisoutname);    
    close(figall);
    disp(['Overview for specimen No. ',num2str(sppin),' out of ',num2str(sppamounts),' are saved.']);
    
    [~,bandno]=size(sppimgs1);
        for imgtp=1:bandno
            %Save images with outline
            demooutname0=strjoin([specimenLabelList(sppin),side,imgtypes{imgtp},'demo_noline.jpg'],'_');
            demoout0=fullfile('Drawer_result',template,[template,'_visualization'],[template,'_',imgtypes{imgtp}],demooutname0);
            imscaleline=zeros(50,size(sppimgs1{imgtp},2),size(sppimgs1{imgtp},3));
            imscaleline(20:30,round(end-100-cmscale):round(end-100),:)=1;
            bandImg=vertcat(sppimgs1{imgtp},imscaleline);
            imwrite(bandImg, demoout0);    
                        
            %Save images with outline
            demooutname=strjoin([specimenLabelList(sppin),side,imgtypes{imgtp},'demo.jpg'],'_');
            demoout=fullfile('Drawer_result',template,[template,'_visualization'],[template,'_',imgtypes{imgtp}],demooutname);
            %imscaleline=zeros(50,size(sppimgs1{imgtp},2),size(sppimgs1{imgtp},3));
            %imscaleline(20:30,round(end-100-cmscale):round(end-100),:)=1;
            %bandImg=vertcat(sppimgs1{imgtp},imscaleline);
            fig=figure('visible', 'off');
            imshow(bandImg);
            hold on;
            plot(specimenB{1}(:,2), specimenB{1}(:,1), 'r', 'LineWidth', 0.5);
            hold off;
            export_fig(fig, demoout, '-jpg', '-r100');
%             saveas(fig, demoout);
            %Save a copy for inspection purpose
            if imgtp==2
                inspout=fullfile('Drawer_result',sppInspectionDir,demooutname);
                export_fig(fig, inspout, '-jpg', '-r100');
%                 saveas(fig, inspout);
            end
            %Special display for mask
            if imgtp<11
                disp(['Band ',num2str(imgtp),' (',imgtypes{imgtp},') of specimen No. ',num2str(sppin),' is saved.']);
            else
                disp(['The mask of specimen No. ',num2str(sppin),' is saved.']);
            end
            close(fig);
        end
    disp(['Images for specimen No. ',num2str(sppin),' out of ',num2str(sppamounts),' are saved.']);
end
disp('Images of all specimens are saved.');
end