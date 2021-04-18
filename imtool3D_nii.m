function tool = imtool3D_nii(filename,viewplane,maskfname, parent, range)
% NIFTI Viewer
%
% INPUT
%   filename            String or cell of string with nifti filenames
%                       First filename is used as spatial reference
%                       Other nifti are resliced to this spatial reference
%   viewplane           String. 'axial', 'sagittal' or 'coronal'
%   maskfname           String. filename of the mask in NIFTI
%   parent              Handle to a figure or panel
%   range               1x2 or cell of 1x2 float numbers (min and max intensity)
%
% OUTPUT
%   tool                imtool3D object. 
%
% EXAMPLE
%   imtool3D_nii fmri.nii.gz
%   imtool3D_nii fmri.nii.gz sagittal
%   imtool3D_nii *fmri*.nii.gz
%   imtool3D_nii({'fmri.nii.gz', 'T1.nii.gz'})
%
% Tanguy DUVAL, INSERM, 2019
% SEE ALSO imtool3D, imtool3D_nii_3planes

if nargin==0, filename = []; end

if ~exist('parent','var'), parent=[]; end
if ~exist('viewplane','var'), viewplane=[]; end
if isempty(viewplane), untouch = true; viewplane=3; else, untouch = false; end
if ~exist('range','var'), range=[]; end
if ~exist('maskfname','var'), maskfname=[]; end

% LOAD IMAGE
if ~isempty(filename)
    if isnumeric(filename)
        filename = nii_tool('init',filename);
        filename.hdr.pixdim = [4 1 1 1 1 1 0 0 0];
        filename.fname = inputname(1);
    end
    if isstruct(filename)
        dat = filename.img;
        hdr = filename.hdr;
        if isfield(filename,'fname')
            list = filename.fname;
        elseif isfield(filename,'label')
            list = filename.label;
        else
            list = {''};
        end
    else
        [dat, hdr, list] = nii_load(filename,untouch);
    end
    disp(list)
else
    load mri % example mri image provided by MATLAB
    dat = D;
    dat = squeeze(dat);
    try
        isLPI = strfind(uigetpref('imtool3D','rot90','Set orientation','How to display the first dimension of the matrix?',{'Vertically (Photo)','Horizontally (Medical)'},'CheckboxState',1,'HelpString','Help','HelpFcn','helpdlg({''If this option is wrongly set, image will be rotated by 90 degree.'', ''Horizontal orientation is usually used in Medical (first dimension is Left-Right)'', '''', ''This preference can be reset in the Settings menu (<about> button).'', '''', ''Orientation can also be changed while viewing an image using the command: tool.setOrient(''''vertical'''')''})'),'hor');
    catch
        isLPI = 1;
    end
    if isLPI
        dat = permute(dat(end:-1:1,:,:),[2 1 3]); % LPI orientation
    end
    list = {'MRI EXAMPLE'};
    if ~isdeployed
        A = which('nii_tool');
        if isempty(A)
            error('Dependency to Xiangrui Li NIFTI tools is missing. http://www.mathworks.com/matlabcentral/fileexchange/42997');
        end
    end
    niiinit = nii_tool('init',dat);
    hdr = niiinit.hdr;
    hdr.file_name = 'MRI EXAMPLE';
    hdr.pixdim = [4 1 1 2.5];
    untouch = false;
end

% LOAD MASK
if iscell(maskfname), maskfname = maskfname{1}; end
if ~isempty(maskfname)
    if isnumeric(maskfname)
        mask = maskfname;
    else
        mask = nii_load({hdr,maskfname},untouch); 
        if iscell(mask),    mask = mask{1}; end
    end
else
    mask = [];
end

% OPEN IMTOOL3D
if isnumeric(viewplane) && length(viewplane)>1
    % Call imtool3D_3planes
    tool3P = imtool3D_3planes(dat,mask,parent,range);
    tool = tool3P.getTool;
else
    tool = imtool3D(dat,[],parent,range,[],mask);
    tool.setviewplane(viewplane);
end

% Set Labels
for ii=1:length(tool)
    tool(ii).setlabel(list);
end

% set voxelsize
for ii=1:length(tool)
    tool(ii).setAspectRatio(hdr.pixdim(2:4));
end

% add Header Info button
Pos = get(tool(1).getHandles.Tools.Save,'Position');
Pos(1) = Pos(1)+2*Pos(3);
Pos(3) = 20;
HeaderButton           =   uicontrol(tool(1).getHandles.Panels.Tools,'Style','pushbutton','String','HDR','Position',Pos,'FontSize',6);
set(HeaderButton,'Callback',@(h,e) openvar2(get(h,'UserData')))
str = evalc('hdr');
set(HeaderButton,'TooltipString',str)
set(HeaderButton,'UserData',hdr)

% add header to save/load Mask
H = tool(1).getHandles;
set(H.Tools.maskSave,'Callback',@(hObject,evnt)saveMask(tool(1),hObject,get(HeaderButton,'UserData')))
set(H.Tools.maskLoad,'Callback',@(hObject,evnt)loadMask(tool(1),hObject,get(HeaderButton,'UserData')))

if length(tool)==1
Pos = get(tool(1).getHandles.Tools.ViewPlane,'Position');
Pos(1) = Pos(1) + 30;
set(tool(1).getHandles.Tools.ViewPlane,'Position',Pos);
end

% add LPI labels
if untouch
    [~,orient] = nii_get_orient(hdr);
else
    orient = {'L' 'P' 'I';
              'R' 'A' 'S'};
end
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String',orient{1,1},'Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String',orient{2,1},'Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String',orient{1,2},'Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String',orient{2,2},'Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);

if length(tool)>1
    annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','P','Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','A','Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','S','Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','I','Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);
    
    annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','L','Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','R','Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','S','Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','I','Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);
end

if exist('tool3P','var'), tool = tool3P; end


function openvar2(hdr)
assignin('base','hdr',hdr);
evalin('base', ['openvar hdr']);