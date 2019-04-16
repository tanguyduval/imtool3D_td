function save_nii_datas(img,hdr,FileName)
% save_nii_datas(img,hdr,FileName) save the matrix img in nifti
% img and hdr must have been loaded with load_nii_datas

nii = unxform_nii(hdr,img);
nii_tool('save',nii,FileName)


function nii = unxform_nii(hdr, img)
if isfield(hdr,'rot_orient') && ~isempty(hdr.rot_orient)
    [~, unrotate_orient] = sort(hdr.rot_orient);
    img = permute(img, [unrotate_orient 4 5 6 7]);
    hdr.pixdim(2:4) = hdr.pixdim(unrotate_orient+1);
    hdr.dim(2:4) = hdr.dim(unrotate_orient+1);
end

if isfield(hdr,'flip_orient') && ~isempty(hdr.flip_orient)
    flip_orient = hdr.flip_orient(unrotate_orient);
    
    for ii = 1:3
        if flip_orient(ii)
            img = flip(img, ii);
        end
    end
end
nii.img = img;
nii.hdr = hdr;
