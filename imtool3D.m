
classdef imtool3D < handle
    %This is a image slice viewer with built in scroll, contrast, zoom and
    %ROI tools.
    %
    %   Use this class to place a self-contained image viewing panel within
    %   a GUI (or any figure). 
    %
    %   Similar to imtool but with slice scrolling, mouse controls, and 
    %   drag&drop image files feature. Always open in grayscale (intensity) 
    %   images by default. Use button below the left scrollbar to turn into RGB 
    %   and control color channels. Use the mouse to control how the image is 
    %   displayed. A left click allows window and leveling, a right click is 
    %   for panning, and a middle click is for zooming. Also the scroll wheel 
    %   can be used to scroll through slices.
    %   Drag and drop one or multiple images on the viewer to open them.
    %   Switch between multiple images using the up or down arrows.
    %   Go across time frame (4th dim) using left/right arrows
    %   Open 5D images or multiple 4D images.
    %   
    %----------------------------------------------------------------------
    %Inputs:
    %
    %   I           An m x n x k image array of grayscale values. Default
    %               is a 100x100x3 random noise image.
    %   position    The position of the panel containing the image and all
    %               the tools. Format is [xmin ymin width height]. Default
    %               position is [0 0 1 1] (units = normalized). See the
    %               setPostion and setUnits methods to change the postion
    %               or units.
    %   h           Handle of the parent figure. If no handles is provided,
    %               a new figure will be created.
    %   range       The display range of the image. Format is [min max].
    %               The range can be adjusted with the contrast tool or
    %               with the setRange method. Default is [min(I) max(I)].
    %----------------------------------------------------------------------
    %Output:
    %
    %   tool        The imtool3D object. Use this object as input to the
    %               class methods described below.
    %----------------------------------------------------------------------
    %Constructor Syntax
    %
    %tool = imtool3d() creates an imtool3D panel in the current figure with
    %a random noise image. Returns the imtool3D object.
    %
    %tool = imtool3d(I) sets the image of the imtool3D panel.
    %
    %tool = imtool3D(I,position) sets the position of the imtool3D panel
    %within the current figure. The default units are normalized.
    %
    %tool = imtool3D(I,position,h) puts the imtool3D panel in the figure
    %specified by the handle h.
    %
    %tool = imtool3D(I,position,h,range) sets the display range of the
    %image according to range=[min max].
    %
    %tool = imtool3D(I,position,h,range,tools) lets the scroll wheel
    %properly sync if you are displaying multiple imtool3D objects in the
    %same figure.
    %
    %tool = imtool3D(I,position,h,range,tools,mask) allows you to overlay a
    %semitransparent binary mask on the image data.
    %
    %Note that you can pass an empty matrix for any input variable to have
    %the constructor use default values. ex. tool=imtool3D([],[],h,[]).
    %----------------------------------------------------------------------
    %Examples:
    %
    % ## open a 5D volume
    % A = rand(100,100,30,10,3);
    % imtool3D(A)
    % 
    % 
    % ## open an MRI volume
    % load mri % example mri image provided by MATLAB
    % D = squeeze(D);
    % D = permute(D(end:-1:1,:,:),[2 1 3]); % LPI orientation
    % tool = imtool3D(D);
    % tool.setAspectRatio([1 1 2.5]) % set voxel size to 1mm x 1mm x 2.5mm
    % 
    %
    % ## open in RGB mode 
    % I = imread('board.tif');
    % tool = imtool3D(I);
    % % use RGB mode
    % tool.isRGB = 1;
    % tool.RGBdim = 3;
    % tool.RGBindex = [1 2 3];
    %
    % Note: Use the button bellow left slider ('.' or 'R','G','B') to turn between RGB and grayscale and to select active color channel 
    %
    %
    % ## include in a GUI
    % % Add viewer in a panel in the middle of the GUI
    % GUI = figure('Name','GUI with imtool3D embedded');
    % annotation(GUI,'textbox',[0 .5 1 .5],'String','Create your own GUI here',...
    %                'HorizontalAlignment','center','VerticalAlignment','middle');
    % Position = [0 0 1 .5]; % Bottom. normalized units
    % tool = imtool3D([],Position,GUI)
    % % set image
    % load mri
    % tool.setImage(squeeze(D))
    %
    %
    % ## play a video
    % v = VideoReader('xylophone.mp4');
    % tool = imtool3D(v.read([1 Inf]));
    % tool.isRGB = 1;
    %
    % Note: use left/right arrows to move through image frames  
    %       use shift+right for fast forward (10-by-10 frames)  
    %
    % ## Compare two images
    % A = imread('cameraman.tif');
    % B = imrotate(A,5,'bicubic','crop');
    % tool = imtool3D({A,B})
    %
    % % Option 1: fuse both images in grayscale
    % tool.setNvol(2); % show top image (B)
    % tool.setOpacity(.5) % set opacity of current image (B)
    %
    % % Option 2: fuse both images with false colors
    % tool.setNvol(1);
    % tool.changeColormap('red');
    % tool.setNvol(2);
    % tool.changeColormap('green')
    % tool.setOpacity(.5) % set opacity of current image (B)
    %
    % % Option 3: distribute images in different RGB channels
    % tool.isRGB = 1;
    % tool.RGBdim = 5; % different images are stacked in the 5th dimension
    % tool.RGBindex = [1 2 2]; % red for the 1st image, blue and green for the 2nd
    %
    % % Option 4: alternate both images
    % tool = imtool3D({A,B})
    % tool.grid = 1;
    % for loop=1:10
    %   tool.setNvol(mod(loop,2)+1);
    %   pause(.5)
    % end
    % 
    %
    %----------------------------------------------------------------------
    %Methods:
    %
    %   tool.setImage(I) displays a new image. I can be a cell of multiple 
    %   images or a N-D matrix
    %
    %   I = tool.getImage() returns the image being shown by the tool
    %   I = tool.getImage(1) returns all the images loaded in the tool
    %
    %   setMask(tool,mask) replaces the overlay mask with a new one
    %
    %   tool.rescaleFactor = scale; sets the zoom scale of the image (1 is 100%, 2 is 200%)
    %
    %   tool.isRGB = 0/1 turns between RGB and grayscale.
    %
    %   tool.RGBdim = 3/4/5; select matrix dimension along which RGB planes
    %   are selected
    %
    %   tool.RGBindex = [1x3 Int]; select the planes along RGBdim used for
    %   RGB planes
    %
    %   tool.setAspectRatio([1x3 double]) sets the pixel size in the 3
    %   directions
    %
    %   tool.setviewplane(view) sets the view to 'axial', 'coronal' or 'saggital'
    %
    %   tool.label({label}) sets the labels of all images loaded in the
    %   tool
    %
    %   setAlpha(tool,alpha) sets the transparency of the overlaid mask
    %
    %   alpha = getAlpha(tool) gets the current transparency of the
    %   overlaid mask
    %
    %   setPosition(tool,position) sets the position of tool.
    %
    %   position = getPosition(tool) returns the position of the tool
    %   relative to its parent figure.
    %
    %   setUnits(tool,Units) sets the units of the position of tool. See
    %   uipanel properties for possible unit strings.
    %
    %   units = getUnits(tool) returns the units of used for the position
    %   of the tool.
    %
    %   handles = getHandles(tool) returns a structured variable, handles,
    %   which contains all the handles to the various objects used by
    %   imtool3D.
    %
    %   setDisplayRange(tool,range) sets the display range of the image.
    %   see the 'Clim' property of an Axes object for details.
    %
    %   range=getDisplayRange(tool) returns the current display range of
    %   the image.
    %
    %   setWindowLevel(tool,W,L) sets the display range of the image in
    %   terms of its window (diff(range)) and level (mean(range)).
    %
    %   [W,L] = getWindowLevel(tool) returns the display range of the image
    %   in terms of its window (W) and level (L)
    %
    %   setCurrentSlice(tool,slice) sets the current displayed slice.
    %
    %   slice = getCurrentSlice(tool) returns the currently displayed
    %   slice number.
    %
    %----------------------------------------------------------------------
    %Notes:
    %
    %   Author: Justin Solomon, July, 26 2013 (Latest update April, 16,
    %   2016)
    %
    %   Contact: justin.solomon@duke.edu
    %
    %   Current Version 2.4
    %   Version Notes:
    %                   1.1-added method to get information about the
    %                   currently selected ROI.
    %
    %                   2.0- Completely redesigned the tool. Window and
    %                   leveleing, pan, and zoom are now done with the
    %                   mouse as is standard in most medical image viewers.
    %                   Also the overall astestic design of the tool is
    %                   improved with a new black theme. Added ability to
    %                   change the colormap of the image. Also when
    %                   resizing the figure, the tool behaves better and
    %                   maintains maximum viewing area for the image while
    %                   keeping the tool buttons correctly sized.
    %                   IMPORTANT: Any code that worked with the version
    %                   1.0 may not be compatible with version 2.0.
    %
    %                   2.1- Added crop tool, help button, and button that
    %                   resets the pan and zoom settings to show the entire
    %                   image (useful when you're zoomed in and you just
    %                   want to zoom out quickly. Also made the window and
    %                   level adjustable by draging the lines on the
    %                   histogram
    %
    %                   2.2- Added support for Matlab 2014b. Added ability
    %                   to overlay a semi-transparent binary mask on the
    %                   image data. Useful to visiulize segmented data.
    %
    %                   2.3- Simplified the ROI tools. imtool3D no longer
    %                   relies on MATLAB'S imroi classes, rather I've made
    %                   a set of ROI classes just for imtool3D. This
    %                   greatly simplifies the integration of the ROI
    %                   tools. You can export and delete the ROIs directly
    %                   from their context menus.
    %
    %                   2.3.1- Make sure the figure is centered when
    %                   creating an imtool3D object in a new figure
    %
    %                   2.3.2- Squished a few bugs for older Matlab
    %                   versions. Added method to set and get the
    %                   transparency of the overlaid mask. Refined the
    %                   panning and zooming.
    %
    %                   2.3.3- Fixed a bug with the cropping function
    %
    %                   2.3.4- Added check box to toggle on and off the
    %                   mask overlay. Fixed a bug with the interactive
    %                   window and leveling using the histogram view. Added
    %                   a paint brush to allow user to quickly segment
    %                   something
    %
    %                   2.4- Added methods to get the min, max, and range
    %                   of pixel values. Updated the window and leveling to
    %                   be adaptive to the dynamic range of the image data.
    %                   Should work well if the range is small or large.
    %
    %                   2.4.1- fixed a small bug related to windowing with
    %                   the mouse.
    %
    %                   2.4.2- Added a "smart" paint brush which helps to
    %                   segment borders cleanly.
    %
    %   Created in MATLAB_R2015b
    %
    %   Requires the image processing toolbox
    
    properties (SetAccess = private, GetAccess = private)
        I            %Image data (MxNxKxTxV) matrix of image data
        Nvol         % Current volume
        Ntime        % Current time
        range        % Range of images
        NvolOpts     % [Struct] with .Climits (color limits (Clim) for each Nvol to display images in I (cell))
                     %               .Opacity
                     %               .Cmap (color map per Nvol)
        mask         %Indexed mask that can be overlaid on the image data
        maskHistory  %History of mask  for undo
        maskSelected %Index of the selected mask color
        maskUpdated=1%Recompute stats in mask?
        lockMask     %Lock other mask colors
        maskColor    %Nx3 vector specifying the RGB color of the overlaid mask. Default is red (i.e., [1 0 0]);
        handles      %Structured variable with all the handles
        centers      %list of bin centers for histogram
        alpha        %transparency of the overlaid mask (default is .2)
        Orient       % [0,-90] vertical or horizontal
        aspectRatio = [1 1 1];
        viewplane    = 3; % Direction of the 3rd dimension
        optdlg       % option dialog object
    end
    
    properties
        windowSpeed=2; %Ratio controls how fast the window and level change when you change them with the mouse
        upsample = false;
        upsampleMethod = 'lanczos3'; %Can be any of {'bilinear','bicubic','box','triangle','cubic','lanczos2','lanczos3'}
        Visible = true;              %lets the user hide the imtool3D panel
        grid    = false;
        montage = false;
        brushsize = 5; % default size of the brush
        gamma = 1; % gamma correction
        isRGB        = false; % colored image?
        RGBindex     = [1 2 3]; % R, G, and B bands index in case of color image
        RGBdim       = 3; % [3, 4 or 5] dimension along which RGB planes are extracted
        RGBdecorrstretch = false;
        RGBalignhisto = false;
        registrationMode = false;
        label        = {''};
    end
    
    properties (Dependent = true)
        rescaleFactor %This is the screen pixels/image pixels. used to resample image data when being displayed
    end
    
    events
        newImage
        maskChanged
        maskUndone
        newMousePos
        newSlice
    end
    
    methods
        
        function tool = imtool3D(varargin)  %Constructor
            
            % Parse Inputs
            [I, position, h, range, tools, mask, enableHist] = parseinputs(varargin{:});
            
            % display figure
            try, Orient = uigetpref('imtool3D','rot90','Set orientation','How to display the first dimension of the matrix?',{'Vertically (Photo)','Horizontally (Medical)'},'CheckboxState',1,'HelpString','Help','HelpFcn','helpdlg({''If this option is wrongly set, image will be rotated by 90 degree.'', ''Horizontal orientation is usually used in Medical (first dimension is Left-Right)'', '''', ''This preference can be reset in the Settings menu (<about> button).'', '''', ''Orientation can also be changed while viewing an image using the command: tool.setOrient(''''vertical'''')''})'); 
            catch
            Orient = 'vertical';    
            end
            if isempty(h)
                
                h=figure;
                set(h,'Toolbar','none','Menubar','none','NextPlot','new')
                set(h,'Units','Pixels');
                pos=get(h,'Position');
                Af=pos(3)/pos(4);   %input Ratio of the figure
                if iscell(I)
                    S = [size(I{1},1) size(I{1},2) size(I{1},3)];
                else
                    S = [size(I,1) size(I,2) size(I,3)];
                end
                
                if strfind(lower(Orient),'vertical')
                        AI=S(2)/S(1); %input Ratio of the image
                else
                        AI=S(1)/S(2); %input Ratio of the image
                end
                
                if Af>AI    %Figure is too wide, make it taller to match
                    pos(4)=pos(3)/AI;
                elseif Af<AI    %Figure is too long, make it wider to match
                    pos(3)=AI*pos(4);
                end
                
                %set minimal size
                try
                    %https://undocumentedmatlab.com/articles/working-with-non-standard-dpi-displays
                    ScreenSizeW = java.awt.Toolkit.getDefaultToolkit.getScreenSize.getWidth;
                    ScreenSizeH = java.awt.Toolkit.getDefaultToolkit.getScreenSize.getHeight;
                    screensize=[0 0 ScreenSizeW ScreenSizeH];
                catch
                    screensize = get(0,'ScreenSize');
                end
                pos(3)=min(max(700,pos(3)),screensize(3)*.9);
                pos(4)=min(max(500,pos(4)),screensize(4)*.9);

                %make sure the figure is centered
                pos(1) = ceil((screensize(3)-pos(3))/2);
                pos(2) = ceil((screensize(4)-pos(4))/2);
                set(h,'Position',pos)
                set(h,'Units','normalized');
            end
            
            %find the parent figure handle if the given parent is not a
            %figure
            if ~strcmp(get(h,'type'),'figure')
                fig = getParentFigure(h);
            else
                fig = h;
            end
            
            if ~exist('overview_zoom_in.png','file')
                repopath = fileparts(mfilename('fullpath'));
                addpath(genpath(fullfile(repopath,'src')))
                addpath(genpath(fullfile(repopath,'External')));
            end
            %--------------------------------------------------------------
            tool.lockMask = true;
            tool.handles.fig=fig;
            tool.handles.parent = h;
            tool.maskColor = [  0     0     0;
                                1     0     0;
                                1     1     0;
                                0     1     0;
                                0     1     1;
                                0     0     1;
                                1     0     1];
            tool.maskColor = cat(1,tool.maskColor,colorcube(30));
            tool.maskColor(end-5:end,:) = [];
            tool.maskColor(end+1,:)     = [0.8500    0.3250    0.0980];
            tool.maskSelected = 1;
            tool.maskHistory  = cell(1,10);
            tool.alpha = .2;
            tool.Nvol = 1;
            tool.Ntime = 1;
            
            %Create the panels and slider
            w=30; %Pixel width of the side panels
            h=110; %Pixel height of the histogram panel
            wbutt=20; %Pixel size of the buttons
            tool.handles.Panels.Large   =   uipanel(tool.handles.parent,'Units','normalized','Position',position,'Title','','Tag','imtool3D');
            pos=getpixelposition(tool.handles.parent); pos(1) = pos(1)+position(1)*pos(3); pos(2) = pos(2)+position(2)*pos(4); pos(3) = pos(3)*position(3); pos(4) = pos(4)*position(4);
            tool.handles.Panels.Hist   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[w pos(4)-w-h pos(3)-2*w h],'Title','');
            tool.handles.Panels.Image   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[w w pos(3)-2*w pos(4)-2*w],'Title','');
            tool.handles.Panels.Tools   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 pos(4)-w pos(3) w],'Title','');
            tool.handles.Panels.ROItools    =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[pos(3)-w  w w pos(4)-2*w],'Title','');
            tool.handles.Panels.Slider  =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 w w pos(4)-2*w],'Title','');
            tool.handles.Panels.Info   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 0 pos(3) w],'Title','');
            try
                set(cell2mat(struct2cell(tool.handles.Panels)),'BackgroundColor','k','ForegroundColor','w','HighlightColor','k')
            catch
                objarr=struct2cell(tool.handles.Panels);
                objarr=[objarr{:}];
                set(objarr,'BackgroundColor','k','ForegroundColor','w','HighlightColor','k');
            end
            
            %Create Color Channel Picker below slider for rgb images
            butString = {'.','R','G','B'};
            tool.handles.SliderColor = uicontrol(tool.handles.Panels.Slider,'Style','pushbutton','String',butString{1},'Position',[max(0,w-wbutt) 0 wbutt wbutt],'TooltipString',sprintf('Color channel used by slider:\n.  channels are split\nR  slider control red\nG  slider control green\nB  slider control Blue'));
            fun=@(src,evnt)SelectSliderColor(tool);
            c = uicontextmenu(tool.handles.fig);
            set(tool.handles.SliderColor,'Callback',fun,'UIContextMenu',c)
            tool.handles.uimenu.RGB(1) = uimenu('Parent',c,'Label','switch to RGB/Monochrome','Callback',@(src,evnt) assignval(tool,'isRGB',~tool.isRGB));
            tool.handles.uimenu.RGB(2) = uimenu('Parent',c,'Label','RGB dimension');
            tool.handles.uimenu.RGB(3) = uimenu('Parent',tool.handles.uimenu.RGB(2) ,'Label','slice (3rd)','Callback',@(src,evnt) assignval(tool,'RGBdim',3),'Checked','on');
            tool.handles.uimenu.RGB(4) = uimenu('Parent',tool.handles.uimenu.RGB(2),'Label','time (4th)','Callback',@(src,evnt) assignval(tool,'RGBdim',4));
            tool.handles.uimenu.RGB(5) = uimenu('Parent',tool.handles.uimenu.RGB(2),'Label','volume (5th)','Callback',@(src,evnt) assignval(tool,'RGBdim',5));
            tool.handles.uimenu.RGB(6) = uimenu('Parent',c,'Label','RGB index','Callback',@(src,evnt) dlgsetRGBindex(tool));
            tool.handles.uimenu.RGB(7) = uimenu('Parent',c,'Label','align RGB bands','Callback',@(src,evnt) assignval(tool,'RGBalignhisto',~tool.RGBalignhisto));

            %Create Slider for scrolling through image stack
            tool.handles.Slider         =   uicontrol(tool.handles.Panels.Slider,'Style','Slider','Position',[0 wbutt w pos(4)-2*w-wbutt],'TooltipString','Change Slice (can use scroll wheel also)');
            scrollfun = getpref('imtool3D','ScrollWheelFcn','slice');
            tool.setScrollWheelFun(scrollfun,0,tools);
            
            %Create image axis
            tool.handles.Axes           =   axes('Position',[0 0 1 1],'Parent',tool.handles.Panels.Image,'Color','none');
            tool.handles.I              =   imshow(zeros(3,3),[0 1],'Parent',tool.handles.Axes); hold on;
            set(tool.handles.I,'Clipping','off')
            tool.setOrient(Orient)
            set(tool.handles.Axes,'XLimMode','manual','YLimMode','manual','Clipping','off');
            
            
            %Set up the binary mask viewer
            im = ind2rgb(zeros(3,3),tool.maskColor);
            tool.handles.mask           =   imshow(im);
            set(tool.handles.Axes,'Position',[0 0 1 1],'Color','none','XColor','r','YColor','r','GridLineStyle','--','LineWidth',1.5,'XTickLabel','','YTickLabel','');
            axis off
            grid off
            axis fill
            
            %Set up image info display
            tool.handles.Info=uicontrol(tool.handles.Panels.Info,'Style','text','String','(x,y) val','Units','Normalized','Position',[0 .1 .5 .8],'BackgroundColor','k','ForegroundColor','w','FontSize',12,'HorizontalAlignment','Left');
            fun=@(src,evnt)getImageInfo(src,evnt,tool);
            set(tool.handles.fig,'WindowButtonMotionFcn',fun);
            %tool.handles.LabelText=uicontrol(tool.handles.Panels.Info,'Style','text','Units','Normalized','Position',[.25 .1 .3 .8],'BackgroundColor','k','ForegroundColor','w','FontSize',12,'HorizontalAlignment','Center');
            tool.handles.LabelText=annotation(tool.handles.Panels.Image,'textbox','EdgeColor','none','String','','Position',[0 0 1 0.05],'Color',[1 1 1],'Interpreter','none');
            c = uicontextmenu(tool.handles.fig);
            tool.handles.SliceText=uicontrol(tool.handles.Panels.Info,'Style','text','UIContextMenu',c,'String','','Units','Normalized','Position',[.5 .1 .43 .8],'BackgroundColor','k','ForegroundColor','w','FontSize',12,'HorizontalAlignment','Right', 'TooltipString', 'Use arrows to navigate through time (4th dim) and volumes (5th dim)');
            uimenu('Parent',c,'Label','100%','Callback',@(s,h) assignval(tool, 'rescaleFactor',1))
            uimenu('Parent',c,'Label','10%','Callback',@(s,h) assignval(tool, 'rescaleFactor',.1))
            uimenu('Parent',c,'Label','50%','Callback',@(s,h) assignval(tool, 'rescaleFactor',.5))
            uimenu('Parent',c,'Label','200%','Callback',@(s,h) assignval(tool, 'rescaleFactor',2))
            uimenu('Parent',c,'Label','400%','Callback',@(s,h) assignval(tool, 'rescaleFactor',4))

            % Help Annotation when cursor hover Help Button
            tool.handles.HelpAnnotation = [];
            %Set up mouse button controls
            fun=@(hObject,eventdata) imageButtonDownFunction(hObject,eventdata,tool);
            set(tool.handles.mask,'ButtonDownFcn',fun)
            set(tool.handles.I,'ButtonDownFcn',fun)
            
            %create the tool buttons
            wp=w;
            w=wbutt;
            buff=(wp-w)/2;
            
            % icon directory
            if ~isdeployed
                MATLABdir = fullfile(toolboxdir('matlab'), 'icons');
            else
                if ~ispc
                    MATLABdir = '/opt/mcr/v95/mcr/toolbox/matlab/icons';
                else
                    % TODO:
                    MATLABdir = fullfile(toolboxdir('matlab'), 'icons');
                end
            end

            %Create the histogram plot
            %set(tool.handles.Panels.Image,'Visible','off')
            if enableHist
                tool.handles.HistAxes           =   axes('Position',[.025 .15 .95 .55],'Parent',tool.handles.Panels.Hist);
                hold(tool.handles.HistAxes,'on')
                tool.handles.HistLine=[plot([0 1],[0 1],'-w','LineWidth',1);...
                    plot([0 1],[0 1],'-g','LineWidth',1);...
                    plot([0 1],[0 1],'-b','LineWidth',1)];
                hold(tool.handles.HistAxes,'off');
                set(tool.handles.HistAxes,'Color','none','XColor','w','YColor','w','FontSize',9,'YTick',[])
                axis on
                hold on
                axis fill
                xlim(get(gca,'Xlim'))
                tool.handles.Histrange(1)=plot([0 0 0],[0 .5 1],'.-r');
                tool.handles.Histrange(2)=plot([1 1 1],[0 .5 1],'.-r');
                tool.handles.Histrange(3)=plot([0.5 0.5 0.5],[0 .5 1],'.--r');
                tool.handles.HistImageAxes           =   axes('Position',[.025 .75 .95 .2],'Parent',tool.handles.Panels.Hist);
                set(tool.handles.HistImageAxes,'Units','Pixels'); pos=get(tool.handles.HistImageAxes,'Position'); set(tool.handles.HistImageAxes,'Units','Normalized');
                tool.handles.HistImage=imshow(repmat(linspace(0,1,256),[round(pos(4)) 1]),[0 1]);
                set(tool.handles.HistImageAxes,'XColor','w','YColor','w','XTick',[],'YTick',[])
                axis on;
                box on;
                axis normal
                fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,1);
                set(tool.handles.Histrange(1),'ButtonDownFcn',fun);
                fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,2);
                set(tool.handles.Histrange(2),'ButtonDownFcn',fun);
                fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,3);
                set(tool.handles.Histrange(3),'ButtonDownFcn',fun);
                
                %Create histogram checkbox
                tool.handles.Tools.Hist     =   uicontrol(tool.handles.Panels.Tools,'Style','ToggleButton','String','','Position',[buff buff w w],'TooltipString','Show Colorbar and histogram of current slice');
                MATLABicondir = fullfile(toolboxdir('matlab'), 'icons');
                icon_colorbar = makeToolbarIconFromPNG(fullfile(MATLABicondir,'tool_colorbar.png'));
                set(tool.handles.Tools.Hist,'CData',icon_colorbar)
                fun=@(hObject,evnt) ShowHistogram(hObject,evnt,tool,wp,h);
                set(tool.handles.Tools.Hist,'Callback',fun)
                lp=buff+w;
            else
                lp=buff;
            end
            
            %Set up the resize function
            fun=@(x,y) panelResizeFunction(x,y,tool,wp,h,wbutt);
            set(tool.handles.Panels.Large,'ResizeFcn',fun)
            
            %% TOOLBAR ON TOP
            %Create window and level boxes
            tool.handles.Tools.TL       =   uicontrol(tool.handles.Panels.Tools,'Style','text','String','L','Position',[lp+buff buff w w],'BackgroundColor','k','ForegroundColor','w','TooltipString',sprintf('Intensity Window Lower Bound\nRight Click to set current window to all volumes\n(left click and drag on the image to control window width and level)'));
            tool.handles.Tools.L        =   uicontrol(tool.handles.Panels.Tools,'Style','Edit','String','0','Position',[lp+buff+w buff 2*w w],'TooltipString',sprintf('Intensity Window Lower Bound\nRight Click to set current window to all volumes\n(left click and drag on the image to control window width and level)'),'BackgroundColor',[.2 .2 .2],'ForegroundColor','w');
            tool.handles.Tools.TU       =   uicontrol(tool.handles.Panels.Tools,'Style','text','String','U','Position',[lp+2*buff+3*w buff w w],'BackgroundColor','k','ForegroundColor','w','TooltipString',sprintf('Intensity Window Upper Bound\nRight Click to set current window to all volumes\n(left click and drag on the image to control window width and level)'));
            tool.handles.Tools.U        =   uicontrol(tool.handles.Panels.Tools,'Style','Edit','String','1','Position',[lp+2*buff+4*w buff 2*w w],'TooltipString',sprintf('Intensity Window Upper Bound\nRight Click to set current window to all volumes\n(left click and drag on the image to control window width and level)'),'BackgroundColor',[.2 .2 .2],'ForegroundColor','w');
            tool.handles.Tools.TO       =   uicontrol(tool.handles.Panels.Tools,'Style','text','String','O','Position',[lp+2*buff+6*w buff w w],'BackgroundColor','k','ForegroundColor','w','TooltipString',sprintf('Opacity'));
            tool.handles.Tools.O        =   uicontrol(tool.handles.Panels.Tools,'Style','Edit','String','1','Position',[lp+2*buff+7*w buff w w],'TooltipString',sprintf('Opacity'),'BackgroundColor',[.2 .2 .2],'ForegroundColor','w');
            tool.handles.Tools.SO       =   uicontrol(tool.handles.Panels.Tools,'Style','Slider','Position',[lp+2*buff+8*w buff w/2 w],'TooltipString',sprintf('Opacity'),'Min',0,'Max',1,'Value',1,'SliderStep',[.1 .1]);

            lp=lp+3*buff+8.5*w;
            
            %Creat window and level callbacks
            fun=@(hobject,evnt) WindowLevel_callback(hobject,evnt,tool);
            funSameWL = @(src,evnt) tool.setClimits(repmat({get(tool.handles.Axes(tool.Nvol),'Clim')},[1 length(tool.I)]));
            funAutoRange = @(src,evnt) tool.setClimits(double(range_outlier(tool.I{tool.Nvol}(:),5)));
            c = uicontextmenu(tool.handles.fig);
            set(tool.handles.Tools.L,'Callback',fun,'UIContextMenu',c); % right click set the same range for all volumes
            set(tool.handles.Tools.U,'Callback',fun,'UIContextMenu',c); 
            uimenu('Parent',c,'Label','Auto window level','Callback',funAutoRange)
            uimenu('Parent',c,'Label','Same window level for all volumes','Callback',funSameWL)

            fun=@(hobject,evnt) setOpacity(tool,[], hobject);
            set(tool.handles.Tools.O,'Callback',fun);
            set(tool.handles.Tools.SO,'Callback',fun);
            
            %Create view restore button
            tool.handles.Tools.ViewRestore           =   uicontrol(tool.handles.Panels.Tools,'Style','pushbutton','String','','Position',[lp buff w w],'TooltipString',sprintf('Reset Pan and Zoom\n(Right Click (Ctrl+Click) to Pan and Middle (Shift+Click) Click to zoom)'));
            icon_save = makeToolbarIconFromPNG('overview_zoom_in.png');
            set(tool.handles.Tools.ViewRestore,'CData',icon_save);
            fun=@(hobject,evnt) resetViewCallback(hobject,evnt,tool);
            set(tool.handles.Tools.ViewRestore,'Callback',fun)
            lp=lp+w+2*buff;
            
            %Create grid checkbox
            tool.handles.Tools.Grid           =   uicontrol(tool.handles.Panels.Tools,'Style','checkbox','String','Grid?','Position',[lp buff 2.5*w w],'BackgroundColor','k','ForegroundColor','w');
            fun=@(hObject,evnt) toggleGrid(hObject,evnt,tool);
            set(tool.handles.Tools.Grid,'Callback',fun)
            set(tool.handles.Tools.Grid,'TooltipString','Toggle Gridlines')
            lp=lp+2.5*w;
            
            %Create the mask view switch
            tool.handles.Tools.Mask           =   uicontrol(tool.handles.Panels.Tools,'Style','checkbox','String','Mask?','Position',[lp buff 3*w w],'BackgroundColor','k','ForegroundColor','w','TooltipString','Toggle Binary Mask (spacebar)','Value',1);
            fun=@(hObject,evnt) toggleMask(hObject,evnt,tool);
            set(tool.handles.Tools.Mask,'Callback',fun)
            lp=lp+3*w;
            
            %Create colormap pulldown menu
            mapNames={'Gray','Parula','Jet','HSV','Hot','Cool','red','green','blue','Spring','Summer','Autumn','Winter','Bone','Copper','Pink','Lines','colorcube','flag','prism','white'};
            tool.handles.Tools.Color          =   uicontrol(tool.handles.Panels.Tools,'Style','popupmenu','String',mapNames,'Position',[lp buff 3.5*w w]);
            fun=@(hObject,evnt) changeColormap(tool,[],hObject);
            set(tool.handles.Tools.Color,'Callback',fun)
            set(tool.handles.Tools.Color,'TooltipString','Select a colormap')
            lp=lp+3.5*w+buff;
            
            %Create save button
            tool.handles.Tools.Save           =   uicontrol(tool.handles.Panels.Tools,'Style','pushbutton','String','','Position',[lp buff w w]);
            lp=lp+w+buff;
            icon_save = makeToolbarIconFromPNG([MATLABicondir '/file_save.png']);
            set(tool.handles.Tools.Save,'CData',icon_save);
            fun=@(hObject,evnt) saveImage(tool,hObject);
            set(tool.handles.Tools.Save,'Callback',fun)
            set(tool.handles.Tools.Save,'TooltipString','Save screenshot')
            
            %Create viewplane button
            tool.handles.Tools.ViewPlane    =   uicontrol(tool.handles.Panels.Tools,'Style','popupmenu','String',{'Axial','Sagittal','Coronal'},'Position',[lp buff 3.5*w w],'Value',4-tool.viewplane,'TooltipString','Select slicing plane orientation (for 3D volume)');
            lp=lp+3.5*w+buff;
            fun=@(hObject,evnt) setviewplane(tool,hObject);
            set(tool.handles.Tools.ViewPlane,'Callback',fun)
            
            %Create montage button
            tool.handles.Tools.montage    =   uicontrol(tool.handles.Panels.Tools,'Style','togglebutton','Position',[lp buff w w],'Value',0,'TooltipString','display multiple slices as montage');
            icon_profile = makeToolbarIconFromPNG('icon_montage.png');
            set(tool.handles.Tools.montage ,'Cdata',icon_profile)
            lp=lp+w+buff;
            fun=@(hObject,evnt) toggleMontage(hObject,[],tool); % show 12 slices by default
            set(tool.handles.Tools.montage,'Callback',fun)
            
            %Create Help Button
            pos = get(tool.handles.Panels.Tools,'Position');
            tool.handles.Tools.Help             =   uicontrol(tool.handles.Panels.Tools,'Style','checkbox','String','Help','Position',[pos(3)-5*w buff 3*w-buff w],'BackgroundColor',[0, 0.65, 1],'ForegroundColor',[1 1 1],'FontWeight','bold');
            fun = @(hObject,evnt) showhelpannotation(tool);
            set(tool.handles.Tools.Help,'Callback',fun)
            tool.handles.Tools.About             =   uicontrol(tool.handles.Panels.Tools,'Style','popupmenu','String',{'about','Settings','Dock figure','Export imtool object'},'Position',[pos(3)-2*w-buff buff 4*w w],'TooltipString','Help with imtool3D');
            fun=@(hObject,evnt) displayHelp(hObject,evnt,tool);
            set(tool.handles.Tools.About,'Callback',fun)
            
            %% MASK TOOLBAR ON RIGHT
            %Create mask2poly button
            tool.handles.Tools.mask2poly             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff w w],'TooltipString','Mask2Poly');
            icon_profile = makeToolbarIconFromPNG([MATLABicondir '/linkproduct.png']);
            set(tool.handles.Tools.mask2poly ,'Cdata',icon_profile)
            fun=@(hObject,evnt) mask2polyImageCallback(hObject,evnt,tool);
            set(tool.handles.Tools.mask2poly ,'Callback',fun)
            addlistener(tool,'newSlice',@tool.SliceEvents);
            
            %Create Circle ROI button
            tool.handles.Tools.CircleROI           =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+w w w],'TooltipString','Create Elliptical ROI');
            icon_ellipse = makeToolbarIconFromPNG([MATLABicondir '/tool_shape_ellipse.png']);
            set(tool.handles.Tools.CircleROI,'Cdata',icon_ellipse)
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'ellipse');
            set(tool.handles.Tools.CircleROI,'Callback',fun)
            
            %Create Square ROI button
            tool.handles.Tools.SquareROI           =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+2*w w w],'TooltipString','Create Rectangular ROI');
            icon_rect = makeToolbarIconFromPNG([MATLABicondir '/tool_shape_rectangle.png']);
            set(tool.handles.Tools.SquareROI,'Cdata',icon_rect)
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'rectangle');
            set(tool.handles.Tools.SquareROI,'Callback',fun)
            
            %Create Polygon ROI button
            tool.handles.Tools.PolyROI             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','\_/','Position',[buff buff+3*w w w],'TooltipString','Create Polygon ROI');
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'polygon');
            set(tool.handles.Tools.PolyROI,'Callback',fun)
            
            %Create line profile button
            tool.handles.Tools.Ruler             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+4*w w w],'TooltipString','Measure Distance');
            icon_distance = makeToolbarIconFromPNG([MATLABicondir '/tool_line.png']);
            set(tool.handles.Tools.Ruler,'CData',icon_distance);
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'profile');
            set(tool.handles.Tools.Ruler,'Callback',fun)
            
            %Create smooth3 button
            tool.handles.Tools.smooth3             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+5*w w w],'TooltipString','Smooth Mask in 3D');
            icon_profile = makeToolbarIconFromPNG('icon_smooth3.png');
            set(tool.handles.Tools.smooth3 ,'Cdata',icon_profile)
            fun=@(hObject,evnt) smooth3Callback(hObject,evnt,tool);
            set(tool.handles.Tools.smooth3 ,'Callback',fun)
            
            %Create maskinterp button
            tool.handles.Tools.maskinterp             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+6*w w w],'TooltipString','Interp Mask');
            icon_profile = makeToolbarIconFromPNG('icon_interpmask.png');
            set(tool.handles.Tools.maskinterp ,'Cdata',icon_profile)
            fun=@(hObject,evnt) maskinterpImageCallback(hObject,evnt,tool);
            set(tool.handles.Tools.maskinterp ,'Callback',fun)
            
            %Create active countour button
            tool.handles.Tools.maskactivecontour             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+7*w w w],'TooltipString','Active Contour 3D');
            icon_profile = makeToolbarIconFromPNG('icon_activecontour.png');
            set(tool.handles.Tools.maskactivecontour ,'Cdata',icon_profile)
            fun=@(hObject,evnt) ActiveCountourCallback(hObject,evnt,tool);
            set(tool.handles.Tools.maskactivecontour ,'Callback',fun)
            addlistener(tool,'maskChanged',@tool.maskEvents);
            addlistener(tool,'maskUndone',@tool.maskEvents);
            
            %Paint brush tool button
            tool.handles.Tools.PaintBrush        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','String','','Position',[buff buff+8*w w w],'TooltipString','Paint Brush Tool (B)');
            icon_profile = makeToolbarIconFromPNG([MATLABicondir '/tool_data_brush.png']);
            set(tool.handles.Tools.PaintBrush ,'Cdata',icon_profile)
            fun=@(hObject,evnt) PaintBrushCallback(hObject,evnt,tool,'Normal');
            set(tool.handles.Tools.PaintBrush ,'Callback',fun)
            tool.handles.PaintBrushObject=[];
            
            %Smart Paint brush tool button
            tool.handles.Tools.SmartBrush        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','String','','Position',[buff buff+9*w w w],'TooltipString','Smart Brush Tool (S)');
            icon_profile = makeToolbarIconFromPNG('tool_data_brush_smart.png');
            set(tool.handles.Tools.SmartBrush ,'Cdata',icon_profile)
            fun=@(hObject,evnt) PaintBrushCallback(hObject,evnt,tool,'Smart');
            set(tool.handles.Tools.SmartBrush ,'Callback',fun)
            
            %undo mask button
            tool.handles.Tools.undoMask        = uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+10*w w w],'TooltipString','Undo (Z)');
            icon_profile = load([MATLABicondir filesep 'undo.mat']);
            set(tool.handles.Tools.undoMask ,'Cdata',icon_profile.undoCData)
            fun=@(hObject,evnt) maskUndo(tool);
            set(tool.handles.Tools.undoMask ,'Callback',fun)
            
            %             %Create poly tool button
            %             tool.handles.Tools.mask2poly             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+8*w w w],'TooltipString','mask2poly');
            %             icon_profile = makeToolbarIconFromPNG([MATLABdir '/linkproduct.png']);
            %             set(tool.handles.Tools.mask2poly ,'Cdata',icon_profile)
            %             fun=@(hObject,evnt) CropImageCallback(hObject,evnt,tool);
            %             set(tool.handles.Tools.mask2poly ,'Callback',fun)
            
            pos=get(tool.handles.Panels.ROItools,'Position');
            % mask selection
            for islct=1:5
                tool.handles.Tools.maskSelected(islct)        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','String',num2str(islct),'Position',[buff pos(4)-islct*w w w],'Tag','MaskSelected');
                set(tool.handles.Tools.maskSelected(islct) ,'Cdata',repmat(permute(tool.maskColor(islct+1,:)*tool.alpha+(1-tool.alpha)*[.4 .4 .4],[3 1 2]),w,w))
                set(tool.handles.Tools.maskSelected(islct) ,'Callback',@(hObject,evnt) setmaskSelected(tool,islct))
                c = uicontextmenu(tool.handles.fig);
                set(tool.handles.Tools.maskSelected(islct),'UIContextMenu',c)
                uimenu('Parent',c,'Label','delete','Callback',@(hObject,evnt) maskClean(tool,islct))
                if islct == 5
                    uimenu('Parent',c,'Label','Set value','Callback',@(hObject,evnt) maskCustomValue(tool))
                end
            end
            
            % lock mask
            tool.handles.Tools.maskLock        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','Position',[buff pos(4)-(islct+1)*w w w], 'Value', 1, 'TooltipString', 'Protect other labels (except selected one)');
            icon_profile = makeToolbarIconFromPNG('icon_lock.png');
            set(tool.handles.Tools.maskLock ,'Cdata',icon_profile)
            set(tool.handles.Tools.maskLock ,'Callback',@(hObject,evnt) setlockMask(tool))
            
            % mask statistics
            tool.handles.Tools.maskStats        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','Position',[buff pos(4)-(islct+2)*w w w], 'Value', 1, 'TooltipString', sprintf('Statistics in the different ROI\n(or in the whole volume if mask empty)'));
            icon_hist = makeToolbarIconFromPNG('plottype-histogram.png');
            icon_hist = min(1,max(0,imresize_noIPT(icon_hist,[16 16])));
            set(tool.handles.Tools.maskStats ,'Cdata',icon_hist)
            set(tool.handles.Tools.maskStats ,'Callback',@(hObject,evnt) StatsCallback(hObject,evnt,tool))
            
            % mask save
            tool.handles.Tools.maskSave        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','Position',[buff pos(4)-(islct+3)*w w w], 'Value', 1, 'TooltipString', 'Save mask');
            icon_save = makeToolbarIconFromPNG([MATLABicondir '/file_save.png']);
            icon_save = min(1,max(0,imresize_noIPT(icon_save,[16 16])));
            set(tool.handles.Tools.maskSave ,'Cdata',icon_save)
            fun=@(hObject,evnt) saveMask(tool,hObject);
            set(tool.handles.Tools.maskSave ,'Callback',fun)
            
            % mask load
            tool.handles.Tools.maskLoad        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','Position',[buff pos(4)-(islct+4)*w w w], 'Value', 1, 'TooltipString', 'Load mask');
            icon_load = makeToolbarIconFromPNG([MATLABicondir '/file_open.png']);
            set(tool.handles.Tools.maskLoad ,'Cdata',icon_load)
            fun=@(hObject,evnt) loadMask(tool,hObject);
            set(tool.handles.Tools.maskLoad ,'Callback',fun)
            
            %Set font size of all the tool objects
            try
                set(cell2mat(struct2cell(tool.handles.Tools)),'FontSize',9,'Units','Pixels')
            catch
                objarr=struct2cell(tool.handles.Tools);
                objarr=[objarr{:}];
                set(objarr,'FontSize',9,'Units','Pixels')
            end
            
            set(tool.handles.fig,'NextPlot','new')
            
            %%
            % add shortcuts
            
            set(gcf,'Windowkeypressfcn', @(hobject, event) tool.shortcutCallback(event))
            
            %run the reset view callback
            resetViewCallback([],[],tool)
            
            % Enable/Disable buttons based on mask
            tool.maskEvents;
            
            % set Image
            setImage(tool, varargin{:})
            
            % disable ROI tools if no image processing toolbox
            result = license('test','image_toolbox') && ~isempty(which('poly2mask.m'));
            if result==0
                warning('Image processing toolbox is missing... ROI tools will not work')
                set(findobj(tool.handles.Panels.ROItools,'type','uicontrol'),'visible','off');
                set(tool.handles.Tools.maskLoad,'visible','on');
                set(tool.handles.Tools.maskStats,'visible','on');
                set(tool.handles.Tools.maskSelected,'visible','on');
                set(tool.handles.Tools.montage,'visible','on');
            end
            
            try
                % Add Drag and Drop feature
                %             txt_drop = annotation(tool.handles.Panels.Image,'textbox','Visible','off','EdgeColor','none','FontSize',25,'String','DROP!','Position',[0.5 0.5 0.6 0.1],'FitBoxToText','on','Color',[1 0 0]);
                wrn = warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
                jFrame = get(tool.handles.fig, 'JavaFrame');
                jAxis = jFrame.getAxisComponent();
                dndcontrol.initJava();
                dndobj = dndcontrol(jAxis);
                dndobj.DropFileFcn = @(s, e)onDrop(tool, s, e); %,'DragEnterFcn',@(s,e) setVis(txt_drop,1),'DragExitFcn',@(s,e) setVis(txt_drop,0));
                warning(wrn);
            catch err
                warning(err.message)
            end
        end
        
        function setPosition(tool,position)
            % tool.setPosition(position)
            % ex: tool.setPosition([0 0 1 .5])
            set(tool.handles.Panels.Large,'Position',position)
        end
        
        function position = getPosition(tool)
            % position = tool.getPosition()
            position = get(tool.handles.Panels.Large,'Position');
        end
        
        function setUnits(tool,units)
            % tool.setUnits(units)
            % ex: tool.setUnits('pixels')
            set(tool.handles.Panels.Large,'Units',units)
        end
        
        function units = getUnits(tool)
            % tool.getUnits()
            units = get(tool.handles.Panels.Large,'Units');
        end
        
        function setMask(tool,mask)
            % tool.setMask(mask)
            % ex: S = tool.getImageSize();
            %     mask = ones(S(1:3),'uint8');
            %     tool.setMask(mask)
            
            % 4D mask --> indice along 4th dim
            if ndims(mask)>3, [~,masktmp] = max(uint8(mask(:,:,:,:)),[],4); mask = uint8(masktmp).*uint8(any(mask(:,:,:,:),4)); end
            if ~isempty(mask) && (size(mask,1)~=size(tool.I{1},1) || size(mask,2)~=size(tool.I{1},2) || size(mask,3)~=size(tool.I{1},3))
                warning(sprintf('Mask (%dx%dx%d) is inconsistent with Image (%dx%dx%d)',size(mask,1),size(mask,2),size(mask,3),size(tool.I{1},1),size(tool.I{1},2),size(tool.I{1},3)))
                mask = [];
            end
            if isempty(mask) && (isempty(tool.mask) || size(tool.mask,1)~=size(tool.I{1},1) || size(tool.mask,2)~=size(tool.I{1},2) || size(tool.mask,3)~=size(tool.I{1},3))
                tool.mask=zeros([size(tool.I{1},1) size(tool.I{1},2) size(tool.I{1},3)],'uint8');
            elseif ~isempty(mask)
                if islogical(mask)
                    maskOld = tool.mask;
                    if isempty(maskOld), maskOld = mask; end
                    maskOld(maskOld==tool.maskSelected)=0;
                    if tool.lockMask
                        maskOld(mask & maskOld==0) = tool.maskSelected;
                    else
                        maskOld(mask) = tool.maskSelected;
                    end
                    tool.mask=uint8(maskOld);
                else
                    if max(mask(:))>255
                        tool.mask=uint16(mask);
                    else
                        tool.mask=uint8(mask);
                    end
                end
            end
            
            showSlice(tool)
            notify(tool,'maskChanged')
        end
        
        function Num = getmaskSelected(tool)
            % Ind = tool.getmaskSelected()
            % Get the mask index currently selected
            % (Mask is multi-label uint8 indexed image)
            Num = tool.maskSelected;
        end
        
        function mask = getMask(tool,all)
            % mask = tool.getMask(all);
            % ex: mask = tool.getMask(); get currently selected
            %                            index of the 3D mask
            %     mask = tool.getMask(1); get the entire multi-label mask
            if nargin<2, all=false; end
            if all
                mask = tool.mask;
            else
                mask = tool.mask==tool.maskSelected;
            end
        end
        
        function maskUndo(tool)
            % tool.maskUndo() undo last operation done on the mask
            if ~isempty(tool.maskHistory{end-1})
                tool.mask=tool.maskHistory{end-1};
                showSlice(tool)
                tool.maskHistory = circshift(tool.maskHistory,1,2);
                tool.maskHistory{1}=[];
            end
            if isempty(tool.maskHistory{end-1})
                set(tool.handles.Tools.undoMask, 'Enable', 'off')
            end
            notify(tool,'maskUndone')
        end
        
        function maskClean(tool,islct)
            % tool.maskClean(islct)
            % ex: tool.maskClean(1)  set mask to 0 for index '1'
            if islct == 5
                islct = str2num(get(tool.handles.Tools.maskSelected(5),'String'));
            end
            
            tool.mask(tool.mask==islct)=0;
            showSlice(tool)
            notify(tool,'maskChanged')
        end
        
        function maskCustomValue(tool,islct)
            % tool.maskCustomValue(islct) sets a new label islct
            % ex: tool.maskCustomValue(3)
            if nargin<2
                islct = inputdlg('Mask Value');
                if isempty(islct) || isempty(str2num(islct{1}))
                    return;
                else
                    islct = str2num(islct{1});
                    islct = floor(islct(1));
                end
            end
            togglebutton(tool.handles.Tools.maskSelected(5))
            Cdata = get(tool.handles.Tools.maskSelected(5),'Cdata');
            Color = tool.maskColor(mod(islct+1,end),:)*tool.alpha+(1-tool.alpha)*[.4 .4 .4];
            Cdata(:,:,1) = Color(1);
            Cdata(:,:,2) = Color(2);
            Cdata(:,:,3) = Color(3);
            set(tool.handles.Tools.maskSelected(5),'Cdata',Cdata,'String',num2str(islct));
            tool.maskSelected = islct;
        end
        
        function setmaskSelected(tool,islct)
            if islct == 5
                tool.maskSelected = str2num(get(tool.handles.Tools.maskSelected(5),'String'));
            else
                tool.maskSelected = islct;
            end
            set(tool.handles.Tools.maskSelected(min(5,islct)),'FontWeight','bold','FontSize',12,'ForegroundColor',[1 1 1]);
            set(tool.handles.Tools.maskSelected(setdiff(1:5,islct)),'FontWeight','normal','FontSize',9,'ForegroundColor',[0 0 0]);
        end
               
        function setlockMask(tool)
            % tool.setlockMask() toggle lock on (preventing overwritting of other labels) or off
            tool.lockMask = ~tool.lockMask;
            CData = get(tool.handles.Tools.maskLock,'CData');
            S = size(CData);
            CData = CData.*repmat(permute(([0.4 0.4 0.4]*(~tool.lockMask) + 1./[0.4 0.4 0.4]*tool.lockMask),[3 1 2]),S(1), S(2));
            set(tool.handles.Tools.maskLock,'CData',CData)
        end
        function setMaskColor(tool,maskColor)
            % tool.setMaskColor(maskColor)
            % tool.setMaskColor('y') for yellow mask for all labels
            % tool.setMaskColor(hsv(30))
            
            if ischar(maskColor)
                switch maskColor
                    case 'y'
                        maskColor = [1 1 0];
                    case 'm'
                        maskColor = [1 0 1];
                    case 'c'
                        maskColor = [0 1 1];
                    case 'r'
                        maskColor = [1 0 0];
                    case 'g'
                        maskColor = [0 1 0];
                    case 'b'
                        maskColor = [0 0 1];
                    case 'w'
                        maskColor = [1 1 1];
                    case 'k'
                        maskColor = [0 0 0];
                end
            end
            
            tool.maskColor = maskColor;
            tool.showSlice;
            
        end
        
        function maskColor = getMaskColor(tool)
            % maskColor = tool.getMaskColor()
            maskColor = tool.maskColor;
        end
        
        function setImage(tool, varargin)
            % tool.setImage(I) replace currently loaded images with I (image or cellarray images)
            % tool.setImage(I, [], [], range) set range at the same time
            % tool.setImage(I, [], [], range, tools) sync slider with other
            %                                        tools objects
            % tool.setImage(I, [], [], range, tools, mask) use a mask
            % tool.setImage(I, [], [], range, tools, mask,  enableHist) use
            %                                    Histogram function? Slower...
            [I, position, h, range, tools, mask, enablehist] = parseinputs(varargin{:});
            
            if isempty(I)
                try
                    Orient = getOrient(tool);
                    switch abs(Orient)>45
                        case 1 % medical
                            load mri
                            phantom3 = squeeze(D);
                            phantom3 = permute(phantom3(end:-1:1,:,:),[2 1 3]); % LPI orientation
                            S = size(phantom3);
                            phantom3 = max(0,cat(5,phantom3,88 - phantom3, cast((-(double(phantom3)/88).^2+double(phantom3)/88)*88*4,'like',phantom3)));
                            pixdim = [1 1 2.5];
                            label = {'BRAIN T1w contrast','BRAIN T2w contrast','BRAIN PDw contrast'};
                        case 0 % photo
                            phantom3 = multibandread('paris.lan',[512, 512, 7],'uint8=>uint8',...
                                128,'bil','ieee-le');
                            S = size(phantom3);
                            pixdim = [1 1 1];
                            label = 'Paris multispectral (7 bands) LandSat';
                    end
                catch % mri file not available
                    S = [64 64 64];
                    pixdim = [1/S(1) 1/S(2) 1/S(3)];
                    phantom3 = phantom3d('Modified Shepp-Logan',S(1));
                    phantom3 = min(1,max(0,cat(5,phantom3,1 - phantom3, -phantom3.^2+phantom3)));
                    phantom3 = cast(phantom3*255,'uint8');
                    label = 'Shepp-Logan phantom';
                end
                I=phantom3;
                tool.setAspectRatio(pixdim);
            end
            
            if iscell(I)
                S = [max(cell2mat(cellfun(@(x) size(x,1), I, 'uni', false))),...
                    max(cell2mat(cellfun(@(x) size(x,2), I, 'uni', false))),...
                    max(cell2mat(cellfun(@(x) size(x,3), I, 'uni', false)))];
                for iii = 1:length(I)
                    Siii = [size(I{iii},1) size(I{iii},2) size(I{iii},3)];
                    if ~isequal(S,Siii)
                        Iiii = zeros([S size(I{iii},4)],'like',I{iii});
                        Iiii(1:Siii(1),1:Siii(2),1:Siii(3),:) = I{iii};
                        I{iii} = Iiii;
                    end
                end
            else
                I = mat2cell(I,size(I,1),size(I,2),size(I,3),size(I,4),ones(1,size(I,5)),size(I,6));
            end
            
            if islogical(I{1})
                range = [0 1];
            end
            
            if iscell(range)
                tool.range = range;
                range = range{1};
            else
                for ivol = 1:length(I)
                    if islogical(I{ivol})
                        tool.range{ivol} = [0 1];
                    else
                        tool.range{ivol}=double(range_outlier(I{ivol}(:),5));
                    end
                end
            end
            tool.NvolOpts.Climits = tool.range;
            tool.NvolOpts.Opacity = mat2cell(ones(1,length(I)),1,ones(1,length(I)));
            tool.NvolOpts.Cmap = tool.NvolOpts.Opacity;
            
            if ~isempty(range)
                tool.NvolOpts.Climits{1} = range;
            end
            
            range = tool.NvolOpts.Climits{1};

            tool.Nvol = 1;
            
            tool.I=I;
            
            tool.setMask(mask);
            
            %Update the histogram
            if isfield(tool.handles,'HistAxes')
                Ivol = I{tool.Nvol}(unique(round(linspace(1,numel(I{tool.Nvol}),min(5000,numel(I{tool.Nvol}))))));
                Ivol = Ivol(Ivol>min(Ivol) & Ivol<max(Ivol));
                if isempty(Ivol), Ivol=0; end
                tool.centers=linspace(range(1)-diff(range)*0.05,range(2)+diff(range)*0.05,256*3);
                nelements=hist(Ivol(Ivol~=min(Ivol(:)) & Ivol~=max(Ivol(:))),tool.centers); nelements=nelements./max(nelements);
                set(tool.handles.HistLine(1),'XData',tool.centers,'YData',nelements);
                pos=getpixelposition(tool.handles.HistImageAxes);
                set(tool.handles.HistImage(1),'CData',repmat(tool.centers,[round(pos(4)) 1]),'XData',[min(tool.centers) max(tool.centers)]);
                try
                    xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)])
                catch
                    xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)+.1])
                end
                set(tool.handles.HistImage,'XData',[1 256]);
                axis(tool.handles.HistAxes,'fill')
            end
            %Update the window and level
            setWL(tool,diff(range),mean(range))
            
            %Update the image
            %set(tool.handles.I,'CData',im)
            switch tool.viewplane
                case 1
                    xlim(tool.handles.Axes,[0 size(I{tool.Nvol},3)])
                    ylim(tool.handles.Axes,[0 size(I{tool.Nvol},2)])
                    set(tool.handles.I,'XData',[1 max(2,size(I{tool.Nvol},3))]);
                    set(tool.handles.I,'YData',[1 max(2,size(I{tool.Nvol},2))]);
                case 2
                    xlim(tool.handles.Axes,[0 size(I{tool.Nvol},3)])
                    ylim(tool.handles.Axes,[0 size(I{tool.Nvol},1)])
                    set(tool.handles.I,'XData',[1 max(2,size(I{tool.Nvol},3))]);
                    set(tool.handles.I,'YData',[1 max(2,size(I{tool.Nvol},1))]);
                case 3
                    xlim(tool.handles.Axes,[0 size(I{tool.Nvol},2)])
                    ylim(tool.handles.Axes,[0 size(I{tool.Nvol},1)])
                    set(tool.handles.I,'XData',[1 max(2,size(I{tool.Nvol},2))]);
                    set(tool.handles.I,'YData',[1 max(2,size(I{tool.Nvol},1))]);
            end
            
            %update the mask cdata (in case it has changed size)
            C=zeros(size(I{tool.Nvol},1),size(I{tool.Nvol},2),3,'uint8');
            C(:,:,1)=tool.maskColor(1); C(:,:,2)=tool.maskColor(2); C(:,:,3)=tool.maskColor(3);
            set(tool.handles.mask,'CData',C);
            
            %Update the slider
            setupSlider(tool)
            
            %Update the TIme
            tool.Ntime = min(tool.Ntime,size(I{tool.Nvol},4));
            
            %Update the gridlines
            try, setupGrid(tool); end
            
            % Create missing image objects
            for it = (length(tool.handles.I)+1):length(I)
                tool.handles.Axes(it)           =   axes('Position',[0 0 1 1],...
                                                         'Parent',tool.handles.Panels.Image,...
                                                         'Color','none');
                tool.handles.I(it)              =   imshow(zeros(3,3),range,'Parent',tool.handles.Axes(it));
                set(tool.handles.I(it),'Clipping','off')
                fun=@(hObject,eventdata) imageButtonDownFunction(hObject,eventdata,tool);
                set(tool.handles.I(it),'ButtonDownFcn',fun);
                
                tool.Nvol = it;
                showSlice(tool); % fill image objects
                set(tool.handles.I(it),'Visible','off')
                Grphs = get(tool.handles.Panels.Image,'Children'); % reorder
                set(tool.handles.Panels.Image,'Children',Grphs([2:(end-it+1) 1 (end-it+2):end]));
            end
            setOrient(tool,getOrient(tool),0)
            xlim(tool.handles.Axes,get(tool.handles.Axes(1),'XLim'))
            ylim(tool.handles.Axes,get(tool.handles.Axes(1),'YLim'))

            %Show the first slice
            tool.Nvol = 1;
            showSlice(tool)
            
            %Broadcast that the image has been updated
            notify(tool,'newImage')
            notify(tool,'maskChanged')
            
            % add label
            if exist('label','var')
                tool.label = label;
            end
            
            
        end
        
        function I = getImage(tool,all)
            % I = tool.getImage() get currently viewing image
            % I = tool.getImage(1) get all images loaded in the tool
            if nargin<2, all=false; end
            if all
                I=tool.I;
            else
                I=tool.I{tool.Nvol}(:,:,:,min(end,tool.Ntime));
            end
        end
        
        function Nvol = getNvol(tool)
            % Nvol = tool.getNvol() get the currently displayed image
            % number
            Nvol=tool.Nvol;
        end

        function NvolMax = getNvolMax(tool)
            % NvolMax = tool.getNvolMax() get the number of images loaded
            NvolMax=length(tool.I);
        end

        function setNvol(tool,Nvol,saveClim)
            % tool.setNvol(Nvol) sets the image to display
            
            if ~exist('saveClim','var'), saveClim = true; end % save Clim by default

            % save window and level
            if saveClim
                tool.NvolOpts.Climits{tool.Nvol} = get(tool.handles.Axes(tool.Nvol),'Clim');
                tool.NvolOpts.Opacity{tool.Nvol} = str2num(get(tool.handles.Tools.O,'String'));
                tool.NvolOpts.Cmap{tool.Nvol} = get(tool.handles.Tools.Color,'Value');
            end
            childrenObj = get(tool.handles.Axes(tool.Nvol),'Children');
            % change Volume
            tool.Nvol = max(1,min(Nvol,length(tool.I)));
            % move Mask to current volume
            set(tool.handles.mask,'Parent',tool.handles.Axes(tool.Nvol))
            % move the rest (polygones, lines, grid, etc...)
            set(childrenObj(~strcmp(get(childrenObj,'Type'),'image')),'Parent',tool.handles.Axes(tool.Nvol))
            % load new window and level
            NewRange = tool.NvolOpts.Climits{tool.Nvol};
            W=NewRange(2)-NewRange(1); L=mean(NewRange);
            tool.setWL(W,L);
            NewOpacity = tool.NvolOpts.Opacity{tool.Nvol};
            tool.setOpacity(NewOpacity)
            NewCmap = tool.NvolOpts.Cmap{tool.Nvol};
            set(tool.handles.Tools.Color,'Value',NewCmap)
            changeColormap(tool,[],[],0)
            % apply xlim to histogram
            range = tool.range{tool.Nvol};
            if ~any(isnan(range))
                tool.centers = linspace(range(1)-diff(range)*0.05,range(2)+diff(range)*0.05,256*3);
                if isfield(tool.handles,'HistAxes')
                    try
                        xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)])
                    catch
                        xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)+.1])
                    end
                    set(tool.handles.HistImageAxes,'Units','Pixels'); pos=get(tool.handles.HistImageAxes,'Position'); set(tool.handles.HistImageAxes,'Units','Normalized');
                    set(tool.handles.HistImage,'CData',repmat(tool.centers,[round(pos(4)) 1]),'XData',[0 256]);
                end
            end
            % show volume and hide volumes overlayed on top
            set(tool.handles.I(tool.Nvol),'Visible','on')
            set(tool.handles.I(tool.Nvol+1:length(tool.handles.I)),'Visible','off')

            showSlice(tool);
        end
        
        function setlabel(tool,label)
            % tool.label = label; set the text displayed on top of images
            % tool.label = {'MRI'}; 
            tool.label = label;
        end
        
        function r = getrange(tool)
            % r = tool.getrange() get the max - min of the current image
            r=diff(tool.range{tool.Nvol});
        end
        
        function setClimits(tool,range)
            % tool.setClimits(range) set the range of the display
            % tool.setClimits([0 255])
            if iscell(range)
                tool.setDisplayRange(range{tool.getNvol})
                tool.NvolOpts.Climits = range;
            else
                tool.setDisplayRange(range)
                tool.NvolOpts.Climits{tool.getNvol} = range;
            end
        end
        
        function Climits = getClimits(tool)
            % Climits = tool.getClimits()
            Climits = tool.NvolOpts.Climits;
        end
        
        function Nt = getNtime(tool)
            % Nt = tool.getNtime()
            Nt=tool.Ntime;
        end
        
        function m = max(tool)
            % m = tool.max() max of the current image
            m = max(tool.I{tool.getNvol}(:));
        end
        
        function m = min(tool)
            % m = tool.min() min of the current image
            m = min(tool.I{tool.getNvol}(:));
        end
        
        function handles=getHandles(tool)
            % h=tool.getHandles() get handles to all objects in imtool3D
            % ex: 
            %   set(h.Panels.ROItools,'Visible','off') % hides the ROItools
            handles=tool.handles;
        end
        
        function aspectRatio = getAspectRatio(tool)
            %This gets the aspect ratio of the viewer for cases
            %where you have non-square pixels
            %  aspectRatio = tool.getAspectRatio()
            switch tool.viewplane
                case 1
                    aspectRatio = tool.aspectRatio([2 3 1]);
                case 2
                    aspectRatio = tool.aspectRatio([1 3 2]);
                case 3
                    aspectRatio = tool.aspectRatio([1 2 3]);
            end
        end
        
        function setAspectRatio(tool,psize)
            %This sets the proper aspect ratio of the viewer for cases
            %where you have non-square pixels
            % tool.setAspectRatio(psize)
            % ex: tool.setAspectRatio([1 1 2.5])
            tool.aspectRatio = psize;
            aspectRatio = getAspectRatio(tool);
            set(tool.handles.Axes,'DataAspectRatio',aspectRatio)
        end
        
        function dim = getviewplane(tool)
            dim = tool.viewplane;
        end
        
        function setviewplane(tool,dim)
            if isa(dim,'matlab.ui.control.UIControl') % called from the button
                hObject = dim;
                set(hObject, 'Enable', 'off');
                drawnow;
                set(hObject, 'Enable', 'on');
                dim = get(hObject,'String');
                dim=dim{get(hObject,'Value')};
            end
            
            if ischar(dim)
                switch lower(dim)
                    case 'sagittal'
                        dim=1;
                    case 'coronal'
                        dim=2;
                    otherwise
                        dim=3;
                end
            end
            tool.viewplane = min(3,max(1,round(dim)));
            tool.setOrient(tool.getOrient);
            showSlice(tool,round(size(tool.I{tool.getNvol},dim)/2))
            switch dim
                case 1
                    xlim(tool.handles.Axes,[0 size(tool.I{tool.getNvol},3)])
                    ylim(tool.handles.Axes,[0 size(tool.I{tool.getNvol},2)])
                    set(tool.handles.I,'XData',[1 max(2,size(tool.I{tool.getNvol},3))]);
                    set(tool.handles.I,'YData',[1 max(2,size(tool.I{tool.getNvol},2))]);
                case 2
                    xlim(tool.handles.Axes,[0 size(tool.I{tool.getNvol},3)])
                    ylim(tool.handles.Axes,[0 size(tool.I{tool.getNvol},1)])
                    set(tool.handles.I,'XData',[1 max(2,size(tool.I{tool.getNvol},3))]);
                    set(tool.handles.I,'YData',[1 max(2,size(tool.I{tool.getNvol},1))]);
                case 3
                    xlim(tool.handles.Axes,[0 size(tool.I{tool.getNvol},2)])
                    ylim(tool.handles.Axes,[0 size(tool.I{tool.getNvol},1)])
                    set(tool.handles.I,'XData',[1 max(2,size(tool.I{tool.getNvol},2))]);
                    set(tool.handles.I,'YData',[1 max(2,size(tool.I{tool.getNvol},1))]);
            end
            setupSlider(tool)
            try, setupGrid(tool); end

            
            switch dim
                case 1
                    dim = 'Sagittal';
                case 2
                    dim = 'Coronal';
                case 3
                    dim = 'Axial';
            end
            S = get(tool.handles.Tools.ViewPlane,'String');
            set(tool.handles.Tools.ViewPlane,'Value',find(strcmpi(S,dim)));
            
            % permute aspect ratio
            setAspectRatio(tool,tool.aspectRatio)
            showSlice(tool)
        end
        
        function set.label(tool,label)
            if ischar(label) || isstring(label)
                tool.label{tool.Nvol} = char(label);
            elseif iscellstr(label)
                tool.label = label;
            end
            showSlice(tool)
        end
        
        function setDisplayRange(tool,range)
            W=diff(range);
            L=mean(range);
            setWL(tool,W,L);
            showSlice(tool)
        end
        
        function range=getDisplayRange(tool)
            range=get(tool.handles.Axes(tool.Nvol),'Clim');
        end
        
        function setOpacity(tool,O, hObject)
            % tool.setOpacity(Opac) set opacity of current image
            % ex: tool.setOpacity(0.2)
            if ~exist('hObject','var') || isempty(hObject)
                hObject = tool.handles.Tools.O; 
            else
                % unselect button to prevent activation with spacebar
                set(hObject, 'Enable', 'off');
                drawnow;
                set(hObject, 'Enable', 'on');
            end

            if ~exist('O','var') || isempty(O)
                switch get(hObject,'Style')
                    case 'edit'
                        O=str2num(get(hObject,'String'));
                    case 'slider'
                        O = get(hObject,'Value');
                end
            end
            
            if isempty(O)
                O=1;
            end
            O = min(1,max(0,O));
            
            tool.NvolOpts.Opacity{tool.Nvol} = O;
            set(tool.handles.Tools.O,'String',num2str(O));
            set(tool.handles.Tools.SO,'Value',O);
            set(tool.handles.I(tool.Nvol),'AlphaData',O);
        end

        function setWindowLevel(tool,W,L)
            setWL(tool,W,L);
            showSlice(tool);
        end
        
        function [W,L] = getWindowLevel(tool)
            range=get(tool.handles.Axes(tool.Nvol),'Clim');
            W=diff(range);
            L=mean(range);
        end
        
        function setCurrentSlice(tool,slice)
            % tool.setCurrentSlice(slice)
            % ex: (set slice to 3/4th)
            %     S = tool.getImageSize();
            %     dim = tool.getviewplane;
            %     tool.setCurrentSlice(ceil(S(dim)*3/4))
            showSlice(tool,slice)
        end
        
        function slice = getCurrentSlice(tool)
            % slice = tool.getCurrentSlice()
            slice=round(get(tool.handles.Slider,'value'));
        end
        
        function mask = getCurrentMaskSlice(tool,all)
            % mask = tool.getCurrentMaskSlice(all?)
            if ~exist('all','var'), all=0; end
            slice = getCurrentSlice(tool);
            switch tool.viewplane
                case 1
                    mask=tool.mask(slice,:,:);
                case 2
                    mask=tool.mask(:,slice,:);
                case 3
                    if size(tool.mask,3)==1 % prevet slicing
                        mask=tool.mask;
                    else
                        mask=tool.mask(:,:,slice);
                    end
            end
            
            if ~all
                mask = mask==tool.maskSelected;
            end
            mask = squeeze(mask);
        end
        
        function setCurrentMaskSlice(tool,mask,combine)
            if ~exist('combine','var'), combine=false; end
            slice = getCurrentSlice(tool);
            maskOld = getCurrentMaskSlice(tool,1);
            % combine mask
            if ~combine
                maskOld(maskOld==tool.maskSelected)=0;
            end
            if tool.lockMask
                maskOld(mask & maskOld==0) = tool.maskSelected;
            else
                maskOld(logical(mask)) = tool.maskSelected;
            end
            % update mask
            switch tool.viewplane
                case 1
                    tool.mask(slice,:,:) = maskOld;
                case 2
                    tool.mask(:,slice,:) = maskOld;
                case 3
                    tool.mask(:,:,slice) = maskOld;
            end
            showSlice(tool,slice)
        end
        
        function im = getCurrentImageSlice(tool)
            slice = getCurrentSlice(tool);
            ColorChannel = get(tool.handles.SliderColor,'String');
            

            if ~tool.isRGB
                switch tool.viewplane
                    case 1
                        im = tool.I{tool.Nvol}(slice,:,:,min(end,tool.Ntime),:,:);
                    case 2
                        im = tool.I{tool.Nvol}(:,slice,:,min(end,tool.Ntime),:,:);
                    case 3
                        if size(tool.I{tool.Nvol},3)==1 && size(tool.I{tool.Nvol},4)==1 % no slicing to save memory
                            im = tool.I{tool.Nvol};
                        else
                            im = tool.I{tool.Nvol}(:,:,slice,min(end,tool.Ntime),:,:);
                        end
                end

            else % RGB photo
                switch tool.viewplane
                    case 1
                        order = [2 3 1 4 5 6 7];
                        im = permute(tool.I{tool.Nvol},order);
                    case 2
                        order = [1 3 2 4 5 6 7];
                        im = permute(tool.I{tool.Nvol},order);
                    case 3
                        order = [1 2 3 4 5 6 7];
                        im = tool.I{tool.Nvol};
                end

                switch tool.RGBdim
                    case 3
                        im = im(:,:,min(tool.RGBindex,end),min(end,tool.Ntime));
                    case 4
                        im = im(:,:,slice,min(end,tool.RGBindex));
                    case 5
                        im1 = permute(tool.I{min(end,tool.RGBindex(1))},order);
                        im2 = permute(tool.I{min(end,tool.RGBindex(2))},order);
                        im3 = permute(tool.I{min(end,tool.RGBindex(3))},order);
                        
                        im = cat(6,im1(:,:,slice,min(end,tool.Ntime),:),...
                            im2(:,:,slice,min(end,tool.Ntime),:),...
                            im3(:,:,slice,min(end,tool.Ntime),:));
                end
            end
            im = squeeze(im);
        end
        
        function setAlpha(tool,alpha)
            if alpha <=1 && alpha >=0
                tool.alpha = alpha;
                slice = getCurrentSlice(tool);
                showSlice(tool,slice)
            else
                warning('Alpha value should be between 0 and 1')
            end
        end
        
        function alpha = getAlpha(tool)
            alpha = tool.alpha;
        end
        
        function changeColormap(tool,cmap,hObject,show)
            if ~exist('hObject','var') ||isempty(hObject), hObject = tool.handles.Tools.Color; end
            % unselect button to prevent activation with spacebar
            set(hObject, 'Enable', 'off');
            drawnow;
            set(hObject, 'Enable', 'on');

            maps=get(hObject,'String');
            if ~exist('cmap','var') ||isempty(cmap)
                n=get(hObject,'Value');
                cmap = maps{n};
            else
                n = find(strcmp(cmap,maps));
            end
            set(tool.handles.Tools.Color,'Value',n);
            if ~isnumeric(cmap)
            switch cmap
                case 'red'
                    cmap = [linspace(0,1,256)' zeros(256,2)];
                case 'green'
                    cmap = [zeros(256,1) linspace(0,1,256)' zeros(256,1)];
                case 'blue'
                    cmap = [zeros(256,2) linspace(0,1,256)'];
            end
            end
            h = tool.getHandles;
            colormap(h.Axes(tool.Nvol),cmap)
            if isfield(h,'HistImageAxes')
                colormap(h.HistImageAxes,cmap)
            end
            tool.NvolOpts.Cmap{tool.Nvol} = n;
            if ~exist('show','var') || show
                tool.showSlice();
            end
        end

        function Orient = getOrient(tool)
            Orient = tool.Orient;
        end
        
        function setOrient(tool,Orientstr,savepref)
            if ~exist('savepref','var')
                savepref = 0;
            end
            for iax = 1:length(tool.handles.Axes)
                if isnumeric(Orientstr)
                    Orient = Orientstr;
                    if abs(Orient)>45
                        Orientstr = 'horizontal';
                    else
                        if isempty(Orient), Orient=0; end
                        if tool.viewplane ~= 3
                            Orient = Orient-90;
                        end
                        Orientstr = 'vertical';
                    end
                elseif strfind(lower(Orientstr),'horizontal')
                    Orient = -90;
                    Orientstr = 'horizontal';
                elseif strfind(lower(Orientstr),'vertical')
                    if tool.viewplane == 3
                        Orient = 0;
                    else
                        Orient = -90;
                    end
                    Orientstr = 'vertical';
                else
                    Orient = get(tool.handles.Axes(1),'view');
                    Orient = Orient(1);
                end
                view(tool.handles.Axes(iax),Orient,90);
            end
            if savepref
                setpref('imtool3D','rot90',Orientstr)
            end
            switch Orientstr
                case 'horizontal'
                    tool.Orient = -90;
                case 'vertical'
                    tool.Orient = 0;
            end
        end
        
        function setScrollWheelFun(tool,scrollfun,savepref,tools)
            if ~exist('tools','var'), tools = []; end
            switch lower(scrollfun)
                case 'zoom'
                    fun=@(scr,evnt) adjustZoomScroll(evnt,tool);
                case 'slice'
                    fun=@(scr,evnt)multipleScrollWheel(scr,evnt,[tool tools]);
            end
            set(tool.handles.fig,'WindowScrollWheelFcn',fun);
            if savepref
                setpref('imtool3D','ScrollWheelFcn',scrollfun)
            end
        end
        
        function S = getImageSize(tool,withVP)
            if ~exist('withVP','var'), withVP = true; end
            
            S=size(tool.I{tool.Nvol});
            if length(S)<3, S(3) = 1; end
            if withVP
                switch tool.viewplane
                    case 1
                        S = S([2 3 1]);
                    case 2
                        S = S([1 3 2]);
                end
            end
        end
        
        function addImageValues(tool,im,lims)
            %this function adds im to the image at location specified by
            %lims . Lims defines the box in which the new data, im, will be
            %inserted. lims = [ymin ymax; xmin xmax; zmin zmax];
            
            tool.I{tool.Nvol}(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2),min(end,tool.Ntime))=...
                tool.I{tool.Nvol}(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2),min(end,tool.Ntime))+im;
            showSlice(tool);
        end
        
        function replaceImageValues(tool,im,lims)
            %this function replaces pixel values with im at location specified by
            %lims . Lims defines the box in which the new data, im, will be
            %inserted. lims = [ymin ymax; xmin xmax; zmin zmax];
            tool.I{tool.Nvol}(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2),min(end,tool.Ntime))=im;
            showSlice(tool);
        end
        
        function im = getImageValues(tool,lims)
            im = tool.I{tool.Nvol}(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2));
        end
        
        function im = getImageSlices(tool,zmin,zmax)
            S = getImageSize(tool);
            switch tool.viewplane
                case 1
                    lims = [zmin zmax; 1 S(2); 1 S(3)];
                case 2
                    lims = [1 S(1); zmin zmax; 1 S(3)];
                case 3
                    lims = [1 S(1); 1 S(2); zmin zmax];
            end
            im = getImageValues(tool,lims);
        end
        
        function createBrushObject(tool,style)
            switch style
                case 'Normal'
                    tool.handles.PaintBrushObject=maskPaintBrush(tool);
                case 'Smart'
                    tool.handles.PaintBrushObject=maskSmartBrush(tool);
            end
        end
        
        function removeBrushObject(tool)
            try
                delete(tool.handles.PaintBrushObject)
            end
            tool.handles.PaintBrushObject=[];
        end
        
        function delete(tool)
            tool.I = [];
            try
                delete(tool.handles.Panels.Large)
                set(tool.handles.fig,'WindowButtonMotionFcn',[]);
                H = tool.optdlg.getHandles();
                delete(H.fig)
            end
        end
        
        function [xi,yi,zi]=getCurrentMouseLocation(tool)
            pos=round(get(tool.handles.Axes(tool.Nvol),'CurrentPoint'));
            pos=pos(1,1:2); xi=max(1,pos(1)); yi=max(1,pos(2)); zi=getCurrentSlice(tool);
        end
        
        function rescaleFactor = get.rescaleFactor(tool)
            %Get aspect ratio of image as currently being displayed
            w = diff(get(tool.handles.Axes(tool.Nvol),'Xlim'))+1;
            h = diff(get(tool.handles.Axes(tool.Nvol),'Ylim'))+1;
            Ai  = w/h;
            
            %Get aspect ratio of parent axes
            pos = getPixelPosition(tool.handles.Axes(tool.Nvol));
            Aa = pos(3)/pos(4);
            
            %get the rescale factor
            if Aa>=Ai
                rescaleFactor = pos(4)/h;
            else
                rescaleFactor = pos(3)/w;
            end
            
            
        end
        
        function set.rescaleFactor(tool, value)
            %Get aspect ratio of image as currently being displayed
            w = diff(get(tool.handles.Axes(tool.Nvol),'Xlim'))+1;
            h = diff(get(tool.handles.Axes(tool.Nvol),'Ylim'))+1;
            Ai  = w/h;
            
            %Get aspect ratio of parent axes
            pos = getPixelPosition(tool.handles.Axes(tool.Nvol));
            Aa = pos(3)/pos(4);
            
            %get the rescale factor
            if Aa>=Ai
                h = pos(4)/value;
                w = Ai*h;
            else
                w = pos(3)/value;
                h = w/Ai;
            end
            
            mid = mean(get(tool.handles.Axes(tool.Nvol),'Xlim'));
            if isfinite(mid+w+h)
                if tool.registrationMode
                    CurrentAxes = tool.handles.Axes(tool.Nvol);
                else
                    CurrentAxes = tool.handles.Axes;
                end
                set(CurrentAxes,'Xlim',[mid-(w-1)/2 mid+(w-1)/2])
                mid = mean(get(tool.handles.Axes(tool.Nvol),'Ylim'));
                set(CurrentAxes,'Ylim',[mid-(h-1)/2 mid+(h-1)/2])
            end
            
            % update Text (bottom Right)
            n = tool.getCurrentSlice;
            set(tool.handles.SliceText,'String',['Vol: ' num2str(tool.Nvol) '/' num2str(length(tool.I)) '    Time: ' num2str(tool.Ntime) '/' num2str(size(tool.I{tool.Nvol},4)) '    Slice: ' num2str(n) '/' num2str(size(tool.I{tool.Nvol},tool.viewplane)) '    ' sprintf('%.1f%%',tool.rescaleFactor*100)])
        end
        
        function set.upsample(tool,upsample)
            tool.upsample = logical(upsample);
            showSlice(tool);
        end
        
        function set.upsampleMethod(tool,upsampleMethod)
            switch upsampleMethod
                case {'bilinear','bicubic','box','triangle','cubic','lanczos2','lanczos3'}
                    tool.upsampleMethod = upsampleMethod;
                otherwise
                    warning(['Upsample method ''' upsampleMethod ''' not valid, using bilinear']);
                    tool.upsampleMethod = 'bilinear';
            end
            showSlice(tool);
        end
        
        function set.gamma(tool,gamma)
            tool.gamma = gamma;
            showSlice(tool);
        end
        
        function set.RGBdecorrstretch(tool,decorr)
            tool.RGBdecorrstretch = logical(decorr);
            showSlice(tool);
        end
        
        function set.RGBalignhisto(tool,RGBalignhisto)
            tool.RGBalignhisto = logical(RGBalignhisto);
            if tool.RGBalignhisto
                setWL(tool,256,128)
            else
                CL = tool.range{tool.Nvol};
                setWL(tool,diff(CL),mean(CL))
            end
            showSlice(tool);
            onoff = {'off','on'};
            H = tool.getHandles;            
            set(H.uimenu.RGB(7),'Checked',onoff{1+tool.RGBalignhisto});
        end
        
        function set.RGBindex(tool,index)
            tool.RGBindex = index;
            tool.showSlice();
        end
        
        function dlgsetRGBindex(tool)
            set(tool.handles.fig,'Units','Pixels')
            CallerPos = get(tool.handles.fig, 'Position');
            hrgbindex = figure(1.8392e9);
            set(hrgbindex,'Position',[max(100,CallerPos(1)) max(100,CallerPos(2)) 300 75],'Toolbar','none','Menubar','none','NextPlot','new',...
                'Name','Choose RGB channels','NumberTitle','off');
            dlgrgbindex = optiondlg({'RGB index',tool.RGBindex,'apply','pushbutton'},hrgbindex);
            dlgh = dlgrgbindex.getHandles;
            dlgrgbindex.setCallback('apply', @(src,evnt) cellfun(@(fun) feval(fun,src) , {@(src) assignval(tool,'RGBindex',round(get(dlgh.buttons.RGBindex,'Data'))), @(src) set(src,'Value',0)}))
        end

        function set.RGBdim(tool,dim)
            if ~ismember(dim,[3 4 5 6])
                error('RGB is handled only along the 3rd, 4th, 5th or 6th dimension')
            end
            tool.RGBdim = dim;
            showSlice(tool);
            onoff = {'off','on'};
            H = tool.getHandles;
            set(H.uimenu.RGB(3),'Checked',onoff{double(dim==3)+1});
            set(H.uimenu.RGB(4),'Checked',onoff{double(dim==4)+1});
            set(H.uimenu.RGB(5),'Checked',onoff{double(dim==5)+1});
        end
        
        function set.isRGB(tool,iscolor)
            tool.isRGB = logical(iscolor);
            if iscolor
                SelectSliderColor(tool,'R');
            else
                SelectSliderColor(tool,'.')
            end
            onoff = {'off','on'};
            H = tool.getHandles;
            set(H.uimenu.RGB(1),'Checked',onoff{iscolor+1});
        end
        
        function set.Visible(tool,Visible)
            if Visible
                set(tool.handles.Panels.Large,'Visible','on');
            else
                set(tool.handles.Panels.Large,'Visible','off');
            end
        end
        
        function set.grid(tool,Visible)
            % set.grid(tool,Visible)
            set(tool.handles.Tools.Grid,'Value',logical(Visible))
            if logical(Visible)
                if ~ishandle(tool.handles.grid), setupGrid(tool); end
                set(tool.handles.grid,'Visible','on')
            else
                set(tool.handles.grid,'Visible','off')
            end
            tool.grid = logical(Visible);
        end
        
        function set.montage(tool,montagemode)
            % set.montage(tool,montagemode)
            % set.montage(tool,True)
            tool.montage = logical(montagemode);
            set(tool.handles.Tools.montage,'Value',tool.montage)
            showSlice(tool,12+(1-get(tool.handles.Tools.montage,'Value'))*(round(size(tool.I{tool.Nvol},tool.viewplane)/2)-12)); % show 12 slices by default
        end
        
        function shortcutCallback(tool,evnt)
            switch evnt.Key
                case 'space'
                    togglebutton(tool.handles.Tools.Mask)
                case 'b'
                    togglebutton(tool.handles.Tools.PaintBrush)
                case 's'
                    togglebutton(tool.handles.Tools.SmartBrush)
                case 'z'
                    maskUndo(tool);
                case 'l'
                    setlockMask(tool)
                case 'leftarrow'
                    if isprop(evnt,'Modifier') && ~isempty(evnt.Modifier) && any(strcmp(evnt.Modifier,'shift'))
                        tool.Ntime = max(tool.Ntime-10,1);
                    else
                        tool.Ntime = max(tool.Ntime-1,1);
                    end
                    % Change color channel in RGB mode
                    if tool.RGBdim == 4
                        ColorChannel = get(tool.handles.SliderColor,'String');
                        switch ColorChannel
                            case 'R'
                                tool.RGBindex(1) = tool.Ntime;
                            case 'G'
                                tool.RGBindex(2) = tool.Ntime;
                            case 'B'
                                tool.RGBindex(3) = tool.Ntime;
                        end
                    end
                    showSlice(tool);
                case 'rightarrow'
                    if isprop(evnt,'Modifier') && ~isempty(evnt.Modifier) && any(strcmp(evnt.Modifier,'shift'))
                        tool.Ntime = min(tool.Ntime+10,size(tool.I{tool.Nvol},4));
                    else
                        tool.Ntime = min(tool.Ntime+1,size(tool.I{tool.Nvol},4));
                    end
                    % Change color channel in RGB mode
                    if tool.RGBdim == 4
                        ColorChannel = get(tool.handles.SliderColor,'String');
                        switch ColorChannel
                            case 'R'
                                tool.RGBindex(1) = tool.Ntime;
                            case 'G'
                                tool.RGBindex(2) = tool.Ntime;
                            case 'B'
                                tool.RGBindex(3) = tool.Ntime;
                        end
                    end
                    showSlice(tool);
                case 'uparrow'
                    setNvol(tool,tool.Nvol+1)
                case 'downarrow'
                    setNvol(tool,tool.Nvol-1)
                otherwise
                    switch evnt.Character
                        case '1'
                            togglebutton(tool.handles.Tools.maskSelected(1))
                        case '2'
                            togglebutton(tool.handles.Tools.maskSelected(2))
                        case '3'
                            togglebutton(tool.handles.Tools.maskSelected(3))
                        case '4'
                            togglebutton(tool.handles.Tools.maskSelected(4))
                        otherwise
                            islct = str2num(evnt.Character);
                            if ~isempty(islct)
                                maskCustomValue(tool,islct);
                            end
                    end
            end
            %      disp(evnt.Key)
        end
        
        function saveImage(tool,hObject, Filename)
            persistent imformats
            if exist('hObject','var') && ~isempty(hObject) && any(ishandle(hObject))
                % unselect button to prevent activation with spacebar
                set(hObject, 'Enable', 'off');
                drawnow;
                set(hObject, 'Enable', 'on');
            end
            
            h = tool.getHandles;
            cmap = colormap(h.Tools.Color.String{h.Tools.Color.Value});
            if isempty(imformats)
                imformats = {'*.tif';'*.jpg';'*.bmp';'*.gif';'*.hdf'; ...
                    '*.jp2';'*.pbm';'*.pcx';'*.pgm'; ...
                    '*.pnm';'*.ppm';'*.ras';'*.xwd'};
                imformats = cat(2,imformats,cellfun(@(X) sprintf('Current slice (%s)',X),imformats,'uni',0));
                imformats = cat(1,{'*.png','Current slice (*.png)';
                    '*.tif','Whole stack (*.tif)'},imformats);
            end
            
            if exist('Filename','var')
                [PathName,FileName, ext] = fileparts(Filename);
                FileName = [FileName,ext];
                PathName = [PathName filesep];
                ext = find(cellfun(@(x) strcmp(x(2:end),ext),imformats(:,1)));
            else
                [FileName,PathName, ext] = uiputfile(imformats,'Save Image');
            end
            if isequal(FileName,0)
                return;
            end
            imformats = imformats([ext,setdiff(1:end,ext)],:);
            ext = 1;
            
            if strfind(imformats{ext,2},'slice') % Current slice
                try, I = getframe(h.Axes(tool.Nvol)); I = I.cdata; catch I=get(h.I,'CData'); end
                if iscell(I), I = I{tool.Nvol}; end
                viewtype = get(tool.handles.Axes(tool.Nvol),'View');
                if viewtype(1)==-90, I=rot90(I);  end
                if size(I,3)==1
                    lims=get(h.Axes(tool.Nvol),'CLim');
                    I = uint8(max(0,min(1,(double(I)-lims(1))/diff(lims)))*(size(cmap,1)-1));
                    imwrite(cat(2,I,repmat(round(linspace(size(cmap,1),0,size(I,1)))',[1 round(size(I,2)/50)])),cmap,[PathName FileName])
                else
                    if strfind(imformats{ext,1},'gif')
                        [I,cm] = rgb2ind(I,256); 
                        if ~exist(fullfile(PathName, FileName),'file')
                            imwrite(I,cm,fullfile(PathName, FileName),'gif','Loopcount',inf);
                        else
                            imwrite(I,cm,fullfile(PathName, FileName),'gif','WriteMode','append');
                        end
                    else
                        imwrite(I,fullfile(PathName, FileName))
                    end
                end
            else
                lims=get(h.Axes(tool.Nvol),'CLim');
                
                if FileName == 0
                else
                    I = tool.getImage;
                    viewtype = get(tool.handles.Axes(tool.Nvol),'View');
                    if viewtype(1)==-90, I=rot90(I);  end
                    
                    for z=1:size(I,tool.viewplane)
                        switch tool.viewplane
                            case 1
                                Iz = I(z,:,:);
                            case 2
                                Iz = I(:,z,:);
                            case 3
                                Iz = I(:,:,z);
                        end
                        imwrite(gray2ind(mat2gray(Iz,lims),size(cmap,1)),cmap, fullfile(PathName,FileName), 'WriteMode', 'append',  'Compression','none');
                    end
                end
            end
        end
        
        function saveMask(tool,hObject,hdr)
            if exist('hObject','var') && ~isempty(hObject)
                % unselect button to prevent activation with spacebar
                set(hObject, 'Enable', 'off');
                drawnow;
                set(hObject, 'Enable', 'on');
            end
            
            Mask = tool.getMask(1);
            if any(Mask(:))
                if ~exist('hdr','var')
                    maskfname = 'Mask.tif';
                    filters = {'*.tif';'*.nii.gz;*.nii';'*.mat'};
                else
                    path = fileparts(hdr.file_name);
                    maskfname = fullfile(path,'Mask.nii.gz');
                    filters = {'*.nii.gz;*.nii';'*.mat';'*.tif'};
                end
                [FileName,PathName] = uiputfile(filters,'Save Mask',maskfname);
                if isequal(FileName,0)
                    return;
                end
                [~,~,ext] = fileparts(FileName);
                FileName = strrep(FileName,'.gz','.nii.gz');
                FileName = strrep(FileName,'.nii.nii','.nii');
                switch lower(ext)
                    case {'.nii','.gz'}  % .nii.gz
                        if ~exist('hdr','var')
                            err=1;
                            while(err)
                                answer = inputdlg2({'save as:','browse reference scan'},'save mask',[1 50],{fullfile(PathName,FileName), ''});
                                if isempty(answer), err=0; break; end
                                if ~isempty(answer{1})
                                    answer{1} = strrep(answer{1},'.gz','.nii.gz');
                                    answer{1} = strrep(answer{1},'.nii.nii','.nii');
                                    if ~isempty(answer{2})
                                        try
                                            [~,hdr] = nii_load(answer{2});
                                            nii_save(tool.getMask(1),hdr,answer{1});
                                            err=0;
                                        catch bug
                                            uiwait(warndlg(bug.message,'wrong reference','modal'))
                                        end
                                    else
                                        nii_save(uint8(tool.getMask(1)),[],answer{1})
                                        err=0;
                                    end
                                end
                            end
                        else
                            hdr.scl_slope=1; % no slope for Mask
                            hdr.scl_inter=0;
                            nii_save(Mask,hdr,fullfile(PathName,FileName))
                        end
                    case '.mat'
                        save(fullfile(PathName,FileName),'Mask');
                    case '.tif'
                        Mask = tool.getMask(1);
                        for z=1:size(Mask,tool.viewplane)
                            switch tool.viewplane
                                case 1
                                    Maskz = Mask(z,:,:);
                                case 2
                                    Maskz = Mask(:,z,:);
                                case 3
                                    Maskz = Mask(:,:,z);
                            end
                            if z==1
                                imwrite(uint8(Maskz), [PathName FileName], 'WriteMode', 'overwrite',  'Compression','none');
                            else
                                imwrite(uint8(Maskz), [PathName FileName], 'WriteMode', 'append',  'Compression','none');
                            end
                        end
                end
            else
                warndlg('Mask empty... Draw a mask using the brush tools on the right')
            end
        end
        
        function loadMask(tool,hObject,hdr)
            if exist('hObject','var') && ~isempty(hObject)
                % unselect button to prevent activation with spacebar
                set(hObject, 'Enable', 'off');
                drawnow;
                set(hObject, 'Enable', 'on');
            end
            
            if exist('hdr','var')
                path=fullfile(fileparts(hdr.file_name),'Mask.nii.gz');
            else
                path = 'Mask.tif';
            end
            [FileName,PathName] = uigetfile('*','Load Mask',path);
            if isequal(FileName,0), return; end
            [~,~,ext] = fileparts(FileName);
            switch lower(ext)
                case {'.nii','.gz'} % .nii.gz
                    if exist('hdr','var')
                        Mask = nii_load([{hdr} fullfile(PathName,FileName)],0,'nearest');
                    else
                        Mask = nii_load(fullfile(PathName,FileName));
                    end
                    if iscell(Mask), Mask = Mask{1}; end
                case '.mat'
                    load(fullfile(PathName,FileName));
                case {'.tif','.tiff'}
                    info = imfinfo(fullfile(PathName,FileName));
                    num_images = numel(info);
                    for k = 1:num_images
                        Mask(:,:,k) = imread(fullfile(PathName,FileName), k);
                    end
                case {'.png','.jp2','.jpg','.bmp'}
                    Mask = imread(fullfile(PathName,FileName));
                otherwise
                    return
            end
            S = tool.getImageSize(0);
            if ~isequal([size(Mask,1) size(Mask,2) size(Mask,3)],S(1:3))
                errordlg(sprintf('Inconsistent Mask size (%dx%dx%d). Please select a mask of size %dx%dx%d',size(Mask,1),size(Mask,2),size(Mask,3),S(1),S(2),S(3)))
                return;
            end
            tool.setMask(Mask);
        end
        
    end
    
    methods (Access = private)
        
        function showSlice(varargin)
            persistent timer
            if isempty(timer), timer=tic; end
            if toc(timer)<0.1
                return;
            end

             % Parse inputs
            switch nargin
                case 1
                    tool=varargin{1};
                    n=round(get(tool.handles.Slider,'value'));
                case 2
                    tool=varargin{1};
                    n=varargin{2};
                otherwise
                    tool=varargin{1};
                    n=round(get(tool.handles.Slider,'value'));
            end
            
            if n < 1
                n=round(size(tool.I{tool.Nvol},tool.viewplane)/2);
            end
            
            if n > size(tool.I{tool.Nvol},tool.viewplane)
                n=size(tool.I{tool.Nvol},tool.viewplane);
            end
            set(tool.handles.Slider,'value',n);
            
            Nvol = tool.Nvol;
            for ivol = 1:Nvol
                tool.Nvol = ivol;
            % Get Slice to show
            Orient = abs(tool.Orient)>45;
            if get(tool.handles.Tools.montage,'Value')
                n = max(n,3);
                I = tool.getImage;
                M = tool.getMask(1);
                Indices = unique(round(linspace(1,size(I,tool.viewplane),n)));
                switch tool.viewplane
                    case 1
                        order = [2 3 1];
                    case 2
                        order = [1 3 2];
                    case 3
                        order = [1 2 3];
                end
                if Orient
                    I = permute(I,order([2 1 3]));
                    M = permute(M,order([2 1 3]));
                else
                    I = permute(I,order);
                    M = permute(M,order);
                end
                S = size(I);
                [In,Mrows,Mcols]    = imagemontage(I,Indices);
                maskn = imagemontage(M,Indices);
                if Orient
                    In = permute(In,[2 1 3]);
                    maskn = permute(maskn,[2 1 3]);
                    S = S([2 1]);
                end
                newAspectRatio = size(In)./[S(1) S(2)];
                set(tool.handles.Tools.montage,'UserData',[Mrows Mcols Indices(:)']);
                set(tool.handles.Axes,'DataAspectRatio',tool.getAspectRatio.*[newAspectRatio 1]);
            else
                In = squeeze(tool.getCurrentImageSlice);
                maskn = squeeze(tool.getCurrentMaskSlice(1));
                tool.setAspectRatio(tool.aspectRatio)
            end
            
            % Manage brighness / contrast for colour images
            if size(In,3) > 1
                CL = get(tool.handles.Axes(tool.Nvol),'Clim');
                InOrig = In(round(linspace(1,end,min(end,70))),round(linspace(1,end,min(end,70))),:); % keep small version of original for histo
                InOrig = reshape(InOrig,[numel(InOrig)/3 3]);
                
                if tool.RGBalignhisto
                    %In = imadjust(In,stretchlim(In));

                    RGBstd = std(double(InOrig),0,1);
                    RGBmean = mean(double(InOrig),1);
                    for iband = 1:3
                        factor = 50/RGBstd(iband);
                        In(:,:,iband) = (double(In(:,:,iband))-RGBmean(iband))*factor+128;
                        InOrig(:,iband) =  (double(InOrig(:,iband))-RGBmean(iband))*factor+128;
                    end
                    range = [0 255];
                else
                    range = tool.range{tool.Nvol};
                end
                tool.centers = linspace(range(1)-diff(range)*0.05,range(2)+diff(range)*0.05,256*3);
                if isfield(tool.handles,'HistAxes')
                    try
                        xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)])
                    catch
                        xlim(tool.handles.HistAxes,[tool.centers(1) tool.centers(end)+.1])
                    end
                    set(tool.handles.HistImageAxes,'Units','Pixels'); pos=get(tool.handles.HistImageAxes,'Position'); set(tool.handles.HistImageAxes,'Units','Normalized');
                    set(tool.handles.HistImage,'CData',repmat(tool.centers,[round(pos(4)) 1]));
                end

                In = min(CL(2),max(CL(1),In));
                In = cast((In - CL(1))*(255/diff(CL)),'uint8');

                
                if tool.RGBdecorrstretch
                    In = decorrstretch(In);
                end
            end
            
            % apply gamma correction
            if tool.gamma ~= 1
                range = tool.range{tool.Nvol};
                switch class(In)
                    case 'uint8' % gamma between 0 and 255
                        lut = uint8(linspace(0,1,256).^tool.gamma*255);
                        In(:) = lut(In(:)+1);
                    case 'uint16' % gamma between range(1) and range(2)
                        range = round(range);
                        lut = uint16(linspace(0,1,diff(range)).^tool.gamma*diff(range));
                        lut = [zeros(1,range(1)-1,'uint16'), lut, range(2)*ones(1,2^16-range(2)+1,'uint16')];
                        In(:) = lut(In(:)+1);
                    otherwise % gamma between range(1) and range(2)
                        In = (max(0,double(In)-range(1))/diff(range)).^tool.gamma*diff(range)+range(1);
                end
            end
            
            % SHOW SLICE
            Opac = tool.NvolOpts.Opacity{ivol};
            if ~tool.upsample || get(tool.handles.Tools.montage,'Value')
                set(tool.handles.I(tool.Nvol),'CData',In,'AlphaData',Opac,'XData',get(tool.handles.I(1),'XData'),'YData',get(tool.handles.I(1),'YData'))
            else
                Inresized = imresize_noIPT(In,size(In)*2,tool.upsampleMethod);
                set(tool.handles.I(tool.Nvol),'CData',Inresized,'AlphaData',Opac,'XData',get(tool.handles.I(1),'XData'),'YData',get(tool.handles.I(1),'YData'))
            end
            end
            tool.Nvol = Nvol;
            if numel(maskn)>10e7 || ~any(maskn(:))
                maskrgb = maskn*100; % gray level mask if too big
            else
                maskrgb = ind2rgb8(maskn,tool.maskColor);
            end
            
            % SHOW MASK
            set(tool.handles.mask,'CData',maskrgb,'XData',get(tool.handles.I(tool.Nvol),'XData'),'YData',get(tool.handles.I(tool.Nvol),'YData'));
            
            if ~any(maskn(:))
                alphaLayer = 0;
            elseif numel(maskn)>10e7
                alphaLayer = tool.alpha;
            else
                alphaLayer = tool.alpha*logical(maskn);
            end
            set(tool.handles.mask,'AlphaData',alphaLayer)
            
            % Update Label
            try
                label = tool.label{tool.Nvol};
                if length(label)>70
                    label =  ['..' label(max(1,length(label)-70):end)];
                end
            catch
                label='';
            end
            set(tool.handles.LabelText,'String',label)
            set(tool.handles.SliceText,'String',['Vol: ' num2str(tool.Nvol) '/' num2str(length(tool.I)) '    Time: ' num2str(tool.Ntime) '/' num2str(size(tool.I{tool.Nvol},4)) '    Slice: ' num2str(n) '/' num2str(size(tool.I{tool.Nvol},tool.viewplane)) '    ' sprintf('%.1f%%',tool.rescaleFactor*100)])
            
            % Update Histogram
            if isfield(tool.handles.Tools,'Hist') && get(tool.handles.Tools.Hist,'value')
                if size(In,3) > 1
                    % plot R, G and B histogram
                    In = InOrig';
                    set(tool.handles.HistLine(1),'Color',[1 0 0])
                else
                    % plot histogram in white
                    % keep max 5000 pixels for faster process
                    In = In(round(linspace(1,end,min(end,5000))));
                    set(tool.handles.HistLine(1),'Color',[1 1 1])
                end
                for channel = 1:3
                    if channel>size(In,1)
                        set(tool.handles.HistLine(channel),'Visible','off')
                    else
                        Inc = In(channel,:);
                        Inc(Inc<tool.centers(1) | Inc>tool.centers(end)) = [];
                        err = (max(Inc(:)) - min(Inc(:)))*1e-10;
                        nelements=hist(Inc(Inc>(min(Inc(:))+err) & Inc<max(Inc(:)-err)),tool.centers);
                        range = get(tool.handles.Axes(tool.Nvol),'Clim');
                        if ~tool.isRGB
                            currentCenters = tool.centers>range(1) & tool.centers<range(2);
                            if any(currentCenters)
                                nelements=min(1,nelements./max(10,max(nelements(currentCenters))));
                            end    
                        else
                            nelements=min(1,nelements/max(nelements));
                        end
                        set(tool.handles.HistLine(channel),'YData',nelements);
                        set(tool.handles.HistLine(channel),'XData',tool.centers);
                        set(tool.handles.HistLine(channel),'Visible','on')
                    end
                end
            end
            
            notify(tool,'newSlice')
            
        end
        
        function setupSlider(tool)
            n=size(tool.I{tool.Nvol},tool.viewplane);
            if n==1
                set(tool.handles.Slider,'visible','off');
            else
                set(tool.handles.Slider,'visible','on');
                set(tool.handles.Slider,'SliderStep',[1/(size(tool.I{tool.Nvol},tool.viewplane)-1) 1/(size(tool.I{tool.Nvol},tool.viewplane)-1)])
                fun=@(hobject,eventdata)showSlice(tool,[],hobject,eventdata);
                set(tool.handles.Slider,'Callback',@(h,e) cellfun(@(x) feval(x,h,e), {@(h,e) set(tool.handles.Slider, 'Enable', 'off'),...
                                                                   @(h,e) drawnow,...
                                                                   @(h,e) set(tool.handles.Slider, 'Enable', 'on'),...
                                                                   @(h,e) setRGBindex3(tool),...
                                                                   fun}));
            end
            set(tool.handles.Slider,'min',1,'max',size(tool.I{tool.Nvol},tool.viewplane));
            if get(tool.handles.Slider,'value')==0 || get(tool.handles.Slider,'value')>n
                currentslice = round(size(tool.I{tool.Nvol},tool.viewplane)/2);
            else
                currentslice = get(tool.handles.Slider,'value');
            end
            set(tool.handles.Slider,'value',currentslice)
        end
        
        function setRGBindex3(tool)
            % Change color channel in RGB mode
            if tool.RGBdim == 3
                ColorChannel = get(tool.handles.SliderColor,'String');
                currentslice = round(max(1,get(tool.handles.Slider,'value')));
                switch ColorChannel
                    case 'R'
                        tool.RGBindex(1) = currentslice;
                    case 'G'
                        tool.RGBindex(2) = currentslice;
                    case 'B'
                        tool.RGBindex(3) = currentslice;
                end
            end    
        end
        
        function setupGrid(tool)
            %Update the gridlines
            try
                delete(tool.handles.grid)
            end
            nGrid=5;
            nMinor=5;
            posdim = setdiff(1:3,tool.viewplane);
            x=linspace(1,size(tool.I{tool.Nvol},posdim(2)),nGrid);
            y=linspace(1,size(tool.I{tool.Nvol},posdim(1)),nGrid);
            hold on;
            tool.handles.grid=[];
            gColor=[255 38 38]./256;
            mColor=[255 102 102]./256;
            for i=1:nGrid
                tool.handles.grid(end+1)=plot([.5 size(tool.I{tool.Nvol},posdim(2))-.5],[y(i) y(i)],'-','LineWidth',1.2,'HitTest','off','Color',gColor,'Parent',tool.handles.Axes(1));
                tool.handles.grid(end+1)=plot([x(i) x(i)],[.5 size(tool.I{tool.Nvol},posdim(1))-.5],'-','LineWidth',1.2,'HitTest','off','Color',gColor,'Parent',tool.handles.Axes(1));
                if i<nGrid
                    xm=linspace(x(i),x(i+1),nMinor+2); xm=xm(2:end-1);
                    ym=linspace(y(i),y(i+1),nMinor+2); ym=ym(2:end-1);
                    for j=1:nMinor
                        tool.handles.grid(end+1)=plot([.5 size(tool.I{tool.Nvol},posdim(2))-.5],[ym(j) ym(j)],'-r','LineWidth',.9,'HitTest','off','Color',mColor,'Parent',tool.handles.Axes(1));
                        tool.handles.grid(end+1)=plot([xm(j) xm(j)],[.5 size(tool.I{tool.Nvol},posdim(1))-.5],'-r','LineWidth',.9,'HitTest','off','Color',mColor,'Parent',tool.handles.Axes(1));
                    end
                end
            end
            tool.handles.grid(end+1)=scatter(.5+size(tool.I,posdim(2))/2,.5+size(tool.I{tool.Nvol},posdim(1))/2,'r','filled','Parent',tool.handles.Axes(1));
            
            fun=@(hObject,eventdata) imageButtonDownFunction(hObject,eventdata,tool);
            set(tool.handles.grid,'ButtonDownFcn',fun,'Hittest','on')

            if get(tool.handles.Tools.Grid,'Value')
                set(tool.handles.grid,'Visible','on')
            else
                set(tool.handles.grid,'Visible','off')
            end
        end
        
        function setWL(tool,W,L)
            try
                set(tool.handles.Axes(tool.Nvol),'Clim',[L-W/2 L+W/2])
                set(tool.handles.Tools.L,'String',num2str(L-W/2));
                set(tool.handles.Tools.U,'String',num2str(L+W/2));
                set(tool.handles.HistImageAxes,'Clim',[L-W/2 L+W/2])
                set(tool.handles.Histrange(1),'XData',[L-W/2 L-W/2 L-W/2])
                set(tool.handles.Histrange(2),'XData',[L+W/2 L+W/2 L+W/2])
                set(tool.handles.Histrange(3),'XData',[L L L])
            end
        end
        
        function maskEvents(tool,src,evnt)
            % Enable/Disable buttons
            [x,y,z] = find3d(tool.mask==tool.maskSelected);
            switch tool.viewplane
                case 1
                    z=x;
                case 2
                    z=y;
            end
            
            z = unique(z);
            if length(z)>1 && length(z)<(max(z)-min(z)+1)% if more than mask on more than 2 slices and holes
                set(tool.handles.Tools.maskinterp,'Enable','on')
            else
                set(tool.handles.Tools.maskinterp,'Enable','off')
            end
            
            if length(z)>1 && any(diff(z)==1)
                set(tool.handles.Tools.smooth3,'Enable','on')
            else
                set(tool.handles.Tools.smooth3,'Enable','off')
            end
            
            if ~isempty(z)
                set(tool.handles.Tools.maskactivecontour,'Enable','on')
            else
                set(tool.handles.Tools.maskactivecontour,'Enable','off')
            end
            if ~exist('evnt','var') || strcmp(evnt.EventName,'maskChanged')
                tool.setmaskHistory(tool.getMask(true));
            end
            
            tool.maskUpdated = true;
        end
        
        function setmaskstatistics(tool,current_object)
            
            % if Mouse over Mask Selection button
            if ishandle(current_object) && strcmp(get(current_object,'Tag'),'MaskSelected')
                % Prevent too many calls: Limit to 1 call every 10 seconds
                if ~tool.maskUpdated
                    return;
                end
                tool.maskUpdated = false;
                set(tool.handles.Tools.maskSelected,'TooltipString','Computing stats...')
                % Get statistics
                I = tool.getImage;
                for ii=1:length(tool.handles.Tools.maskSelected)
                    if ii == 5
                        iival = str2num(get(tool.handles.Tools.maskSelected(5),'String'));
                    else
                        iival = ii;
                    end
                    mask_ii = tool.mask==iival;
                    I_ii = I(mask_ii);
                    mean_ii = mean(I_ii);
                    std_ii  = std(double(I_ii));
                    area_ii = sum(mask_ii(:));
                    str = [sprintf('%-12s%.2f\n','Mean:',mean_ii), ...
                        sprintf('%-12s%.2f\n','STD:',std_ii),...
                        sprintf('%-12s%i','Area:',area_ii) 'px'];
                    

                    set(tool.handles.Tools.maskSelected(max(1,min(5,ii))),'TooltipString',str)
                end
                
            end
        end
        
        function showhelpannotation(tool)
            set(tool.handles.Tools.Help, 'Enable', 'off');
            drawnow;
            set(tool.handles.Tools.Help, 'Enable', 'on');
            if get(tool.handles.Tools.Help,'Value')
                a = rectangle(tool.handles.Axes(end),'Position',[0 0 1e12 1e12], ...
                    'FaceColor',[0 0 0 .7]);
                a(2) = annotation(tool.handles.Panels.Image,'textarrow',[0.1 0], [0.9 1],...
                    'String','Colorbar & Histogram','Color',[1 1 1]);
                a(3) = annotation(tool.handles.Panels.Image,'textarrow',[0.5 0.5], [0.8 1],...
                    'String','Display Options','Color',[1 1 1]);
                a(4) = annotation(tool.handles.Panels.Image,'textarrow',[0.9 1], [0.85 .85],...
                    'String',sprintf('3D Mask (Multi-label ROI)\n- Select label number\n- Fill with Paint brush\n- Hover label for stats\n- Right-click to delete'),'Color',[1 1 1]);
                a(5) = annotation(tool.handles.Panels.Image,'textarrow',[0.9 1], [0.25 .25],...
                    'String','ROI and measurement tools','Color',[1 1 1]);
                a(6) = annotation(tool.handles.Panels.Image,'textarrow',[0.7 .7], [0.08 0],...
                    'String',sprintf('Use arrows to navigate through\nTime (4th) or Volume (5th) dimension'),'Color',[1 1 1],'HorizontalAlignment','left');
                a(7) = annotation(tool.handles.Panels.Image,'textarrow',[0.1 0], [0.1 0.02],...
                    'String',sprintf('RGB mode:\nSwitch between RGB\nor Grayscale mode\nand select active\nchannel (R,G or B)\nRight-click for more options\n\n'),'Color',[1 1 1],'HorizontalAlignment','left');
                a(8) = annotation(tool.handles.Panels.Image,'textarrow',[0.1 0], [0.5 0.5],...
                    'String',sprintf('Use scroll wheel to navigate\nthrough slices (3rd dim)'),'Color',[1 1 1],'HorizontalAlignment','left');
                a(9) = annotation(tool.handles.Panels.Image,'textbox',[0.4 0.3 .4 .4],'FitBoxToText','on',...
                    'String',sprintf('Left-click for contrast/brightness\n\nRight-click to pan\n\nMiddle-click + up to zoom\n\nDrag&Drop image files HERE\n\nHover cursor over any button\nfor help\n\nSee <about> for Keyboard shortcuts\n\n'),'Color',[1 1 1],'EdgeColor',[1 1 1],'HorizontalAlignment','left');
                tool.handles.HelpAnnotation = a;
            else
                delete(tool.handles.HelpAnnotation)
            end
        end
        
        function setmaskHistory(tool,mask)
            if ~isequal(mask,tool.maskHistory{end})
                tool.maskHistory{1} = mask;
                tool.maskHistory = circshift(tool.maskHistory,-1,2);
                if isempty(tool.maskHistory{end-1})
                    set(tool.handles.Tools.undoMask, 'Enable', 'off')
                else
                    set(tool.handles.Tools.undoMask, 'Enable', 'on')
                end
            end
        end
        
        function SliceEvents(tool,src,evnt)
            mask = tool.getCurrentMaskSlice(1);
            
            if any(mask(:))
                set(tool.handles.Tools.mask2poly,'Enable','on')
            else
                set(tool.handles.Tools.mask2poly,'Enable','off')
            end
        end
        
    end
    
    
end

function StatsCallback(hObject,evnt,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

if tool.isRGB && tool.RGBdim == 3
    Color = [0 0 0; 1 0 0; 0 1 0; 0 0 1];
    S = tool.getImageSize(0);
    Mask = zeros(S(1),S(2),S(3),'uint8');
    Mask(:,:,tool.RGBindex(3))=3;
    Mask(:,:,tool.RGBindex(2))=2;
    Mask(:,:,tool.RGBindex(1))=1;
else
    Color = tool.getMaskColor;
    Mask = tool.getMask(1);
end
% use filename only if label is path:
label = cellfun(@(X) X{end},cellfun(@(X) strsplit(X,filesep), tool.label, 'UniformOutput', false), 'UniformOutput', false);
EmptyFields = cellfun(@(x) ['vol #' x],strsplit(num2str(1:length(tool.I))),'uni',0);
label(cellfun(@(X) isempty(X), label)) = EmptyFields(cellfun(@(X) isempty(X), label));

% Open Stats figure
f1 = StatsGUI(tool.I,Mask,label(end:-1:1),Color);
% Open Histogram figure
f2 = HistogramGUI(tool.getImage(0),Mask,Color);

pos = get(f1,'Position');
name = 'Statistics';
if length(tool.I)>1, name = [name ' in each volume']; end
if tool.isRGB && tool.RGBdim == 3, name = [name ' in the channels RGB']; else
if any(Mask(:)) name = [name ' in the different ROI']; end
end
set(f1,'Name',name)
pos(1) = pos(1)+pos(3);
set(f2,'Position',pos,'Name',['Histrogram of ' label{tool.Nvol}])
end

function PaintBrushCallback(hObject,evnt,tool,style)
%Remove any old brush
removeBrushObject(tool);

if get(hObject,'Value')
    switch style
        case 'Normal'
            set(tool.handles.Tools.SmartBrush,'Value',0);
        case 'Smart'
            set(tool.handles.Tools.PaintBrush,'Value',0);
    end
    createBrushObject(tool,style);
end

end

function mask2polyImageCallback(hObject,evnt,tool)
h = getHandles(tool);
mask = tool.getCurrentMaskSlice(0);
mask = imfill(mask,'holes');
if any(mask(:))
    [labels,num] = bwlabel(mask);
    for ilab=1:num
        labelilab = labels==ilab;
        if sum(labelilab(:))>15
            P = bwboundaries(labelilab); P = P{1}; P = P(:,[2 1]);
            if size(P,1)>16, P = reduce_poly(P(2:end,:)',max(6,round(size(P,1)/15))); P(:,end+1)=P(:,1); end
            if ~isempty(P)
                imtool3DROI_poly(h.I(tool.Nvol),P',tool);
            end
        end
    end
end

end

function smooth3Callback(hObject,evnt,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

mask = getMask(tool);
mask = smooth3(mask)>0.45;
tool.setMask(mask);
end

function maskinterpImageCallback(hObject,evnt,tool)
mask = getMask(tool);
[x,y,z] = find3d(mask);
mask2=false(size(mask));

switch tool.viewplane
    case 1
        z = unique(x);
        mask2(min(z):max(z),:,:) = interpmask(z, mask(unique(z),:,:),min(z):max(z),'interpDim',1,'pchip');
    case 2
        z = unique(y);
        mask2(:,min(z):max(z),:) = interpmask(z, mask(:,unique(z),:),min(z):max(z),'interpDim',2,'pchip');
    case 3
        z = unique(z);
        mask2(:,:, min(z):max(z)) = interpmask(z, mask(:,:,unique(z)),min(z):max(z),'interpDim',3,'pchip');
end
tool.setMask(mask2);
end


function ActiveCountourCallback(hObject,evnt,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

mask = getMask(tool);
if any(mask(:))
    I = tool.getImage;
    [W,L] = getWindowLevel(tool);
    I = mat2gray(I,[L-W/2 L+W/2]);
    
    %     mask = smooth3(mask);
    %     mask = mask>0.8;
    [x,y,z] = find3d(mask);
    switch tool.viewplane
        case 1
            z=x;
        case 2
            z=y;
    end
    z = unique(z);
    for iz = z'
        switch tool.viewplane
            case 1
                Iiz = I(iz,:,:);
                maskiz = mask(iz,:,:);
            case 2
                Iiz = I(:,iz,:);
                maskiz = mask(:,iz,:);
            case 3
                Iiz = I(:,:,iz);
                maskiz = mask(:,:,iz);
        end
        
        J = activecontour(squeeze(Iiz), squeeze(maskiz), 3,'Chan-Vese','SmoothFactor',0.1,'ContractionBias' ,0);
        switch tool.viewplane
            case 1
                mask(iz,:,:) = J;
            case 2
                mask(:,iz,:) = J;
            case 3
                mask(:,:,iz) = J;
        end
    end
    tool.setMask(mask);
end
end

% function CropImageCallback(hObject,evnt,tool)
% [I2 rect] = imcrop(tool.handles.Axes);
% rect=round(rect);
% mask = getMask(tool);
% range=getDisplayRange(tool);
% setImage(tool, tool.I(rect(2):rect(2)+rect(4)-1,rect(1):rect(1)+rect(3)-1,:),range,mask(rect(2):rect(2)+rect(4)-1,rect(1):rect(1)+rect(3)-1,:))
% end

function [I, position, h, range, tools, mask, enableHist] = parseinputs(varargin)
switch length(varargin)
    case 0  %tool = imtool3d()
        I=[];
        position=[0 0 1 1]; h=[];
        range=[]; tools=[]; mask=[]; enableHist=true;
    case 1  %tool = imtool3d(I)
        I=varargin{1}; position=[0 0 1 1]; h=[];
        range=[]; tools=[]; mask=[]; enableHist=true;
    case 2  %tool = imtool3d(I,position)
        I=varargin{1}; position=varargin{2}; h=[];
        range=[]; tools=[]; mask=[]; enableHist=true;
    case 3  %tool = imtool3d(I,position,h)
        I=varargin{1}; position=varargin{2}; h=varargin{3};
        range=[]; tools=[]; mask=[]; enableHist=true;
    case 4  %tool = imtool3d(I,position,h,range)
        I=varargin{1}; position=varargin{2}; h=varargin{3};
        range=varargin{4}; tools=[]; mask=[]; enableHist=true;
    case 5  %tool = imtool3d(I,position,h,range,tools)
        I=varargin{1}; position=varargin{2}; h=varargin{3};
        range=varargin{4}; tools=varargin{5}; mask=[];
        enableHist=true;
    case 6  %tool = imtool3d(I,position,h,range,tools,mask)
        I=varargin{1}; position=varargin{2}; h=varargin{3};
        range=varargin{4}; tools=varargin{5}; mask=varargin{6};
        enableHist=true;
    case 7  %tool = imtool3d(I,position,h,range,tools,mask)
        I=varargin{1}; position=varargin{2}; h=varargin{3};
        range=varargin{4}; tools=varargin{5}; mask=varargin{6};
        enableHist = varargin{7};
end

if isempty(position)
    position=[0 0 1 1];
end
end

function measureImageCallback(hObject,evnt,tool,type)
removeBrushObject(tool)
switch type
    case 'ellipse'
        h = getHandles(tool);
        ROI = imtool3DROI_ellipse(h.I(tool.Nvol),[],tool);
    case 'rectangle'
        h = getHandles(tool);
        ROI = imtool3DROI_rect(h.I(tool.Nvol),[],tool);
    case 'polygon'
        h = getHandles(tool);
        ROI = imtool3DROI_poly(h.I(tool.Nvol),[],tool);
    case 'profile'
        h = getHandles(tool);
        ROI = imtool3DROI_line(h.I(tool.Nvol),[],tool);
    otherwise
end


end

function varargout = imageButtonDownFunction(hObject,eventdata,tool)
switch nargout
    case 0
        bp = get(0,'PointerLocation');
        WBMF_old = get(tool.handles.fig,'WindowButtonMotionFcn');
        WBUF_old = get(tool.handles.fig,'WindowButtonUpFcn');
        switch get(tool.handles.fig,'SelectionType')
            case 'normal'   %Adjust window and level
                CLIM=get(tool.handles.Axes(tool.Nvol),'Clim');
                W=CLIM(2)-CLIM(1);
                L=mean(CLIM);
                %make the contrast icon for the pointer
                icon = zeros(16);
                x = 1:16; [X,Y]= meshgrid(x,x); R = sqrt((X-8).^2 + (Y-8).^2);
                icon(Y>8) = 1;
                icon(Y<=8) = 2;
                icon(R>8) = nan;
                set(tool.handles.fig,'PointerShapeCData',icon);
                set(tool.handles.fig,'Pointer','custom')
                fun=@(src,evnt) adjustContrastMouse(src,evnt,bp,tool.handles.Axes,tool,W,L);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
            case 'extend'  %Zoom
                xlims=get(tool.handles.Axes(tool.Nvol),'Xlim');
                ylims=get(tool.handles.Axes(tool.Nvol),'Ylim');
                bpA=get(tool.handles.Axes(tool.Nvol),'CurrentPoint');
                bpA=[bpA(1,1) bpA(1,2)];
                setptr(tool.handles.fig,'glass');
                if tool.registrationMode % pan each volume independantly?
                    CurrentAxes = tool.handles.Axes(tool.Nvol);
                else
                    CurrentAxes = tool.handles.Axes;
                end
                fun=@(src,evnt) adjustZoomMouse(src,evnt,bp,CurrentAxes,tool,xlims,ylims,bpA);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
            case 'alt' %pan
                xlims=get(tool.handles.Axes(tool.Nvol),'Xlim');
                ylims=get(tool.handles.Axes(tool.Nvol),'Ylim');
                oldUnits =  get(tool.handles.Axes(tool.Nvol),'Units'); set(tool.handles.Axes,'Units','Pixels');
                pos = get(tool.handles.Axes(tool.Nvol),'Position');
                set(tool.handles.Axes,'Units',oldUnits);
                axesPixels = pos(3:end);
                imagePixels = [diff(xlims) diff(ylims)];
                scale = imagePixels./axesPixels;
                scale = max(scale);
                setptr(tool.handles.fig,'closedhand');
                if tool.registrationMode % pan each volume independantly?
                    CurrentAxes = tool.handles.Axes(tool.Nvol);
                else
                    CurrentAxes = tool.handles.Axes;
                end
                fun=@(src,evnt) adjustPanMouse(src,evnt,bp,CurrentAxes,xlims,ylims,scale);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        end
    case 2
        bp=get(tool.handles.Axes(tool.Nvol),'CurrentPoint');
        x=bp(1,1); y=bp(1,2);
        varargout{1}=x; varargout{2}=y;
end
end

function resetViewCallback(hObject,evnt,tool)
set(tool.handles.Axes,'Xlim',get(tool.handles.I(tool.Nvol),'XData'))
set(tool.handles.Axes,'Ylim',get(tool.handles.I(tool.Nvol),'YData'))
end

function toggleGrid(hObject,eventdata,tool)
% unselect button to prevent activation with spacebar
try
    warning off
    set(hObject, 'Enable', 'off');
    drawnow;
    set(hObject, 'Enable', 'on');
    warning on
end

tool.grid = get(hObject,'Value');
end

function toggleMontage(hObject,eventdata,tool)
% unselect button to prevent activation with spacebar
try
    warning off
    set(hObject, 'Enable', 'off');
    drawnow;
    set(hObject, 'Enable', 'on');
    warning on
end

tool.montage = get(hObject,'Value');
end

function toggleMask(hObject,eventdata,tool)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

if get(hObject,'Value')
    set(tool.handles.mask,'Visible','on')
else
    set(tool.handles.mask,'Visible','off')
end

end

function WindowLevel_callback(hobject,evnt,tool)
range=get(tool.handles.Axes(tool.Nvol),'Clim');

L=str2num(get(tool.handles.Tools.L,'String'));
if isempty(L)
    L=range(1);
    set(tool.handles.Tools.L,'String',num2str(L))
end
U=str2num(get(tool.handles.Tools.U,'String'));
if isempty(U)
    U=range(2);
    set(tool.handles.Tools.U,'String',num2str(U))
end
if U<L
    U=L+max(eps,abs(0.1*L));
    set(tool.handles.Tools.U,'String',num2str(U))
end
setWL(tool,U-L,mean([U,L]))
showSlice(tool)
end

function histogramButtonDownFunction(hObject,evnt,tool,line)

WBMF_old = get(tool.handles.fig,'WindowButtonMotionFcn');
WBUF_old = get(tool.handles.fig,'WindowButtonUpFcn');

switch line
    case 1 %Lower limit of range
        fun=@(src,evnt) newLowerRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
    case 2 %Upper limt of range
        fun=@(src,evnt) newUpperRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
    case 3 %Middle line
        fun=@(src,evnt) newLevelRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
end
end

function scrollWheel(scr,evnt,tool)
%Check to see if the mouse is over the axis
% units=get(tool.handles.fig,'Units');
% set(tool.handles.fig,'Units','Pixels')
% point=get(tool.handles.fig, 'CurrentPoint');
% set(tool.handles.fig,'Units',units)
%
% units=get(tool.handles.Panels.Large,'Units');
% set(tool.handles.Panels.Large,'Units','Pixels')
% pos_p=get(tool.handles.Panels.Large,'Position');
% set(tool.handles.Panels.Large,'Units',units)
%
% units=get(tool.handles.Panels.Image,'Units');
% set(tool.handles.Panels.Image,'Units','Pixels')
% pos_a=get(tool.handles.Panels.Image,'Position');
% set(tool.handles.Panels.Image,'Units',units)
%
% xmin=pos_p(1)+pos_a(1); xmax=xmin+pos_a(3);
% ymin=pos_p(2)+pos_a(2); ymax=ymin+pos_a(4);



%if point(1)>=xmin && point(1)<=xmax && point(2)>=ymin && point(2)<=ymax
%if isMouseOverAxes(tool.handles.Axes)
newSlice=get(tool.handles.Slider,'value')-evnt.VerticalScrollCount;
if newSlice>=1 && newSlice <=size(tool.I{tool.Nvol},tool.viewplane)
    set(tool.handles.Slider,'value',newSlice);
    showSlice(tool)
end
%end

end

function multipleScrollWheel(scr,evnt,tools)
% unselect button to prevent activation with spacebar
for i=1:length(tools)
    scrollWheel(scr,evnt,tools(i))
end
end

function SelectSliderColor(tool,color)
H = tool.getHandles;
src = H.SliderColor;
butString = {'.','R','G','B'};
if exist('color','var')
    nextChannel = find(ismember(butString,{color,'.'}),1,'last');
else
    nextChannel = mod(find(strcmp(get(src,'String'),butString)),4)+1;
    tool.isRGB = (nextChannel > 1);
end
set(src,'String',butString{nextChannel});
if(nextChannel>1)
    switch tool.RGBdim
        case 3
            tool.setCurrentSlice(tool.RGBindex(nextChannel-1));
        case 4
            tool.Ntime = tool.RGBindex(nextChannel-1);
        case 5
            setNvol(tool,tool.RGBindex(nextChannel-1))
    end
end
set(src,'String',butString{nextChannel});
showSlice(tool);
end

function newLowerRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes(tool.Nvol),'Clim');
Xlims=get(hObject,'Xlim');
r=double(tool.getrange);
ord = round(log10(r));
if ord>1
    cp(1)=round(cp(1));
end
range(1)=cp(1);
W=diff(range);
L=mean(range);
if W>0 && range(1)>=Xlims(1)
    setWL(tool,W,L)
    showSlice(tool)
end
end

function newUpperRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes(tool.Nvol),'Clim');
Xlims=get(hObject,'Xlim');
r=double(tool.getrange);
ord = round(log10(r));
if ord>1
    cp(1)=round(cp(1));
end
range(2)=cp(1);
W=diff(range);
L=mean(range);
if W>0 && range(2)<=Xlims(2)
    setWL(tool,W,L)
    showSlice(tool)
end
end

function newLevelRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes(tool.Nvol),'Clim');
Xlims=get(hObject,'Xlim');
r=double(tool.getrange);
ord = round(log10(r));
if ord>1
    cp(1)=round(cp(1));
end
L=cp(1);
W=diff(range);
if L>=Xlims(1) && L<=Xlims(2)
    setWL(tool,W,L)
    showSlice(tool)
end
end

function adjustContrastMouse(src,evnt,bp,hObject,tool,W,L)
cp = get(0,'PointerLocation');
SS=get( 0, 'Screensize' ); SS=SS(end-1:end); %Get the screen size
d=round(cp-bp)./SS;
r=max(W,tool.getrange());
WS=tool.windowSpeed;
W2=W+r*d(1)*WS; L=L-r*d(2)*WS;
if W2>0
    W=W2;
else
    W=.001*W;
end

ord = round(log10(r));
if ord>1
    W=ceil(W);
    L=round(L);
end

setWL(tool,W,L)
if tool.isRGB
    showSlice(tool)
end
end

function adjustZoomMouse(src,~,bp,hObject,tool,xlims,ylims,bpA)

%get the zoom factor
cp = get(0,'PointerLocation');
d=cp(2)-bp(2);  %
zfactor = 1; %zoom percentage per change in screen pixels
resize = 100 + d*zfactor;   %zoom percentage

%get the old center point
cold = [xlims(1)+diff(xlims)/2 ylims(1)+diff(ylims)/2];

%get the direction vector from old center to the clicked point
dir = cold-bpA;
pfactor = 100; %zoom percentage at which clicked point becomes the new center

%rescale the dir vector according to ratio between resize and pfactor
dir = (dir*((resize-100)/pfactor));

%get the new center
cx = cold(1) + dir(1);
cy = cold(2) + dir(2);

%get the new width
newXwidth = diff(xlims)* (resize/100);
newYwidth = diff(ylims)* (resize/100);

%set the new axis limits
xlims = [cx-newXwidth/2 cx+newXwidth/2];
ylims = [cy-newYwidth/2 cy+newYwidth/2];
if resize > 0
    set(hObject,'Xlim',xlims,'Ylim',ylims)
end

% set to integer zooming factor if necessary
n = tool.getCurrentSlice;
if abs(tool.rescaleFactor - round(tool.rescaleFactor))<0.05
    tool.rescaleFactor = round(tool.rescaleFactor);
elseif tool.rescaleFactor<1 && (abs(1/tool.rescaleFactor - round(1/tool.rescaleFactor))<0.05)
    tool.rescaleFactor = 1/round(1/tool.rescaleFactor);
end
tool.rescaleFactor = round(tool.rescaleFactor*1000)/1000;

% update Text
set(tool.handles.SliceText,'String',['Vol: ' num2str(tool.Nvol) '/' num2str(length(tool.I)) '    Time: ' num2str(tool.Ntime) '/' num2str(size(tool.I{tool.Nvol},4)) '    Slice: ' num2str(n) '/' num2str(size(tool.I{tool.Nvol},tool.viewplane)) '    ' sprintf('%.1f%%',tool.rescaleFactor*100)])

end

function adjustZoomScroll(evnt,tool)

xlims=get(tool.handles.Axes(tool.Nvol),'Xlim');
ylims=get(tool.handles.Axes(tool.Nvol),'Ylim');

zfactor = 1.2; %zoom percentage per change in screen pixels
resize = 100 + sign(evnt.VerticalScrollCount)*abs(evnt.VerticalScrollCount)^zfactor;   %zoom percentage

% old center
cold = [xlims(1)+diff(xlims)/2 ylims(1)+diff(ylims)/2];
pfactor = 100; %zoom percentage at which clicked point becomes the new center
%get the zoom factor
cp = get(tool.handles.Axes(tool.Nvol),'CurrentPoint');
cp = cp(1,1:2);
dir = cold - cp;
dir = (dir*((resize-100)/pfactor));
%get the new center
cx = cold(1) + dir(1);
cy = cold(2) + dir(2);

%get the new width
newXwidth = diff(xlims)* (resize/100);
newYwidth = diff(ylims)* (resize/100);

%set the new axis limits
xlims = [cx-newXwidth/2 cx+newXwidth/2];
ylims = [cy-newYwidth/2 cy+newYwidth/2];
if resize > 0
    set(tool.handles.Axes,'Xlim',xlims,'Ylim',ylims)
end

% update Text
n = tool.getCurrentSlice;
set(tool.handles.SliceText,'String',['Vol: ' num2str(tool.Nvol) '/' num2str(length(tool.I)) '    Time: ' num2str(tool.Ntime) '/' num2str(size(tool.I{tool.Nvol},4)) '    Slice: ' num2str(n) '/' num2str(size(tool.I{tool.Nvol},tool.viewplane)) '    ' sprintf('%.1f%%',tool.rescaleFactor*100)])

end

function adjustPanMouse(src,evnt,bp,hObject,xlims,ylims,scale)
cp = get(0,'PointerLocation');
V = get(hObject,'View'); if iscell(V), V = V{1}; end
d = scale*(bp-cp);
if V(1)==-90
    d(1) = -d(1);
    d = d([2 1]);
elseif V(1)==90
    d(2) = -d(2);
    d = d([2 1]);
end
set(hObject,'Xlim',xlims+d(1),'Ylim',ylims-d(2))
end

function buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old)
%showSlice(tool)
setptr(tool.handles.fig,'arrow');
set(src,'WindowButtonMotionFcn',WBMF_old,'WindowButtonUpFcn',WBUF_old);

end

function getImageInfo(src,evnt,tool)
current_object = hittest(tool.handles.fig);
% if Mouse over Mask Selection button
setmaskstatistics(tool,current_object)

h = tool.getHandles;
isax = false;
for iax = 1:length(h.Axes), isax = isax | isequal(h.Axes(iax),current_object); end
for iI = 1:length(h.I), isax = isax | isequal(h.I(iI),current_object); end
for ian = 1:length(h.HelpAnnotation), isax = isax | isequal(h.HelpAnnotation(ian),current_object); end

if ~isax && ~isequal(h.mask,current_object)
    S = tool.getImageSize(1);
    set(h.Info,'String',sprintf('(%d,%d,%d) val',S(1),S(2),S(3)))
    return
end

% if Mouse outside Help button, hide help
set(tool.handles.Tools.Help,'Value',0)
delete(tool.handles.HelpAnnotation)

pos=get(h.Axes(tool.Nvol),'CurrentPoint');
rot90on = get(h.Axes(tool.Nvol),'view'); rot90on = rot90on(1);
pos=pos(1,1:2);
n=round(get(h.Slider,'value'));
if n==0
    n=1;
end

if get(tool.handles.Tools.montage,'Value')
    Msize = get(tool.handles.Tools.montage,'UserData');
    if ~rot90on
        Msize([2 1]) = Msize([1 2]);
    end
    
    if ~isempty(Msize)
        S = tool.getImageSize(1);
        pos = pos.*Msize(1:2);
        pos = max(0,pos);
        n = Msize(min(end,2+floor(pos(1)/S(2))*Msize(2)+floor(pos(2)/S(1))+1));
        pos(1) = mod(pos(1),S(2));
        pos(2) = mod(pos(2),S(1));
    end
end
pos = round(pos);
posdim = setdiff(1:3, tool.viewplane);
if pos(1)>0 && pos(1)<=size(tool.I{tool.Nvol},posdim(2)) && pos(2)>0 && pos(2)<=size(tool.I{tool.Nvol},posdim(1))
    switch tool.viewplane
        case 1
            set(h.Info,'String',['(' num2str(n) ',' num2str(pos(2)) ',' num2str(pos(1)) ') value=' num2str(tool.I{tool.Nvol}(n,pos(2),pos(1),min(end,tool.Ntime))) ' label=' num2str(tool.mask(n,pos(2),pos(1)))])
        case 2
            set(h.Info,'String',['(' num2str(pos(2)) ',' num2str(n) ',' num2str(pos(1)) ') value=' num2str(tool.I{tool.Nvol}(pos(2),n,pos(1),min(end,tool.Ntime))) ' label=' num2str(tool.mask(pos(2),n,pos(1)))])
        case 3
            if tool.isRGB
                switch tool.RGBdim
                    case 3
                        values = tool.I{tool.Nvol}(pos(2),pos(1),min(tool.RGBindex,end),min(end,tool.Ntime));
                    case 4
                        values = tool.I{tool.Nvol}(pos(2),pos(1),n,min(tool.RGBindex,end));
                    case 5
                        values = [tool.I{min(tool.RGBindex(1),end)}(pos(2),pos(1),n,min(end,tool.Ntime)),...
                                  tool.I{min(tool.RGBindex(2),end)}(pos(2),pos(1),n,min(end,tool.Ntime)),...
                                  tool.I{min(tool.RGBindex(3),end)}(pos(2),pos(1),n,min(end,tool.Ntime))];
                end
                values = ['[' num2str(values(1)) ',' num2str(values(2)) ',' num2str(values(3)) '] label=' num2str(tool.mask(pos(2),pos(1),n))];
            else
                values = [num2str(tool.I{tool.Nvol}(pos(2),pos(1),n,min(end,tool.Ntime))) ' label=' num2str(tool.mask(pos(2),pos(1),n))];
            end
            set(h.Info,'String',['(' num2str(pos(2)) ',' num2str(pos(1)) ',' num2str(n) ') value=' values])
    end
    notify(tool,'newMousePos')
else
    set(h.Info,'String','(x,y) val')
end



end

function panelResizeFunction(hObject,events,tool,w,h,wbutt)
hh = tool.getHandles;
try
    units=get(hh.Panels.Large,'Units');
    set(hh.Panels.Large,'Units','Pixels')
    pos=get(hh.Panels.Large,'Position');
    set(hh.Panels.Large,'Units',units)
    if isfield(hh.Tools,'Hist') && get(hh.Tools.Hist,'value')
        set(hh.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w-h])
    else
        set(hh.Panels.Image,'Position',[w w max(0,pos(3)-2*w) max(0,pos(4)-2*w)])
    end
    %set(h.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
    set(hh.Panels.Hist,'Position',[w max(0,pos(4)-w-h) max(0,pos(3)-2*w) h])
    set(hh.Panels.Tools,'Position',[0 max(0,pos(4)-w) pos(3) w])
    set(hh.Panels.ROItools,'Position',[max(0,pos(3)-w)  w w max(0,pos(4)-2*w)])
    set(hh.Panels.Slider,'Position',[0 w w max(0,pos(4)-2*w)])
    set(hh.Slider,'Position',[0 wbutt w max(0,pos(4)-2*w-wbutt)])
    set(hh.Panels.Info,'Position',[0 0 pos(3) w])
    axis(hh.Axes,'fill');
    buff=(w-wbutt)/2;
    
    pos = get(tool.handles.Panels.Tools,'Position');
    set(hh.Tools.Help,'Position',[pos(3)-5*wbutt buff 3*wbutt-buff wbutt]);
    set(hh.Tools.About,'Position',[pos(3)-2*wbutt-buff buff 4*wbutt wbutt]);
    pos=get(hh.Panels.ROItools,'Position');
    for islct=1:5
        set(hh.Tools.maskSelected(islct),'Position',[buff pos(4)-buff-islct*wbutt wbutt wbutt]);
    end
    
    set(hh.Tools.maskLock,'Position',[buff pos(4)-buff-(islct+1)*wbutt wbutt wbutt]);
    set(hh.Tools.maskStats,'Position',[buff pos(4)-buff-(islct+2)*wbutt wbutt wbutt]);
    set(hh.Tools.maskSave,'Position',[buff pos(4)-buff-(islct+3)*wbutt wbutt wbutt]);
    set(hh.Tools.maskLoad,'Position',[buff pos(4)-buff-(islct+4)*wbutt wbutt wbutt]);
    
    set(hh.Axes,'XLimMode','manual','YLimMode','manual');
    
end
end

function icon = makeToolbarIconFromPNG(filename)
% makeToolbarIconFromPNG  Creates an icon with transparent
%   background from a PNG image.

%   Copyright 2004 The MathWorks, Inc.
%   $Revision: 1.1.8.1 $  $Date: 2004/08/10 01:50:31 $

% Read image and alpha channel if there is one.
[icon,map,alpha] = imread(filename);

% If there's an alpha channel, the transparent values are 0.  For an RGB
% image the transparent pixels are [0, 0, 0].  Otherwise the background is
% cyan for indexed images.
if (ndims(icon) == 3) % RGB
    
    idx = 0;
    if ~isempty(alpha)
        mask = alpha == idx;
    else
        mask = icon==idx;
    end
    
else % indexed
    
    % Look through the colormap for the background color.
    if isempty(map), idx=1; icon = im2double(repmat(icon, [1 1 3])); return; end
    for i=1:size(map,1)
        if all(map(i,:) == [0 1 1])
            idx = i;
            break;
        end
    end
    
    mask = icon==(idx-1); % Zero based.
    icon = ind2rgb(icon,map);
    
end

% Apply the mask.
icon = im2double(icon);

for p = 1:3
    
    tmp = icon(:,:,p);
    if ndims(mask)==3
        tmp(mask(:,:,p))=NaN;
    else
        tmp(mask) = NaN;
    end
    icon(:,:,p) = tmp;
    
end

end

function ShowHistogram(hObject,evnt,tool,w,h)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

hh = tool.getHandles;
set(hh.Panels.Large,'Units','Pixels')
pos=get(hh.Panels.Large,'Position');
set(hh.Panels.Large,'Units','normalized')

if get(hh.Tools.Hist,'value')
    set(hh.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w-h])
else
    set(hh.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
end
axis(hh.Axes,'fill');
showSlice(tool)

end

function fig = getParentFigure(fig)
% if the object is a figure or figure descendent, return the
% figure. Otherwise return [].
while ~isempty(fig) & ~strcmp('figure', get(fig,'type'))
    fig = get(fig,'parent');
end
end

function overAxes = isMouseOverAxes(ha)
%This function checks if the mouse is currently hovering over the axis in
%question. hf is the handle to the figure, ha is the handle to the axes.
%This code allows the axes to be embedded in any size heirarchy of
%uipanels.

point = get(ha,'CurrentPoint');
x = point(1,1); y = point(1,2);
xlims = get(ha,'Xlim');
ylims = get(ha,'Ylim');

overAxes = x>=xlims(1) & x<=xlims(2) & y>=ylims(1) & y<=ylims(2);



end

function displayHelp(hObject,evnt,tool)
%%
h = get(hObject,'Value');
if h == 1

    msg = {'imtool3D, written by Justin Solomon',...
    'justin.solomon@duke.edu',...
    'adapted by Tanguy Duval',...
    'https://github.com/tanguyduval/imtool3D_td',...
    '------------------------------------------',...
    '',...
    'MOUSE CONTROLS',...
    'Middle Click and drag      Zoom in/out',...
    'Left   Click and drag      Contrast/Brightness',...
    'Right  Click and drag      Pan',...
    '',...
    'TRACKPAD CONTROLS',...
    'Shift + Click and drag     Zoom in/out',...
    'Left    Click and drag     Contrast/Brightness',...
    'Ctrl  + Click and drag     Pan',...
    '',...
    'KEYBOARD SHORTCUTS:',...
    'Left/right arrows          navigate through time (4th dimension)',...
    'Top/bottom arrows          navigate through volumes (5th ',...
    '                           dimension)',...
    '[X]                        [available in imtool3D_3planes only]',...
    '                              Set slices based on current mouse location',...
    '                             (hold X and move the mouse to navigate',...
    '                              in the volume)',...
    '',...
    '[Spacebar]                 Show/hide mask',...
    '[B]                        Toolbrush ',...
    '                             * Middle click and drag to change',...
    '                               diameter',...
    '                             * Right click to erase',...
    '[S]                        Smart Toolbrush',...
    '                             double click to toggle between'...
    '                             bright or dark segmentation',...
    '[Z]                        Undo mask',...
    '[1]                        Select mask label 1',...
    '[2]                        Select mask label 2',...
    '[...]'};
h = questdlg(msg,'imtool3D','OK','Preferences','Update','OK');
elseif h==3
    switch get(tool.handles.fig,'WindowStyle')
        case 'docked'
            set(tool.handles.fig,'WindowStyle','normal');
        otherwise
            set(tool.handles.fig,'WindowStyle','docked');
    end
    set(hObject,'Value',1);
elseif h==4
    name = inputdlg('Enter variable name','',1,{'tool'});
    if isempty(name); return; end
    name=name{1};
    assignin('base', name, tool)
    set(hObject,'Value',1);
end
switch h
    case 'Update'
        checkUpdate();
    case {'Preferences',2}
        %%
        buttons = {'Orientation', {'Vertical (Photo)','Horizontal (Medical)'}, ...
            'Scrool wheel function', {'Slice','Zoom'},...
            'upsample', tool.upsample, ...
            'gamma', tool.gamma, ...
            'is RGB image?',tool.isRGB,...
            'PANEL','RGB image',4,...
            'RGB dimension', {3,4,5}, ...
            'RGB index',tool.RGBindex,...
            'decorrelation stretch', tool.RGBdecorrstretch, ...
            'align RGB histograms', tool.RGBalignhisto, ...
            'windowSpeed', tool.windowSpeed};
        
        h = figure('opt' * 256.^(1:3)');
        set(h,'Name','Preferences','NumberTitle','off');
        set(h,'Toolbar','none','Menubar','none','NextPlot','new')
        set(h,'Units','Pixels');
        set(tool.handles.fig,'Units','Pixels')
        CallerPos = get(tool.handles.fig, 'Position');
        screensize = get(0,'ScreenSize');
        NewPos = [min(screensize(3)-250,CallerPos(1)+CallerPos(3)), CallerPos(2), 250, CallerPos(4)];
        set(h, 'Position', NewPos);

        tool.optdlg = optiondlg(buttons,h);
        tool.optdlg.setValue('RGB image_RGB dimension',tool.RGBdim-2)
        H = tool.optdlg.getHandles();
        
        % delete if main is deleted
        figfun = get(tool.handles.fig,'CloseRequestFcn');
        if ischar(figfun)
            set(tool.handles.fig,'CloseRequestFcn',@(src,evt) cellfun(@(x) feval(x), {figfun,@() delete(H.fig)}));
        else
            set(tool.handles.fig,'CloseRequestFcn',@(src,evt) cellfun(@(x) feval(x,src,evt), {figfun,@(h,e) delete(H.fig)}));
        end

        % Add Callbacks for buttons
        Orient = getOrient(tool);
        if abs(Orient)>45, tool.optdlg.setValue('Orientation',2); end
        tool.optdlg.setCallback('Orientation',@(src,evnt) tool.setOrient(src.String{src.Value},true))
        tool.optdlg.setCallback('Scrool wheel function',@(src,evnt) tool.setScrollWheelFun(src.String{src.Value},true));
        tool.optdlg.setCallback('upsample', @(src,evnt) assignval(tool,'upsample',src.Value))
        tool.optdlg.setCallback('gamma', @(src,evnt) assignval(tool,'gamma',str2num(src.String)))
        H = tool.optdlg.getHandles();
        H = get(H.Panel.RGBimage,'Children');
        valonoff = {'off','on'};
        set(H,'enable',valonoff{tool.isRGB+1});
        tool.optdlg.setCallback('is RGB image?', @(src,evnt) cellfun(@(f) feval(f,src,evnt), {@(src,evnt) assignval(tool,'isRGB',src.Value),@(src,evnt) tool.showSlice(),...
                                                     @(src,evnt) set(H,'enable',valonoff{src.Value+1})}))
        tool.optdlg.setCallback('RGB image_RGB dimension', @(src,evnt) assignval(tool,'RGBdim',str2num(src.String{src.Value})))
        tool.optdlg.setCallback('RGB image_decorrelation stretch', @(src,evnt) assignval(tool,'RGBdecorrstretch',src.Value))
        tool.optdlg.setCallback('RGB image_align RGB histograms', @(src,evnt) assignval(tool,'RGBalignhisto',src.Value))
        tool.optdlg.setCallback('RGB image_RGB index', @(src,evnt) assignval(tool,'RGBindex',src.Data))
        tool.optdlg.setCallback('windowSpeed', @(src,evnt) assignval(tool,'windowSpeed',str2num(src.String)))

        
end

end

function pos = getPixelPosition(h)
oldUnits = get(h,'Units');
set(h,'Units','Pixels');
pos = get(h,'Position');
set(h,'Units',oldUnits);
end

function togglebutton(h)
set(h,'Value',~get(h,'Value'))
fun = get(h,'Callback');
fun(h,1)
end

function [p,ellipse]=phantom3d(varargin)
%PHANTOM3D Three-dimensional analogue of MATLAB Shepp-Logan phantom
%   P = PHANTOM3D(DEF,N) generates a 3D head phantom that can
%   be used to test 3-D reconstruction algorithms.
%
%   DEF is a string that specifies the type of head phantom to generate.
%   Valid values are:
%
%      'Shepp-Logan'            A test image used widely by researchers in
%                               tomography
%      'Modified Shepp-Logan'   (default) A variant of the Shepp-Logan phantom
%                               in which the contrast is improved for better
%                               visual perception.
%
%   N is a scalar that specifies the grid size of P.
%   If you omit the argument, N defaults to 64.
%
%   P = PHANTOM3D(E,N) generates a user-defined phantom, where each row
%   of the matrix E specifies an ellipsoid in the image.  E has ten columns,
%   with each column containing a different parameter for the ellipsoids:
%
%     Column 1:  A      the additive intensity value of the ellipsoid
%     Column 2:  a      the length of the x semi-axis of the ellipsoid
%     Column 3:  b      the length of the y semi-axis of the ellipsoid
%     Column 4:  c      the length of the z semi-axis of the ellipsoid
%     Column 5:  x0     the x-coordinate of the center of the ellipsoid
%     Column 6:  y0     the y-coordinate of the center of the ellipsoid
%     Column 7:  z0     the z-coordinate of the center of the ellipsoid
%     Column 8:  phi    phi Euler angle (in degrees) (rotation about z-axis)
%     Column 9:  theta  theta Euler angle (in degrees) (rotation about x-axis)
%     Column 10: psi    psi Euler angle (in degrees) (rotation about z-axis)
%
%   For purposes of generating the phantom, the domains for the x-, y-, and
%   z-axes span [-1,1].  Columns 2 through 7 must be specified in terms
%   of this range.
%
%   [P,E] = PHANTOM3D(...) returns the matrix E used to generate the phantom.
%
%   Class Support
%   -------------
%   All inputs must be of class double.  All outputs are of class double.
%
%   Remarks
%   -------
%   For any given voxel in the output image, the voxel's value is equal to the
%   sum of the additive intensity values of all ellipsoids that the voxel is a
%   part of.  If a voxel is not part of any ellipsoid, its value is 0.
%
%   The additive intensity value A for an ellipsoid can be positive or negative;
%   if it is negative, the ellipsoid will be darker than the surrounding pixels.
%   Note that, depending on the values of A, some voxels may have values outside
%   the range [0,1].
%
%   Example
%   -------
%        ph = phantom3d(128);
%        figure, imshow(squeeze(ph(64,:,:)))
%
%   Copyright 2005 Matthias Christian Schabel (matthias @ stanfordalumni . org)
%   University of Utah Department of Radiology
%   Utah Center for Advanced Imaging Research
%   729 Arapeen Drive
%   Salt Lake City, UT 84108-1218
%
%   This code is released under the Gnu Public License (GPL). For more information,
%   see : http://www.gnu.org/copyleft/gpl.html
%
%   Portions of this code are based on phantom.m, copyrighted by the Mathworks
%
[ellipse,n] = parse_inputs(varargin{:});
p = zeros([n n n]);
rng =  ( (0:n-1)-(n-1)/2 ) / ((n-1)/2);
[x,y,z] = meshgrid(rng,rng,rng);
coord = [flatten(x); flatten(y); flatten(z)];
p = flatten(p);
for k = 1:size(ellipse,1)
    A = ellipse(k,1);            % Amplitude change for this ellipsoid
    asq = ellipse(k,2)^2;        % a^2
    bsq = ellipse(k,3)^2;        % b^2
    csq = ellipse(k,4)^2;        % c^2
    x0 = ellipse(k,5);           % x offset
    y0 = ellipse(k,6);           % y offset
    z0 = ellipse(k,7);           % z offset
    phi = ellipse(k,8)*pi/180;   % first Euler angle in radians
    theta = ellipse(k,9)*pi/180; % second Euler angle in radians
    psi = ellipse(k,10)*pi/180;  % third Euler angle in radians
    
    cphi = cos(phi);
    sphi = sin(phi);
    ctheta = cos(theta);
    stheta = sin(theta);
    cpsi = cos(psi);
    spsi = sin(psi);
    
    % Euler rotation matrix
    alpha = [cpsi*cphi-ctheta*sphi*spsi   cpsi*sphi+ctheta*cphi*spsi  spsi*stheta;
        -spsi*cphi-ctheta*sphi*cpsi  -spsi*sphi+ctheta*cphi*cpsi cpsi*stheta;
        stheta*sphi                  -stheta*cphi                ctheta];
    
    % rotated ellipsoid coordinates
    coordp = alpha*coord;
    
    idx = find((coordp(1,:)-x0).^2./asq + (coordp(2,:)-y0).^2./bsq + (coordp(3,:)-z0).^2./csq <= 1);
    p(idx) = p(idx) + A;
end
p = reshape(p,[n n n]);
end
function out = flatten(in)
out = reshape(in,[1 prod(size(in))]);
end


function [e,n] = parse_inputs(varargin)
%  e is the m-by-10 array which defines ellipsoids
%  n is the size of the phantom brain image
n = 128;     % The default size
e = [];
defaults = {'shepp-logan', 'modified shepp-logan', 'yu-ye-wang'};
for i=1:nargin
    if ischar(varargin{i})         % Look for a default phantom
        def = lower(varargin{i});
        idx = strmatch(def, defaults);
        if isempty(idx)
            eid = sprintf('Images:%s:unknownPhantom',mfilename);
            msg = 'Unknown default phantom selected.';
            error(eid,'%s',msg);
        end
        switch defaults{idx}
            case 'shepp-logan'
                e = shepp_logan;
            case 'modified shepp-logan'
                e = modified_shepp_logan;
            case 'yu-ye-wang'
                e = yu_ye_wang;
        end
    elseif numel(varargin{i})==1
        n = varargin{i};            % a scalar is the image size
    elseif ndims(varargin{i})==2 && size(varargin{i},2)==10
        e = varargin{i};            % user specified phantom
    else
        eid = sprintf('Images:%s:invalidInputArgs',mfilename);
        msg = 'Invalid input arguments.';
        error(eid,'%s',msg);
    end
end
% ellipse is not yet defined
if isempty(e)
    e = modified_shepp_logan;
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Default head phantoms:   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function e = shepp_logan
e = modified_shepp_logan;
e(:,1) = [1 -.98 -.02 -.02 .01 .01 .01 .01 .01 .01];
end

function e = modified_shepp_logan
%
%   This head phantom is the same as the Shepp-Logan except
%   the intensities are changed to yield higher contrast in
%   the image.  Taken from Toft, 199-200.
%
%         A      a     b     c     x0      y0      z0    phi  theta    psi
%        -----------------------------------------------------------------
e =    [  1  .6900  .920  .810      0       0       0      0      0      0
    -.8  .6624  .874  .780      0  -.0184       0      0      0      0
    -.2  .1100  .310  .220    .22       0       0    -18      0     10
    -.2  .1600  .410  .280   -.22       0       0     18      0     10
    .1  .2100  .250  .410      0     .35    -.15      0      0      0
    .1  .0460  .046  .050      0      .1     .25      0      0      0
    .1  .0460  .046  .050      0     -.1     .25      0      0      0
    .1  .0460  .023  .050   -.08   -.605       0      0      0      0
    .1  .0230  .023  .020      0   -.606       0      0      0      0
    .1  .0230  .046  .020    .06   -.605       0      0      0      0 ];

end

function e = yu_ye_wang
%
%   Yu H, Ye Y, Wang G, Katsevich-Type Algorithms for Variable Radius Spiral Cone-Beam CT
%
%         A      a     b     c     x0      y0      z0    phi  theta    psi
%        -----------------------------------------------------------------
e =    [  1  .6900  .920  .900      0       0       0      0      0      0
    -.8  .6624  .874  .880      0       0       0      0      0      0
    -.2  .4100  .160  .210   -.22       0    -.25    108      0      0
    -.2  .3100  .110  .220    .22       0    -.25     72      0      0
    .2  .2100  .250  .500      0     .35    -.25      0      0      0
    .2  .0460  .046  .046      0      .1    -.25      0      0      0
    .1  .0460  .023  .020   -.08    -.65    -.25      0      0      0
    .1  .0460  .023  .020    .06    -.65    -.25     90      0      0
    .2  .0560  .040  .100    .06   -.105    .625     90      0      0
    -.2  .0560  .056  .100      0    .100    .625      0      0      0 ];

end

function [M,rows,cols,indices] = imagemontage(I,indices)
if ~exist('indices','var'), indices = 1:size(I,3); end
nz = length(indices);
if nz<8
    rows = 1;  % show in line if less than 7. Better for articles
else
    rows = floor(sqrt(nz));
end
cols = ceil(nz/rows);
try
    M = images.internal.createMontage(I, [size(I,1) size(I,2)],...
        [rows cols], [0 0], [], indices, []);
catch
    Ipad = cat(3,I(:,:,indices),zeros(size(I,1),size(I,2),cols*rows-nz));
    M = squeeze(mat2cell(Ipad,size(I,1),size(I,2),ones(cols*rows,1)));
    M =cell2mat(reshape(M,[rows cols]));
end
end

%% Check for newer version on GitHub
% Simplified from checkVersion in findjobj.m by Yair Altman
function checkUpdate()
mfile = 'imtool3D';
if ~isdeployed
    msg = ['Update to the newest version ?'];
    answer = questdlg(msg, ['Update ' mfile], 'Yes', 'Later', 'Yes');
    if ~strcmp(answer, 'Yes'), return; end
    
    url = 'https://github.com/tanguyduval/imtool3D_td/archive/master.zip';
    tmp = tempdir;
    try
        fname = websave('imtool3D_github.zip', url); % 2014a
        unzip(fname, tmp); delete(fname);
        tdir = [tmp 'imtool3D_td-master/'];
    catch
        try
            fname = [tmp 'imtool3D_github.zip'];
            urlwrite(url, fname);
            unzip(fname, tmp); delete(fname);
            tdir = [tmp 'imtool3D_td-master/'];
        catch me
            errordlg(['Error in updating: ' me.message], mfile);
            web(url, '-browser');
            return;
        end
    end
    mfiledir = fileparts(which(mfile));
    % delete subfolders before copying
    listdir = dir(mfiledir);
    listdir = listdir(~cellfun(@(X) strcmp(X(1),'.'),{listdir.name}));
    listdir = listdir([listdir.isdir]);
    for iii = 1:length(listdir)
        rmdir(fullfile(mfiledir,listdir(iii).name), 's');
    end
    % copy
    movefile([tdir '*.*'], [fileparts(which(mfile)) '/.'], 'f');
    rmdir(tdir, 's');
    rehash;
    addpath(genpath(mfiledir));
    warndlg(['Package updated successfully. Please restart ' mfile ...
        ', otherwise it may give error.'], 'Check update');
end
end

function Ires = imresize_noIPT(I,S,intrp)
if ~exist('intrp','var') || isempty(intrp)
    intrp = 'linear';
end
Xq = linspace(1,size(I,1),S(1));
Yq = linspace(1,size(I,2),S(2));
Ires = zeros(S(1),S(2),size(I,3),'like',I);
for iz = 1:size(I,3)
    Ires(:,:,iz) = interp2(double(I(:,:,iz)),Yq,Xq',intrp);
end
end

function assignval(tool, var,val)
tool.(var) = val;
end

function var = assignind(var,ind,val)
var(ind) = val;
end


function onDrop(tool, listener, evtArg)
ht = wait_msgbox;
imformatlist = imformats;

% Get back the dropped data
data = evtArg.Data;
data = sort(data);
% Is it transferable as a list of files
if length(data)==1 && isdir(data{1})
    imlist = dir(fullfile(data{1},'*.png'));
    imlist = [imlist dir(fullfile(data{1},'*.tif'))];
    imlist = [imlist dir(fullfile(data{1},'*.jpg'))];
    if length(imlist)>1
    I = {};
    for ii = 1:length(imlist)
        if strcmp(imlist(ii).name(1),'.'), continue; end
        I = [I {imread(fullfile(data{1},imlist(ii).name))}];
    end
    tool.setImage(I);
    tool.label = {imlist.name};
    end
else
    [~,~,ext] = fileparts(data{1});
    if exist(['imread' lower(ext(2:end)) '.m'],'file')
        fun = str2func(['imread' lower(ext(2:end))]);
        for id = 1:length(data)
            dat{id} = fun(data{id});
        end
        hdr.pixdim = [1 1 1 1];
    else
        switch lower(ext)
            case {'.nii','.gz'}
                [dat, hdr] = nii_load(data);
            case {'.tif', '.tiff'}
                for id = 1:length(data)
                    info = imfinfo(data{id});
                    num_images = numel(info);
                    for k = 1:num_images
                        dat{id}(:,:,k) = imread(data{id}, k);
                    end
                end
                hdr.pixdim = [1 1 1 1];
            case cellfun(@(x) ['.' x], [imformatlist.ext], 'UniformOutput', false)
                for id = 1:length(data)
                    dat{id} = imread(data{id});
                end
                hdr.pixdim = [1 1 1 1];
            case '.mat'
                for id = 1:length(data)
                    tmp = load(data{id});
                    ff = fieldnames(tmp);
                    dat{id} = tmp.(ff{1});
                end
                hdr.pixdim = [1 1 1 1];
            otherwise
                error('unknown format %s',ext)
        end
    end
    rep = questdlg('','','replace','append','replace');
    switch rep
        case 'append'
            for ii=1:length(tool)
                tool(ii).setImage([tool(ii).getImage(1) dat]);
                tool(ii).setlabel([tool(ii).label(:); data]);
            end
        case 'replace'     
            for ii=1:length(tool)
                tool(ii).setImage(dat)
                tool(ii).setAspectRatio(hdr.pixdim(2:4));
                tool(ii).setlabel(data);
            end
    end
end
delete(ht)
end

function h = wait_msgbox
txt = 'Loading files. Please wait...';
h=figure('units','norm','position',[.5 .75 .2 .2],'menubar','none','numbertitle','off','resize','off','units','pixels');
ha=uicontrol('style','text','units','norm','position',[0 0 1 1],'horizontalalignment','center','string',txt,'units','pixels','parent',h);
hext=get(ha,'extent');
hext2=hext(end-1:end)+[60 60];
hpos=get(h,'position');
set(h,'position',[hpos(1)-hext2(1)/2,hpos(2)-hext2(2)/2,hext2(1),hext2(2)]);
set(ha,'position',[30 30 hext(end-1:end)]);
disp(char(txt));
drawnow;
end
