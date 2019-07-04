function imtool3D_BIDS(BidsFolder)
% PANELS
h = figure('Name','imtool3D BIDS Viewer','MenuBar','none');
ptool = uipanel(h);
ptool.Position = [0,0,1,.8];
plb = uipanel(h);
plb.Position = [0,.8,1 .2];
% VIEWER
tool = imtool3D_nii_3planes([],[],ptool);
% LISTBOX
tsub = uicontrol(plb,'Style','listbox','Units','normalized','Position',[0 0 0.25 1],'Max',30);
tses = uicontrol(plb,'Style','listbox','Units','normalized','Position',[0.25 0 0.25 1],'Max',30);
tmodality = uicontrol(plb,'Style','listbox','Units','normalized','Position',[0.5 0 0.25 1],'Max',30);
tsequence = uicontrol(plb,'Style','listbox','Units','normalized','Position',[0.75 0 0.25 1],'Max',30);
% PARSE BIDS
BIDS = bids.layout(BidsFolder);
tsub.Callback = @(hobj,evnt) filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'sub');
tses.Callback = @(hobj,evnt) filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'ses');
tmodality.Callback = @(hobj,evnt) filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'modality');
tsequence.Callback = @(hobj,evnt) filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'sequence');

% fill subject listbox
tsub.String = bids.query(BIDS,'subjects');
% fill other listbox
filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'sub');

% Add view button
btn_view = uicontrol(plb,'Style','pushbutton','String','view','Units','normalized','Position',[0.9 0 0.1 .3],'BackgroundColor',[0, 0.65, 1]);
btn_view.Callback = @(hobj,evnt) viewCallback(tool, BIDS,tsub,tses,tmodality,tsequence);

function filterDatabase(BIDS,tsub,tses,tmodality,tsequence,listbox)
if strcmp(listbox,'sub')
    tses.String = bids.query(BIDS,'sessions','sub',tsub.String{tsub.Value(1)});
    tses.Value(tses.Value>length(tses.String)) = [];
end

if strcmp(listbox,'sub') || strcmp(listbox,'ses')
    tmodality.String =bids.query(BIDS,'modalities','sub',tsub.String(tsub.Value),'ses',tses.String(tses.Value));
    tmodality.Value(tmodality.Value>length(tmodality.String)) = [];
end

tsequence.String = bids.query(BIDS,'types','sub',tsub.String(tsub.Value),'ses',tses.String(tses.Value),'modality',tmodality.String(tmodality.Value));
tsequence.Value(tsequence.Value>length(tsequence.String)) = [];

function viewCallback(tool, BIDS,tsub,tses,tmodality,tsequence)
dat = bids.query(BIDS,'data','sub',tsub.String(tsub.Value),'ses',tses.String(tses.Value),'modality',tmodality.String(tmodality.Value),'type',tsequence.String(tsequence.Value));
[dat, hdr, list] = nii_load(dat);
for ii=1:length(tool)
    tool(ii).setImage(dat);
    tool(ii).setAspectRatio(hdr.pixdim(2:4));
    tool(ii).setlabel(list);
end