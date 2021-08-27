function d = point_to_line(pt, v1, v2)
%derive the vector according to input points in 2D space
    BA = v2-v1;
    CA = pt-v1;
    d=norm(CA-dot(CA,BA)/dot(BA,BA)*BA);      
end