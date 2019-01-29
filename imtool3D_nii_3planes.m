function tool = imtool3D_nii_3planes(filename,maskname)
if nargin==0
    [filename, path] = uigetfile({'*.nii;*.nii.gz','NIFTI Files (*.nii,*.nii.gz)'},'Select an image','MultiSelect', 'on'); 
    if isequal(filename,0), return; end
    filename = fullfile(path,filename); 
end
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
tool(ii).setAspectRatio(hdr.pixdim(2:4));
end
% save Mask
H = tool(1).getHandles;
set(H.Tools.Save,'Callback',@(hObject,evnt)saveMask(tool(1),hdr))


function saveMask(tool,hdr)
H = tool.getHandles;
S = get(H.Tools.SaveOptions,'String');
switch S{get(H.Tools.SaveOptions,'value')}
    case 'Mask'
        Mask = tool.getMask(1);
        if any(Mask(:))        
        [FileName,PathName, ext] = uiputfile({'*.nii.gz';'*.mat'},'Save Mask','Mask');
        FileName = strrep(FileName,'.gz','.nii.gz');
        FileName = strrep(FileName,'.nii.nii','.nii');
        if ext==1 % .nii.gz
            masknii.img = unxform_nii(hdr,Mask);
            masknii.hdr = hdr.original;
            nii_tool('save',masknii,fullfile(PathName,FileName))
        elseif ext==2 % .mat
            Mask = tool.getMask(1);
            save(fullfile(PathName,FileName),'Mask');
        end

        else
            warndlg('Mask empty... Draw a mask using the brush tools on the right')
        end
    otherwise
        tool.saveImage;
end

function outblock = unxform_nii(hdr, inblock)

if isempty(hdr.rot_orient)
    outblock=inblock;
else
    [~, unrotate_orient] = sort(hdr.rot_orient);
    outblock = permute(inblock, unrotate_orient);
end

if ~isempty(hdr.flip_orient)
    flip_orient = hdr.flip_orient(unrotate_orient);
    
    for i = 1:3
        if flip_orient(i)
            outblock = flip(outblock, i);
        end
    end
end
