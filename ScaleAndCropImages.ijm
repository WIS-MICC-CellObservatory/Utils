// @string(choices=("SingleFile", "WholeFolder", "AllSubFolders"), style="list") ProcessMode
// @string(choices=("UnderOrigFolder", "InNewLocation"), style="list") ResultsLocation
// @string FolderNamePattern 
// @string FileNamePattern 
// @boolean SkipExistingScaledImage
// @boolean SkipExistingCroppedImage
// @boolean UseScaleBarFromPrevImage
// @int DefaultKnownDist
// @string ScaleUnit 
// @string(choices=("tif", "ilastik hdf5"), style="list") OutputFileType

/* ScaleAndCropImages
 *  
 *  Overview
 *  =========
 *  
 *  Utility program to help handling of multiple EM images for analysis
 *  Go over all images (see details below), for each image:
 *  - Open the image
 *  - prompt the user to drwa a line along the scalebar
 *  - prompt the user to select region-of-interest to keep , usually you will select the whole area without the scalebar and the rest of the EM microscope information 
 *  
 *  Control Options
 *  ================
 *  ResultsLocation:  Two options for saving results: 
 *  - UnderOrigFolder: save under InputFolder/Scaled  OR
 *  - InNewLocation:   resScaledFolder/FolderName 
 *  - OutputFileType: allow saving cropped file into either tif orilastik hdf5 format (for further training ilastik classifier suitable for running from Fiji)
 *  
 *  The following strategies are employed to allow fast scaling and cropping: 
 *  - let you process single image OR whole folder of images OR all images in all subfolders of a selected folder
 *  - let you select subset of images that macth specific folder and file names pattern (FolderNamePattern, FileNamePattern)
 *  - use default ScaleBar (controlled by DefaultKnownDist)
 *  - use the by default same scalebar ROI and same cropping region as used for the previous image , and let you change them if needed
 *  - save scaled image and cropping region in a file under "ScaledImages" subfolder, 
 *    this enables processing only of images that were not processed before OR repeated cropping without rescaling,  OR   correction for few images
 *  - final output (scaled and cropped) images are saved in different location under "ScaledAndCroppedImages" subfolder"
 */


// Parameters
//==============
var fileExtension = ".tif";
var SummaryTable = "SummaryResults.xls";
var ScaledSubFolder = "ScaledImages";
var CroppedSubFolder = "ScaledAndCroppedImages";
var lowCasePattern = toLowerCase(FolderNamePattern);
var upCasePattern  = toUpperCase(FolderNamePattern);

var UseScaleBarFromPrevImageFlag = UseScaleBarFromPrevImage;
var SkipExistingScaledImageFlag = SkipExistingScaledImage;
var SkipExistingCroppedImageFlag = SkipExistingCroppedImage;

// Keep track of scale bar from previous file
var x1;
var y1;
var x2; 
var y2;
var lineWidth;
var KnownDist = DefaultKnownDist;
var SaveWithScaleBarLine = 1; 

var x;
var y;
var width;
var height;

var SaveFormat = OutputFileType;
var croppedOutExt = ".tif";
 
var macroVersion = "1.2"; 	

//============================================================================================
//------ Main Workflow --------------------------------
Initialization();

// Choose image folder
//======================
if (matches(ProcessMode, "SingleFile")) 
{
	file_name=File.openDialog("Please select an image file to process");
	print("Processing",file_name);
	directory = File.getParent(file_name);
} else if (matches(ProcessMode, "WholeFolder")) 
{
	directory = getDirectory("Open Image folders"); 
	folderName = File.getName(directory);
} else if (matches(ProcessMode, "AllSubFolders")) 
{
	parentDirectory = getDirectory("Open Parent Folder of subfolders to process"); 
	if (matches(ResultsLocation, "UnderOrigFolder")) {
		resParentFolder = parentDirectory;
	} else { // ResultsUnderOrigFolder==0		 
		resParentFolder = getDirectory("Open Parent Folder of Results"); }
}
	
// Processing: "wholeFolder" or "singleFile" mode
//============================================================================
if (matches(ProcessMode, "WholeFolder") || matches(ProcessMode, "SingleFile")) 
{
	if (matches(ResultsLocation, "UnderOrigFolder")) 
	{
		resScaledFolder = directory + File.separator + ScaledSubFolder + File.separator; 
		resCroppedFolder = directory + File.separator + CroppedSubFolder + File.separator; 
	} else // ResultsUnderOrigFolder==0
	{		 
		resParentFolder = getDirectory("Open Parent Folder of Results"); 
		resScaledFolder  = resParentFolder + File.separator + ScaledSubFolder  + File.separator; 
		resCroppedFolder = resParentFolder + File.separator + CroppedSubFolder + File.separator; 
		File.makeDirectory(resScaledFolder);
		File.makeDirectory(resCroppedFolder);
		if (matches(ProcessMode, "WholeFolder"))
		{
			resScaledFolder  = resScaledFolder  + folderName + File.separator; 
			resCroppedFolder = resCroppedFolder + folderName + File.separator; 
			//resFolder = resParentFolder + File.separator + ResultsSubFolder + File.separator; 
			//resFolder = resParentFolder + File.separator ; 
		}
	}
	File.makeDirectory(resScaledFolder);
	File.makeDirectory(resCroppedFolder);
	
	if (matches(ProcessMode, "SingleFile")) 
	{
		ProcessFile(file_name, directory, resScaledFolder, resCroppedFolder);
	}
	else if (matches(ProcessMode, "WholeFolder")) 
	{
		ProcessFiles(directory, resScaledFolder, resCroppedFolder); 
	}
	//SavePrms(resFolder, origNameNoExt);
} 

// Processing : "AllSubFolders" 
//=============================
else if (matches(ProcessMode, "AllSubFolders")) 
{ 	
	list = getFileList(parentDirectory);
	for (i = 0; i < list.length; i++) 
	{
		if(File.isDirectory(parentDirectory + list[i])) 
		{
			subFolderName = list[i];
			//print(subFolderName);
			subFolderName = substring(subFolderName, 0,lengthOf(subFolderName)-1);
			// process ONLY Sub Folders matching pattern
			if ( (indexOf(subFolderName, lowCasePattern) > 0) || (indexOf(subFolderName, upCasePattern) > 0) )
			{
				directory = parentDirectory + subFolderName + File.separator;			
				
				if (matches(ResultsLocation, "UnderOrigFolder")) 
				{
					directory = parentDirectory + subFolderName + File.separator;
					File.makeDirectory(directory);
					resScaledFolder = directory + File.separator + ScaledSubFolder + File.separator; 
					resCroppedFolder = directory + File.separator + CroppedSubFolder + File.separator; 
				} else // ResultsUnderOrigFolder==0
				{		 
					resScaledFolder  = resParentFolder + File.separator + ScaledSubFolder  + File.separator; 
					resCroppedFolder = resParentFolder + File.separator + CroppedSubFolder + File.separator; 
					File.makeDirectory(resScaledFolder);
					File.makeDirectory(resCroppedFolder);
					resScaledFolder  = resScaledFolder  + subFolderName + File.separator; 
					resCroppedFolder = resCroppedFolder + subFolderName + File.separator; 
				}
				File.makeDirectory(resScaledFolder);
				File.makeDirectory(resCroppedFolder);
		
				print("inDir=",directory," scaledDir=",resScaledFolder," croppededDir=",resCroppedFolder);
				ProcessFiles(directory, resScaledFolder, resCroppedFolder);
				print("Processing ",subFolderName, " Done");
			} // check pattern
		} // isDir
	} // loop on subfolders
} // AllSubFolders

Cleanup();
print("Done !");

//------End of Main Workflow --------------------------------
//============================================================================================

// ===== End of Main Code =================================================================


// ===== Helper Functions =================================================================

//============================================================================================
// Export Images from A single File 
//============================================================================================
function ProcessFile(full_name, directory, resScaledFolder, resCroppedFolder)
{
	file_name = File.getName(full_name);
	file_name_no_ext = replace(file_name, fileExtension, "");
	scaledName = resScaledFolder + File.separator + file_name;
	croppedRoi = resScaledFolder + File.separator + file_name_no_ext + ".roi";

	if (matches(SaveFormat, "ilastik hdf5"))
		croppedOutExt = ".h5";
	else if (matches(SaveFormat, "tif"))
		croppedOutExt = ".tif";
	croppedName = resCroppedFolder + File.separator + file_name_no_ext + croppedOutExt;

	needScaleFile   = SkipExistingScaledImage==0  || File.exists(scaledName)==0  ;
	needCroppedFile = SkipExistingCroppedImage==0 || File.exists(croppedName)==0 ;
	if ( needScaleFile || needCroppedFile )
		GetScaledFile(full_name, directory, scaledName);
	
	if ( needCroppedFile )
		GetCroppedFile(full_name, directory, croppedRoi, croppedName);

	// Cleanup
	Cleanup();

} // End of ProcessFile


//============================================================================================
function GetScaledFile(full_name, directory, scaledName)
{
	found = 0;
	if (SkipExistingScaledImage==1)
	{
		if (File.exists(scaledName))
		{
			print("Reading existing Scaled Image ...");
			open(scaledName);
			found = 1;
		}
	}
	if (found == 0)
	{
		//open(directory+file_name);
		open(full_name);
		Name = getTitle();
	
		// Ask the user to mark the scalebar 
		setTool("line");			
		if (UseScaleBarFromPrevImageFlag)
			makeLine(x1, y1, x2, y2, lineWidth);
		waitForUser("Measure Scalebar Done ?");
		
		// Get the line information and calculate line length 
		getLine(x1, y1, x2, y2, lineWidth);
		//print("Starting point: (" + x1 + ", " + y1 + ")");
		//print("Ending point:   (" + x2 + ", " + y2 + ")");
		dx = x2-x1; dy = y2-y1;
		//length = sqrt(dx*dx+dy*dy);
		
		// Ask the user to enter the Known Distance
		KnownDist = getNumber("Enter Known Distance ("+ScaleUnit+"):", KnownDist);
		
		// Scale the Image
		run("Set Scale...", "distance="+dx+" known="+KnownDist+" pixel=1 unit="+ScaleUnit);
		
		// Reset selection tool 
		if (SaveWithScaleBarLine==0)
			run("Select None");
		setTool("hand");		
		
		// Save the scaled Image
		print("scaledName=",scaledName);
		saveAs("Tiff", scaledName);
	}
	rename("Scaled");	
}



//============================================================================================
function GetCroppedFile(full_name, directory, croppedRoi, croppedName)
{
	found = 0;
	if (SkipExistingCroppedImage==1)
	{
		if (File.exists(croppedName))
		{
			print("Cropped File exist: "+croppedName+ " - skipping");
			//open(scaledName);
			found = 1;
		}
	}
	if (found == 0)
	{
		selectWindow("Scaled");
		roiManager("reset");
		if (File.exists(croppedRoi))
		{
			// Read scaled image
			roiManager("open", croppedRoi)
			roiManager("select", 0);
		} else 
		{   
			setTool("rectangle");
			if (UseScaleBarFromPrevImageFlag)
				makeRectangle(x, y, width, height);
			waitForUser("Draw a Rectangle to Exclude the Scalebar, click OK when you are done");
			getSelectionBounds(x, y, width, height);
			roiManager("add");
			roiManager("save", croppedRoi);
		}
		
		run("Duplicate...", "title=Cropped");
		ImToSave = getTitle();
		setTool("hand");		

		if (matches(SaveFormat, "ilastik hdf5"))
			run("Export HDF5", "select=["+croppedName+"] exportpath=["+croppedName+"] datasetname=data compressionlevel=0 input=["+ImToSave+"]");
		else if (matches(SaveFormat, "tif"))
			saveAs("Tiff", croppedName);
	}
	rename("Cropped");	
}

//============================================================================================
// Loop on all files in a given folder and Run analysis on each of them
//============================================================================================
function ProcessFiles(directory, resScaledFolder, resCroppedFolder) 
{
	// Get the files in the folder 
	fileListArray = getFileList(directory);
	
	// Loop over files
	for (fileIndex = 0; fileIndex < lengthOf(fileListArray); fileIndex++) {
		// Check for file pattern
		print(fileListArray[fileIndex], endsWith(fileListArray[fileIndex], fileExtension), indexOf(fileListArray[fileIndex], FileNamePattern));
		if ((endsWith(fileListArray[fileIndex], fileExtension)) && (indexOf(fileListArray[fileIndex], FileNamePattern)>-1)) {
			full_name = directory+fileListArray[fileIndex];
			
			print("processing:",fileListArray[fileIndex]);
			showProgress(fileIndex/lengthOf(fileListArray));
			ProcessFile(full_name, directory, resScaledFolder, resCroppedFolder);
			//Cleanup();
		} // end of if endsWith
	} // end of for loop

} // end of ProcessFiles

//============================================================================================

	
//============================================================================================
// Initialization - make sure the script always start at the same conditions
//============================================================================================
function Initialization()
{
	roiManager("Reset");
	run("Close All");
	// Clear Log window
	print("\\Clear");
}

//--------------------------------------
function Cleanup()
{
	roiManager("Reset");
	run("Close All");
}

