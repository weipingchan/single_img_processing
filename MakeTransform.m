function cout=MakeTransform(operation, c1, c2)
%derive the transformation matrix for two sets of points
switch operation
    case 't' % do transformation
        switch size(c1,2)
            case 2 % transform coordinates
                c1=cat(2,c1,ones(size(c1,1),1));
                cout=c1*c2;
                cout=cout(:,1:2);
            case 4 % transform position
                cv1=cat(2,c1(:,1:2),ones(size(c1,1),1));
                cv2=cat(2,c1(:,1:2)+c1(:,3:4),ones(size(c1,1),1));
                cv1=cv1*c2;
                cv2=cv2*c2;
                cout=cat(2,cv1(:,1:2),cv2(:,1:2)-cv1(:,1:2));
        end
        
    case 'tm' % generate transformation matrix from
        if size(c1)==size(c2)
            switch size(c1,2)
                case 2 % coordinates to coordinates
                    cout=fitgeotrans(c1,c2,'nonreflectivesimilarity');
                    cout=cout.T;
                case 4 % position to position
                    c1=cat(1,c1(:,1:2),c1(:,1:2)+c1(:,3,4));
                    c2=cat(1,c2(:,1:2),c2(:,1:2)+c2(:,3,4));
                    cout=fitgeotrans(c1,c2,'nonreflectivesimilarity');
                    cout=cout.T;
            end
        end
        
end
end