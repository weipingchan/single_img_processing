function single_img_processing(Img_directory, Code_directory, Result_directory, labelfileName, scaleevidence, template, legacy_input, manual_input)
%process a set of drawer images
%legacy 0 represents no, 1 represents yes (legacy indicates those images with brighter background and shadows)
%manual 0 represents off, 1 represents on (manual indicates if manually defined specimen boxes are used or not)

%Convert double quotes to single quotes for the matlab version prior than 2017
if size(Img_directory,2)==1 Img_directory=Img_directory{1};, end;
if size(Code_directory,2)==1 Code_directory=Code_directory{1};, end;
if size(Result_directory,2)==1 Result_directory=Result_directory{1};, end;
if size(labelfileName,2)==1 labelfileName=labelfileName{1};, end;
if size(scaleevidence,2)==1 scaleevidence=scaleevidence{1};, end;
if size(template,2)==1 template=template{1};, end;

imgFiletype='tiff'; %Default image file type
shapethreshold = 0.8; %Use to find the round-shape reference and exclude them from specimens
maxarea2rectangleratio=0.8; %Use to remove rectangle shape (board with references and a scale)
shapetemplateName='shapeTemplate.mat'; %Defalt shape context file, which derived from well outlined specimens' masks.

%Define the file name of evidence image in order to find the scale bar
%scaleevidence='forensic-evidence-labels.jpg'; in our case

%The information of references (These values are derived from the standard references provider)
reflectanceBlack = 1.1192;
reflectanceWhite = 99.1508;

legacy=str2num(legacy_input);
pauseornot=0; % 0 represents off, 1 represents on; if pause is on, CPUs have time to cool down, preventing overheated
manual=str2num(manual_input);

addpath(genpath(Code_directory)) %Add the library to the path
cd(Result_directory); %Move to the directory where the results will be stored.

disp('Start to create / find primary folders.');
%Create result directory
if ~exist('Drawer_result', 'dir')
    mkdir('Drawer_result');
end

drawerInspectionDir='drawer_inspection';
if ~exist(fullfile('Drawer_result',drawerInspectionDir), 'dir')
    mkdir(fullfile('Drawer_result',drawerInspectionDir));
end

sppMatriceDir='spp_matrices';
if ~exist(fullfile('Drawer_result',sppMatriceDir), 'dir')
    mkdir(fullfile('Drawer_result',sppMatriceDir));
end

sppInspectionDir='spp_inspection';
if ~exist(fullfile('Drawer_result',sppInspectionDir), 'dir')
    mkdir(fullfile('Drawer_result',sppInspectionDir));
end

logHistoryDir='log_history';
if ~exist(fullfile('Drawer_result',logHistoryDir), 'dir')
    mkdir(fullfile('Drawer_result',logHistoryDir));
end
disp('Primary folders are created / found.');

%Read the file list in the Img_directory
img_ds = struct2dataset(dir(fullfile(Img_directory,'*.tiff')));
img_listing=img_ds(:,1);

spectralnames={'740','940','uv','uv_fluorescence','white','whitepol','whitepol2'};
%Check the number of a set of images
imgcheck=zeros(size(spectralnames,2),1);
for spec=1:size(spectralnames,2)
    if any(strcmp(img_listing.name,strjoin([template,'_',spectralnames(spec),'.',imgFiletype],'')))
        check=1;
    else
        check=0;
    end
    imgcheck(spec)=check;
end

if prod(imgcheck)>0
    disp(['All 7 imgs of drawer: [',template,'] are found.']);
    %Start to process the set of drawer images
    drawerProcessing(Img_directory, Code_directory, Result_directory, drawerInspectionDir, sppMatriceDir, sppInspectionDir,logHistoryDir, template, imgFiletype, labelfileName, scaleevidence, shapetemplateName, shapethreshold, maxarea2rectangleratio, reflectanceBlack, reflectanceWhite, pauseornot, legacy, manual);
    
    %Move images that were analyzed to a sub directory
    cd(Img_directory); %Move to the directory where the original images are stored.
    
    %Move those images having been analyzed to a subdirectory
    finishedDir='done';
    if ~exist(finishedDir, 'dir')
        mkdir(finishedDir);
    end
    movefile([template,'*.tiff'], finishedDir);
    disp('Images analyzed have been moved to done directory.');
else
    disp(['Drawer: [',template,'] has insufficient spectral images, so will not be processed.']);
end
end
