classdef optiondlg < handle
    %This is a settings dialog
    % Use this class to Generate Buttons in vertical arrangement based on a cell array
    %----------------------------------------------------------------------
    % opts = optiondlg(buttons,h,maxButtonSize)
    % Example:
    %   buttons = {'SNR',50,'Method',{'Analytical equation','Block equation'},'Reset Mz',false}
    %   opt = optiondlg(buttons)
    %   Options = opt.getOptions;
    %
    
    properties (SetAccess = private, GetAccess = private)
        handles
    end
    
    properties
        ncol=1;
    end
    
    methods
        function opt = optiondlg(varargin) % Constructor
            varargin{6} = []; %init to empty
            if isempty(varargin{1})
                buttons = [];
            else
                buttons = varargin{1};
            end
            
            if isempty(varargin{2})
                h = figure('opt' * 256.^(1:3)');
                set(h,'Name','Preferences','NumberTitle','off');
                set(h,'Toolbar','none','Menubar','none','NextPlot','new')
                set(h,'Units','Pixels');
                pos = get(h,'Position');
                pos(4) = 600;
                pos(3) = 400;
                set(h,'Position',pos)
            else
                h = varargin{2};
            end
            
            if isempty(varargin{3})
                tips = {};
            else
                tips = varargin{3};
            end
            
            opt.handles.parent = h;
            %find the parent figure handle if the given parent is not a
            %figure
            if ~strcmp(get(h,'type'),'figure')
                opt.handles.fig = getParentFigure(h);
            else
                opt.handles.fig = h;
            end
            
            PanelPos = find(strcmp(buttons,'PANEL')); % Panel position
            nPanel = length(PanelPos);                % Number of panels
            nOpts = (length(buttons)-3*nPanel);       % Number of options
            
            % Panel declarations
            
            PanelTitle = cell(1,nPanel);
            PanelnElements = ones(1,nPanel);
            PanelNum = ones(1,nPanel);
            
            % Take the title and the number of element in memory before removing the
            % Panel informations ('PANEL','PanelTitle','PanelnElements')
            
            for i = 1:nPanel
                PanelNum(i) = PanelPos(i) - 3*(i-1);
                PanelTitle(i) = buttons(PanelNum(i)+1);
                PanelnElements(i) = buttons{PanelNum(i)+2};
                buttons([PanelNum(i),PanelNum(i)+1,PanelNum(i)+2]) = [];
            end
            
            % Each column of NumPanel and NumNoPanel indicates the beginning (row1) and
            % the end (row2) of a group of options combine whether in the same panel
            % (NumPanel) or between 2 panels (NumNoPanel)
            
            NumOpts = 1:nOpts;
            NumPanel = ones(2,nPanel);
            tempPanel = [];
            
            for iP = 1:nPanel
                NumPanel(:,iP) = [PanelNum(iP);PanelNum(iP)+2*PanelnElements(iP)-1];
                tempPanel = horzcat(tempPanel, NumPanel(1,iP):NumPanel(2,iP));
            end
            
            % Below line gives buttons that are not scoped by a panel.
            temp = diff([0, ~ismember(NumOpts,tempPanel), 0]);
            
            NumNoPanel = [find(temp==1); find(temp==-1)-1];
            
            NoPanelnElements = (NumNoPanel(2,:)-NumNoPanel(1,:)+1)/2;
            
            
            if ~isempty(buttons)
                
                % Counters declaration
                io = 1; % Object
                ip = 1; % Panel
                inp = 1; % NoPanel
                yPrev = 1; % Starting point for the first Panel/NoPanel
                
                % ----------------------------------------------------------------------------------------------------
                %   PANELS DISPLAY
                if ~exist('h','var'), h = figure; end
                Position = getpixelposition(h);
                PanelHeight = 35/Position(4);
                PanelGap = 0.02;
                % ----------------------------------------------------------------------------------------------------
                
                while io < nOpts
                    
                    % Fix the location and adjust the position (x, y, width and height)
                    
                    if find(NumPanel(1,:)==io)
                        
                        location = 'Panel';
                        x = 0.05;
                        Width = 0.905;
                        Height = PanelHeight*PanelnElements(ip);
                        y = yPrev - PanelGap - Height;
                        
                    elseif find(NumNoPanel(1,:)==io)
                        
                        location = 'NoPanel';
                        x = 0;
                        Width = 1;
                        Height = PanelHeight*NoPanelnElements(inp);
                        y = yPrev - PanelGap - Height;
                        
                    else
                        
                        warning('WARNING');
                        
                    end
                    
                    yPrev = y;
                    
                    
                    % Create Panels and fill them
                    switch location
                        
                        case 'Panel' % Reel Panels
                            
                            if strcmp(PanelTitle{ip}(1:min(end,2)),'##')
                                disablepanel = true;
                            else
                                disablepanel=false;
                            end
                            
                            ReelPanel = uipanel('Parent',h,'Title',PanelTitle{ip},'FontSize',11,'FontWeight','bold',...
                                'BackgroundColor',[0.94 0.94 0.94],'Position',[x y Width Height]);
                            
                            opt.handles.Panel.(genvarname_v2(PanelTitle{ip})) = ReelPanel;
                            if disablepanel, set(ReelPanel,'Visible','off'); end
                            
                            
                            htmp = GenerateButtonsInPanels(buttons(io:NumPanel(2,ip)),ReelPanel,[],tips);
                            
                            f = fieldnames(htmp);
                            
                            for i = 1:length(f)
                                opt.handles.buttons.([genvarname_v2(PanelTitle{ip}) '_' f{i}]) = htmp.(f{i});
                            end
                            
                            io = NumPanel(2,ip)+1;
                            ip = ip+1;
                            
                        case 'NoPanel' % "Fake" Panels
                            
                            FakePanel(inp) = uipanel('Parent',h,'BorderType','none','BackgroundColor',[0.94 0.94 0.94],...
                                'Position',[x y Width Height]);
                            
                            npref = strcat('NoPanel',num2str(inp)); % NoPanel reference in the handle
                            
                            htmp = GenerateButtonsInPanels(buttons(io:NumNoPanel(2,inp)),FakePanel(inp),[],tips);
                            
                            f = fieldnames(htmp);
                            
                            for i = 1:length(f)
                                
                                opt.handles.buttons.(f{i}) = htmp.(f{i});
                                
                            end
                            
                            io = NumNoPanel(2,inp)+1;
                            
                            inp = inp+1;
                            
                        case 'WARNING'
                            
                            warndlg('Your "buttons" input isn''t good!','WRONG!');
                            
                    end
                end
            end
            
        end
        
        function Options = getOptions(opt)
            % Read buttons values
            % Options = opt.getOptions()
            ff=fieldnames(opt.handles.buttons);
            N = length(ff);
            for ii = 1:N
                if strcmp(get(opt.handles.buttons.(ff{ii}),'type'),'uitable')
                    Options.(ff{ii}) = get(opt.handles.buttons.(ff{ii}),'Data');
                else
                    switch get(opt.handles.buttons.(ff{ii}),'Style')
                        case 'edit'
                            Options.(ff{ii}) = str2num(get(opt.handles.buttons.(ff{ii}),'String'));
                        case 'checkbox'
                            Options.(ff{ii}) = get(opt.handles.buttons.(ff{ii}),'Value');
                        case 'popupmenu'
                            list = get(opt.handles.buttons.(ff{ii}),'String');
                            Options.(ff{ii}) = list{get(opt.handles.buttons.(ff{ii}),'Value')};
                        case 'togglebutton'
                            Options.(ff{ii}) = get(opt.handles.buttons.(ff{ii}),'Value');
                            set(opt.handles.buttons.(ff{ii}),'Value',0);
                    end
                end
            end
        end
        
        function H = getHandles(opt)
            H = opt.handles;
        end
        
        function setValue(opt,Name,Value)
            set(opt.handles.buttons.(genvarname_v2(Name)),'Value',Value)
        end
        
        function setToolTipString(opt,Name,Value)
            set(opt.handles.buttons.(genvarname_v2(Name)),'ToolTipString',Value)
        end
        
        function setCallback(opt,Name,CB)
            if strcmp(get(opt.handles.buttons.(genvarname_v2(Name)),'Type'),'uitable')
                set(opt.handles.buttons.(genvarname_v2(Name)),'CellEditCallback',CB)
            else
                set(opt.handles.buttons.(genvarname_v2(Name)),'Callback',CB)
            end
        end
        
        function delete(opt)
            try
                %delete(opt.handles.parent)
            end
        end
    end
    
end

function handle = GenerateButtonsInPanels(opts, PanelHandle, style, tips)

if nargin < 3 || isempty(style)

    style = 'SPREAD'; %Set 'SPREAD' display as default

end

N = length(opts)/2;

% ----------------------------------------------------------------------------------------------------
%   OPTIONS DISPLAY

    Height = 0.6/N;
    Width = 0.5;

    if N == 1 %Special condition if N=1
        y = (1-Height)/2;

    elseif N == 2

        y = N/(N+1)-Height/4:-1/(N+1)-Height/2:0; %Special condition if N=2

    else

        switch style

            case 'CENTERED'

                y = N/(N+1)-Height/2:-1/(N+1):0;

            case 'SPREAD'

                y = N/(N+1):-1/(N+1)-Height/(N-1):0;
        end
    end
% ----------------------------------------------------------------------------------------------------

% The below comments belong to the buttons that are not scoped by a Panel:
%
% When prepended to the button name (obj.buttons{idx}) ### disables the
% corresponding UIControl object on the Options panel.
%
% When prepended to the button name (obj.buttons{idx}) *** hides the
% corresponding UIControl object on the Options panel.

for ii = 1:N 

    % Buttons are ordered as key<value> pairs in an array form.

    % 2*ii is for value
    % 2*ii-1 is for key

    val = opts{2*ii};

    % special case: disable if ### in option name
    if strcmp(opts{2*ii-1}(1:2),'##')

       opts{2*ii-1} = opts{2*ii-1}(3:end);
       disable=true;

    else

       disable = false;

    end

    if strcmp(opts{2*ii-1}(1:2),'**')

       opts{2*ii-1} = opts{2*ii-1}(3:end);
       noVis = true;

    else

      noVis =false;

    end

    % Variable names are generated regarding the key. Since these elements
    % are not scoped by a panel, they will be accessed at the first level
    % of the obj.options field.

    % genvarname_v2 will get rid of several chars such as white spaces,
    % parantheses etc., but also the disable/hide Jokers.

    tag = genvarname_v2(opts{2*ii-1});

    % Below if-else conditions are to deduce which type of UIObject will
    % be placed at the Options panel, regarding the itered <value>.

    if islogical(opts{2*ii}) % Checkbox (true/false)
        
        % Checkbox itself  
        handle.(tag) = uicontrol('Style','checkbox','String',opts{2*ii-1},'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','Position',[0.05 y(ii) 0.9 Height],...
            'Value',logical(val),'HorizontalAlignment','center');

    elseif isnumeric(opts{2*ii}) && length(opts{2*ii})==1 % Single val i/p
        
        % Entry box label 
        handle.([tag 'label']) = uicontrol('Style','Text','String',[opts{2*ii-1} ':'],'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','HorizontalAlignment','left','Position',[0.05 y(ii) Width Height]);
        
        % Entry box itself  
        handle.(tag) = uicontrol('Style','edit',...
            'Parent',PanelHandle,'Units','normalized','Position',[0.45 y(ii) Width Height],'String',val,'Callback',@(x,y) check_numerical(x,y,val));

    elseif iscell(opts{2*ii}) % Pop-up (or dropdown...) menu.

        % popup menu label 
        handle.([tag 'label']) = uicontrol('Style','Text','String',[opts{2*ii-1} ':'],'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','HorizontalAlignment','left','Position',[0.05 y(ii) Width Height]);

        if iscell(val), val = 1; else val =  find(cell2mat(cellfun(@(x) strcmp(x,val),opts{2*ii},'UniformOutput',0))); end % retrieve previous value
        
        % popup menu itself 
        handle.(tag) = uicontrol('Style','popupmenu',...
            'Parent',PanelHandle,'Units','normalized','Position',[0.45 y(ii) Width Height],'String',opts{2*ii},'Value',val);



    elseif isnumeric(opts{2*ii}) && length(opts{2*ii})>1 % A table.
        
        % table label 
        handle.([tag 'label']) =  uicontrol('Style','Text','String',[opts{2*ii-1} ':'],'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','HorizontalAlignment','left','Position',[0.05 y(ii) Width Height]);
             
             % table itself 
             handle.(tag) = uitable(PanelHandle,'Data',opts{2*ii},'Units','normalized','Position',[0.45 y(ii) Width Height*1.1]);
             
             % table assingment options till the next elseif 
             set(handle.(tag),'ColumnEditable',true(1,size(opts{2*ii},2)));

             % Hardcoded convention to assign whether as Row or Col name

             if size(opts{2*ii},1)<5, set(handle.(tag),'RowName',''); end

             widthpx = getpixelposition(PanelHandle)*Width; widthpx = floor(widthpx(3))-2; % ?

             if size(opts{2*ii},2)<5, set(handle.(tag),'ColumnName',''); set(handle.(tag),'ColumnWidth',repmat({widthpx/size(opts{2*ii},2)/1.5},[1 size(opts{2*ii},2)])); end

    elseif strcmp(opts{2*ii},'pushbutton') % This creates a button.

             % Agah: Trace how to assign a callback to this.

             handle.(tag) = uicontrol('Style','togglebutton','String',opts{2*ii-1},'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','Position',[0.05 y(ii) 0.9 Height],...
            'HorizontalAlignment','center');
    end

    if disable % Please see the first if statement inside the loop line250.

        set(handle.(tag),'enable','off');

    end

    if noVis % Please see the second if statement inside the loop line250.

        set(handle.(tag),'visible','off');
        fnames = fieldnames(handle);
        boollabel = ismember([tag 'label'],fnames);

        if boollabel
            set(handle.([tag 'label']),'visible','off');
        end

    end

    % Below if statement is to add TooltipString to the OptionsPanel BUTTONS
    % For buttons accompanied by a label object, only label will attain the
    % tip string. Otherwise some objects (such as tables) are going to 
    % collapse, partially visible etc. 
    
    
    
    if not(isempty(tips)) % Add Tooltip string 
        
        % Convert all cell to the varnames including tip explanations
        tipTag = cellfun(@genvarname_v2, tips,'UniformOutput',false);
        
        % Odd entries contain the keys. Get tag vars only. 
        tipTag = tipTag(1:2:end);
        tipsy   = tips(2:2:end);
        [bool, pos] = ismember(tag,tipTag);
        if bool

            

            fnames = fieldnames(handle);
            boollabel = ismember([tag 'label'],fnames);
            
            if boollabel
                set(handle.([tag 'label']),'Tooltipstring',tipsy{pos});
            else
                set(handle.(tag),'Tooltipstring',tipsy{pos});
            end

        end

    end

end
end


function check_numerical(src,eventdata,val)
str=get(src,'String');
if isempty(str2num(str))
    set(src,'string',num2str(val));
    warndlg('Input must be numerical');
end
end

function str = genvarname_v2(str)
str = strrep(str,'##','');
str = strrep(str,'**','');
str = strrep(str,'#','N');
str = strrep(str,' ','');
str = strrep(str,'=','');
str = strrep(str,'-','');
str = strrep(str,'(','');
str = strrep(str,')','');
str = strrep(str,'/','');
str = strrep(str,'*','');
str = strrep(str,'�','e');
str = strrep(str,'[','_');
str = strrep(str,']','_');
str = strrep(str,',','');
str = strrep(str,'?','Q');
end
