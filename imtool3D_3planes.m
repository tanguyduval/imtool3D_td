classdef imtool3D_3planes < handle
% imtool3D_3planes(I,mask,parent,range) image viewer with synchronised
% axial, saggital and coronal view
%
% Input:
%   I           3D-5D matrix
%   (mask)        multi-label mask. Only 3D masks are supported (same size as
%                 I in the first 3 dimensions).
%   (parent)      [Figure/Panel handle] container for the viewer
%   (range)       range on figure opening
%
% Example:
%   for ivol = 1:2
%       load(fullfile(toolboxdir('images'),'imdata','BrainMRILabeled','images',sprintf('vol_00%i.mat',ivol)));
%       load(fullfile(toolboxdir('images'),'imdata','BrainMRILabeled','labels',sprintf('label_00%i.mat',ivol)));
%       I{ivol} = vol;
%       mask{ivol} = label;
%   end
%   tool = imtool3D_3planes(I,mask{1}) 
%   tool.setOrient('horizontal'); % medical orientation

    properties (SetAccess = private, GetAccess = private)
        tool  % 1x3 imtool3D objects
        cross % cross structure
        HelpAnnotation
    end
    
    properties
        crossVisible=1; %Show cross?
    end
    
    methods
        
        function tool3P = imtool3D_3planes(varargin) % Constructor (dat,mask,parent,range)
            % parse inputs
            dat=[];
            mask=[];
            parent=[];
            range=[];
            if length(varargin)>0, dat = varargin{1}; end
            if length(varargin)>1, mask = varargin{2}; end
            if length(varargin)>2, parent = varargin{3}; end
            if length(varargin)>3, range = varargin{4}; end
            
            % construct imtool3D objects
            tool = imtool3D(dat,[],parent,range,[],mask);
            resizefactorthree = false;
            if isempty(parent), parent = tool(1).getHandles.fig; resizefactorthree = true; end
            range = tool.getClimits;
            CB_Motion1 = get(gcf,'WindowButtonMotionFcn');
            tool(2) = imtool3D(dat,[],parent,range,[],mask);
            CB_Motion2 = get(gcf,'WindowButtonMotionFcn');
            tool(3) = imtool3D(dat,[],parent,range,[],mask);
            CB_Motion3 = get(gcf,'WindowButtonMotionFcn');
            
            % set orient
            setviewplane(tool(2),'sagittal');
            setviewplane(tool(3),'coronal');
            
            % Set each plane position
            % horizontal config
            tool(1).setPosition([0 0 0.33 1])
            tool(2).setPosition([0.33 0 0.33 1])
            tool(3).setPosition([0.66 0 0.33 1])
            % square config
            % tool(1).setPosition([0 0.5 0.5 0.5])
            % tool(2).setPosition([0.5 0.5 0.5 0.5])
            % tool(3).setPosition([0 0 0.5 0.5])
            
            % Make figure bigger
            if resizefactorthree
                % Make figure 3 times larger
                h = tool(1).getHandles.fig;
                set(h,'Units','Pixels');
                pos = get(tool(1).getHandles.fig,'Position');
                pos(3)=3*pos(3);
                screensize = get(0,'ScreenSize');
                pos(3) = min(pos(3),screensize(3)-100);
                pos(4) = min(pos(4),screensize(4)-100);
                pos(1) = ceil((screensize(3)-pos(3))/2);
                pos(2) = ceil((screensize(4)-pos(4))/2);
                set(h,'Position',pos)
                set(h,'Units','normalized');
            end
            
            
            % Synchronize masks
            for ii=1:3
                addlistener(tool(ii),'maskChanged',@(x,y) syncMasks(tool,ii));
                addlistener(tool(ii),'maskUndone',@(x,y) syncMasks(tool,ii));
                addlistener(tool(ii),'newSlice',@(x,y) tool3P.showcross());
            end
            % tool of first block transfert to all
            controls1 = findobj(tool(1).getHandles.Panels.Tools,'Type','uicontrol');
            controls2 = findobj(tool(2).getHandles.Panels.Tools,'Type','uicontrol');
            controls3 = findobj(tool(3).getHandles.Panels.Tools,'Type','uicontrol');
            controls1 = cat(1,controls1,tool(1).getHandles.Tools.maskSelected',tool(1).getHandles.Tools.maskLock);
            controls2 = cat(1,controls2,tool(2).getHandles.Tools.maskSelected',tool(2).getHandles.Tools.maskLock);
            controls3 = cat(1,controls3,tool(3).getHandles.Tools.maskSelected',tool(3).getHandles.Tools.maskLock);
            controls1 = cat(1,controls1,tool(1).getHandles.Tools.PaintBrush);
            controls2 = cat(1,controls2,tool(2).getHandles.Tools.PaintBrush);
            controls3 = cat(1,controls3,tool(3).getHandles.Tools.PaintBrush);
            controls1 = cat(1,controls1,tool(1).getHandles.Tools.SmartBrush);
            controls2 = cat(1,controls2,tool(2).getHandles.Tools.SmartBrush);
            controls3 = cat(1,controls3,tool(3).getHandles.Tools.SmartBrush);

            for ic = 1:length(controls1)
                if ~isempty(controls1(ic).Callback) && ~isempty(strfind(func2str(controls1(ic).Callback),'saveImage')), continue; end % save Mask only once!
                if ~isempty(controls1(ic).Callback) && ~isempty(strfind(func2str(controls1(ic).Callback),'displayHelp')), continue; end % Display Help only once!
                
                CB = get(controls1(ic),'Callback');
                CB2 = get(controls2(ic),'Callback');
                CB3 = get(controls3(ic),'Callback');
                
                if strcmp(get(controls1(ic),'Style'),'togglebutton')
                    CB2 = @(h,e) cellfun(@(x) feval(x,h,e), {@(h,e) set(controls2(ic),'Value',~get(controls2(ic),'Value')),CB2});
                    CB3 = @(h,e) cellfun(@(x) feval(x,h,e), {@(h,e) set(controls3(ic),'Value',~get(controls3(ic),'Value')),CB3});
                end
                
                if ~isempty(CB)
                    switch nargin(CB)
                        case 1
                            set(controls1(ic),'Callback', @(a) Callback3(CB,CB2,CB3,a))
                        case 2
                            set(controls1(ic),'Callback', @(a,b) Callback3(CB,CB2,CB3,a,b))
                        case 3
                            set(controls1(ic),'Callback', @(a,b,c) Callback3(CB,CB2,CB3,a,b,c))
                    end
                end
            end
            
            % hide buttons with repeated functionalities
            hp = tool(3).getHandles.Panels.ROItools;
            set(tool(1).getHandles.Tools.maskSelected,'Parent',hp)
            set(tool(2).getHandles.Tools.maskSelected,'Visible','off')
            set(tool(3).getHandles.Tools.maskSelected,'Visible','off')
            set(tool(1).getHandles.Tools.maskLock,'Parent',hp)
            set(tool(2).getHandles.Tools.maskLock,'Visible','off')
            set(tool(3).getHandles.Tools.maskLock,'Visible','off')
            set(tool(1).getHandles.Tools.maskStats,'Parent',hp)
            set(tool(2).getHandles.Tools.maskStats,'Visible','off')
            set(tool(3).getHandles.Tools.maskStats,'Visible','off')
            set(tool(1).getHandles.Tools.maskSave,'Parent',hp)
            set(tool(2).getHandles.Tools.maskSave,'Visible','off')
            set(tool(3).getHandles.Tools.maskSave,'Visible','off')
            set(tool(1).getHandles.Tools.maskLoad,'Parent',hp)
            set(tool(2).getHandles.Tools.maskLoad,'Visible','off')
            set(tool(3).getHandles.Tools.maskLoad,'Visible','off')
            set(tool(1).getHandles.Tools.undoMask,'Parent',hp)
            set(tool(2).getHandles.Tools.undoMask,'Visible','off')
            set(tool(3).getHandles.Tools.undoMask,'Visible','off')
            set(tool(1).getHandles.Tools.PaintBrush,'Parent',hp)
            set(tool(2).getHandles.Tools.PaintBrush,'Visible','off')
            set(tool(3).getHandles.Tools.PaintBrush,'Visible','off')
            set(tool(1).getHandles.Tools.SmartBrush,'Parent',hp)
            set(tool(2).getHandles.Tools.SmartBrush,'Visible','off')
            set(tool(3).getHandles.Tools.SmartBrush,'Visible','off')
            set(tool(1).getHandles.Tools.ViewPlane,'Visible','off')
            set(tool(2).getHandles.Panels.Tools,'Visible','off') % hide Panels
            % move buttons from first to third panel for cosmetic reason
            hp = tool(3).getHandles.Panels.Tools;
            set(get(hp,'Children'),'Visible','off')
            set(tool(1).getHandles.Tools.About,'Parent',hp)
            set(tool(1).getHandles.Tools.Help,'Parent',hp)
            buts2move = {'Grid','Mask','Color','montage','Save'};
            buff = 5; xpos = buff;
            for ibut = 1:length(buts2move)
                butpos = get(tool(1).getHandles.Tools.(buts2move{ibut}),'Position');
            set(tool(1).getHandles.Tools.(buts2move{ibut}),'Parent',hp,...
                    'Position',[xpos buff butpos(3) butpos(4)]);
                xpos = xpos + butpos(3) + buff;
            end
            
            % Add crosses
            H = tool(1).getHandles;
            S = tool(1).getImageSize;
            y1 = tool(2).getCurrentSlice;
            x1 = tool(3).getCurrentSlice;
            tool3P.cross.X1 = plot(H.Axes(1),[x1 x1],[0 S(1)],'r-');
            tool3P.cross.Y1 = plot(H.Axes(1),[0 S(2)],[y1 y1],'r-');
            
            H = tool(2).getHandles;
            S = tool(2).getImageSize;
            y2 = tool(3).getCurrentSlice;
            x2 = tool(1).getCurrentSlice;
            tool3P.cross.X2 = plot(H.Axes(1),[x2 x2],[0 S(1)],'r-');
            tool3P.cross.Y2 = plot(H.Axes(1),[0 S(3)],[y2 y2],'r-');
            
            H = tool(3).getHandles;
            S = tool(3).getImageSize;
            y3 = tool(2).getCurrentSlice;
            x3 = tool(1).getCurrentSlice;
            tool3P.cross.X3 = plot(H.Axes(1),[x3 x3],[0 S(1)],'r-');
            tool3P.cross.Y3 = plot(H.Axes(1),[0 S(3)],[y3 y3],'r-');
            
            fun = get(tool(1).getHandles.I(1),'ButtonDownFcn');
            set(tool3P.cross.X1,'ButtonDownFcn',fun);
            set(tool3P.cross.Y1,'ButtonDownFcn',fun);
            set(tool3P.cross.X2,'ButtonDownFcn',fun);
            set(tool3P.cross.Y2,'ButtonDownFcn',fun);
            set(tool3P.cross.X3,'ButtonDownFcn',fun);
            set(tool3P.cross.Y3,'ButtonDownFcn',fun);
            
            tool3P.hidecross();
            
            % add left button options
            hp = tool(2).getHandles.Panels.Tools;
            set(get(hp,'Children'),'Visible','off')
            set(hp,'Visible','on')
            bgc = get(hp,'BackgroundColor');
            for ii=1:3
                ContrastWBDF{ii} = get(tool(ii).getHandles.I(1),'ButtonDownFcn');
            end
            txt = uicontrol(hp,'Style','text','String','Mouse Left Click:','Units','Pixels','Position',[5 0 100 20]);
            lbo = uibuttongroup(hp,'Units','Pixels','Position',[105 5 250 20],...
                'SelectionChangedFcn',@(source,event) lboselection(source,event,tool3P,ContrastWBDF));
            lbo1 = uicontrol(lbo,'Style','radiobutton','String','Adjust Contrast','Position',[5 0 100 20]);
            lbo2 = uicontrol(lbo,'Style','radiobutton','String','Cursor (hold [X] key)','Position',[105 0 150 20]);
            set([txt lbo lbo1 lbo2],'BackgroundColor',bgc,'ForegroundColor',[1 1 1],'FontSize',8);
            
            % add tooltip
            for ii=1:3
                set(tool(ii).getHandles.Slider,'TooltipString',sprintf('Change Slice (use the scroll wheel)\nAlso, use and hold the [X] key to navigate in the volume based on mouse location)'));
            end
                        
            % Add mouse/keyboard interactions
            h = tool(1).getHandles.fig;
            set(h,'WindowScrollWheelFcn',@(src, evnt) scrollWheel(src, evnt, tool) )
            set(h,'Windowkeypressfcn', @(hobject, event) shortcutCallback(hobject, event,tool3P))
            set(h,'WindowButtonMotionFcn',@(src,evnt) Callback3(CB_Motion1,CB_Motion2,CB_Motion3,src,evnt))
            set(h,'WindowKeyReleaseFcn',@(hobject,key) setappdata(hobject,'HoldX',0))
            setappdata(h,'HoldX',0)
            
            addlistener(tool(1).getHandles.Tools.L,'String','PostSet',@(x,y) setWL(tool));
            addlistener(tool(1).getHandles.Tools.U,'String','PostSet',@(x,y) setWL(tool));
            
            tool3P.tool = tool;
            
            % change Help
            fun = @(hObject,evnt) showhelpannotation(tool3P);
            set(tool(1).getHandles.Tools.Help,'Callback',fun)

        end
        
        function tool = getTool(tool3P,plane)
            if ~exist('plane','var'), plane = []; end
            if isempty(plane)
                tool = tool3P.tool;
                return;
            end
            
            switch plane
                case {'axial',1}
                    tool = tool3P.tool(1);
                case {'sagittal',2}
                    tool = tool3P.tool(2);
                case {'coronal',3}
                    tool = tool3P.tool(3);
                otherwise
                    error(sprintf('Input must be one of the following: axial, sagittal, coronal, 1, 2, 3\nExample: tool = tool3P.getTool(''axial'')'));
            end
        end
        
        function H = getHandles(tool3P)
            H = getHandles(tool3P.tool(1));
        end
        
        function setlabel(tool3P,label)
            for ii=1:length(tool3P.tool)
                tool3P.tool(ii).setlabel(label);
            end
        end
        
        function setAspectRatio(tool3P,pixdim)
            for ii=1:length(tool3P.tool)
                tool3P.tool(ii).setAspectRatio(pixdim);
            end
        end
        
        function setOrient(tool3P,orient)
            for ii=1:length(tool3P.tool)
                tool3P.tool(ii).setOrient(orient);
            end
        end

        function setPlaneDisposition(tool3P,M)
            % get limits
            PosC = [inf, inf; -inf -inf];
            for ii=1:3
                Pos  = tool3P.tool(ii).getPosition;
                PosC = [min(PosC(1,1:2),Pos(1:2));max(PosC(2,1:2),Pos(1:2)+Pos(3:4))];
            end
            
            % set position
            [Xm,Ym] = size(M);
            PosC(2,:) = PosC(2,:)./[Ym,Xm];
            for ii=1:3
                [X,Y] = find(M==ii,1);
                if isempty(X), continue; end
                PosCii = [PosC(1,:)+[(Y-1)*PosC(2,1), (Xm-X)*PosC(2,2)], PosC(2,:)];
                tool3P.tool(ii).setPosition(PosCii);
            end
        end
        
        function NvolMax = getNvolMax(tool3P)
            NvolMax = tool3P.tool(1).getNvolMax();
        end
        
        function Nvol = getNvol(tool3P)
            Nvol = tool3P(1).getNvol();
        end

        function setNvol(tool3P,Nvol)
            for ii = [2 3 1]
                tool3P.tool(ii).setNvol(Nvol,ii==1)
                H = tool3P.tool(ii).getHandles();
                Nvol = min(max(1,Nvol),length(tool3P.tool(ii).getImage(1)));
                set(tool3P.cross.(sprintf('X%d',ii)),'Parent',H.Axes(Nvol))
                set(tool3P.cross.(sprintf('Y%d',ii)),'Parent',H.Axes(Nvol))
            end
        end
        
        function showcross(tool3P)            
            
            tool = tool3P.tool;
            S = tool(1).getImageSize;
            set(tool3P.cross.X1,'XData',[tool(3).getCurrentSlice tool(3).getCurrentSlice])
            set(tool3P.cross.X1,'YData',[0 S(1)])
            set(tool3P.cross.Y1,'YData',[tool(2).getCurrentSlice tool(2).getCurrentSlice])
            set(tool3P.cross.Y1,'XData',[0 S(2)])
            set(tool3P.cross.X2,'XData',[tool(1).getCurrentSlice tool(1).getCurrentSlice])
            set(tool3P.cross.X2,'YData',[0 S(2)])
            set(tool3P.cross.Y2,'YData',[tool(3).getCurrentSlice tool(3).getCurrentSlice])
            set(tool3P.cross.Y2,'XData',[0 S(3)])
            set(tool3P.cross.X3,'XData',[tool(1).getCurrentSlice tool(1).getCurrentSlice])
            set(tool3P.cross.X3,'YData',[0 S(1)])
            set(tool3P.cross.Y3,'YData',[tool(2).getCurrentSlice tool(2).getCurrentSlice])
            set(tool3P.cross.Y3,'XData',[0 S(3)])
                
            if tool3P.crossVisible
            	tool3P.hidecross('on');
            else
                tool3P.hidecross('off');
            end
        end
        
        function hidecross(tool3P,type)
            if ~exist('type','var'), type = 'off'; end
            set(tool3P.cross.X1,'Visible',type)
            set(tool3P.cross.Y1,'Visible',type)
            set(tool3P.cross.X2,'Visible',type)
            set(tool3P.cross.Y2,'Visible',type)
            set(tool3P.cross.X3,'Visible',type)
            set(tool3P.cross.Y3,'Visible',type)
        end
        
        function I = getImage(tool3P,varargin)
            I = tool3P.tool(1).getImage(varargin{:});
        end
        
        function setImage(tool3P,I)
            for ii=1:3
                tool3P.tool(ii).setImage(I);
            end
        end
        
        function addImage(tool3P,I)
            Iold = tool3P.tool(1).getImage(1);
            
            for ii=1:3
                tool3P.tool(ii).setImage(cat(2,Iold,{I}))
            end
        end
        
        function setrescaleFactor(tool3P,factor)
            for ii=1:length(tool3P.tool)
                tool3P.tool(ii).rescaleFactor = factor;
            end
        end
    end
    
    methods(Access = private)
        function syncSlices(tool3P)
            persistent timer
            if isempty(timer), timer=tic; end
            if toc(timer)<0.1
                return;
            end
            
            tool = tool3P.getTool();
            currentobj = hittest;
            for ii=1:length(tool)
                if ismember(currentobj,findobj(tool(ii).getHandles.Axes))
                    movetools = setdiff(1:length(tool),ii);
                    [xi,yi,~] = tool(ii).getCurrentMouseLocation;
                    if ii==1
                        tool(movetools(1)).setCurrentSlice(yi);
                        tool(movetools(2)).setCurrentSlice(xi);
                    else
                        tool(movetools(1)).setCurrentSlice(xi);
                        tool(movetools(2)).setCurrentSlice(yi);
                    end
                end
            end
            tool3P.showcross();
            timer=tic;
        end
    end
end

function setWL(tool)
L=str2num(get(tool(1).getHandles.Tools.L,'String'));
U=str2num(get(tool(1).getHandles.Tools.U,'String'));
for ii=2:3
    tool(ii).setDisplayRange([L U]);
end
end

function scrollWheel(src, evnt, tool)
currentobj = hittest;
for ii=1:length(tool)
    try
        if ismember(currentobj,findobj(tool(ii).getHandles.Axes))
            newSlice=tool(ii).getCurrentSlice-evnt.VerticalScrollCount;
            dim = tool(ii).getImageSize(1);
            if newSlice>=1 && newSlice <=dim(3)
                tool(ii).setCurrentSlice(newSlice);
            end
            
        end
    end
end
end

function shortcutCallback(hobject, event,tool3P)
tool = tool3P.getTool();
switch event.Key
    case 'x'
        if getappdata(hobject,'HoldX'), return; end
        setappdata(hobject,'HoldX',1)
        while getappdata(hobject,'HoldX')
            tool3P.syncSlices()
            drawnow;
        end
        hidecross(tool3P)
    case {'z','b','s'}
        tool(1).shortcutCallback(event)
    case 'uparrow'
        setNvol(tool3P,tool(1).getNvol()+1)
    case 'downarrow'
        setNvol(tool3P,tool(1).getNvol()-1)
    otherwise
        fig = tool(1).getHandles.fig;
        oldWBMF = get(fig,'WindowButtonMotionFcn');
        oldPTR  = get(fig,'Pointer');
        for ii=length(tool):-1:1
            set(fig,'WindowButtonMotionFcn',oldWBMF);
            set(fig,'Pointer',oldPTR);
            tool(ii).shortcutCallback(event)
            CB_Motion_mod{ii} = get(fig,'WindowButtonMotionFcn');
        end
        if ~isequal(CB_Motion_mod{1},CB_Motion_mod{2})
            set(fig,'WindowButtonMotionFcn',@(src,evnt) Callback3(CB_Motion_mod{1},CB_Motion_mod{2},CB_Motion_mod{3},src,evnt));
        end
end
end

% change left button mode
function lboselection(source,event,tool3P,ContrastWBDF)
tool = tool3P.getTool();
for ii = 1:3
    switch get(event.NewValue,'String')
        case 'Adjust Contrast'
            set(tool(ii).getHandles.I,'ButtonDownFcn',ContrastWBDF{ii})
            set(tool(ii).getHandles.mask,'ButtonDownFcn',ContrastWBDF{ii})
            tool3P.hidecross();
        case 'Cursor (hold [X] key)'
            set(tool(ii).getHandles.I,'ButtonDownFcn',@(src,evnt) BTF_syncSlices(src,evnt,ContrastWBDF{ii},tool3P))
            set(tool(ii).getHandles.mask,'ButtonDownFcn',@(src,evnt) BTF_syncSlices(src,evnt,ContrastWBDF{ii},tool3P))
    end
end
end

function BTF_syncSlices(src,evnt,ContrastWBDF,tool3P)
tool = tool3P.getTool();
fig = tool(1).getHandles.fig;
WBMF_old = get(fig,'WindowButtonMotionFcn');
WBUF_old = get(fig,'WindowButtonUpFcn');

switch get(fig,'SelectionType')
    case 'normal'
        tool3P.syncSlices();
        fun=@(src,evnt) tool3P.syncSlices();
        fun2=@(src,evnt) set(src,'WindowButtonMotionFcn',WBMF_old,'WindowButtonUpFcn',WBUF_old);
        set(fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
    otherwise
        ContrastWBDF(src,evnt);
end
end

function Callback3(CB1,CB2,CB3,varargin)
CB3(varargin{:})
CB1(varargin{:})
CB2(varargin{:})
end

function syncMasks(tool,ic)
persistent timer
if isempty(timer), timer=tic; end
if toc(timer)<1, return; end
timer=tic;

for ii=setdiff(1:3,ic)
    tool(ii).setMask(tool(ic).getMask(1));
end
end

function showhelpannotation(tool3P)
tool = tool3P.tool;
set(tool(1).getHandles.Tools.Help, 'Enable', 'off');
drawnow;
set(tool(1).getHandles.Tools.Help, 'Enable', 'on');
if get(tool.getHandles.Tools.Help,'Value')
    a = rectangle(tool(1).getHandles.Axes(end),'Position',[0 0 1e12 1e12], ...
        'FaceColor',[0 0 0 .7]);
    a(2) = annotation(tool(1).getHandles.Panels.Image,'textarrow',[0.1 0], [0.9 1],...
        'String','Colorbar & Histogram','Color',[1 1 1]);
    a(3) = annotation(tool(1).getHandles.Panels.Image,'textarrow',[0.5 0.5], [0.8 1],...
        'String','Display Options','Color',[1 1 1]);
    a(4) = annotation(tool(3).getHandles.Panels.Image,'textarrow',[0.9 1], [0.85 .85],...
        'String',sprintf('3D Mask (Multi-label ROI)\n- Select label number\n- Fill with Paint brush\n- Hover label for stats\n- Right-click to delete'),'Color',[1 1 1]);
    a(5) = annotation(tool(1).getHandles.Panels.Image,'textarrow',[0.9 1], [0.25 .25],...
        'String',sprintf('ROI and measurement tools\nfor this slicing plane'),'Color',[1 1 1]);
    a(6) = annotation(tool(3).getHandles.Panels.Image,'textarrow',[0.7 .7], [0.08 0],...
        'String',sprintf('Use arrows to navigate through\nTime (4th) or Volume (5th) dimension'),'Color',[1 1 1],'HorizontalAlignment','left');
    a(7) = annotation(tool(1).getHandles.Panels.Image,'textarrow',[0.1 0], [0.1 0.02],...
        'String',sprintf('RGB mode:\nSwitch between RGB\nor Grayscale mode\nand select active\nchannel (R,G or B)'),'Color',[1 1 1],'HorizontalAlignment','left');
    a(8) = annotation(tool(1).getHandles.Panels.Image,'textarrow',[0.1 0], [0.5 0.5],...
        'String',sprintf('Use scroll wheel to navigate\nthrough slices'),'Color',[1 1 1],'HorizontalAlignment','left');
    a(9) = annotation(tool(2).getHandles.Panels.Image,'textbox',[0.05 0.1 .9 .4],'FitBoxToText','off',...
        'String',sprintf('Left-click for contrast/brightness\n\nRight-click to pan\n\nMiddle-click + up to zoom\n\nDrag&Drop image files HERE\n\nHover cursor over any button\nfor help\n\nSee <about> for Keyboard shortcuts\n\n'),'Color',[1 1 1],'EdgeColor',[1 1 1],'HorizontalAlignment','left');
    a(10) = rectangle(tool(2).getHandles.Axes(end),'Position',[0 0 1e12 1e12], ...
        'FaceColor',[0 0 0 .7]);
    a(11) = rectangle(tool(3).getHandles.Axes(end),'Position',[0 0 1e12 1e12], ...
        'FaceColor',[0 0 0 .7]);
    a(12) = annotation(tool(2).getHandles.Panels.Image,'textarrow',[0.5 0.5], [0.8 1],'HorizontalAlignment','left',...
        'String',sprintf('Three ways to go through slices:\n- use scroll wheel on each slicing plane\n- Position cursor on the image and press the [X] key.\n- Select cursor mode here and click on the image.'),'Color',[1 1 1]);

    tool3P.HelpAnnotation = a;
else
    delete(tool3P.HelpAnnotation)
end
end
