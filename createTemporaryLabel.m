function  specimenLabelList=createTemporaryLabel(subtemplate1,sppamounts)
%If the number of specimens on the imaging stage is different from the
%number of provided label information, it generates temporary ones
%according to the image name.
specimenLabelList=cell(sppamounts,0);
for sp=1:sppamounts
    specimenLabelList{sp} = ['TempLabel-',subtemplate1,'-',num2str(sp)];
end
disp('Temporary label information is used.');
end