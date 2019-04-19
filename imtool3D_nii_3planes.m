function tool = imtool3D_nii_3planes(filename,varargin)
if ~exist('filename','var'), filename=[]; end
tool = imtool3D_nii(filename,[1 2 3],varargin{:});