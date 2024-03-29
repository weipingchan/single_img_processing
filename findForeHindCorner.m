function [conjPt, forehindCorner,beltHpar] =findForeHindCorner(nStrongCornersList,nSectionList,mask,realCen,symAxis,tarCorner,boundingBox,slopeSwitch)
%To find the gap point of fore- and hindwings
%Moving parameter searching is applied in order to find the more accurate targets
beltHparList=[0.2:0.01:0.25];
beltHpars=[];
nsecn=1;
    for nstrongID=1:length(nStrongCornersList)
        nStrongCorners=nStrongCornersList(nstrongID);
        disp(['Try number of interesting points: ',num2str(nStrongCorners)]);
        forehindCorner=zeros(length(nSectionList),2);
        for nsec=1: length(nSectionList)
            nSection=nSectionList(nsec);
            disp(['Section number: ',num2str(nSection)]);
            %%
                    for beltNo=1:length(beltHparList)
                        beltHpar=beltHparList(beltNo);
                        disp('     ');
                        disp(['Try belt height parameter: ',num2str(beltHpar)]);
                        disp('     ');
                        try %Try different beltWpar value
                            beltWpar=0.1;
                            disp(['Try belt width parameter: ',num2str(beltWpar)]);
                            forehindCorner0=find_fore_hind_corner(mask,nStrongCorners,realCen,symAxis,tarCorner,nSection,boundingBox,beltWpar,beltHpar,slopeSwitch);
                            if isempty(forehindCorner0)                        
                            end
                        catch
                            try
                                beltWpar=0.2;
                                disp(['Try belt width parameter: ',num2str(beltWpar)]);
                                forehindCorner0=find_fore_hind_corner(mask,nStrongCorners,realCen,symAxis,tarCorner,nSection,boundingBox,beltWpar,beltHpar,slopeSwitch);
                                if isempty(forehindCorner0)                         
                                end
                            catch
                                try
                                    beltWpar=0.3;
                                    disp(['Try belt width parameter: ',num2str(beltWpar)]);
                                    forehindCorner0=find_fore_hind_corner(mask,nStrongCorners,realCen,symAxis,tarCorner,nSection,boundingBox,beltWpar,beltHpar,slopeSwitch);
                                    if isempty(forehindCorner0)
                                        disp([num2str(beltHpar),' as the belt height parameter DOES NOT work.']);
                                    end
                                catch
                                    forehindCorner0=[]; %If every try doesn't work, assign an empty list to the vector.
                                    disp([num2str(beltHpar),' as the belt height parameter DOES NOT work.']);
                                end
                            end
                        end

                        %%
                        if ~isempty(forehindCorner0)
                            forehindCorner(nsecn,:)=forehindCorner0;
                            beltHpars=[beltHpars, beltHpar];
                            disp('############################################');
                            disp('     ');
                            disp([num2str(beltHpar),' as the belt height parameter WORKS.']);
                            disp(['Parameter [forehindCorner0]: ',num2str(forehindCorner0)]);
                            disp('     ');
                            disp('############################################');
                            nsecn=nsecn+1;
                            break
                        else
                        end
                    end
                    %%
            if nnz(forehindCorner(:,1))>=13
                disp([num2str(nSection),' as n section WORKS.']);
                disp(['Parameter [nSection]: ',num2str(nSection)]);
                break
            else
                disp([num2str(nSection),' as n section does not work.']);
            end
        end
        %%
        if nnz(forehindCorner(:,1))>=13
            disp([num2str(nStrongCorners),' interesting points WORKS.']);
            disp(['Parameter [nStrongCorners]: ',num2str(nStrongCorners)]);
            break
        else
            disp([num2str(nStrongCorners),' interesting points does not work.']);
        end
    end
    
    %output the maximum beltWpar
    beltHpar=max(beltHpars);
        
    %If still cannot find the segment corner, use the horizontal vector to
    %assign one unideal point
    if isempty(forehindCorner)
        %Calculate necessary vectors
        symOrtho=reshape(null(symAxis(:).'),1,[]);
        horVector=symOrtho*size(mask,2);
        
        %Find all edge points
        [specimenB,~]=bwboundaries(mask);
        sppEdgePt=specimenB{1};
        
        tmpSegPtsf=[realCen-horVector ; realCen+horVector];
        [intersectXf,intersectYf]= polyxpoly(tmpSegPtsf(:,1),tmpSegPtsf(:,2),sppEdgePt(:,2),sppEdgePt(:,1));
        seg2f=[intersectXf,intersectYf];
        [~,minLoc]=min(intersectXf);
        conjPt=seg2f(minLoc,:);
    else
        if size(forehindCorner(forehindCorner(:,1)>0,:),1)>1
            conjPt=mode(forehindCorner(forehindCorner(:,1)>0,:));
        else %if there is only one set of points
            conjPt=forehindCorner(forehindCorner(:,1)>0,:);
        end
    end
end