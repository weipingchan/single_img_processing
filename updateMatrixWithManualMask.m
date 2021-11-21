function updateMatrixWithManualMask(manual_shape_directory,spp_mat_directory,Code_directory,Result_directory)
%Update the existing matrices
addpath(genpath(Code_directory)) %Add the library to the path

MinimalObjectSize=500; %Define the minimal object that is retained as the mask, removing all other trivial spots

 idcs   = strfind(spp_mat_directory,filesep); %'filesep' here is a preserved variable in matlab
 NsppDir = spp_mat_directory(1:idcs(end)-1);

 
% Turn off this warning "Warning: Image is too big to fit on screen; displaying at 33% "
% To set the warning state, you must first know the message identifier for the one warning you want to enable. 
warning('off', 'Images:initSize:adjustingMag');
 
%Create a directory for inspection if it does not exist
sppInspectionDir='manual_mask_inspection';
if ~exist(fullfile(Result_directory,sppInspectionDir), 'dir')
    mkdir(fullfile(Result_directory,sppInspectionDir));
end

%Create a directory for outdated matrices if it does not exist
outdatedDir='outdated_matrices';
if ~exist(fullfile(NsppDir,outdatedDir), 'dir')
    mkdir(fullfile(NsppDir,outdatedDir));
end

%Create a directory for outdated matrices if it does not exist
doneDir='manual_tiff_done';
if ~exist(fullfile(manual_shape_directory,doneDir), 'dir')
    mkdir(fullfile(manual_shape_directory,doneDir));
end

vdlist={'dorsal','ventral'};
%Read the file list in the Img_directory
img_ds0 = struct2dataset(dir(fullfile(manual_shape_directory,'*for_manual_adj.tif')));
% if isempty(img_ds)
img_ds1 = struct2dataset(dir(fullfile(manual_shape_directory,'*for_manual_adj.tiff')));
% end
if isempty(img_ds0); img_ds02=[]; else img_ds02=img_ds0(:,1); end; 
if isempty(img_ds1); img_ds12=[]; else img_ds12=img_ds1(:,1); end; 
img_listing=[img_ds02; img_ds12];

for matinID=1:length(img_listing)
    if length(img_listing)>1
        manuallinname=fullfile(manual_shape_directory,img_listing.name{matinID});
        matinname=img_listing.name{matinID};
    elseif length(img_listing)==1
        manuallinname=fullfile(manual_shape_directory,img_listing.name);
        matinname=img_listing.name;
    end
    [barcode, side, flag]=file_name_decoder(matinname);
    template=[barcode,'_',vdlist{side},flag];
%     template=img_listing.name{matinID}(1:end-20);

    %Only update the matrix if the original matrix can be found
    try
        %read original matrice
        try
            matinname=fullfile(spp_mat_directory,[template,'_AllBandsMask.mat']);
            sppmat0=load(matinname);
        catch
            matinname=fullfile(spp_mat_directory,[template,'_AllBandsMask.mat']);
            sppmat0=load(matinname);
        end
        sppimgs=sppmat0.sppimgs;
        clear sppmat0

        %read manually corrected img
        %manuallinname=fullfile(manual_shape_directory,[template,'_for_manual_adj.tiff']);
        manualimg=read(Tiff(manuallinname,'r'));
        sppimgs{end-1}=bwareaopen(imbinarize(manualimg(:,:,end),0.1),MinimalObjectSize);

        matoutname=fullfile(Result_directory,[template,'_AllBandsMask.mat']);
        save(matoutname,'sppimgs', '-v7.3'); %save the specimen matrix. The argument '-v7.3' allows files larger than 2 GB being saved with compression

        %Save manual result for inspection
        [specimenB,~]=bwboundaries(sppimgs{end-1},'noholes');

        inspectooutname=[template,'_manual_shape_inspection.jpg'];
        inspout=fullfile(Result_directory,sppInspectionDir,inspectooutname);

        fig=figure('visible', 'off');
        imshow(sppimgs{2});
        hold on;
        plot(specimenB{1}(:,2), specimenB{1}(:,1), 'r', 'LineWidth', 2);
        hold off;
%         saveas(fig, inspout);
        export_fig(fig,inspout, '-jpg','-r100');
        close(fig);
        disp(['The matrix of Image [',template,'] has been updated.']);

        %Move and collect those updated matrices
        movefile(matinname, fullfile(NsppDir,outdatedDir));
        disp(['outdated specimen matrix [',template,'] have been moved to the outdated directory.']);
        movefile(manuallinname, fullfile(manual_shape_directory,doneDir));
        disp(['manually corrected mask [',template,'] have been moved to the done directory.']);
    catch
        disp(['The matrix of [',template,'] cannot be found, so the shape matrix cannot be updated.']);
    end
    disp(['No. ',num2str(matinID),' out of ',num2str(length(img_listing)),' is done.']);
end
end