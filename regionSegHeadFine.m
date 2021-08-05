function panel_r= regionSegHeadFine(panel,panel_seg2,panel_ed5,Cmask_head_fine)
%Focus on the head region in order to deal with the antenna issue
%Find the optimal value of multiplyFactor
    factorlist=[];
    for multiplyFactor=2:0.1:10 
        panel_r=bwareaopen(imbinarize(panel_seg2+panel_ed5+panel*multiplyFactor,0.95),300);
        panel_ff=imfill(imdilate(imerode(panel_r,strel('disk',1)),strel('disk',1)),'hole');
        [sB,sL] = bwboundaries(bwareaopen(imclearborder(immultiply(panel_ff,Cmask_head_fine),4),100),'noholes');
        stats_sL = regionprops(sL, 'Area', 'EulerNumber');
        
        if (length(sB)==1) && (stats_sL.EulerNumber==1)
              % obtain (X,Y) boundary coordinates corresponding to label 'k'
              boundary = sB{1};
              % compute a simple estimate of the object's perimeter
              delta_sq = diff(boundary).^2;    
              perimeter = sum(sqrt(sum(delta_sq,2)));
              factorlist=[factorlist; [multiplyFactor,perimeter,stats_sL.Area]];
        end
    end
%Assign a fake value for the following if judgement    
if isempty(factorlist)
    factorlist=[0,0,0];
end

if length(factorlist(:,1))<2
    panel_r=bwareaopen(panel_seg2+panel_ed5,100);
else
           %Drop the value after peak value because it saturates the image panel
    [~,IndM] = max(factorlist(:,2));
    [~,Indm] = min(factorlist(:,2));    
    if IndM>Indm
       factorlist_n=factorlist(Indm:IndM,:);
    else
       factorlist_n=factorlist(IndM:Indm,:);
    end

    if length(factorlist_n(:,2))>15
        movingbox=10;
    else
        movingbox=ceil(length(factorlist_n(:,2))*2/3);
    end

    if (length(factorlist_n(:,2))< movingbox) || (movingbox<2)
        cutfactor1=factorlist_n(ceil(length(factorlist_n(:,2))/2),1); 
    else
    
        Dvec = movingslope(factorlist_n(:,2),movingbox,1,0.1);

        yy1 = smooth(factorlist_n(:,1),Dvec,0.3,'lowess');
        %Depands on the curve shape
        if IndM>Indm
            slopethreshold=max(yy1);
        else
            slopethreshold=min(yy1);
        end

         [~, thres] = min(abs(Dvec-slopethreshold) );
         if thres ==length(factorlist_n(:,1))
             thresf=thres;
         else
             thresf=thres+1;
         end

        cutfactor1=factorlist_n(thresf,1);
    end 
    
    
    if (length(factorlist(:,2))< 3) 
        cutfactor2=factorlist(ceil(length(factorlist(:,1))/2),1);
    else
        %Use moving slope to find the transition of perimeter of the object
        Dvec2 = movingslope(factorlist(:,3),3,1,0.1);
        [~,locs,~,proms] = findpeaks(Dvec2);

        peaksloc=find(proms>mean(proms));
        yy2 = smooth(factorlist(:,1),factorlist(:,3),0.2,'lowess');

        preloc=locs(peaksloc);
        [~,peakMax]=max(yy2(preloc));

             if preloc(peakMax) ==length(factorlist(:,1))
                 thresf2=preloc(peakMax);
             else
                 thresf2=preloc(peakMax)+1;
             end

        cutfactor2=factorlist(thresf2,1);
    end
    cutfactor=mean([cutfactor1,cutfactor2]);
    panel_r=imerode(imfill(imdilate(bwareaopen(imbinarize(panel_seg2+panel_ed5+panel*cutfactor,0.95),300),strel('disk',2)),'hole'),strel('disk',1));
end
end