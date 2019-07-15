# DropListener

Adds drag and drop support for Matlab (as a proxy on top of [java.awt.dnd.DropTarget](https://docs.oracle.com/javase/7/docs/api/java/awt/dnd/DropTarget.html))

```matlab
%
% PURPOSE:
%
%   Show how to add drop support from file explorer to some matlab axis.
%
% SYNTAX:
%
%   [] = DropListenerDemo();
%
% USAGE:
%
%   Simply drop files from file explorer into displayed axis.
%

%%
function [] = DropListenerDemo()
%[
    % Create a figure with some axis inside
    fig = figure(666); clf;
    axes('Parent', fig);
    
    % Get back the java component associated to the axis
    % NB1: See §3.7.2 of Undocumented Secrets of Matlab Java Programming
    % NB2: or use findjobj, or javaObjectEDT for drop support onto other component types
    jFrame = get(handle(fig), 'JavaFrame');
    jAxis = jFrame.getAxisComponent();
    
    % Add listener for drop operations
    DropListener(jAxis, ... % The component to be observed
                 'DropFcn', @(s, e)onDrop(fig, s, e)); % Function to call on drop operation    
%]
end
function [] = onDrop(fig, listener, evtArg) %#ok<INUSL>
%[
    % Get back the dropped data
    data = evtArg.GetTransferableData();
    
    % Is it transferable as a list of files
    if (data.IsTransferableAsFileList)       
        
        % Do whatever you need with this list of files
        msg = sprintf('%s\n', data.TransferAsFileList{:});
        msg = sprintf('Do whatever you need with:\n\n%s', msg);
        uiwait(msgbox(msg));
                
        % Indicate to the source that drop has completed 
        evtArg.DropComplete(true);
        
    else
    
        % Not interested
        evtArg.RejectDrop();
        evtArg.DropComplete(false);
        
    end
%]
end
```

This project is based on [dndcontrol](https://fr.mathworks.com/matlabcentral/fileexchange/53511-drag---drop-functionality-for-java-gui-components) contribution on [file exchange](https://fr.mathworks.com/matlabcentral/fileexchange/). It aims to be a more generic wrapper on top of [java.awt.dnd.DropTarget](https://docs.oracle.com/javase/7/docs/api/java/awt/dnd/DropTarget.html) and it should be used in the same way as its java peer.
