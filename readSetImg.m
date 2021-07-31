function imgs=readSetImg(directory, template, filetype)
spectralnames={'740','940','uv','uv_fluorescence','white','whitepol','whitepol2'};

img_names=cell(1,size(spectralnames,2));
for spec=1:size(spectralnames,2)
    img_names{spec}=fullfile(directory,strjoin([template,'_',spectralnames(spec),'.',filetype],''));
end

% Directory
[~,nfile]=size(img_names);
imgs=cell(nfile,1);
for i=1:nfile
     imgs{i} = import_img(img_names{i});
end
end