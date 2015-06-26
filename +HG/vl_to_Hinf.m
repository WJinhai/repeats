function HH = vl_to_Hinf(vl)
H = repmat(eye(3,3),[1 1 size(vl,2)]);
H(3,:,:) = permute(vl,[3 1 2]);
if (size(H,3) == 1)
    HH = mat2cell(H,3,3);
else
    HH = ...
        squeeze(squeeze(mat2cell(H,3,3,ones(1,size(H, ...
                                                   3)))));
end