function [barcode, side, flag]=file_name_decoder(matinname)
    vdlist={'dorsal','ventral'};
    if contains(matinname, 'dorsal')
        side=1;
        template0=strsplit(matinname,['_',vdlist{side}]);
        barcode=template0{1};
    elseif contains(matinname, 'ventral')
        side=2;
        template0=strsplit(matinname,['_',vdlist{side}]);
        barcode=template0{1};
    end

    if contains(matinname, '_r_')
        flag='_r';
    elseif contains(matinname, '_m_')
        flag='_m';
    else
        flag='';
    end
end