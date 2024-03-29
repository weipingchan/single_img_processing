function drawerProcessing(Img_directory, Code_directory, Result_directory, drawerInspectionDir, sppMatriceDir, sppInspectionDir,logHistoryDir, template, imgFiletype, labelfileName, scaleevidence, shapetemplateName, shapethreshold, maxarea2rectangleratio, reflectanceBlack, reflectanceWhite, pauseornot, legacy,manual)
disp(['Start to analyze drawer: ', template]);
%read the label file
labelfile=readtable(fullfile(Code_directory,labelfileName));
drawerlist=table2cell(labelfile(:,1));
disp('The file including label information is found.');

imgtypes={'740','940','UV','UVF','F','white','whitePo1','whitePo2','FinRGB','PolDiff','mask'};

% Turn off this warning "Warning: Image is too big to fit on screen; displaying at 33% "
% To set the warning state, you must first know the message identifier for the one warning you want to enable. 
warning('off', 'Images:initSize:adjustingMag');

cd(Result_directory); %Move to the directory where the results will be stored.
disp('Start to create / find corresponding drawer folders.');
%Create result directory
if ~exist(fullfile('Drawer_result',template), 'dir')
    mkdir(fullfile('Drawer_result',template));
end

if ~exist(fullfile('Drawer_result',template,[template,'_visualization']), 'dir')
    mkdir(fullfile('Drawer_result',template,[template,'_visualization']));
end
disp('corresponding drawer folders are created / found.');

logfilename=fullfile('Drawer_result',logHistoryDir,['log_',datestr(now,'dd-mm-yy','local'),'_',datestr(now,'hh-MM-ss','local'),'_drawername_',template,'.txt']);
%Start to write the log file
diary(logfilename);
disp(['Variable [directory]: ',Img_directory]);
disp(['Variable [template]: ',template]);
disp(['Variable [imgFiletype]: ',imgFiletype]);
disp(['Variable [shapethreshold]: ',num2str(shapethreshold)]);
disp(['Variable [maxarea2rectangleratio]: ',num2str(maxarea2rectangleratio)]);
disp(['Variable [reflectanceBlack]: ',num2str(reflectanceBlack)]);
disp(['Variable [reflectanceWhite]: ',num2str(reflectanceWhite)]);
disp(['Variable [labelfileName]: ',labelfileName]);
disp(['Variable [pauseornot]: ',num2str(pauseornot)]);
disp(['Variable [legacy]: ',num2str(legacy)]);
disp(['Variable [manual]: ',num2str(manual)]);

%Image analysis
disp('Start to read images into memory.');
img0s=readSetImg(Img_directory, template, imgFiletype);
disp('A set of images is read into memory.');

[wbimg0s, cen1, rad1, cen0, rad0, cmscale]=whiteBalance2(img0s,shapethreshold,reflectanceBlack,reflectanceWhite,scaleevidence,template);
disp(['Variable of BLACK ref [[cen0], rad0]: [[',num2str(cen0(1)),',',num2str(cen0(2)),'],',num2str(rad0),']']);
disp(['Variable of WHITE ref [[cen0], rad0]: [[',num2str(cen1(1)),',',num2str(cen1(2)),'],',num2str(rad1),']']);
disp(['Variable [cmscale]: ',num2str(cmscale)]);

if legacy==1 %If there are inconsistent small patches in the background, we carefully filter out small object detected
    MinimalObjectSize=ceil(size(wbimg0s{2},1)*size(wbimg0s{2},2)/4000); %Define the minimal size of an object
    darkThreshold=0.4; %Default dark threshold for previous platform
else %if the background is clean, we use smaller threshold to include everything detected
    MinimalObjectSize=round(ceil(size(wbimg0s{2},1)*size(wbimg0s{2},2)/20000)/3); %Define the minimal size of an object
    darkThreshold=0.1; %Default dark threshold for the imaging platform we designed
end

%Find the corresponding labels and match with the number of specimens
%Create temporary one if cannot find one

%Detect if there is a corresponding manually-defined bounding box in the folder
boxInfoDir='manual_boxes';
box_ds = struct2dataset(dir(fullfile(Code_directory,boxInfoDir,'*_Boxes.mat')));
box_listing=box_ds(:,1);
if any(strcmp(box_listing.name,[template,'_Boxes.mat']))
    manual=1;
end

if manual==0
    [wbimg0s,img0s]=historical_imgs_cropping2(wbimg0s,img0s); %Crop unwanted border outside of the imaging platform if there is any
    gatheringfactorlist=[2, 5, 20,10,15]; %factor(pixel) to link object; when specimens are close, use smaller one; the default value used for drawer without label information is the 3rd place in the list
    [geometry_osize,specimenLabelList]=findCoraseOutlines(Unlinear_img(img0s{2}),template,drawerlist,labelfile,shapethreshold,maxarea2rectangleratio,gatheringfactorlist,MinimalObjectSize,Code_directory,drawerInspectionDir);
    disp(['Variable [MinimalObjectSize]: ',num2str(MinimalObjectSize)]);
else
    [wbimg0s,~]=historical_imgs_cropping2(wbimg0s,img0s); %Crop unwanted border outside of the imaging platform if any
    disp(['Manually defined specimen boxes are used. Matrix name: [',[template,'_Boxes.mat]']]);
    [geometry_osize,specimenLabelList]=findCoraseOutlines_inputBoxes(wbimg0s{2},template,drawerlist,labelfile,drawerInspectionDir,Code_directory);
end
clear img0s

%cookie-cutting specimen images from the drawer image
cropedimgs=cropimg(wbimg0s,geometry_osize);
clear wbimg0s
disp('Specimen images are cropped based on the bounding boxes.');

%realign multispectral images
refno=2; %Use Near infrared (940 nm) as the reference image
if legacy==1
    realignedcropedimgs=realignspecimen3His(cropedimgs,refno,pauseornot);
else
    realignedcropedimgs=realignspecimen4(cropedimgs,refno,pauseornot);
end
clear cropedimgs

%shapetemplateName; %Feel lazy to
%remove this variable in all connected parental files though it is useless
%now

%Detect the outline of each specimen
[realignedcropedsymimgs,sppmask,sppedge,finalCentroidList]=findSpecimenFineEdge4(realignedcropedimgs,darkThreshold);
clear realignedcropedimgs

%Save the results in all formats for archiving and inspection
savedSpecimenResult2(realignedcropedsymimgs,sppmask,sppedge,imgtypes,template,sppMatriceDir,sppInspectionDir,specimenLabelList,cmscale,finalCentroidList);
disp('Preliminary analysis finished! Results are saved.');
diary off;
end