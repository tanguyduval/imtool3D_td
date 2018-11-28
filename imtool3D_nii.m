function tool = imtool3D_nii(filename,viewplane,maskfname)
% imtool3D_nii fmri.nii.gz
% imtool3D_nii fmri.nii.gz sagittal
% imtool3D_nii *fmri*.nii.gz
% imtool3D_nii({'fmri.nii.gz', 'T1.nii.gz'})

if ~iscell(filename)
    list = sct_tools_ls(filename,1,1,2,1);
else
    list = filename;
end
if exist('maskfname','var') && iscell(maskfname)
    maskfname = maskfname{1};
end
if isempty(list)
    
end
for iii=1:length(list)
    if nargin>1 && ~isempty(viewplane)
        [dat{iii}, hdriii] = load_nii_data(list{iii});
        if iii==1
            hdr = hdriii;
        end
        if iii==1 && nargin>2 && ~isempty(maskfname)
            mask  = load_nii_data(maskfname);
        end
    else
        nii = load_untouch_nii(list{iii});
        dat{iii} = nii.img;
        if iii==1
            hdr = nii.hdr;
        end
        if iii==1 && nargin>2 && ~isempty(maskfname)
            mask  = load_untouch_nii(maskfname);
            mask = mask.img;
        end
    end
end

if nargin<2 || isempty(viewplane), viewplane = 'axial'; end
switch viewplane
    case 'sagittal'
        dat = cellfun(@(x) permute(x,[2 3 1]),dat,'UniformOutput',false);
    case 'coronal'
        dat = cellfun(@(x) permute(x,[1 3 2]),dat,'UniformOutput',false);
end

if nargin>2 && ~isempty(maskfname)
tool = imtool3D(dat,[],[],[],[],mask);
else
tool = imtool3D(dat);
end

% set voxelsize

H = getHandles(tool);
set(H.Axes,'DataAspectRatio',hdr.dime.pixdim(2:4))

view(-90,90)
