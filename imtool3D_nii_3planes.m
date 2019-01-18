function tool = imtool3D_nii_3planes(filename,maskname)
if ~exist('maskname','var'), maskname=[]; end
[dat, hdr] = load_nii_datas(filename,0);
if ~isempty(maskname)
    mask = load_nii_datas(maskname,0); mask = mask{1};
else
    mask = [];
end
tool = imtool3D_3planes(dat,mask);
% set voxelsize
for ii=1:3
tool(ii).setAspectRatio(hdr.dime.pixdim(2:4));
end