function nii_save(img,hdr,FileName)
% nii_save(img,hdr,FileName) save the matrix img in nifti
% img and hdr must have been loaded with nii_load

if ~isdeployed
    A = which('nii_tool');
    if isempty(A)
        error('Dependency to Xiangrui Li NIFTI tools is missing. http://www.mathworks.com/matlabcentral/fileexchange/42997');
    end
end

if isempty(hdr)
    nii = nii_tool('init',img);
else
    nii = nii_reset_orient(hdr,img);
end
nii_tool('save',nii,FileName)