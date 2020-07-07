# Utilities ImageJ Macros by MICC Cell Observatory team

## Content

ScaleAndCropImages: Utility program to help handling of multiple EM images for analysis
ExportImagesFromComplexMicroscopyFiles: Export individual images From Complex Microscopy file (lif, czi, nd2) to Tiff Files

Written by: Ofra Golani at MICC Cell Observatory, Weizmann Institute of Science
Software package: Fiji (ImageJ)
Workflow language: ImageJ macro


## ScaleAndCropImages
  
Overview
--------
  
Utility program to help handling of multiple EM images for analysis
Go over all images (see details below), for each image:
- Open the image
- prompt the user to drwa a line along the scalebar
- prompt the user to select region-of-interest to keep , usually you will select the whole area without the scalebar and the rest of the EM microscope information 
  
Control Options
---------------
- ResultsLocation:  Two options for saving results: 
- UnderOrigFolder: save under InputFolder/Scaled  OR
- InNewLocation:   resScaledFolder/FolderName 
 
The following strategies are employed to allow *fast* scaling and cropping: 
- let you process single image OR whole folder of images OR all images in all subfolders of a selected folder
- let you select subset of images that macth specific folder and file names pattern (FolderNamePattern, FileNamePattern)
- use default ScaleBar (controlled by DefaultKnownDist)
- use the by default same scalebar ROI and same cropping region as used for the previous image , and let you change them if needed
- save scaled image and cropping region in a file under "ScaledImages" subfolder, 
  this enables processing only of images that were not processed before OR repeated cropping without rescaling,  OR   correction for few images
- final output (scaled and cropped) images are saved in different location under "ScaledAndCroppedImages" subfolder"


## ExportImagesFromComplexMicroscopyFiles

Overview
--------
Export individual images From Complex Microscopy file (lif, czi, nd2) to Tiff Files
 
Input:  Single complex file namedeg XX.lif  or folder of complex files 
Output: for each lif file: Subfolder named XX_Tif with the individual series saved as tif files
 
Control Options
---------------
- Controled by a dialog box
- Export all Images / Export Last series / Export the N series / Export only images that match criteria on size/number of channels
- Match Criteria: 
	* number of channels 
 	* image size
	* image name include specified Text 
    * Processing Type: None/MaxProject/Stitching (not implemented)
- Output type: Tif / hdf5 / ilastik hdf5 
- Location of output files: UnderOrigFolder / InNewLocation 
  this option usefull especially for working with files stored on network disks such as BioImg storage server (for WIS users)
 
Reference
---------
Based on Bio-Formats plugin, Bio-Formats Macro Extensions (called from Plugins menu of Fiji) and 
code examples from https://docs.openmicroscopy.org/bio-formats/5.8.0/users/imagej/  
