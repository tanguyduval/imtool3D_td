//
// PURPOSE:
//
//    Extended DropTarget class so that it can be used from Matlab side.
//
// DESCRIPTION:
//
//    * What is wrong with directly using 'DropTarget' object in Matlab ?
//
//        Trying to obtain transfered data from matlab directly in 
//        'DropTargetDragEvent' or 'DropTargetDropEvent' does not
//        seem to work and this even if not putting breakpoints in matlab 
//        code (which may have cause to put dnd operation in invalid state):
//
//              t = dragEventData.getTransferable();
//              if (t.isDataFlavorSupported(java.awt.datatransfer.DataFlavor.javaFileListFlavor))
//                  d = t.getTransferData(java.awt.datatransfer.DataFlavor.javaFileListFlavor);
//                  ... matlab crash just the line above, while in pure java it is ok ...
//
//                      Java exception occurred:
//                      java.awt.dnd.InvalidDnDOperationException: No drop current
//
//                      at sun.awt.dnd.SunDropTargetContextPeer.getTransferData(Unknown Source)
//                      at sun.awt.datatransfer.TransferableProxy.getTransferData(Unknown Source)
//                      at java.awt.dnd.DropTargetContext$TransferableProxy.getTransferData(Unknown Source)
//              end
//
//    * What is the workaround here ?
//
//        We store transferable information directly in this instance, this 
//        way matlab side can access this information without looking at 
//        DropTargetDragEvent or DropTargetDropEvent parameters.
//
//        NB: Data to transfer are stored on each DragEnter event (i.e. 
//        only mouse position information is supposed to change for other
//        ones.
// 

import java.awt.dnd.*;
import java.awt.datatransfer.*;
import java.util.*;
import java.io.File;
import java.io.IOException;
     
public class JDropListener extends DropTarget
{
    private static final long serialVersionUID = 1L;
    
    private boolean canTransferAsFileList;
    private String[] transferDataAsFileList;
    
    private boolean canTransferAsString;
    private String transferDataAsString;
        
    @SuppressWarnings("unchecked")
    @Override
	public synchronized void dragEnter(DropTargetDragEvent evt) 
    {   
        // Get transferable
        Transferable t = evt.getTransferable();
        
        // Test if transferable as file list
        canTransferAsFileList = false;
        transferDataAsFileList = null;
        try 
        {
            if (t.isDataFlavorSupported(DataFlavor.javaFileListFlavor)) 
            {
                List<File> fileList = (List<File>)t.getTransferData(DataFlavor.javaFileListFlavor);
                transferDataAsFileList = new String[fileList.size()];
            	for (int i = 0; i < fileList.size(); i++) { transferDataAsFileList[i] = fileList.get(i).getAbsolutePath(); }
                canTransferAsFileList = true;
            }
        }
        catch (UnsupportedFlavorException e) 
        {
        	canTransferAsFileList = false;
            transferDataAsFileList = null;
        } 
        catch (IOException e) 
        {
        	canTransferAsFileList = false;
            transferDataAsFileList = null;
        }
        
        // Test if transferable as string
        canTransferAsString = false;
        transferDataAsString = null;
        try 
        {
            if (t.isDataFlavorSupported(DataFlavor.stringFlavor)) 
            {
                transferDataAsString = (String) t.getTransferData(DataFlavor.stringFlavor);
            	canTransferAsString = true;
            }
        }
        catch (UnsupportedFlavorException e) 
        {
        	canTransferAsString = false;
            transferDataAsString = null;
        } 
        catch (IOException e) 
        {
        	canTransferAsString = false;
            transferDataAsString = null;
        }
                
        // Ok now that we stored transferable details, we can call built-in drag enter method 
        // (so it will fire MATLAB Callback that can read into us for transferable details)       
        super.dragEnter(evt);        
    }
    
    public boolean getCanTransferAsFileList() 
    {
		return canTransferAsFileList;
	}	
	public String[] getTransferAsFileList() 
    {
        return transferDataAsFileList;
    }
    
    public boolean getCanTransferAsString() 
    {
		return canTransferAsString;
	}	
	public String getTransferAsString() 
    {
        return transferDataAsString;
    }
}