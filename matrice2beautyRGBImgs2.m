function matrice2beautyRGBImgs2(spp_mat_directory, Code_directory, Result_directory, rmBGorNot, outImgformat,outImgDPI)
if size(spp_mat_directory,2)==1 spp_mat_directory=spp_mat_directory{1};, end;
if size(Code_directory,2)==1 Code_directory=Code_directory{1};, end;
if size(Result_directory,2)==1 Result_directory=Result_directory{1};, end;
if size(outImgformat,2)==1 outImgformat=outImgformat{1};, end;
if ~isnumeric(rmBGorNot) rmBGorNot=str2num(rmBGorNot);, end; 
if ~isnumeric(outImgDPI) outImgDPI=str2num(outImgDPI);, end; 

% Turn off this warning "Warning: Image is too big to fit on screen; displaying at 33% "
% To set the warning state, you must first know the message identifier for the one warning you want to enable. 
warning('off', 'Images:initSize:adjustingMag');

vdlist={'dorsal','ventral'};

addpath(genpath(Code_directory)) %Add the library to the path
%Read the file list in the Img_directory
img_ds = struct2dataset(dir(fullfile(spp_mat_directory,'*_AllBandsMask.mat')));
img_listing=img_ds(:,1);

matoutname1=fullfile(Result_directory,'original_list.mat');
save(matoutname1,'img_listing'); %save the specimen list

img_list_inspect=cell(0,length(img_listing));
for matinID=1:length(img_listing)
    matinname=img_listing.name{matinID};
    [barcode, side, flag]=file_name_decoder(matinname);
    img_list_inspect{matinID}{1}=[barcode,'_',vdlist{side},flag];
    try
        sppmat=load_mat(spp_mat_directory,matinname);
        disp(['No. ',num2str(matinID),' [',matinname,'] has been read into memory']);
        img_list_inspect{matinID}{2}=1; %%test
        
        cmscale=sppmat{end};
        mask=sppmat{end-1};
        background = mask == 0; % Find black pixels.
        sppimgsoverview0RGB=sppmat{6};
        sppimgsoverviewHSV = rgb2hsv(sppimgsoverview0RGB);
        % "20% more" saturation:
        sppimgsoverviewHSV(:, :, 2) = sppimgsoverviewHSV(:, :, 2) * 1.2;
        %sppimgsoverviewHSV(:, :, 2) = sppimgsoverviewHSV(:, :, 2)+0.2;
        sppimgsoverviewHSV(sppimgsoverviewHSV > 1) = 1;  % Limit values
        sppimgsoverview0L=sppimgsoverviewHSV(:,:,3);
        %Gamma adjust the brightness (gamma<1: brighter; gamma >1: darker)
        sppimgsoverviewHSV(:,:,3)=imadjust(sppimgsoverview0L,[],[],0.75);
        sppimgsoverview1RGB= hsv2rgb(sppimgsoverviewHSV);
        
        %create scale bar in black
        scaleline=zeros(50,size(sppimgsoverview1RGB,2),3);
        opacityscaleline=scaleline;
        %scaleline(:,:,:)=1;
        scaleline(20:30,round(end-100-cmscale):end-100,:)=1;
        %combine all image together
        sppimgsoverviewRGB=vertcat(sppimgsoverview1RGB,scaleline);
        
        opacityscaleline(:,:,:)=0;
        opacityscaleline(20:30,end-100-round(cmscale):end-100,:)=1;
        opacitymask=vertcat(mask, opacityscaleline(:,:,1));
        
        if rmBGorNot==1
            sppvisoutname=fullfile(Result_directory,[barcode,'_',vdlist{side},flag,'_Adjusted_Img-rmBG.',outImgformat]);
            figinsp=figure('visible', 'off');
            image(sppimgsoverviewRGB, 'AlphaData', double(opacitymask));
            axis('image');
            truesize([size(sppimgsoverviewRGB,1), size(sppimgsoverviewRGB,2)]);
            set(gca,'Visible','off');
            export_fig(figinsp,sppvisoutname, '-transparent', '-png', ['-r',num2str(outImgDPI)]);
            close(figinsp);
        else
            sppvisoutname=fullfile(Result_directory,[barcode,'_',vdlist{side},flag,'_Adjusted_Img.',outImgformat]);
            figinsp=figure('visible', 'off');
            imshow(sppimgsoverviewRGB);
            export_fig(figinsp,sppvisoutname, ['-',outImgformat],['-r',num2str(outImgDPI)]);
            close(figinsp);
        end
        clear sppmat sppimgsoverview0RGB sppimgsoverviewHSV sppimgsoverview0L sppimgsoverview1RGB sppimgsoverviewRGB;

        disp(['[',barcode,'_',vdlist{side},flag,'_Adjusted_Img.',outImgformat,'] has been saved']);
        disp(['##################################################']);        
    catch
        disp(['No. ',num2str(matinID),' [',matinname,'] cannot be read into memory']);
        img_list_inspect{matinID}{2}=0; %%test
    end
end
        
        matoutname2=fullfile(Result_directory,'inloop_list.mat');
        save(matoutname2,'img_list_inspect'); %save the specimen list for inspection

end