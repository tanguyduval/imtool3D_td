function tool = imtool3D_nii(filename,view)
if nargin<2, view = 'axial'; end
if ~iscell(filename)
    list = sct_tools_ls(filename,1,1,2,1);
else
    list = filename;
end
for iii=1:length(list)
    dat{iii} = load_nii_data(list{iii});
end

switch view
    case 'sagittal'
        dat = cellfun(@(x) permute(x,[2 3 1]),dat,'UniformOutput',false);
    case 'coronal'
        dat = cellfun(@(x) permute(x,[1 3 2]),dat,'UniformOutput',false);
end

tool = imtool3D(dat);

