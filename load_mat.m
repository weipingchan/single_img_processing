function sppmat=load_mat(spp_mat_directory,inname)
    matinname=fullfile(spp_mat_directory,inname);
    sppmat0=load(matinname);
    fieldName=cell2mat(fieldnames(sppmat0));
    sppmat=sppmat0.(fieldName);
    clear sppmat0
end