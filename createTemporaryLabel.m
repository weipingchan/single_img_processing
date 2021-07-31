function  specimenLabelList=createTemporaryLabel(subtemplate1,sppamounts)
specimenLabelList=cell(sppamounts,0);
for sp=1:sppamounts
    specimenLabelList{sp} = ['TempLabel-',subtemplate1,'-',num2str(sp)];
end
disp('Temporary label information is used.');
end