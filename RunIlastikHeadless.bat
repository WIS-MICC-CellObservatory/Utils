:: RunIlastikHeadless.bat
:: 
:: Run Ilastik Pixel Classifier followed by Ilastik boundary based segmentation on all files in a given folder
:: 
:: Usage:  RunIlastikHeadless INPUT_PATH
::
:: Author: Ofra Golani, MICC Cell Observatory, Weizmann Institute of Science
::

@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

:: Setting parameters
set PATH_TO_ILASTIK="C:\Program Files\ilastik-1.3.3post3\ilastik.exe"
set PIXEL_CLASSIFIER="E:\Test\Classifiers\PixelClassifier_v1.ilp"
set MULTICUT_CLASSIFIER="E:\Test\Classifiers\Multicut_v1post1.ilp"
rem set OUTPUT_FILENAME_FORMAT="{dataset_dir}/{nickname}_{result_type}.h5"
set OUTPUT_FILENAME_FORMAT="{dataset_dir}/results/{nickname}_{result_type}.h5"
set DEFAULT_FILE_EXTENSION="*.h5"

set me=%~n0
set parent=%~dp0
set INPUT_PATH=%~1
set FILE_EXTENSION=%~2

IF "%INPUT_PATH%"=="" (
	ECHO Usage: %me% InputFolder [Extension]
	EXIT /B 1
)
IF NOT EXIST "%INPUT_PATH%" (
    ECHO %me%: file not found - %INPUT_PATH% >&2
    EXIT /B 1
)

IF NOT EXIST "%INPUT_PATH%\results" ( mkdir %INPUT_PATH%\results )

IF "%FILE_EXTENSION%"=="" (	set FILE_EXTENSION=%DEFAULT_FILE_EXTENSION% )

FOR %%I IN (%INPUT_PATH%\%FILE_EXTENSION%) DO (
	@ECHO Processing %%I 
	
	call %PATH_TO_ILASTIK% --headless --project="%PIXEL_CLASSIFIER%" --export_source="Probabilities" --output_format=hdf5 --output_filename_format=%OUTPUT_FILENAME_FORMAT% "%%I"
	call %PATH_TO_ILASTIK% --headless --project=%MULTICUT_CLASSIFIER% --raw_data="%%I" --probabilities=%INPUT_PATH%\results\\"%%~nI"_Probabilities.h5 --export_source="Multicut Segmentation" --output_format=hdf5 --output_filename_format=%OUTPUT_FILENAME_FORMAT%
	
)

@ECHO ON
