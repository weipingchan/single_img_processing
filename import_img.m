function corimg = import_img(file)
%parasdir = 'D:\Milk desk\Dropbox\Harvard\Coloration_research\Multi_spectra_processing\Camera_parameters_all_lens.mat';
%load(parasdir)
img = imread(file);
%fileint = strsplit(file,"\");
%filename = fileint(end);
%corimg = undistortImage(img,Cam_uv_Par);

%if contains(filename,'whitepol2')
%    corimg = undistortImage(img,Cam_whitepol2_Par);
%else
%    if contains(filename,'whitepol')
%        corimg = undistortImage(img,Cam_whitepol_Par);
%    else
%        if contains(filename,'white')
           corimg = img;
%        else
%            if contains(filename,'740')
%                corimg = undistortImage(img,Cam_740_Par);
%            else
%                if contains(filename,'940')
%                    corimg = undistortImage(img,Cam_940_Par);
%                else
%                    if contains(filename,'uv_fluorescence')
%                        corimg = undistortImage(img,Cam_uvf_Par);
%                    else
%                        if contains(filename,'uv')
%                            corimg = undistortImage(img,Cam_uv_Par);
%                        else
%                            corimg = img;
%                        end
%                    end
%                end
%            end
%        end
%    end
%end
[imheight, imwidth, imchannel]=size(img);
if imheight>imwidth
corimg=imrotate(corimg, 90);
end

%figure,imshowpair(corimg,rgb2gray(img))
end