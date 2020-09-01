/*
 * Export individual images From Complex Microscopy file (lif, czi, nd2) to Tiff Files
 * 
 * Input:  Single complex file namedeg XX.lif  or folder of complex files 
 * Output: for each lif file: Subfolder named XX_Tif with the individual series saved as tif files
 * 
 * Options: 
 *  - Controled by a dialog box
 * 	- Export all Images / Export Last series / Export the N series / Export only images that match criteria on size/number of channels
 * 	- Match Criteria: 
 * 		- number of channels 
 * 		- image size
 * 		- image name include specified Text 
 * 	- Processing Type: None/MaxProject/Stitching (not implemented)
 * 	- Output type: Tif / hdf5 / ilastik hdf5 
 * 	- Location of output files: UnderOrigFolder / InNewLocation 
 * 	  this option usefull especially for working with files stored on network disks such as BioImg storage server (for WIS users)
 * 
 *  Reference
 * ===========
 * Based on Bio-Formats plugin, Bio-Formats Macro Extensions (called from Plugins menu of Fiji) and 
 * code examples from https://docs.openmicroscopy.org/bio-formats/5.8.0/users/imagej/  
 */

// ======  Parameters Settings , can be tuned by the user ================================

var macroVersion = 2;
var UseDialogGUI = 1; // 0 or 1
var processMode = "SingleFile"; 	// "SingleFile" or "WholeFolder" or "AllSubFolders"

var fileExtension = "lif";
var SaveFormat = "tif";

var ExportImages = "All"; // "All", "Last", "First" "None-PrintOnly"
var UseSeriesNumberCriteria = 0;
var CriteriaSeriesNumberMin = 2;
var CriteriaSeriesNumberMax = 2;

var UseChannelNumberCriteria = 0;
var CriteriaChannelNumberMin = 2;
var CriteriaChannelNumberMax = 2;

var UseImageSizeCriteria = 0;
var CriteriaImageSizeX = 1024;
var CriteriaImageSizeY = 1024;
var CriteriaImageSizeZ = 1;

var UseImageNameCriteria = 0;
var CriteriaImageNameText = "Merged";
var SeriesNumPad = 3;

var ProcType = "None"; // "None", "MaxProject", "Stitch"
var ResultsLocation = "UnderOrigFolder"; // "UnderOrigFolder", "InNewLocation"

var debugMode = 0; // for testing new features eg Stitch

var BatchModeFlag = 1; // 0 or 1, use 1 to work in quiet mode

// ======  End of Parameters Setting, =====================================================

// Global Variables - should not be changed 
var CleanupFlag = 1;

// ===== Main Code ========================================================================
Initialization();
if (UseDialogGUI)
	GetPrmsDialog();

//ShowAndSavePrms(SaveFlag, OutFileName);
ShowAndSavePrms(0, "");

run("Bio-Formats Macro Extensions");

// Choose image folder
//======================
if (matches(processMode, "SingleFile")) 
{
	file_name=File.openDialog("Please select an file to process");
	print("Processing",file_name);
	directory = File.getParent(file_name);
} else if (matches(processMode, "WholeFolder")) 
{
	directory = getDirectory("Open Image folders"); 
} else if (matches(processMode, "AllSubFolders")) 
{
	parentDirectory = getDirectory("Open Parent Folder of subfolders to process"); 
	if (matches(ResultsLocation, "UnderOrigFolder")) {
		resParentFolder = parentDirectory;
	} else { // ResultsUnderOrigFolder==0		 
		resParentFolder = getDirectory("Open Parent Folder of Results"); }
}
	
if (BatchModeFlag)
{
	print("Working in Batch Mode, processing without opening images");
	setBatchMode(true);
}

// Exporting: "wholeFolder" or "singleFile" mode
//============================================================================
if (matches(processMode, "WholeFolder") || matches(processMode, "SingleFile")) 
{
	if (matches(ResultsLocation, "UnderOrigFolder")) 
	{
		resFolder = directory + File.separator ; 
	} else // ResultsUnderOrigFolder==0
	{		 
		resParentFolder = getDirectory("Open Parent Folder of Extracted Images"); 
		resFolder = resParentFolder + File.separator ; 
	}
	
	if (matches(processMode, "SingleFile")) 
	{
		ProcessFile(file_name, directory, resFolder);
	}
	else if (matches(processMode, "WholeFolder")) 
	{
		ProcessFiles(directory, resFolder); 
	}
} 

// Exporting : "AllSubFolders" 
//=============================
else if (matches(processMode, "AllSubFolders")) 
{ 	
	list = getFileList(parentDirectory);
	for (i = 0; i < list.length; i++) 
	{
		if(File.isDirectory(parentDirectory + list[i])) 
		{
			subFolderName = list[i];
			subFolderName = substring(subFolderName, 0,lengthOf(subFolderName)-1);

			directory = parentDirectory + subFolderName + File.separator;			
			resFolder1 = resParentFolder + File.separator + subFolderName + File.separator; 
			resFolder = resFolder1 ; 
			if (matches(ResultsLocation, "InNewLocation")) {
				File.makeDirectory(resFolder1);  }
			
			print(parentDirectory, directory, resFolder);
			File.makeDirectory(resFolder);
			print("inDir=",directory," outDir=",resFolder);
			
			ProcessFiles(directory, resFolder);
			print("Processing ",subFolderName, " Done");
		}
	}
}

setBatchMode(false);
Ext.close();
Cleanup();
print("Done !");



// ===== End of Main Code =================================================================


// ===== Helper Functions =================================================================

//============================================================================================
// Export Images from A single File 
//============================================================================================
function ProcessFile(full_name, directory, resFolder)
{
	if (matches(SaveFormat, "ilastik hdf5"))
		outExt = ".h5";
	else if (matches(SaveFormat, "tif"))
		outExt = ".tif";
	
	// Create Out Folder
	file_name = File.getName(full_name);
	file_name_no_ext = replace(file_name, "."+fileExtension, "");
	if (matches(SaveFormat, "ilastik hdf5"))
		outFolderExt = "_h5";
	else if (matches(SaveFormat, "tif"))
		outFolderExt = "_Tif";
	else	
		outFolderExt = "";
	outFolder = resFolder + file_name_no_ext +outFolderExt + File.separator;
	File.makeDirectory(outFolder);

	Ext.setId(full_name);
	Ext.getSeriesCount(seriesCount);

	print(file_name_no_ext, " nSeries=", seriesCount);
	
	// Export Last series
	if (matches(ExportImages, "First"))
	{
		print("Opening first series from ", file_name);
		s=0; sNum = s+1;
		Ext.setSeries(s);
		Ext.getSeriesName(sName);
		run("Bio-Formats Importer", "open=["+full_name+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+d2s(sNum,0)); 
		ImToSave = getTitle();
		SaveSingleImage(ImToSave, outFolder, file_name_no_ext, sNum, sName, outExt);
	} else if (matches(ExportImages, "Last"))
	{
		print("Opening last series: # ",seriesCount, " from ", file_name);
		s=seriesCount-1; sNum = seriesCount;
		Ext.setSeries(s);
		Ext.getSeriesName(sName);
		run("Bio-Formats Importer", "open=["+full_name+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+d2s(sNum,0)); 
		ImToSave = getTitle();
		SaveSingleImage(ImToSave, outFolder, file_name_no_ext, sNum, sName, outExt);
	} else 
	{	
		n = 0;
		for (s=0; s<seriesCount; s++) 
		{
	  		sNum = s+1;
			Ext.setSeries(s);
			Ext.getSizeX(sizeX);
			Ext.getSizeY(sizeY);
			Ext.getSizeZ(sizeZ);
			Ext.getSizeC(sizeC);
			Ext.getSizeT(sizeT);
			Ext.getSeriesName(sName);
			//Ext.getSeriesMetadataValue("Image|Tile|FieldX", FieldX);
			//Ext.getSeriesMetadataValue("Image|Tile|FieldY", FieldY);
			//Ext.getSeriesMetadataValue("Image|Tile|PosX", PosX);
			//Ext.getSeriesMetadataValue("Image|Tile|PosY", PosY);
			//Ext.getPlanePositionX(positionX, 0);
			//Ext.getPlanePositionX(positionY, 0);

			if (matches(SaveFormat, "None-OnlyPrintInfo"))
				readFlag = 0;
			else 
			{
			  	readFlag = 1;
		  	  	if (UseSeriesNumberCriteria && ((sNum < CriteriaSeriesNumberMin) || (sNum > CriteriaSeriesNumberMax)) )
		  	  		readFlag = 0;
		  		if (UseChannelNumberCriteria && ((sizeC < CriteriaChannelNumberMin) || (sizeC > CriteriaChannelNumberMax)) )
					readFlag = 0;
				if (UseImageSizeCriteria && ( (sizeX != CriteriaImageSizeX) || (sizeY != CriteriaImageSizeY) || (sizeZ != CriteriaImageSizeZ)) )
		  			readFlag = 0;
				if (UseImageNameCriteria) {
					TextRegExp = ".*"+CriteriaImageNameText+".*";
					if (!matches(sName, TextRegExp))	  	
						readFlag = 0;
				}
			}
			print(s, "Series #" + sNum + ": name is "+ sName+" size is " + sizeX + "x" + sizeY + "x" + sizeZ + "x" + sizeC + "x" + sizeT + " readFlag=" + readFlag);			

		  	if (readFlag)
		  	{
				run("Bio-Formats Importer", "open=["+full_name+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_list="+d2s(sNum,0)); 			
				ImToSave = getTitle();
				
				if (matches(ProcType, "Stitch"))
				{
					rename("NextIm");
					if (n == 0)
						rename("Stack");
					else {
						run("Concatenate...", "  title=HyperStack open image1=Stack image2=NextIm image3=[-- None --]");
						rename("Stack");
					}
					n++;				
				}
				else
				{
					SaveSingleImage(ImToSave, outFolder, file_name_no_ext, sNum, sName, outExt);
				}
		  	}
	  		if (CleanupFlag) Cleanup();
	  		print(IJ.freeMemory());
		} // end of for s...
		if (matches(ProcType, "Stitch"))
		{
			outName = outFolder + file_name_no_ext + "_Stitched"+outExt;			
			selectImage("Stack");
			SaveSingleImage(ImToSave, outFolder, file_name_no_ext, sNum, Name, outExt);
		}
	}
} // End of ProcessFile

//============================================================================================
// Save single open Series after applying Proc if needed
//============================================================================================
function SaveSingleImage(ImToSave, outFolder, file_name_no_ext, sNum, Name, outExt)
{

	suffixStr = "";
	if (matches(ProcType, "MaxProject"))
	{
		//run("Make Composite");
		run("Z Project...", "projection=[Max Intensity]");		
		ImToSave = getTitle();
		suffixStr = "_MaxProject";
	}
	if (matches(ProcType, "Stitch"))
	{
		waitForUser("Record Stitch...");
	}

	outName = outFolder + file_name_no_ext + "_" + IJ.pad(sNum,SeriesNumPad) + "_" + sName + suffixStr + outExt;
	if (matches(SaveFormat, "ilastik hdf5"))
	{
		run("Export HDF5", "select=["+outName+"] exportpath=["+outName+"] datasetname=data compressionlevel=0 input=["+ImToSave+"]");
	} else if (matches(SaveFormat, "tif"))
		saveAs("tiff", outName);
}

//============================================================================================
// Loop on all files in a given folder and Run analysis on each of them
//============================================================================================
function ProcessFiles(directory, resFolder) {

	// Get the files in the folder 
	fileListArray = getFileList(directory);
	
	// Loop over files
	for (fileIndex = 0; fileIndex < lengthOf(fileListArray); fileIndex++) {
		if (endsWith(fileListArray[fileIndex], fileExtension)) {
			full_name = directory+fileListArray[fileIndex];
			
			print("processing:",fileListArray[fileIndex]);
			showProgress(fileIndex/lengthOf(fileListArray));
			ProcessFile(full_name, directory, resFolder);
			Cleanup();
		} // end of if endsWith
	} // end of for loop

} // end of ProcessFiles



//============================================================================================
// GetPrmsDialog: show GUI for parameter settings
//------------------------------------------------
function GetPrmsDialog()
{
	// Initialize choice variables
	ProcModeOptList = newArray("SingleFile","WholeFolder","AllSubFolders");
	ExportCriteriaOptList = newArray("All", "First", "Last");
	if (debugMode == 1)
		ProcTypeOptList = newArray("None", "MaxProject", "Stitch");
	else 
		ProcTypeOptList = newArray("None", "MaxProject"); // "Stitch" is not fully checked yet
	ResultsLocationOptList = newArray("UnderOrigFolder", "InNewLocation");
	SaveFormatOptList = newArray("tif", "ilastik hdf5", "None-OnlyPrintInfo");
	Question = newArray("Yes","No");
	
	// Choose image channels and threshold value
	Dialog.create("Export Images from Complex Microscopy File");
	Dialog.addChoice("Process Mode:  ", ProcModeOptList, processMode);
	Dialog.addString("File Extension:", fileExtension);
	Dialog.addChoice("Save images under the original folder or new location", ResultsLocationOptList, ResultsLocation);
	Dialog.addChoice("Save Format", SaveFormatOptList, SaveFormat);
	
	Dialog.addChoice("Process Type:  ", ProcTypeOptList, ProcType);

	Dialog.addChoice("Which Images to Export:  ", ExportCriteriaOptList, ExportImages);

	Dialog.addCheckbox("Export only Series Number: ", UseSeriesNumberCriteria);
	Dialog.addToSameRow(); 
	Dialog.addNumber("_  ",   CriteriaSeriesNumberMin, 0, 3, "");
	Dialog.addToSameRow(); 
	Dialog.addNumber("_- ", CriteriaSeriesNumberMax, 0, 3, "");

	Dialog.addCheckbox("Export only series with:", UseChannelNumberCriteria);
	Dialog.addToSameRow(); 
	Dialog.addNumber("_  ", CriteriaChannelNumberMin, 0, 1, "");
	Dialog.addToSameRow(); 
	Dialog.addNumber("_-", CriteriaChannelNumberMax, 0, 1, "Channels");

	Dialog.addCheckbox("Export only images of size ", UseImageSizeCriteria);	
	Dialog.addToSameRow(); 
	Dialog.addNumber("_  ",  CriteriaImageSizeX, 0, 5, "");
	Dialog.addToSameRow(); 
	Dialog.addNumber("_X", CriteriaImageSizeY, 0, 5, "");
	Dialog.addToSameRow(); 
	Dialog.addNumber("_X", CriteriaImageSizeZ, 0, 3, "Voxels");
	
	Dialog.addCheckbox("Export only Series whose name contain the Text: ", UseImageNameCriteria);
	Dialog.addToSameRow(); 
	Dialog.addString("_", CriteriaImageNameText, 12);
	Dialog.addCheckbox("Work in Batch Mode ?", BatchModeFlag);

	Dialog.show();

	// Feeding variables from dialog choices
	processMode = Dialog.getChoice();
	fileExtension = Dialog.getString();
	ResultsLocation = Dialog.getChoice();
	SaveFormat = Dialog.getChoice();
	ProcType = Dialog.getChoice();

	ExportImages = Dialog.getChoice();

	UseSeriesNumberCriteria = Dialog.getCheckbox();
	CriteriaSeriesNumberMin = Dialog.getNumber();
	CriteriaSeriesNumberMax = Dialog.getNumber();
	
	UseChannelNumberCriteria = Dialog.getCheckbox();
	CriteriaChannelNumberMin = Dialog.getNumber();
	CriteriaChannelNumberMax = Dialog.getNumber();
	
	UseImageSizeCriteria = Dialog.getCheckbox();
	CriteriaImageSizeX = Dialog.getNumber();
	CriteriaImageSizeY = Dialog.getNumber();
	CriteriaImageSizeZ = Dialog.getNumber();

	UseImageNameCriteria = Dialog.getCheckbox();
	CriteriaImageNameText = Dialog.getString();
	BatchModeFlag = Dialog.getCheckbox();
}

// ========================================================================================

// ShowAndSavePrms: show GUI for parameter settings
//------------------------------------------------
function ShowAndSavePrms(SaveFlag, OutFileName)
{
	print("\\Clear");
	print("Export Images from Complex Microscopy File:");
	print("===========================================");
	print("processMode=", processMode);
	print("fileExtension=", fileExtension);
	print("ResultsLocation=",ResultsLocation);
	print("ProcType=",ProcType);
	print("ExportImages=", ExportImages);

	print("UseSeriesNumberCriteria=",UseSeriesNumberCriteria);
	print("CriteriaSeriesNumberMin=",CriteriaSeriesNumberMin);
	print("CriteriaSeriesNumberMax=",CriteriaSeriesNumberMax);

	print("UseChannelNumberCriteria=",UseChannelNumberCriteria);
	print("CriteriaChannelNumberMin=",CriteriaChannelNumberMin);
	print("CriteriaChannelNumberMax=",CriteriaChannelNumberMax);

	print("UseImageSizeCriteria=",UseImageSizeCriteria);
	print("CriteriaImageSizeX=",CriteriaImageSizeX);
	print("CriteriaImageSizeY=",CriteriaImageSizeY);
	print("CriteriaImageSizeZ=",CriteriaImageSizeZ);

	print("UseImageNameCriteria=",UseImageNameCriteria);
	print("CriteriaImageNameText=",CriteriaImageNameText);

	print("BatchModeFlag=",BatchModeFlag);

	print("\n");	

	if (SaveFlag)
	{
		text = getInfo("Log");
		f = File.open(OutFileName);
		print(f, text);
		File.close(f);
	}
}

//============================================================================================
// Per File Cleanup
//============================================================================================
function Cleanup()
{
	run("Close All");
	run("Collect Garbage"); // to actually free all the memory taken by processing 
}


function Initialization()
{
	run("Close All");
	print("\\Clear");	
}
