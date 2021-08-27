function panel_r= regionSegTail2(panel,panel_seg2,panel_ed5,mask4)
%Focus on the rare end of abdomen in order to solve the issue of entangled legs

%Find the optimal value of multiplyFactor
    factorlist=[];
    for multiplyFactor=2:0.1:10
        panel_r=bwareaopen(imbinarize(panel_seg2+panel_ed5+panel*multiplyFactor,0.95),300);
        panel_ff=imfill(imerode(imdilate(panel_r,strel('disk',2)),strel('disk',2)),'hole');
        [sB,~] = bwboundaries(bwareaopen(imclearborder(immultiply(panel_ff,mask4),4),100),'noholes');
        if length(sB)==1
              % obtain (X,Y) boundary coordinates corresponding to label 'k'
              boundary = sB{1};
              % compute a simple estimate of the object's perimeter
              delta_sq = diff(boundary).^2;    
              perimeter = sum(sqrt(sum(delta_sq,2)));
              factorlist=[factorlist; [multiplyFactor,perimeter]];
        end
    end
    
%Assign a fake value if the following judgment is true
if isempty(factorlist)
    factorlist=[0,0,0];
end

if length(factorlist(:,1))<2
    panel_r=bwareaopen(panel_seg2+panel_ed5,100);
else
    if min(factorlist(:,1))<7.5
        %Use moving slop to find the transition of perimeter of the object
        %Drop the value after peak value because it saturates the image panel
        factorlist=factorlist(factorlist(:,1)<8,:);
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

             if length(factorlist_n(:,2))<2
                    panel_r=bwareaopen(panel_seg2+panel_ed5,100);
             else
                    Dvec = movingslope(factorlist_n(:,2),movingbox,1,0.1);

                    yy1 = smooth(factorlist_n(:,1),Dvec,0.3,'lowess');
                    %Depends on the curve shape
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

                    cutfactor=factorlist_n(thresf,1);
                    panel_r=bwareaopen(imbinarize(panel_seg2+panel_ed5+panel*cutfactor,0.95),300);
             end
     else
        cutfactor=min(factorlist(:,1)); 
        panel_r=bwareaopen(imbinarize(panel_seg2+panel_ed5+panel*cutfactor,0.95),300);
    end
end
end