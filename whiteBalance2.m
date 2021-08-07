function [Wbalance, cen1, rad1, cen0, rad0, cmscale]=whiteBalance2(imgs,shapethreshold,reflectanceBlack,reflectanceWhite,evidence,template)
%Correct the pixel value of entire image according to the standard references.
%The pixel value in the output product indicates reflectance

Wbalance=cell(9,1);
disp('Start to find round shape references and the scale.');
%find the references and the scale in cm; px1: white ref value; px0: black
%ref value; cmscale: pixels/1cm
 [px1, px0, cen1, rad1, cen0, rad0, cmscale,GscaleUR,GscaleLL,scaleBox] = findRefScale(imgs{5}, shapethreshold, evidence,reflectanceBlack,reflectanceWhite);

 disp('Start to rescale the reflectence based on the value of references.');
 %white balance based on white and black references 
 Wbalance{5}=imReScaleRGB(imgs{5}, px0,px1);
 disp(['Variable [px0]: [',num2str(px0(1)),',',num2str(px0(2)),',',num2str(px0(3)),']']);
 disp(['Variable [px1]: [',num2str(px1(1)),',',num2str(px1(2)),',',num2str(px1(3)),']']);
 disp(['Band white had been rescaled based on the reflectence of references.']);

[px1, px0] = findRefOtherBand(imgs{6}, cen1, rad1, cen0, rad0,reflectanceBlack,reflectanceWhite);
Wbalance{6}=imReScaleRGB(imgs{6}, px0,px1);
disp(['Variable [px0]: [',num2str(px0(1)),',',num2str(px0(2)),',',num2str(px0(3)),']']);
disp(['Variable [px1]: [',num2str(px1(1)),',',num2str(px1(2)),',',num2str(px1(3)),']']);
disp(['Band whitePolarized 1 had been rescaled based on the reflectence of references.']);

[px1, px0] = findRefOtherBand(imgs{7}, cen1, rad1, cen0, rad0,reflectanceBlack,reflectanceWhite);
Wbalance{7}=imReScaleRGB(imgs{7}, px0,px1);
disp(['Variable [px0]: [',num2str(px0(1)),',',num2str(px0(2)),',',num2str(px0(3)),']']);
disp(['Variable [px1]: [',num2str(px1(1)),',',num2str(px1(2)),',',num2str(px1(3)),']']);
disp(['Band whitePolarized 2 had been rescaled based on the reflectence of references.']);
 
[px1, px0] = findRefOtherBand(imgs{1}, cen1, rad1, cen0, rad0,reflectanceBlack,reflectanceWhite);
Wbalance{1}=imReScale740(imgs{1}, px0,px1);
disp(['Variable [px0]: [',num2str(px0(1)),',',num2str(px0(2)),',',num2str(px0(3)),']']);
disp(['Variable [px1]: [',num2str(px1(1)),',',num2str(px1(2)),',',num2str(px1(3)),']']);
disp(['Band 740 had been rescaled based on the reflectence of references.']);

[px1, px0] = findRefOtherBand(imgs{2}, cen1, rad1, cen0, rad0,reflectanceBlack,reflectanceWhite);
Wbalance{2}=imReScale940(imgs{2}, px0,px1);  
disp(['Variable [px0]: [',num2str(px0(1)),',',num2str(px0(2)),',',num2str(px0(3)),']']);
disp(['Variable [px1]: [',num2str(px1(1)),',',num2str(px1(2)),',',num2str(px1(3)),']']);
disp(['Band 940 had been rescaled based on the reflectence of references.']);

%For UVrelated bands
[px1UV, px0UV] = findRefOtherBand(imgs{3}, cen1, rad1, cen0, rad0,reflectanceBlack,reflectanceWhite);
Wbalance{3}=imReScaleUV(imgs{3}, px0UV,px1UV);
disp(['Variable [px0UV]: [',num2str(px0UV(1)),',',num2str(px0UV(2)),',',num2str(px0UV(3)),']']);
disp(['Variable [px1UV]: [',num2str(px1UV(1)),',',num2str(px1UV(2)),',',num2str(px1UV(3)),']']);
disp(['Band UV had been rescaled based on the reflectence of references.']);

[px1UVF, px0UVF] = findRefOtherBand(imgs{4}, cen1, rad1, cen0, rad0,reflectanceBlack,reflectanceWhite);
Wbalance{4}= imReScaleUVF(imgs{4}, px0UVF,px1UVF);
disp(['Variable [px0UVF]: [',num2str(px0UVF(1)),',',num2str(px0UVF(2)),',',num2str(px0UVF(3)),']']);
disp(['Variable [px1UVF]: [',num2str(px1UVF(1)),',',num2str(px1UVF(2)),',',num2str(px1UVF(3)),']']);
disp(['Band UVFluorescence had been rescaled based on the reflectence of references.']);

%UV with RGB reflectance bands
 UV3bands=imReScaleRGB(imgs{3}, px0UV,px1UV);
 Wbalance{8}= UV3bands;
 disp(['Band UV in RGB had been rescaled based on the reflectence of references.']);
 clear UV3bands

%UVF with RGB reflectance bands
 UVF3bands=imReScaleRGB(imgs{4}, px0UVF,px1UVF);
 Wbalance{9}= UVF3bands;
 disp(['Band UVFluorescence in RGB had been rescaled based on the reflectence of references.']);
 clear UVF3bands
 
disp('All images have been rescaled based on white and black standard references.');
%Save the references and a scale image
refScaleOutname=fullfile('Drawer_result',template,[template,'_visualization'],[template,'_RefScale.jpg']);
%Show references and a scale
fig=figure('visible', 'off');
imshow(Wbalance{5});
hold on;
viscircles(cen1,rad1,'Color','r','LineWidth', 3);
line([GscaleUR(1),GscaleLL(1)], [GscaleUR(2),GscaleLL(2)], 'Color', 'g' ,'LineWidth', 2);
if sum(cen0)>0
viscircles(cen0,rad0,'Color','b','LineWidth', 3);
end
if cmscale>0
line(scaleBox(:, 1), scaleBox(:, 2), 'Color', 'y' ,'LineWidth', 3);
end
hold off;
export_fig(fig, refScaleOutname, '-jpg', '-r100');
close(fig);
disp('An RGB image with identified references and scale is saved.');

%Create an integrative image for all bands
resizeRatio=1/4;
outpanel=cell(length(Wbalance),0);
for im=1:length(Wbalance)
    if size(Wbalance{im},3)==1
        outpanel{im}=imresize(imadjust(Wbalance{im}),resizeRatio);
    else
        outpanel{im}=imresize(imadjust(Wbalance{im},[]),resizeRatio);
    end
end

    sppimgsoverview0=[outpanel{1:3}];
    sppimgsoverview0RGB=cat(3,sppimgsoverview0,sppimgsoverview0,sppimgsoverview0);
    sppimgsoverview1RGB=[outpanel{9},outpanel{5:7}];
    sppimgsoverview1RGB2=imresize(sppimgsoverview1RGB,size(sppimgsoverview0RGB,2)/size(sppimgsoverview1RGB,2));
    sppimgsoverviewRGB=vertcat(sppimgsoverview0RGB,sppimgsoverview1RGB2);
    
    sppvisoutname=fullfile('Drawer_result',template,[template,'_visualization'],[template,'_drawerAllBands.jpg']);
    imwrite(sppimgsoverviewRGB, sppvisoutname);    
        
    disp('Overview of all bands is saved.');

    %Create an integrative image for original image of all bands
resizeRatio=1/4;
outpanelraw=cell(length(imgs),0);
for im=1:length(imgs)
    outpanelraw{im}=imresize(imgs{im},resizeRatio);
end

    imgsoverview0=[outpanelraw{1:3}];
    imgsoverview0RGB=imgsoverview0;
    imgsoverview1RGB=[outpanelraw{4:end}];
    imgsoverview1RGB2=imresize(imgsoverview1RGB,size(imgsoverview0RGB,2)/size(imgsoverview1RGB,2));
    imgsoverviewRGB=vertcat(imgsoverview0RGB,imgsoverview1RGB2);

    sppvisoutname=fullfile('Drawer_result',template,[template,'_visualization'],[template,'_drawersRaw.jpg']);
    imwrite(uint8(imgsoverviewRGB/256), sppvisoutname);

    disp('Original images of all bands are saved.');
end