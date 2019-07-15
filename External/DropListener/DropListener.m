%
% PURPOSE:
%
%   Adds drop support onto graphical controls.
%
% NOTE:
%
%   DropListener is just a matlab proxy on top of 'java.awt.dnd.DropTarget'.
%   
%   It simply ensure conversion of java-based data types of its peer into 
%   more friendly matlab-based data types and should be used in similar way.
%
%   See https://docs.oracle.com/javase/7/docs/api/java/awt/dnd/DropTarget.html
%   for more details.
%
%   NB: 'DropListener.m' depends on 'DropListener.class' bytecode which 
%   must be  deployed in the same folder. The file 'DropListener.java' is
%   the source code for 'DropListener.class' and is provided for documentation 
%   or further extensions only.
%
% CONSTRUCTION:
%
%   [listener] = DropListener(parent, name, value, ...);
%
%       - 'parent': graphical control on which to attach the listener.
%       
%       - 'name/value': List of properties that can be set at construction time.
%
% PROPERTIES:
%
%   - Parent: Gets or sets the graphical component observed for drop operations onto it.
%
%       * Can be a handle object providing a '.java()' method to access 
%         the underlying 'java.awt.Component' data type or can be a 
%         'java.awt.Component' data type directly.
%
%       * Directly or undirectly 'java.awt.Component' parent must in anyway 
%         support for a 'setDropTarget' method.           
%
%   - DragEnterFcn: Gets or sets the function to call when the mouse enters the operable part of the drop site.
%   - DragExitFcn: Gets or sets the function to call when the mouse leaves the operable part of the drop site.
%   - DragOverFcn: Gets or sets the function to call when the mouse is still over the operable part of the drop site.
%   - DropFcn: Gets or sets the function to call when data is dropped in the operable part of the drop site.
%   - DropActionChangedFcn: Gets or sets the function to call when user modifies the current drop gesture.
%
%       * Generic syntax for these callbacks is as follow:
%
%           [] = callback(source, eventData);
%
%           - source: the object that fired the event (i.e. attached DropListener instance)
%           - eventData: structure containing event information.
%
%       * eventData associated to DragEnter, DragOver and DropActionChanged events is as follow:
%
%           eventData.GetTransferableData(); % Use this callback to access transfered data
%           eventData.IsAutoDrag; % Indicate if drop and drag sites are the in fact the same object
%           eventData.PossibleSourceActions; Indicates the possible actions the source site accepts
%           eventData.UserRequestedAction; Indicates the action the user wants for the drop site (depends on CTRL and SHIFT keys state)
%           eventData.MousePosition; Current position of the mouse in the drop site.
%           eventData.AcceptDrag(action); Use this callback to accept the drag with specified action override compared to user requested action
%                                         TO BE INVESTIGATED: AcceptDrag override does not seem to do anything compared to user requested action, don't know why
%           eventData.RejectDrag(); use this callback to reject the drag
%                                   NB: This works
%           
%       * eventData associated to Drop event is as follow:
%
%           eventData.GetTransferableData(); % Use this callback to access transfered data
%           eventData.IsAutoDrag; % Indicate if drop site and drag site are the same object
%           eventData.IsSameApplicationDrag; % Indicate if drop site and drag site are in the same application domain
%           eventData.PossibleSourceActions; Indicates the possible actions the source site accepts
%           eventData.UserRequestedAction; Indicates the action the user wants (depends on CTRL and SHIFT keys state)
%           eventData.MousePosition; Current position of the mouse in the drop site.
%           eventData.AcceptDrop(action); Use this callback to accept the drag with specified action override compared to user requested action
%                                         TO BE INVESTIGATED: AcceptDrop override does not seem to do anything compared to user requested action, don't know why
%           eventData.RejectDrop(); use this callback to reject the drop
%                                   NB: This works
%           eventData.DropComplete(success); use this callback to indicate if drop was completed
%                                   NB: Don't really know how this can be useful
%
%      * eventData associated to DragExist is as follow:
%
%           eventData = struct([]); % No paramaters assocaited to this event so far.
%
%   - Active: Gets or sets if drop site is active or not
%
%   - DefaultActions: Gets or sets default actions associated to this drop site.
%
% REMARKS:
%
%   Supported actions and default actions is a cell array of string possibly
%   containing none to all of the following values { 'none', 'copy', 'move', 
%   'link' }. Callback to accept drag or drop is one of the above string only.
%
%       Example:
%
%           % Setting default supported actions on the drop site
%           listener.DefaultActions = { 'copy', 'move' };
%       
%           % Specify how drag is currently accepted on drop site;
%           event.AcceptDrag('copy');
%
%   GetTransferableData callback returns the following structure:
%
%       td.IsTransferableAsFileList; Indicates if data can be transfered as a list of files
%       td.TransferAsFileList; The list of files as a cell array of strings;
%            
%       td.IsTransferableAsString; Indicates if data can be transfered as text
%       td.TransferAsString; The text to transfer
%
%       TODO: 'DropListener.java' code may be further extended to also
%       support images and other data-flavors if required.
%

%%
classdef DropListener < handle

    %% Lifetime
    methods
        function [this] = DropListener(parent, varargin)
        % Creates a new DropListener instance.
        
            % Check arguments
            if (nargin < 1), error('Not enough input arguments.'); end
            
            % Supported parameters
            p = inputParser();
            p.StructExpand = false;
            p.KeepUnmatched = false;
            p.addParameter('DragEnterFcn', []);
            p.addParameter('DragExitFcn', []);
            p.addParameter('DragOverFcn', []);
            p.addParameter('DropFcn', []);
            p.addParameter('DropActionChangedFcn', []);
            p.addParameter('Active', true); 
            p.addParameter('DefaultActions', []); 
            p.parse(varargin{:});
                                  
            % Make sure java class used in the background is on the matlab path
            if (exist('JDropListener', 'class') ~= 8)
                classpath = fileparts(mfilename('fullpath')); 
                fn = fullfile(classpath, 'JDropListener.class');
                if (exist(fn, 'file') ~= 2)
                    error('Could not find associated `%s` java file.', fn);
                end
                javaaddpath(classpath, '-end');
            end
            
            % Create the java drop listeners and attach to its events
            this.jDropListener = handle(javaObjectEDT('JDropListener'), 'CallbackProperties');
            set(this.jDropListener, 'DragEnterCallback', @this.onDragEnter);
            set(this.jDropListener, 'DragExitCallback', @this.onDragExit);
            set(this.jDropListener, 'DragOverCallback', @this.onDragOver);
            set(this.jDropListener, 'DropCallback', @this.onDrop);
            set(this.jDropListener, 'DropActionChangedCallback', @this.onDropActionChanged);            
            
            % Init local properties
            this.Parent = parent;
            this.DragEnterFcn = p.Results.DragEnterFcn;
            this.DragExitFcn = p.Results.DragExitFcn;
            this.DragOverFcn = p.Results.DragOverFcn;
            this.DropFcn = p.Results.DropFcn;
            this.DropActionChangedFcn = p.Results.DropActionChangedFcn;
            this.Active = p.Results.Active;
            if (~isempty(p.Results.DefaultActions))
                this.DefaultActions = p.Results.DefaultActions; % override default actions only if provided
            end
            
        end
    end
    methods(Static, Access = private)
        function [] = validateCallback(cb, name)
            if (~isempty(cb) && (~isscalar(cb) || ~isa(cb, 'function_handle')))
                error('%s must be empty or a function handle.', name);                
            end
        end
        function [] = validateParent(parent, name)
            % NB: using numel == 1 because isscalar throws exception for javaobject
            if (~isempty(parent) && (~(numel(parent) == 1) || ~(isa(parent, 'handle') || isa(parent, 'java.awt.Component'))))
                error('%s must be empty or a ''handle'' or a subclass of ''java.awt.Component''.', name);                
            end
            
            if (isempty(parent)), return; end
            
            if (isa(parent, 'handle'))
                if (~ismethod(parent, 'java'))
                    error('%s when provided as a ''handle'' type must have a ''.java()'' method to find underlying java graphical control.', name);
                end
                parent = parent.java();
            end
            
            if (~isa(parent, 'java.awt.Component'))
                error('%s is not a subclass of java.awt.Component.', name);
            end
            
            if (~ismethod(parent, 'setDropTarget'))
                error('%s does not support for attaching drag and drop listener.', name);
            end
            
        end
        function [] = validateActive(active, name)
            if (islogical(active)), active = double(active); end
            if (~(isscalar(active) && isnumeric(active)))
                error('%s must be scalar logical value.', name);                
            end
        end
    end
    
    %% Properties
    properties(Dependent)
        Parent; % Gets or sets the component listened for drop operations.
        
        DragEnterFcn; % Gets or sets the function to call on 'DragEnter' event.
        DragExitFcn; % Gets or sets the function to call on 'DragExit' event.
        DragOverFcn; % Gets or sets the function to call on 'DragOver' event.
        DropFcn; % Gets or sets the function to call on 'Drop' event.
        DropActionChangedFcn; % Gets or sets the function to call on 'DropActionChanged' event.
        
        Active; % Gets or sets if drop site is active or not
        DefaultActions; % Gets or sets default actions supported for this drop site.
    end
    methods

        function [value] = get.Parent(this)
            value = this.parent;
        end
        function [] = set.Parent(this, value)
            this.validateParent(value, 'Parent');
            
            % Detach from mouse events of previous parent
            if (~isempty(this.hparent))
                set(this.hparent, 'MousePressedCallback', []);
                set(this.hparent, 'MouseReleasedCallback', []);                
            end
            this.isParentDragSource = false;
            
            if (isempty(value))
                this.jDropListener.setComponent([]);
                this.parent = [];
                this.hparent = [];
            else
                if (isa(value, 'handle'))
                    this.jDropListener.setComponent(value.java());
                    this.parent = value;
                    this.hparent = handle(value.java(), 'CallbackProperties');
                else
                    this.jDropListener.setComponent(value);
                    this.parent = value;
                    this.hparent = handle(value, 'CallbackProperties');
                end
                
                % Attach mouse events for new parent
                set(this.hparent, 'MousePressedCallback', @this.onMousePressed);
                set(this.hparent, 'MouseReleasedCallback', @this.onMouseReleased);
            end
                        
        end
        
        function [value] = get.DragEnterFcn(this)
            value = this.dragEnterFcn;
        end
        function [] = set.DragEnterFcn(this, value)
            this.validateCallback(value, 'DragEnterFcn'); 
            this.dragEnterFcn = value;
        end
        
        function [value] = get.DragExitFcn(this)
            value = this.dragExitFcn;
        end
        function [] = set.DragExitFcn(this, value)
            this.validateCallback(value, 'DragExitFcn'); 
            this.dragExitFcn = value;
        end
        
        function [value] = get.DragOverFcn(this)
            value = this.dragOverFcn;
        end
        function [] = set.DragOverFcn(this, value)
            this.validateCallback(value, 'DragOverFcn'); 
            this.dragOverFcn = value;
        end
        
        function [value] = get.DropFcn(this)
            value = this.dropFcn;
        end
        function [] = set.DropFcn(this, value)
            this.validateCallback(value, 'DropFcn'); 
            this.dropFcn = value;
        end
        
        function [value] = get.DropActionChangedFcn(this)
            value = this.dropActionChangedFcn;
        end
        function [] = set.DropActionChangedFcn(this, value)
            this.validateCallback(value, 'DropActionChangedFcn'); 
            this.dropActionChangedFcn = value;
        end
        
        function [value] = get.Active(this)
            value = double(this.jDropListener.isActive());
        end
        function [] = set.Active(this, value)
            this.validateActive(value, 'Active');
            if (double(value))
                this.jDropListener.setActive(true);
            else
                this.jDropListener.setActive(false);
            end
        end        
                       
        function [value] = get.DefaultActions(this)
            da = this.jDropListener.getDefaultActions();
            value = this.convertSourceActions(da);
        end
        function [] = set.DefaultActions(this, value)
            if (~(iscellstr(value) && isvector(value)))
                error('Default actions must be a cell array of strings (each being either ''none'', ''copy'', ''move'', ''link''.');
            end
            das = int64(0);
            for ki = 1:length(value)
                switch(lower(strtrim(value{ki})))
                    case 'none', das = bitor(das, int64(java.awt.dnd.DnDConstants.ACTION_NONE));
                    case 'copy', das = bitor(das, int64(java.awt.dnd.DnDConstants.ACTION_COPY));
                    case 'move', das = bitor(das, int64(java.awt.dnd.DnDConstants.ACTION_MOVE));
                    case 'link', das = bitor(das, int64(java.awt.dnd.DnDConstants.ACTION_LINK));
                    otherwise, error('Default actions must be a cell array of strings (each being either ''none'', ''copy'', ''move'', ''link''.');
                end
            end
            this.jDropListener.setDefaultActions(double(das));            
        end           
        
    end
        
    %% Internal
    properties(SetAccess = private, GetAccess = private)
        
        parent; % The component this DropListener instance is attached to
        
        hparent; % This is internal parent to listen to mouse event and know if parent is the drag source
        isParentDragSource; % Storing if parent is the drag source based on mouse state
               
        jDropListener; % The listener for drop operations (java-wrapper that fixes issues with directly working with java.awt.dnd.DropTarget)
        transferableData; % Local storage of transfered data
        
        % User callback for drop operations
        dragEnterFcn;
        dragExitFcn;
        dragOverFcn;
        dropFcn;
        dropActionChangedFcn;
                        
    end
    methods(Access = private)
        
        % This is to listen on mouse event and know if parent
        % is the source of currently on-going dnd operations
        function [] = onMousePressed(this, sender, args) %#ok<INUSD>
            assert(sender == this.hparent);
            this.isParentDragSource = true;
        end
        function [] = onMouseReleased(this, sender, args) %#ok<INUSD>
            assert(sender == this.hparent);
            this.isParentDragSource = false;
        end
        
        % Pre-catching internal listener events before to transmit
        % to user defined callbacks
        function [] = onDragEnter(this, sender, dropTargetDragEvent)
            assert(sender == this.jDropListener);
            
            % Collect transfered data in a matlab suitable format
            this.collectTransferableInfo();
            
            % Fire user defined callback
            this.onDragGeneric(dropTargetDragEvent, this.dragEnterFcn);                        
        end
        function [] = onDragOver(this, sender, dropTargetDragEvent)
            assert(sender == this.jDropListener);
            
            % Fire user defined callback
            this.onDragGeneric(dropTargetDragEvent, this.dragOverFcn);            
        end
        function [] = onDropActionChanged(this, sender, dropTargetDragEvent)
            assert(sender == this.jDropListener);
            
            % Fire user defined callback
            this.onDragGeneric(dropTargetDragEvent, this.dropActionChangedFcn);            
        end
        function [] = onDragExit(this, sender, dropTargetEvent)
            assert(sender == this.jDropListener);
            
            % Careful, this is not the same event type as in dragEnter/dragOver/dragActionChanged, 
            % and it contains almost nothing ==> so nothing to send for user defined callback
            class(dropTargetEvent); 
            if (~isempty(this.dragExitFcn))
                fixedEvent = struct([]);
                this.dragExitFcn(this, fixedEvent);
            end
            
        end        
        function [] = onDrop(this, sender, dropTargetDropEvent)
            assert(sender == this.jDropListener);
           
            % Careful, this is not the same event type as in dragEnter/dragOver/dragActionChanged,
            % Creating custom event data for user defined callback
            if (~isempty(this.dropFcn))
                fixedEvent.GetTransferableData = @this.getLazyCopyOfTransferableData;
                fixedEvent.IsAutoDrag = this.isParentDragSource;
                fixedEvent.IsSameApplicationDrag = dropTargetDropEvent.isLocalTransfer();
                fixedEvent.PossibleSourceActions = this.convertSourceActions(dropTargetDropEvent.getSourceActions());
                fixedEvent.UserRequestedAction = this.convertUserAction(dropTargetDropEvent.getDropAction());
                fixedEvent.MousePosition = dropTargetDropEvent.getLocation();
                fixedEvent.AcceptDrop = @(operation)this.acceptDropCallback(dropTargetDropEvent, operation);
                fixedEvent.RejectDrop = @()this.rejectDropCallback(dropTargetDropEvent);
                fixedEvent.DropComplete = @(success)this.dropCompleteCallback(dropTargetDropEvent, success);
                this.dropFcn(this, fixedEvent);
            end
            
        end
           
        % Helper functions
        function [] = collectTransferableInfo(this)
            
            this.transferableData = struct([]);
            
            this.transferableData(1).IsTransferableAsFileList = this.jDropListener.getCanTransferAsFileList();
            if (this.transferableData.IsTransferableAsFileList)
                jfl = this.jDropListener.getTransferAsFileList();
                this.transferableData.TransferAsFileList = cell(1, length(jfl));
                for ki = 1:length(jfl)
                    this.transferableData.TransferAsFileList{ki} = char(jfl(ki));
                end
            else
                this.transferableData.TransferAsFileList = cell(0);
            end
                    
            this.transferableData.IsTransferableAsString = this.jDropListener.getCanTransferAsString();
            if (this.transferableData.IsTransferableAsString)
                this.transferableData.TransferAsString = char(this.jDropListener.getTransferAsString());
            else
                this.transferableData.TransferAsString = '';
            end
                       
        end
        function [td] = getLazyCopyOfTransferableData(this)
            td.IsTransferableAsFileList = this.transferableData.IsTransferableAsFileList;
            td.TransferAsFileList = this.transferableData.TransferAsFileList;
            
            td.IsTransferableAsString = this.transferableData.IsTransferableAsString;
            td.TransferAsString = this.transferableData.TransferAsString;
        end
        function [] = onDragGeneric(this, dropTargetDragEvent, fcn)
            if (~isempty(fcn))
                fixedEvent.GetTransferableData = @this.getLazyCopyOfTransferableData;
                fixedEvent.IsAutoDrag = this.isParentDragSource;
                fixedEvent.PossibleSourceActions = this.convertSourceActions(dropTargetDragEvent.getSourceActions());
                fixedEvent.UserRequestedAction = this.convertUserAction(dropTargetDragEvent.getDropAction());
                fixedEvent.MousePosition = dropTargetDragEvent.getLocation();
                fixedEvent.AcceptDrag = @(operation)this.acceptDragCallback(dropTargetDragEvent, operation);
                fixedEvent.RejectDrag = @()this.rejectDragCallback(dropTargetDragEvent);
                fcn(this, fixedEvent);
            end
        end
        
    end
    methods(Static, Access = private)
        
        % Converting java-enums-falgs into cell array of strings
        function [csa] = convertSourceActions(sa)
            if (sa == 0)
                csa = { 'none' };
            else
                sa = int64(sa);
                csa = cell(0,1);
                if (bitand(int64(java.awt.dnd.DnDConstants.ACTION_COPY), sa))
                    csa{end+1} = 'copy';
                end
                if (bitand(int64(java.awt.dnd.DnDConstants.ACTION_MOVE), sa))
                    csa{end+1} = 'move';
                end
                if (bitand(int64(java.awt.dnd.DnDConstants.ACTION_LINK), sa))
                    csa{end+1} = 'link';
                end
                if (isempty(csa))
                    csa = { 'none' };
                end
            end
        end
        function [cua] = convertUserAction(ua)
            if (ua == 0)
                cua = 'none';
            else
                ua = int64(ua);
                if (bitand(int64(java.awt.dnd.DnDConstants.ACTION_COPY), ua))
                    cua = 'copy';
                end
                if (bitand(int64(java.awt.dnd.DnDConstants.ACTION_MOVE), ua))
                    cua = 'move';
                end
                if (bitand(int64(java.awt.dnd.DnDConstants.ACTION_LINK), ua))
                    cua = 'link';
                end
            end 
        end
        
        % Callbacks passed in event arguments to end-user
        function [] = acceptDragCallback(evt, operation)
            if (~ischar(operation)), error('Operation must be a string and either ''none'', or ''copy'' or ''move'' or ''link'' only.'); end
            switch(lower(strtrim(operation)))
                case 'none', evt.acceptDrag(0);
                case 'copy', evt.acceptDrag(java.awt.dnd.DnDConstants.ACTION_COPY);
                case 'move', evt.acceptDrag(java.awt.dnd.DnDConstants.ACTION_MOVE);
                case 'link', evt.acceptDrag(java.awt.dnd.DnDConstants.ACTION_LINK);
                otherwise, error('Operation must be a string and either ''none'', or ''copy'' or ''move'' or ''link'' only.');
            end            
        end
        function [] = rejectDragCallback(evt)
            evt.rejectDrag();
        end
        
        % Callbacks passed in event arguments to end-user
        function [] = acceptDropCallback(evt, operation)
            if (~ischar(operation)), error('Operation must be a string and either ''none'', or ''copy'' or ''move'' or ''link'' only.'); end
            switch(lower(strtrim(operation)))
                case 'none', evt.acceptDrop(0);
                case 'copy', evt.acceptDrop(java.awt.dnd.DnDConstants.ACTION_COPY);
                case 'move', evt.acceptDrop(java.awt.dnd.DnDConstants.ACTION_MOVE);
                case 'link', evt.acceptDrop(java.awt.dnd.DnDConstants.ACTION_LINK);
                otherwise, error('Operation must be a string and either ''none'', or ''copy'' or ''move'' or ''link'' only.');
            end            
        end
        function [] = rejectDropCallback(evt)
            evt.rejectDrop();
        end
        function [] = dropCompleteCallback(evt, success)
            if (islogical(success)), success = double(success); end
            if (~(isscalar(success) && isnumeric(success)))
                error('Sucess must be logical scalar value.')
            end
            
            if (success)
                evt.dropComplete(true);
            else
                evt.dropComplete(false);
            end
            
        end
        
    end
        
    %% Demo
    methods (Static)
        function [] = Demo()
        % Demonstration of the DropListener class functionality.

            % Create figure
            hFig = figure();

            % Create Java Swing JTextArea
            jTextArea = javaObjectEDT('javax.swing.JTextArea', sprintf('Drop some files or text content here.\n\n'));

            % Create Java Swing JScrollPane
            jScrollPane = javaObjectEDT('javax.swing.JScrollPane', jTextArea);
            jScrollPane.setVerticalScrollBarPolicy(jScrollPane.VERTICAL_SCROLLBAR_ALWAYS);

            % Add Scrollpane to figure
            [~,hContainer] = javacomponent(jScrollPane, [], hFig);
            set(hContainer, 'Units', 'normalized', 'Position', [0 0 1 1]);

            % Add drop listener for the JTextArea object
            DropListener(jTextArea, 'DropFcn', @DropListener.demoDropFcn);
            
        end
    end   
    methods (Static, Access = private)
        function demoDropFcn(src, evt)
            
            % Obtain the dropped data
            data = evt.GetTransferableData();
            
            % If is it an array of files
            if (data.IsTransferableAsFileList)
                
                % Dump file list in the text area
                src.Parent.append(sprintf('Dropped files:\n'));
                for n = 1:numel(data.TransferAsFileList)
                    src.Parent.append(sprintf('%d %s\n',n, data.TransferAsFileList{n}));
                end
                
                % Mark drop as completed
                evt.DropComplete(true);
               
            % If it is a string
            elseif (data.IsTransferableAsString)
               
                % Dump the string in the text area
                src.Parent.append(sprintf('Dropped text:\n%s\n', data.TransferAsString));
                
                % Mark drop as completed
                evt.DropComplete(true);
                
            else
                
                % Drop not accepted
                evt.RejectDrop();
                evt.DropComplete(false);
                
            end
            
        end
    end
end