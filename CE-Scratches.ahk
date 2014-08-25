;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Downloads and Parses Equibase XML into an Excel spreadsheet. Then reads the 'database' looking for coupled entry scratches.
; For Harness tracks, raw HTML is downloaded and parsed into Excel the same way from Racing Channel.
; 


;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
StartUp()
Version_Name = v0.10

;Dependencies
#Include %A_ScriptDir%\Functions
#Include json_obj


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;PREP AND STARTUP
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

HardCodedGlobals()
;###Invoke and set Global Variables
StartInternalGlobals()



;~~~~~~~~~~~~~~~~~~~~~
;GUI
;~~~~~~~~~~~~~~~~~~~~~
BuildGUI()
ShowGUI()


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;MAIN PROGRAM STARTS HERE
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

UpdateButton:
;Immediately disable all GUI buttons to prevent user from causing two Excel sheets from being made. 
DiableAllButtons()
;Clear the GUI Listview (Contains all found Coupled Entries)
LV_Delete()

;Import Existing Seen Horses DB File
Fn_ImportDBData()

;Switch comment here for live or testing
;Download XML of all TB Track Changes
GetNewXML()
;UseExistingXML()


;###Read XML previously downloaded to FILECONTENTS Var
FileRead, FileContents, %A_ScriptDir%\data\temp\XML.txt


;###Invoke and set Global Variables
StartInternalGlobals()

;~~~~~~~~~~~~~~~~~~~~~
;Excel
;~~~~~~~~~~~~~~~~~~~~~
oExcel := ComObjCreate("Excel.Application") ; create Excel Application object
oExcel.Workbooks.Add ; create a new workbook (oWorkbook := oExcel.Workbooks.Add)
oExcel.Visible := false ; make Excel Application invisible
;oExcel.Worksheets("Sheet2").Delete

;###Read XML previously downloaded to FILECONTENTS Var
FileRead, FileContents, %A_ScriptDir%\data\temp\XML.txt

;###Clean XML so that is can be read one line at a time
ReturnReplace("race_number")
ReturnReplace("race_changes")
ReturnReplace("track_name")
ReturnReplace("Coupled Type")
ReturnReplace("program_number")
ReturnReplace("horse_name")
ReturnReplace("Scratched")
ReturnReplace("new_value")
ReturnReplace("/old_value")
ReturnReplace("<change>")
JustReplace("</change_description><old_value>"," ")

	FileAppend,
	(
	%FileContents%
	), %A_ScriptDir%\data\temp\ConvertedXML.txt
FileContents = ;Free the memory after being written to file.

	;###This does nothing but count the number of lines to be used in progress bar calculations
	Loop, read, %A_ScriptDir%\data\temp\ConvertedXML.txt
	{
	TotalTXTLines += 1
	}
	
	
	;###Read Each line of Converted XML. Valued Information is extracted and thrown into the WriteToExcel function.
	;THIS NEEDS TO BE RE-WRITTEN USING REGULAR EXPRESSIONS
	Loop, read, %A_ScriptDir%\data\temp\ConvertedXML.txt
	{

ReadLine = %A_LoopReadLine%

CleanXML("track_name","TN",12,31)
CleanXML("race_number","RN",13,3)
CleanXML("Coupled Type","COUPLED",44,1)
CleanXML("program_number","PN",16,2)
CleanXML("horse_name","HN",12,2)
CleanXML("Scratched N","SC",0,3)
CleanXML("new_value>N<","UNSCRATCH",0,0)
WriteTBtoExcel()


	TotalWrittentoExcel += 1
	vProgressBar := 100 * (TotalWrittentoExcel / TotalTXTLines)
	GuiControl,, UpdateProgress, %vProgressBar%
	}
	


;### Look through Excel and send scratched CE to Listview for User to see
ReadExceltoListview()


;Modify Race Column to fit whole title (4th column, 40 pixels/units)
LV_ModifyCol(3)
LV_ModifyCol(4, 40)

;### Show number of effected Races so user knows if there is a new change.
Gui, Tab, Scratches
guicontrol, Text, GUI_EffectedEntries, % "Effected Entries: " . EffectedEntries

;###Close Excel Database
;http://msdn.microsoft.com/en-us/library/aa215515
oExcel.ActiveWorkbook.saved := true
CreateArchiveDir() ;this function just makes the archive directory
path = \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\TB_%CurrentDate%
oExcel.ActiveWorkbook.SaveAs(path) ;disable for testing on XP
oExcel.ActiveWorkbook.saved := true
oExcel.Quit

;Export Array as a JSON file
Fn_ExportArray()


EnableAllButtons()
Return


;~~~~~~~~~~~~~~~~~~~~~
;Check Harness Tracks
;~~~~~~~~~~~~~~~~~~~~~
; This is basically the same instructions as TB but its a little outdated as it was just copy-pasted. Working on a way to merge Excel reading as one function
; Main problem is that Harness HMTL does not always include the other parts of a Coupled Entry; so it is fundimentally different in that way.
CheckHarness:
DiableAllButtons()
LV_Delete()
StartInternalGlobals()
FileDelete, \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\HN_%CurrentDate%.xlsx
DownloadAllHarnessTracks()
oExcel := ComObjCreate("Excel.Application") ; create Excel Application object
oExcel.Workbooks.Add ; create a new workbook (oWorkbook := oExcel.Workbooks.Add)
oExcel.Visible := false ; make Excel Application invisible

	
	;Read Each Track's HTML
	Loop, %A_ScriptDir%\data\temp\tracksrawhtml\*_H.txt
	{	
		;Read each line in the HTML looking for "part of entry"
		Loop, read, %A_ScriptDir%\data\temp\tracksrawhtml\%A_LoopFileName%
		{
		ReadLine = %A_LoopReadLine%
		CleanXML("<TITLE>","TN",8,16)
		CleanXML("<TD WIDTH=+150+><B><U>","RN",23,13)
		CleanXML("part of entry","COUPLED",1,1)
		CleanXML("<TD WIDTH=+20+><B>","PN",19,9)
		CleanXML("<TD ALIGN=+LEFT+ WIDTH=+150+><B>","HN",33,9)
		CleanXML("<TD ALIGN=+LEFT+ WIDTH=+250+>","SC",39,5)
		WriteHNtoExcel()
		}
	}

;Excel is finished, read it to the GUI ListView
ReadExceltoListview_HN()

;Save and close Excel
path = %A_ScriptDir%\data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\HN_%CurrentDate%
oExcel.ActiveWorkbook.SaveAs(path)
oExcel.ActiveWorkbook.saved := true
oExcel.Quit
EnableAllButtons()
Return


$F1::
reload
Return

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; FUNCTIONS
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

HardCodedGlobals()
{
global

RaceNumber = 0
;Ignore any entry over this number, example: don't look for Entry 9 or 9A. An attempt to make program run faster. Should be set to 4 or 5 at some point
Ignored_CE = 9

SeenHorses_Array := {HorseName:"", ScratchStatus:""}
SeenHorses_ArraX := 0
return
}



ReadExceltoListview()
{
global

ExcelSheet_Top = 3
ExcelPointerX = 2
Scratch_Counter = 0
Blank_Counter = 0
FirstHorse_Toggle = 1
SheetSelect = 1
CE_FirstFound = 0
CE_Arr := [[x],[y]]
ArrX = 0
ReRead = 0

;DEPRECIATED Find Total Horses for iterations for excel checking. TrackCounter is added since it will read a blank line for every track.
;DEPRECIATED TotalExcelIterations := (TrackCounter + HorseCounter)

	While (SheetSelect <= TrackCounter)
	{		
		
		If (SheetSelect <= TrackCounter && ReRead != 1)
		{
		ExcelPointerX += 1
		Number := oExcel.Sheets("T" . SheetSelect).Range("A" . ExcelPointerX).Value ;Number
		Name := oExcel.Sheets("T" . SheetSelect).Range("B" . ExcelPointerX).Value ;Name
		Status := oExcel.Sheets("T" . SheetSelect).Range("E" . ExcelPointerX).Value ;Status
		Race := oExcel.Sheets("T" . SheetSelect).Range("H" . ExcelPointerX).Value ;Race
		}
	ReRead = 0

	ExcelReadAgain:
	;Ok this exists to save the next horse found after all of a CE has been detected
	; I mean, since the loop doesn't detect the end of a CE list until a different program number is found, we need to go here
	; when a new horse is found and triggers the CE output, but not loose that new horse which might be a 2 with a 2B coming next
		
		;discard this horse because we don't care about anything over 9, unless there was a race with 9+ CE but that should never happen. Eventually work down to 4 or 5
		If (Number > Ignored_CE)
		{
		Continue
		}
		IfInString, Race, .0000
		{
		StringTrimRight, Race, Race, 7
		}
		IfInString, Number, .0000
		{
		StringTrimRight, Number, Number, 7
		}
		
		;End of Track Reached, Turn Page~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		;This is highest because we don't want things getting confused with "" matching "" for a coupled entry
		;We also can't go to the next page immediately because we need to check if there is some CE array to output
		If (Number = "")
		{
		Blank_Counter += 1
			If (Blank_Counter >= 2)
			{
			SheetSelect += 1
			ExcelPointerX = 2 ;Always adds +1 at top of loop, so will select 3rd row immediately.
			CE_FirstFound = 0 ;Set next track to have found no Coupled Entries
			Blank_Counter = 0
			;FirstHorse_Toggle = 1
			Continue
			}
		}
		
		
		
		;FIRST HORSE GOING INTO ARRAY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		If (FirstHorse_Toggle = 1 && Name != "")
		{
			If (ArrX >= 2) 
			{
			WriteTrackToListView()
			FirstHorse_Toggle = 1
			CE_Arr := [[x],[y]]
			ArrX := 0
			Scratch_Counter = 0
			ReRead = 1
			Continue
			}
		ArrX = 1 ; switch to += if needed
		CE_Arr[ArrX,1] := Number
		CE_Arr[ArrX,3] := Name
		CE_Arr[ArrX,2] := Status
		CE_Arr[ArrX,4] := Race
		CE_Race_Found = %Race%
		FirstHorseProgramNumber = %Number%
		Current_Race = %Race%
		FirstHorse_Toggle = 0
		Scratch_Counter = 0 ;might be a better place for this
		ScratchCheck()
		Continue
		}
		
		
		;2nd HORSE FOUND!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		IfInString, Number, %FirstHorseProgramNumber%
		{
			If (Current_Race = Race)
			{
			ArrX += 1
			CE_Arr[ArrX,1] := Number
			CE_Arr[ArrX,3] := Name
			CE_Arr[ArrX,2] := Status
			CE_Arr[ArrX,4] := Race
			ScratchCheck()
			Continue
			}
		
		}
		;DEPRECIATED - I don't remember
		;If (InStr(Number, FirstHorseProgramNumber) && CE_Race_Found = %Race%)
		
		
		
		
		;ALL ELSE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			If (ArrX >= 2) ; && Name != "")
			{
			EffectedEntries += 1
			WriteTrackToListView()
			FirstHorse_Toggle = 1
			CE_Arr := [[x],[y]]
			ArrX := 0
			Scratch_Counter = 0
			ReRead = 1
			Continue
			}
		FirstHorse_Toggle = 1
		Scratch_Counter = 0
		CE_Arr := [[x],[y]]
		ArrX := 0
		ReRead = 1
		Continue

	}

}



ReadExceltoListview_HN()
{
global

ExcelSheet_Top = 3
ExcelPointerX = 3
SheetSelect = 1
CE_FirstFound = 0

;Find Total Horses for iterations for excel checking. TrackCounter is added since it will read a blank line for every track.
TotalExcelIterations := (TrackCounter + HorseCounter)

	Loop, %TotalExcelIterations%
	{
	
	
	Buffer_Number := oExcel.Sheets("T" . SheetSelect).Range("A" . ExcelPointerX).Value
	Buffer_Name := oExcel.Sheets("T" . SheetSelect).Range("B" . ExcelPointerX).Value
	Buffer_Status := oExcel.Sheets("T" . SheetSelect).Range("E" . ExcelPointerX).Value
	Buffer_Race := oExcel.Sheets("T" . SheetSelect).Range("H" . ExcelPointerX).Value
	
		IfInString, Buffer_Race, .0000
		{
		StringTrimRight, Buffer_Race, Buffer_Race, 7
		}
		
		If (InStr(Buffer_Status, "part"))
		{
		;Msgbox, CE found!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		CE_FirstFound += 1
			If (CE_FirstFound = 1)
			{
			LV_AddBlank()
				If (EffectedEntries = 0)
				{
				LV_Delete(1)
				}
			LV_AddTrack()
			CE_FoundRace = %Buffer_Race%
			}
			If (CE_FoundRace != %Buffer_Race%)
			{
			LV_AddRace()
			CE_FoundRace = %Buffer_Race%
			}
		LV_Add("", Buffer_Number, Buffer_Status, Buffer_Name, Buffer_Race)
		EffectedEntries += 1
		ShowGUI()

		LV_ModifyCol()
		ExcelPointerX += 1
		}
		
		
		;if blank excel cell is encountered, move to next sheet
		If Buffer_Number = 
		{
		SheetSelect += 1
		ExcelPointerX = 2 ;Always adds +1 at top of loop, so will select 3rd row immediately.
		CE_FirstFound = 0
		}
		
	;Done, move to next line.
	ExcelPointerX += 1
	}

}




WriteTrackToListView()
{
global

CE_FirstFound += 1
;Create a blank line to separate tracks a little, add more LV_AddBlank() if larger gap is needed
	If (CE_FirstFound = 1)
	{
	LV_AddBlank()
	;Delete Blank Line if this is the first line of the entire program
		If (EffectedEntries= 1)
		{
		LV_Delete(1)
		}
	LV_AddTrack()
	CE_FoundRace = %Race%
	}
	

	;This helps determine if a new RACE LV needs to be added in the case of a 2nd CE program number
	If (CE_FoundRace != %Race%)
	{
	LV_AddRace()
	CE_FoundRace = %Race%
	}

ReadArrayToListView()
}



ReadArrayToListView()
{
global
		
	x = 0
	
	;First just tell user if there are any relivended horses
	Loop % CE_Arr.MaxIndex()
	{
		If Instr(CE_Arr[A_Index,2],"UN")
		{
		Msgbox % CE_Arr[A_Index,1] . " " . CE_Arr[A_Index,3] . " in Race " . CE_Arr[A_Index,4] . " of " . Buffer_TrackName . " has been Re-livened!"
		}
	}
	
	
	
	Loop % CE_Arr.MaxIndex()
	{
	x += 1
	This_HorseName := CE_Arr[x,3]
		Loop % SeenHorses_Array.MaxIndex()
		{
			;mSGBOX % SeenHorses_Array[A_Index,"HorseName"] . "      " . This_HorseName
			If (SeenHorses_Array[A_Index,"HorseName"] = This_HorseName)
			{
			;End this function if horsename is in the list of seen horses
			Return
			}
		}
		
	;DEPRECIATED - Just write out the Array without assigning values to buffer variables. This is left as a note for what each array value holds
	;Buffer_Number := CE_Arr[x,1]
	;Buffer_Name := CE_Arr[x,2]
	;Buffer_Status := CE_Arr[x,3]
	;Buffer_Race := CE_Arr[x,4]
	
	;Found Coupled Entries are stored into this Array, write them out to the GUI Listview
	LV_Add("", CE_Arr[x,1], CE_Arr[x,2], CE_Arr[x,3], CE_Arr[x,4])
	LV_ModifyCol()
	}

}


ScratchCheck()
{
global

	If Status = "Scratched"
	{
	;increase scratch counter
	Scratch_Counter += 1
	}
}



LV_AddBlank()
{
LV_Add("", "", "", "", "")
}

LV_AddTrack()
{
global

Buffer_TrackName := oExcel.Sheets("T" . SheetSelect).Range("A" . 1).Value
LV_Add("", "", "", Buffer_TrackName, "")
}

LV_AddRace()
{
global

Buffer_RaceNumber := CE_Arr[1,4]
Buffer_RaceLV := "Race " . Buffer_RaceNumber
;StringTrimRight, Buffer_RaceLV, Buffer_RaceLV, 7
LV_Add("", "", "", Buffer_RaceLV, "")
}


;This needs an overhaul after converting to Regular Expressions, also needs to be structured as more flexible parameter function
WriteTBtoExcel()
{
global

	If Linetarget = TN
	{
	TrackCounter += 1
	oExcel.Worksheets.Add
	TrackCounter2 := "T" . TrackCounter
	oExcel.ActiveSheet.Name := TrackCounter2
	ExcelPointerX = 1
	oExcel.Range("A" . ExcelPointerX).Value := Stringy
	oExcel.Range("G" . ExcelPointerX).Value := TrackCounter
	ExcelPointerX +=1
	}
	if Linetarget = RN
	{
	RaceNumber = %Stringy%
	}
	if Linetarget = PN ;&& Stringy <= %InterestNumber_Limit%  ;Another good place to reduce runtime by skipping Ignored_CE excel writing
	{
	oExcel.Range("A" . ExcelPointerX).Value := Stringy
		If InStr(Stringy, "A") || InStr(Stringy, "B") || InStr(Stringy, "C") || InStr(Stringy, "X")
		{
		oExcel.Range("A" . ExcelPointerX . ":" . "E" . (ExcelPointerX - 1)).Interior.ColorIndex := 3 ; fill range of cell color number 3
		}
	}
	if Linetarget = HN
	{
	ExcelPointerX += 1
	HorseCounter += 1
	oExcel.Range("B" . ExcelPointerX).Value := Stringy
	oExcel.Range("H" . ExcelPointerX).Value := RaceNumber
	}
	if Linetarget = SC
	{
	oExcel.Range("E" . ExcelPointerX).Value := "Scratched"
	}
	if Linetarget = UNSCRATCH
	{
	oExcel.Range("E" . ExcelPointerX).Value := "UNSCRATCHED"
	}

}

;Same Story here, looks more like a subroutine then a function, make this a priority
WriteHNtoExcel()
{
global

	If Linetarget = TN
	{
	TrackCounter += 1
	oExcel.Worksheets.Add
	TrackCounter2 := "T" . TrackCounter
	oExcel.ActiveSheet.Name := TrackCounter2
	ExcelPointerX = 1
	oExcel.Range("A" . ExcelPointerX).Value := Stringy
	oExcel.Range("G" . ExcelPointerX).Value := TrackCounter
	ExcelPointerX +=1
	}
	if Linetarget = RN
	{
	RaceNumber = %Stringy%
	}
	if Linetarget = PN ;&& Stringy <= %InterestNumber_Limit%
	{
	ExcelPointerX += 1
	oExcel.Range("A" . ExcelPointerX).Value := Stringy
		;IfInString, Stringy, A ;|| IfInString, Stringy, B || IfInString, Stringy, C || IfInString, Stringy, X
		If InStr(Stringy, "A") || InStr(Stringy, "B") || InStr(Stringy, "C") || InStr(Stringy, "X")
		{
		oExcel.Range("A" . ExcelPointerX . ":" . "E" . (ExcelPointerX - 1)).Interior.ColorIndex := 3 ; fill range of cell color number 3
		}
	}
	if Linetarget = HN
	{
	HorseCounter += 1
	oExcel.Range("B" . ExcelPointerX).Value := Stringy
	oExcel.Range("H" . ExcelPointerX).Value := RaceNumber
	}
	if Linetarget = SC
	{
	oExcel.Range("E" . ExcelPointerX).Value := Stringy
	}
	if Linetarget = COUPLED
	{
	oExcel.Range("F" . ExcelPointerX).Value := Stringy
	}
	Stringy = ;Empty Variable
	Linetarget = ;Empty Variable
}


;This function exists only becuase I didn't know how to use Regular Expressions. Should be depreciated asap
CleanXML(TargetWord,Label,TrimLeft,TrimRight)
{
global

ValueLine := 0

; NO STOP PUTTING THIS IN HERE IT WILL BREAK EVERYTHING AS THIS IS RUN MULTIPLES TIMES EACH LINE
; Linetarget = alf
; NO

		IfInString, A_LoopReadLine, %TargetWord%
		{
		Linetarget = %Label%
		StringTrimRight, Stringy, A_LoopReadLine, %TrimRight%
		StringTrimLeft, Stringy, Stringy, %TrimLeft%
		ValueLine = 1
		}
}




JustReplace(Old,New)
{
global

; Replace all spaces with pluses:
StringReplace, FileContents, FileContents, %Old%, %New%, All
}



ReturnReplace(Word)
{
global

; Replace all spaces with pluses:
StringReplace, FileContents, FileContents, %Word%,`n%Word%, All
}




GetNewXML()
{
global

FileRemoveDir, %A_ScriptDir%\data\temp , 1
FileCreateDir, %A_ScriptDir%\data\temp
FileCreateDir, %A_ScriptDir%\data\temp\tracksrawhtml
FileDelete, %A_ScriptDir%\data\temp\ConvertedXML.txt
UrlDownloadToFile, http://www.equibase.com/premium/eqbLateChangeXMLDownload.cfm, %A_ScriptDir%\data\temp\XML.txt
;Copy to Archive
FileCopy %A_ScriptDir%\data\temp\XML.txt, %A_ScriptDir%\data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\XML_%CurrentDate%.txt, 1
}

UseExistingXML()
{
global

FileDelete, %A_ScriptDir%\data\temp\ConvertedXML.txt
FileSelectFile, XMLPath
FileCreateDir, %A_ScriptDir%\data\temp\
FileCopy, %XMLPath%, %A_ScriptDir%\data\temp\XML.txt, 1
}


CreateArchiveDir()
{
global

;CurrentDate = %A_Now%
FormatTime, CurrentDate,, MMddyy
FormatTime, CurrentYear,, yyyy
FormatTime, CurrentMonth,, MMMM
FormatTime, CurrentDay,, dd

FileCreateDir, %A_ScriptDir%\data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\
FileDelete, \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\\data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\TB_%CurrentDate%.xlsx
}


;Imports Existing Seen Horses DB File
Fn_ImportDBData()
{
global
FormatTime, A_Today, , yyyyMMdd
FileRead, MemoryFile, \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\data\archive\DBs\%A_Today%_%Version_Name%DB.json
SeenHorses_Array := Fn_JSONtooOBJ(MemoryFile)
MemoryFile := ;Blank
}


;Export Array as a JSON file
Fn_ExportArray()
{
global
MemoryFile := Fn_JSONfromOBJ(SeenHorses_Array)
FileDelete, \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\data\archive\DBs\%A_Today%_%Version_Name%DB.json
FileAppend, %MemoryFile%, \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\data\archive\DBs\%A_Today%_%Version_Name%DB.json
MemoryFile := ;Blank
}


Fn_DeleteDB()
{
global
FileDelete, \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\data\archive\DBs\%A_Today%_%Version_Name%DB.json
}


DownloadAllHarnessTracks()
{
UrlDownloadToFile, http://tote.racingchannel.com/MEN----H.PHP, %A_ScriptDir%\data\temp\tracksrawhtml\1Main.txt
	Loop, read, %A_ScriptDir%\data\temp\tracksrawhtml\1Main.txt
	{
		If (InStr(A_LoopReadLine, "Changes"))
		{
		;Linetarget = %Label%
		StringTrimRight, TrackUrl, A_LoopReadLine, 52
		StringTrimLeft, TrackUrl, TrackUrl, 13
		StringTrimRight, TrackCode, TrackUrl, 6
		StringTrimLeft, TrackCode, TrackCode, 3
		;ValueLine = 1
		
		TrackToDownload := "http://tote.racingchannel.com/" . TrackUrl
		;http://tote.racingchannel.com/CHGMAY-C.PHP
		UrlDownloadToFile, %TrackToDownload%, %A_ScriptDir%\data\temp\tracksrawhtml\%TrackCode%.txt
		
		
		FileRead, FileContents, %A_ScriptDir%\data\temp\tracksrawhtml\%TrackCode%.txt

		;###Clean quotes out of HTML so that is can be read more accurately.
		StringReplace, FileContents, FileContents,",+, All
		;";Comment
		
		FileAppend,
		(
		%FileContents%
		), %A_ScriptDir%\data\temp\tracksrawhtml\%TrackCode%_H.txt
		FileContents = ;Free the memory after being written to file.
		}
		
	}

}

DownloadAllTracksHTML_DEPRECIATED()
{
global

	Loop, read, %A_ScriptDir%\data\StartingTracks.txt,
	{
	UrlDownloadToFile, http://www.equibase.com/static/latechanges/html/latechanges%A_LoopReadLine%.html, %A_ScriptDir%\data\temp\tracksrawhtml\%A_LoopReadLine%.txt
	}
	
}

ReadTrackFiles()
{
global

Needle = www.equibase.com/profiles/Results


	Loop, %A_ScriptDir%\data\temp\tracksrawhtml\*.txt
	{
	Filepath = %A_LoopFileFullPath%
	TrackFile = %A_LoopField%
	;Msgbox, Loopfield is with txt? %A_LoopField% %A_LoopFileFullPath%
		Loop, read, %A_LoopFileFullPath%,
		{
			IfInString, A_LoopReadLine, %Needle%
			{
			;Msgbox, %A_LoopReadLine%
			StringTrimRight, TrackName, A_LoopReadLine, 32
			StringTrimLeft, TrackName, TrackName, 119
			Msgbox, Trackname is %TrackName%
			}
		
		}
	}
}


;~~~~~~~~~~~~~~~~~~~~~
; Variables
;~~~~~~~~~~~~~~~~~~~~~

StartUp()
{
#NoEnv
#NoTrayIcon
#SingleInstance force
#MaxThreads 1
}

StartInternalGlobals()
{
global

FinalTrack := 0
FinalRace := 0
FinalCouple := 0
FinalNumber := 0
FinalHorse := 0
FinalScratched := 0
Linetarget := 0
WriteNext := 0
EffectedEntries = 0
ScratchCounter := 0
ExcelPointerX := 1
ExcelPointerY := A
TrackCounter := 0
Buffer_Number := 0
Buffer_Race := 0
Buffer_Name := 0
Buffer_Status := 0
HorseCounter := 0
TotalTXTLines := 0
TotalWrittentoExcel := 0
;SetTimer, ProgressBarTimer, 250
}



;~~~~~~~~~~~~~~~~~~~~~
; Temp Controls
;~~~~~~~~~~~~~~~~~~~~~
F9::
Pause
return


;~~~~~~~~~~~~~~~~~~~~~
;Buttons
;~~~~~~~~~~~~~~~~~~~~~

ShiftNotes:
Today:= %A_Now%
FormatTime, CurrentDateTime,, MMddyy
Run \\tvgops\pdxshares\wagerops\Daily Shift Notes\%CurrentDateTime%.xlsx
Return



;~~~~~~~~~~~~~~~~~~~~~
;GUI
;~~~~~~~~~~~~~~~~~~~~~


BuildGUI()
{
Global

Gui, Add, Tab, x2 y0 w630 h700 , Scratches|Options
Gui, Tab, Scratches
Gui, Add, Button, x2 y30 w100 h30 gUpdateButton, Update
Gui, Add, Button, x102 y30 w100 h30 gCheckHarness, Check Harness Tracks
Gui, Add, Button, x202 y30 w100 h30 gShiftNotes, Open Shift Notes
Gui, Add, Button, x302 y30 w50 h30 gResetDB, Reset DB
Gui, Add, Text, x360 y40 w200 vGUI_EffectedEntries, Effected Entries:
Gui, Add, ListView, x2 y70 w490 h556 Grid NoSortHdr gDoubleClick, #|Status|Name|Race
Gui, Add, Progress, x2 y60 w100 h10 vUpdateProgress, 1
Gui, Add, Text, x462 y3 +Right, %Version_Name%
Gui, Tab, Options
;Gui, Add, ListView, x2 y70 w490 h580 Grid Checked, #|Status|Name|Race

Gui, Show, x130 y90 h622 w490, Scratch Detector
Return
}

DoubleClick:
If A_GuiEvent = DoubleClick
{
;Load any existing DB from other Ops
Fn_ImportDBData()

    LV_GetText(RowText, A_EventInfo, 3)  ; Get the text from the row's first field.
    ;Msgbox, You double-clicked row number %A_EventInfo%. Text: "%RowText%"
	X2 := SeenHorses_Array.MaxIndex()
	X2 += 1
	SeenHorses_Array[X2,"HorseName"] := RowText
	Fn_ExportArray()
}
Return


ResetDB:
Fn_DeleteDB()
Return


DiableAllButtons()
{
GuiControl, disable, Update
GuiControl, disable, Check Harness Tracks
GuiControl, disable, Open Shift Notes
}


EnableAllButtons()
{
GuiControl, enable, Update
GuiControl, enable, Check Harness Tracks
GuiControl, enable, Open Shift Notes
}


ShowGUI()
{
global

Gui, Show
}


EndGUI()
{
global

Gui, Destroy
}

GuiClose:
oExcel.ActiveWorkbook.saved := true
oExcel.Quit
ExitApp

;~~~~~~~~~~~~~~~~~~~~~
;Timers
;~~~~~~~~~~~~~~~~~~~~~
ProgressBarTimer:
SetTimer, ProgressBarTimer, -250
GuiControl,, UpdateProgress, %vProgressBar%
Return