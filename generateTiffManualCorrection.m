function generateTiffManualCorrection(spp_mat_directory,Code_directory,Result_directory)
addpath(genpath(Code_directory)) %Add the library to the path

%Create a directory for matrices that have already been output for manually
%correction
donematDir='done_matrices';
if ~exist(fullfile(spp_mat_directory,donematDir), 'dir')
    mkdir(fullfile(spp_mat_directory,donematDir));
end

%Read the file list in the Img_directory
img_ds = struct2dataset(dir(fullfile(spp_mat_directory,'*_AllBandsMask.mat')));
img_listing=img_ds(:,1);
for matinID=1:length(img_listing)
        matinname=fullfile(spp_mat_directory,img_listing.name{matinID});
        template=img_listing.name{matinID}(1:end-17);
    try
        sppmat0=load(matinname);
        sppimgs=sppmat0.sppimgs;
        clear sppmat0

        %Create an RGB image with 940, blue, and mask in RGB band
        outimg=sppimgs{6};
        outimg(:,:,1)=sppimgs{2};
        outimg(:,:,2)=sppimgs{6}(:,:,3);
        outimg(:,:,3)=sppimgs{end-1};

        sppvisoutname=fullfile(Result_directory,[template,'_for_manual_adj.tiff']);
        imwrite(outimg, sppvisoutname);
        disp(['specimen [',template,'] has been saved in the format for manually correction.']);
        movefile(matinname, fullfile(spp_mat_directory,donematDir));
        disp(['spp matrix [',template,'] have been moved to done directory.']);
    catch
        disp(['Something wrong with [',template,'], so the format for manually correction has not been generated.']);
    end
    disp(['No. ',num2str(matinID),' out of ',num2str(length(img_listing)),' is done.']);
end
end