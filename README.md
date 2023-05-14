# Utilities ImageJ Macros and other scripts by MICC Cell Observatory team

## Content

*ScaleAndCropImages*: Utility program to help scaling, cropping and saving (as tiff or hdf5) multiple EM images in preparation for further analysis

*ExportImagesFromComplexMicroscopyFiles*: Export individual images From Complex Microscopy file (lif, czi, nd2) to Tiff or hdf5 Files

*RunIlastikHeadless.bat*: Windows bat file for running Ilastik Pixel Classifier followed by Ilastik boundary based segmentation on all files in a given folder.

<br/> <br/>
Written by: Ofra Golani at the MICC Cell Observatory, Weizmann Institute of Science

Software package: Fiji (ImageJ)

Workflow language: ImageJ macro


## ScaleAndCropImages
  
### Overview
  
Utility program to help scaling, cropping and saving multiple EM images in preparation for further analysis
Go over all images (see details below), for each image:
- Open the image
- prompt the user to draw a line along the scalebar
- prompt the user to select region-of-interest to keep , usually you will select the whole area without the scalebar and the rest of the EM microscope information 
  
### Control Options
- ResultsLocation:  Two options for saving results: 
- UnderOrigFolder: save under InputFolder/Scaled  OR
- InNewLocation:   resScaledFolder/FolderName 
- OutputFileType: allow saving cropped file into either tif or ilastik hdf5 format (for further training ilastik classifier suitable for running from Fiji)
 
The following strategies are employed to allow *fast* scaling and cropping: 
- let you process single image OR whole folder of images OR all images in all subfolders of a selected folder
- let you select subset of images that macth specific folder and file names pattern (FolderNamePattern, FileNamePattern)
- use default ScaleBar (controlled by DefaultKnownDist)
- use the by default same scalebar ROI and same cropping region as used for the previous image , and let you change them if needed
- save scaled image and cropping region in a file under "ScaledImages" subfolder, 
  this enables processing only of images that were not processed before OR repeated cropping without rescaling,  OR   correction for few images
- final output (scaled and cropped) images are saved in different location under "ScaledAndCroppedImages" subfolder"

<p align="left">
<img src="https://github.com/ofrag/Utils/blob/master/ScaleAndCropImages_GUI.PNG" width="250" title="ScaleAndCropImages_GUI">
	</p>

## ExportImagesFromComplexMicroscopyFiles

### Overview

Export individual images From Complex Microscopy file (lif, czi, nd2) to Tiff Files
 
Input:  Single complex file named eg XX.lif  or folder of complex files 
Output: for each lif file: Subfolder named XX_Tif with the individual series saved as tif files
 
### Control Options

- Controled by a dialog box
- Export all Images / Export Last series / Export the N series / Export only images that match criteria on size/number of channels
- Match Criteria: 
	* number of channels 
 	* image size
	* image name include specified Text 
    * Processing Type: None/MaxProject/Extract single channel
- Output type: Tif / hdf5 / ilastik hdf5 / jpg / png
- Location of output files: UnderOrigFolder / InNewLocation 
  this option usefull especially for working with files stored on network disks such as BioImg storage server (for WIS users)
- Exported image files are named either by their original image names (ImName) or FileName_SeriesNum_ImName 

<p align="left">
<img src="https://github.com/ofrag/Utils/blob/master/ExportImagesFromComplexMicroscopyFiles_GUI.PNG" width="500" title="ScaleAndCropImages_GUI">
	</p>

### Reference

Based on Bio-Formats plugin, Bio-Formats Macro Extensions (called from Plugins menu of Fiji) and 
code examples from https://docs.openmicroscopy.org/bio-formats/5.8.0/users/imagej/  
