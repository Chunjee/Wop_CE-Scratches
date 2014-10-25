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
Version_Name = v0.24.1

;Dependencies
#Include %A_ScriptDir%\Functions
#Include sort_arrays
#Include json_obj
;#Include LVA (Listed under Functions)

;For Debug Only
#Include util_arrays

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;PREP AND STARTUP
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Sb_GlobalNameSpace()
;###Invoke and set Global Variables
StartInternalGlobals()

;~~~~~~~~~~~~~~~~~~~~~
;GUI
;~~~~~~~~~~~~~~~~~~~~~
BuildGUI()
LVA_ListViewAdd("GUI_Listview")

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;MAIN PROGRAM STARTS HERE
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
	If (0)
	{
	SetTimer, UpdateButton, %Option_Refresh%
	}

UpdateButton:
;Immediately disable all GUI buttons to prevent user from causing two Excel sheets from being made. 
DiableAllButtons()
Fn_GUI_UpdateProgress(1)
;Clear the GUI Listview (Contains all found Coupled Entries) and AllHorses Array\
LVA_EraseAllCells("GUI_Listview")
LV_Delete()
LVA_Refresh("GUI_Listview")
AllHorses_Array := []
Current_Track := ""
;Invoke and set Global Variables
StartInternalGlobals()


;Import Existing Seen Horses DB File
Fn_ImportDBData()

;Switch comment here for live or testing
;Download XML of all TB Track Changes
GetNewXML("Today_XML.xml")
;UseExistingXML()

;Get Harness Track Data
Sb_DownloadAllRacingChannel()



; Move Equibase's xml to Archive
TodaysFile = %A_ScriptDir%\data\temp\*.xml
Fn_CreateArchiveDir(TodaysFile) ;This function archives the supplied argument/file and also returns the path of the archive parent folder


;Read XML previously downloaded to File_TB_XML Var
FileRead, File_TB_XML, %A_ScriptDir%\data\temp\Today_XML.xml
StringReplace, File_TB_XML, File_TB_XML, `<,`n`<, All
FileAppend, %File_TB_XML%, %A_ScriptDir%\data\temp\ConvertedXML.txt
File_TB_XML = ;Free the memory after being written to file.


										;This counts the number of lines to be used in progress bar calculations and compiles all of RacingChannels HTML to a single file
										The_EquibaseTotalTXTLines := 0
										Loop, read, %A_ScriptDir%\data\temp\ConvertedXML.txt
										{
										The_EquibaseTotalTXTLines += 1
										}

										The_RCTotalTXTLines := 0
										TodaysFile_RC = %A_ScriptDir%\data\temp\RacingChannelHTML.html
										Loop, %A_ScriptDir%\data\temp\RacingChannel\*.*, 0, 1 ;Recurse into all subfolders (TBred and Harness)
										{
										FileRead, MemoryFile, %A_LoopFileFullPath%
										FileAppend, %MemoryFile%, %TodaysFile_RC%
											Loop, Read, %A_LoopFileFullPath%
											{
											The_RCTotalTXTLines += 1
											}
										}
										Fn_CreateArchiveDir(TodaysFile_RC)

	;Read Each line of Converted XML. Valued Information is extracted put into an array
	;THIS NEEDS TO BE RE-WRITTEN USING REGULAR EXPRESSIONS
	Loop, Read, %A_ScriptDir%\data\temp\ConvertedXML.txt
	{
	
	ReadLine := A_LoopReadLine
	
		REG = horse_name="(.*)"\s
		RegexMatch(ReadLine, REG, RE_HorseName)
		If (RE_HorseName1 != "")
		{
		The_HorseName := RE_HorseName1
		}
		
		REG = track_name="(.*)" id
		RegexMatch(ReadLine, REG, RE_TrackName)
		If (RE_TrackName1 != "")
		{
		The_TrackName := RE_TrackName1
		}
		
		REG = race_number="(.*)">
		RegexMatch(ReadLine, REG, RE_RaceNumber)
		If (RE_RaceNumber1 != "")
		{
		The_RaceNumber := RE_RaceNumber1
		}
		
		REG = \sprogram_number="(.*)">
		RegexMatch(ReadLine, REG, RE_ProgramNumber)
		If (RE_ProgramNumber1 != "")
		{
		The_ProgramNumber := RE_ProgramNumber1
		The_EntryNumber := Fn_ConvertEntryNumber(RE_ProgramNumber1)
		The_EntryNumber := The_RaceNumber * 1000 + The_EntryNumber
		}
		
		REG = <change_description>(\w+)
		RegexMatch(ReadLine, REG, RE_Scratch)
		If (RE_Scratch1 = "Scratched")
		{
		The_ScratchGate := 1
		}
		If (RE_Scratch1 = "First")
		{
		The_ScratchGate := 0
		}
		
		REG = <new_value>(Y)
		RegexMatch(ReadLine, REG, RE_Scratch)
		If (RE_Scratch1 != "")
		{
			If (The_ScratchGate = 1)
			{
			The_ScratchStatus := 1
			}
		}
		
		REG = <new_value>(N)
		RegexMatch(ReadLine, REG, RE_Scratch)
		If (RE_Scratch1 != "")
		{ ;In this case changing to a new_value of 'No' would mean the runner has been livened
		The_ScratchStatus := 9
		}
		
		REG = (<\/horse>)
		RegexMatch(ReadLine, REG, RE_Change)
		If (RE_Change1 != "")
		{
		Fn_InsertHorseData()
		The_HorseName := ""
		The_ScratchStatus := 0
		The_EntryNumber := ""
		The_ProgramNumber := ""
		The_ScratchGate := 0
		}


	;TotalWrittentoExcel += 1
	;vProgressBar := 100 * (TotalWrittentoExcel / )
	Fn_GUI_UpdateProgress(A_Index,The_EquibaseTotalTXTLines)
	;GuiControl,, UpdateProgress, %vProgressBar%
	}



;Create RC Array and Dirs to read from
RacingChannel_Array := []
Dir_TBred = %A_ScriptDir%\data\temp\RacingChannel\TBred\*.PHP
Dir_Harness = %A_ScriptDir%\data\temp\RacingChannel\Harness\*.PHP

;Parse Dirs into the array; also compares to AllHorses_Array trying to fix matches
Fn_ParseRacingChannel(RacingChannel_Array, Dir_TBred)
Fn_ParseRacingChannel(RacingChannel_Array, Dir_Harness)


		;UNUSED SORTING
;Fn_Sort2DArray(AllHorses_Array, "EntryNumber")
	;Fn_Sort2DArray(AllHorses_Array, "ProgramNumber")
;Fn_Sort2DArray(AllHorses_Array, "RaceNumber")
;Fn_Sort2DArray(AllHorses_Array, "TrackName")

;For index, obj in AllHorses_Array
;	list3 .= AllHorses_Array[index].ProgramNumber . "    " . AllHorses_Array[index].HorseName . "`n"	
;FileAppend, %list3%, %A_ScriptDir%\allllll.txt


;Look through the provided array and send scratched CE entries to Listview for User to see
Fn_ReadtoListview(AllHorses_Array)

;Now look through the RacingChannel Array for any CE entries that may have been missed. Also handles Harness Scratches
RCOnly_Scratch = 0
Loop, % RacingChannel_Array.MaxIndex()
{
	If (RacingChannel_Array[A_Index,"OtherScratch"] = 1)
	{
	RCOnly_Scratch += 1
	;The_EffectedEntries += 1 ;Problematic
		If (RCOnly_Scratch = 1) ;Simple duplicate
			{
			LV_AddBlank()
			LV_AddBlank()
			LV_AddBlank()
			LV_Add("","","","","Harness / Racing Channel Only Scratches","")
			RCOnly_Scratch := 2
			}
	LV_Add("",RacingChannel_Array[A_Index,"ProgramNumber"],"Scratched","",RacingChannel_Array[A_Index,"HorseName"] . " at " Fn_TrackTitle(RacingChannel_Array[A_Index,"TrackName"]),RacingChannel_Array[A_Index,"RaceNumber"])
	}
}

;Show number of effected Races so user knows if there is a new change.
guicontrol, Text, GUI_EffectedEntries, % The_EffectedEntries


;Modify Race Column to fit whole title (4th column, 40 pixels/units)
;LV_ModifyCol(3, 20)
;LV_ModifyCol(5, 40)

Data_UnHandledRunners := 0
Data_TotalScratches := 0

Loop % LV_GetCount()
{
	The_OuterIndex := A_Index
    LV_GetText(Buffer_ProgramNumber, A_Index, 1)
	LV_GetText(Buffer_Status, A_Index, 2)
	LV_GetText(Buffer_Name, A_Index, 4) ;Commonly the Horsename but sometimes not. 
	If (InStr(Buffer_Name,"■"))
	{
	LVA_SetCell("GUI_Listview", A_Index, 0, "f0f0f0") ;Set to grey if this is a track header
	}
    If (Buffer_ProgramNumber != "")
	{
		If(Buffer_Status != "")
		{
		Data_TotalScratches += 1
		}
		
		Loop, % SeenHorses_Array.MaxIndex()
		{
			If (SeenHorses_Array[A_Index,"HorseName"] = Buffer_Name)
			{
				If (Buffer_Status = "RE-LIVENED")
				{
				LVA_SetCell("GUI_Listview", The_OuterIndex, 0, "red") ;Set to Red if it is a "RE-LIVENED" Horse
				Data_UnHandledRunners += 1
				}
			Continue 2
			}
		}
		If(Buffer_Status = "Scratched")
		{
		LVA_SetCell("GUI_Listview", A_Index, 0, "ff7f27") ;Set to Orange if this horse hasn't been doubleclicked yet.
		Data_UnHandledRunners += 1
		}
		If (Buffer_Status = "RE-LIVENED")
		{
		LVA_SetCell("GUI_Listview", A_Index, 0, "red") ;Set to Red if it is a "RE-LIVENED" Horse
		}
	}
}

;Fix Default Size of all Columns in Listview
LV_ModifyCol(1)
LV_ModifyCol(2)
LV_ModifyCol(3, 20)
LV_ModifyCol(4)
LV_ModifyCol(5, 40)
LV_ModifyCol(6, 100)

;Refresh the Listview colors (Redraws the GUI Control
LVA_Refresh("GUI_Listview")
OnMessage("0x4E", "LVA_OnNotify")
;Guicontrol, +ReDraw, GUI_Listview

;Send Runner numbers to GUI
	If (Data_UnHandledRunners = 0)
	{
	GuiControl, +cBlack, GUI_UnhandledScratches,
	}
	If (Data_UnHandledRunners > 0)
	{
	GuiControl, +cff7f27, GUI_UnhandledScratches,
	;Sb_FlashGUI()
	}
	If (Data_UnHandledRunners > 4)
	{
	GuiControl, +cRed, GUI_UnhandledScratches,
	}
GuiControl, Text, GUI_UnhandledScratches, % Data_UnHandledRunners
GuiControl, Text, GUI_TotalScratches, % Data_TotalScratches

;Warn User if there are no racingchannel files
IfNotExist, %A_ScriptDir%\data\temp\RacingChannel\TBred\*.PHP
	{
	Fn_MouseToolTip("No RacingChannel Data Downloaded. Login and Retry", 10)
	}
;IfNotExist, %A_ScriptDir%\data\temp\RacingChannel\Harness\*.PHP
;	{
;	Fn_MouseToolTip("No RacingChannel Data Downloaded. Login and Retry", 10)
;	}
	IfNotExist, %A_ScriptDir%\data\temp\ConvertedXML.txt
	{
	Fn_MouseToolTip("No EQUIBASE Data Downloaded. Check that site is accessible", 10)
	}
	
	

;END
Fn_GUI_UpdateProgress(100)
EnableAllButtons()
Return


^F3::
;For Array visualization
SetTitleMatchMode, 2
IfWinActive, Scratch Detector
{
Array_Gui(RacingChannel_Array)
;FileAppend, % Array_Print(AllHorses_Array), %A_ScriptDir%\alf.txt
}
Return

;~~~~~~~~~~~~~~~~~~~~~
;Check Results
;~~~~~~~~~~~~~~~~~~~~~
; Going to need a list of every CE runner first
CheckResults:
Msgbox, This is not done yet.
Return


$F1::
WinActivate, Scratch Detector
Goto UpdateButton
Return

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; FUNCTIONS
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
#Include LVA
Sb_GlobalNameSpace()
{
global

CE_Arr := [[x],[y]]
ArrX = 0

AllHorses_Array := []
Ignored_CE = 4
Return
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


Fn_InsertHorseData()
{
global

;The_HorseNameLength := StrLen(The_HorseName)

	X := AllHorses_Array.MaxIndex() 
	;Loop % X
	;{
	;	If (The_HorseName = AllHorses_Array[A_Index, "HorseName"] || The_HorseName = "") ; && The_ScratchStatus != 0
	;	{
	;	;X := A_Index
	;	;Horse already exists in this object, skip
	;	Return
	;	}
	;}
	
	If(The_HorseName != "")
	{
	X += 1
	AllHorses_Array[X,"EntryNumber"] := The_EntryNumber ;Index
	AllHorses_Array[X,"TrackName"] := The_TrackName
	AllHorses_Array[X,"HorseName"] := The_HorseName
	AllHorses_Array[X,"ProgramNumber"] := The_ProgramNumber
	AllHorses_Array[X,"RaceNumber"] := The_RaceNumber
	AllHorses_Array[X,"Scratched"] := The_ScratchStatus
	}
	The_ScratchStatus := 0
}


Fn_TitleCase(para_String)
{
StringUpper, l_ReturnValue, para_String, T
Return %l_ReturnValue%
}


Fn_TrackTitle(para_String)
{
StringUpper, l_ReturnValue, para_String, T
Return % "■ " . l_ReturnValue
}

Fn_ParseRacingChannel(para_Array, para_FileDir)
{

	Global AllHorses_Array
	Global The_RCTotalTXTLines
	X := 0
	
	;Read each RacingChannel file
	Loop, %para_FileDir%
	{
	Fn_GUI_UpdateProgress(A_Index,The_RCTotalTXTLines)
		Loop, Read, %A_LoopFileFullPath%
		{
		;Msgbox, %A_LoopReadLine%
		;TrackName
		RegExFound := Fn_QuickRegEx(A_LoopReadLine,"<TITLE>(\D+) Changes<\/TITLE>")
			If (RegExFound != "null")
			{
			TrackName := RegExFound
			}
		;RaceNumber
		RegExFound := Fn_QuickRegEx(A_LoopReadLine,"<B><U>(\d+)")
			If (RegExFound != "null")
			{
			RaceNumber := RegExFound
			}
		;ProgramNumber
		REG = <TD WIDTH="20"><B>(\w+)<
		RegExFound := Fn_QuickRegEx(A_LoopReadLine,REG)
			If (RegExFound != "null")
			{
			ProgramNumber := RegExFound
			}
		;HorseName
		REG = WIDTH="150"><B>(\D+)<\/B>
		RegExFound := Fn_QuickRegEx(A_LoopReadLine,REG)
			If (RegExFound != "null")
			{
			HorseName := RegExFound
			}
		;Status
		REG = scratched (\(part of entry\))
		RegExFound := Fn_QuickRegEx(A_LoopReadLine,REG)
			If (RegExFound != "null" && HorseName != "")
			{
			HorseStatus := 1
			
			X += 1
			para_Array[X,"TrackName"] := TrackName
			para_Array[X,"RaceNumber"] := RaceNumber
			para_Array[X,"ProgramNumber"] := ProgramNumber
			para_Array[X,"HorseName"] := HorseName
			para_Array[X,"Status"] := HorseStatus
			
			RaceNumber := "", ProgramNumber := "", HorseName := "" , HorseStatus := "" ;Clear all vars
			
				MatchFound := 0
				Loop, % AllHorses_Array.MaxIndex()
				{
					If (AllHorses_Array[A_Index,"HorseName"] = para_Array[X,"HorseName"])
					{
					AllHorses_Array[A_Index,"RCConfirm"] := "/"
					MatchFound := 1
					}
					;Else ;switch back to this if a binary system is needed
					;{
					;AllHorses_Array[A_Index,"RCConfirm"] := 0
					;}
				}
				If (MatchFound != 1)
				{
				para_Array[X,"OtherScratch"] := 1
				}
			HorseStatus := 0
			}

		}

	}
	
}


Fn_WriteOutCE(Obj)
{
Global SeenHorses_Array
Global Current_Track
Global Current_Race
Global The_EffectedEntries

ScratchCheck := 0
;Entire Entry checking
	Loop, % Obj.MaxIndex()
	{
		If(Obj[A_Index,"Scratched"] = 1)
		{
		ScratchCheck += 1
		}
		If(Obj[A_Index,"Scratched"] = 9)
		{
		ReLivened := 1
		}
		else
		{
		ReLivened := 0
		}
	}
	
	
	;Individual Runner
	If (ScratchCheck != 0)
	{
	The_EffectedEntries += 1
		Loop, % Obj.MaxIndex()
		{
		CurrentHorse := Obj[A_Index,"HorseName"]
			If(Obj[A_Index,"Scratched"] = 0)
			{
			Status := ""
			}
			If(Obj[A_Index,"Scratched"] = 1)
			{
			Status := "Scratched"
			}
			If(Obj[A_Index,"Scratched"] = 9)
			{
			Status := "RE-LIVENED"
			}

		;Msgbox, % Obj[A_Index,"ConfirmScratch"] ;Uncomment to see what RacingChannel says for each entry.
			If (Current_Track != Obj[1,"TrackName"])
			{
				If (The_EffectedEntries != 1)
				{
				LV_AddBlank()
				}
			LV_Add("","","","",Fn_TrackTitle(Obj[1,"TrackName"]),"")
			Current_Track := Obj[1,"TrackName"]
			Current_Race := ""
			}
			If (Current_Race != Obj[1,"RaceNumber"])
			{
			LV_Add("","","","","Race" . Obj[1,"RaceNumber"],"")
			Current_Race := Obj[1,"RaceNumber"]
			}
		LV_Add("",Obj[A_Index,"ProgramNumber"],Status,Obj[A_Index,"ConfirmScratch"],Obj[A_Index,"HorseName"],Obj[A_Index,"RaceNumber"])
		}
	}
Return %ScratchCheck%
}


Fn_ReadtoListview(Obj)
{
Scratch_Counter := 0
CE_FirstFound = 0
ReRead = 0
FirstHorse_Toggle := 1

;Loop a total time of all horses
	Loop, % Obj.MaxIndex()
	{
	ReRead:
		If (Obj[A_Index,"ProgramNumber"] >= 9)
		{ ;WARNING - This will cause issues it there is ever a 9A, 10X, etc
		Continue
		}
		
		;If this is the first horse of an entry and the horsename is not blank; put it into the CE_Array0 so that it is remembered.
		If (FirstHorse_Toggle = 1 && Obj[A_Index,"HorseName"] != "")
		{ ;First Horse going into ARRAY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		CE_Array := []
		ArrX := 1
		CE_Array[ArrX,"HorseName"] := Obj[A_Index,"HorseName"]
		CE_Array[ArrX,"Scratched"] := Obj[A_Index,"Scratched"]
		CE_Array[ArrX,"ProgramNumber"] := Obj[A_Index,"ProgramNumber"]
		CE_Array[ArrX,"TrackName"] := Obj[A_Index,"TrackName"]
		CE_Array[ArrX,"RaceNumber"] := Obj[A_Index,"RaceNumber"]
		CE_Array[ArrX,"ConfirmScratch"] := Obj[A_Index,"RCConfirm"]
		FirstHorse_Toggle := 0
		Continue
		}
		
		;If the first entry number is in the current entry; AND the race number is the same; they are part of the same coupled entry. (1 is in 1A) AND tracknames match.
		If (InStr(Obj[A_Index,"ProgramNumber"],CE_Array[1,"ProgramNumber"], false) && Obj[A_Index,"RaceNumber"] = CE_Array[1,"RaceNumber"] && Obj[A_Index,"TrackName"] = CE_Array[1,"TrackName"])
		{ ;2nd HORSE FOUND!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		ArrX += 1
		CE_Array[ArrX,"HorseName"] := Obj[A_Index,"HorseName"]
		CE_Array[ArrX,"Scratched"] := Obj[A_Index,"Scratched"]
		CE_Array[ArrX,"ProgramNumber"] := Obj[A_Index,"ProgramNumber"]
		CE_Array[ArrX,"TrackName"] := Obj[A_Index,"TrackName"]
		CE_Array[ArrX,"RaceNumber"] := Obj[A_Index,"RaceNumber"]
		CE_Array[ArrX,"ConfirmScratch"] := Obj[A_Index,"RCConfirm"]
		Continue
		}
		
		;Catchall for any other instances; Runners not a part of an entry will end up here; triggering the next Program Number to be checked.
		If (CE_Array.MaxIndex() >= 2)
		{
		Fn_WriteOutCE(CE_Array)
		CE_Array := []
		}
	FirstHorse_Toggle = 1
	CE_Array := []
	ArrX := 0
	ReRead = 1
	Goto ReRead
	}

}



LV_AddBlank()
{
LV_Add("", "", "", "", "")
}


;Legacy, Not used
ReturnReplace(Word)
{
global

; Replace all spaces with pluses:
StringReplace, FileContents, FileContents, %Word%,`n%Word%, All
}




GetNewXML(para_FileName)
{
global

FileRemoveDir, %A_ScriptDir%\data\temp, 1
FileCreateDir, %A_ScriptDir%\data\temp
FileCreateDir, %A_ScriptDir%\data\temp\tracksrawhtml
FileDelete, %A_ScriptDir%\data\temp\ConvertedXML.txt
UrlDownloadToFile, http://www.equibase.com/premium/eqbLateChangeXMLDownload.cfm, %A_ScriptDir%\data\temp\%para_FileName%
;Copy to Archive
FileCopy %A_ScriptDir%\data\temp\%para_FileName%, %A_ScriptDir%\data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\EquibaseXML_%CurrentDate%.xml, 1
}

UseExistingXML()
{
global

FileDelete, %A_ScriptDir%\data\temp\ConvertedXML.txt
FileSelectFile, XMLPath
FileCopy, %XMLPath%, %A_ScriptDir%\data\temp\Today_XML.xml, 1
}


Fn_CreateArchiveDir(para_FileToArchive)
{
global

;CurrentDate = %A_Now%
FormatTime, CurrentDate,, MMddyy
FormatTime, CurrentYear,, yyyy
FormatTime, CurrentMonth,, MMMM
FormatTime, CurrentMonthNumber,, MM
FormatTime, CurrentDay,, dd

l_ArchivePath = \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\data\archive\%CurrentYear%\%CurrentMonthNumber%-%CurrentMonth%\%CurrentDay%\
FileCreateDir, %l_ArchivePath%
FileCopy, %para_FileToArchive%, %l_ArchivePath%, 1
Return %l_ArchivePath%
}



DownloadSpecified(para_FileToDownload,para_FileName)
{
SaveLocation = %A_ScriptDir%\data\temp\%para_FileName%
UrlDownloadToFile, %para_FileToDownload%, %SaveLocation%
Return
}


Fn_FileSize(para_File)
{
l_FileSize := ;MakeThis Variable Empty

;Check the size of the file specified in the Function argument/option
FileGetSize, l_FileSize, %para_File%, k

	;If the filesize is NOT blank
	If (l_FileSize != "")
	{
	;Exit the Function with the value of the filesize
	Return %l_FileSize%
	}
;filesize was blank or not understood. Return 0
Return 0
}

Fn_ConvertEntryNumber(para_ProgramNumber)
{
	RegexMatch(para_ProgramNumber, "(\d+)(\D*)|(\d+)", RE_EntryNumber)
	If (RE_EntryNumber2 != "")
	{
	RE_EntryNumber2 := Asc(RE_EntryNumber2)
	RE_EntryNumber2 := RE_EntryNumber2 - 64
	}
	Else
	{
	RE_EntryNumber2 := 0
	}
RE_EntryNumber := RE_EntryNumber1 * 100 + RE_EntryNumber2
Return %RE_EntryNumber%
;Return "ERROR Retrieving Entry Number"
}


Fn_QuickRegEx(para_Input,para_RegEx)
{
	RegExMatch(para_Input, para_RegEx, RE_Match)
	If (RE_Match1 != "")
	{
	Return %RE_Match1%
	}
Return "null"
}


Fn_ExtractEntryNumber(para_ProgramNumber)
{
	RegexMatch(para_ProgramNumber, "(\d*)", RE_EntryNumber)
	If (RE_EntryNumber1 != "")
	{
	Return %RE_EntryNumber1%
	}
Return "ERROR Retrieving Entry Number"	
}


Fn_DeleteDB()
{
global
FileDelete, \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector\data\archive\DBs\%A_Today%_%Version_Name%DB.json
}


;~~~~~~~~~~~~~~~~~~~~~
; Variables
;~~~~~~~~~~~~~~~~~~~~~

StartUp()
{
#NoEnv
;#NoTrayIcon
#SingleInstance force
#MaxThreads 1
}

StartInternalGlobals()
{
global

ScratchCounter := 0
The_EffectedEntries := 0
A_LF := "`n"
}




;~~~~~~~~~~~~~~~~~~~~~
;GUI
;~~~~~~~~~~~~~~~~~~~~~

BuildGUI()
{
Global
Gui, Add, Text, x388 y3 w100 +Right, %Version_Name%
Gui, Add, Tab, x2 y0 w630 h700 , Scratches|Options
;Gui, Tab, Scratches
Gui, Add, Button, x2 y30 w100 h30 gUpdateButton, Update
Gui, Add, Button, x102 y30 w100 h30 gCheckResults, Check Results
Gui, Add, Button, x202 y30 w100 h30 gShiftNotes, Open Shift Notes
Gui, Add, Button, x302 y30 w50 h30 gResetDB, Reset DB
Gui, Add, ListView, x2 y70 w490 h536 Grid NoSort +ReDraw gDoubleClick vGUI_Listview, #|Status|RC|Name|Race|
Gui, Add, Progress, x2 y60 w100 h10 vUpdateProgress, 1


;w200
Gui, Font, s30 w700, Arial
Gui, Add, Text, x360 y24 w42 +Right vGUI_UnhandledScratches gMsgUnhandledScratches,
Gui, Add, Text, x410 y24, /
Gui, Font, s20 w700, Arial
Gui, Add, Text, x430 y24 w30 vGUI_TotalScratches gMsgTotalScratches,
Gui, Font, s10 w10, Arial
Gui, Add, Text, x434 y54 w30 vGUI_EffectedEntries gMsgEffectedEntries,
;Gui, Font, s30 w700, Arial

Gui, Font, s6 w10, Arial
;Gui, Add, Text, x360 y30, Unhandled / Scratches
;Gui, Add, Text, x404 y58, Effected Entries:
Gui, Font,


Gui, Tab, Options
Gui, Add, CheckBox, x10 y30 vGUI_RefreshCheckBox gAutoUpdate, Auto-Update every
Gui, Add, edit, x122 y28 w30 vGUI_RefreshAmmount Number, 10
Gui, Add, text, x160 y30, minutes
GUI, Submit, NoHide

;Gui, Add, Button, x2 y30 w100 h30 gUpdateButton, Update
;Option_Refresh
;Gui, Add, ListView, x2 y70 w490 h580 Grid Checked, #|Status|Name|Race

Gui, Show, x130 y90 h622 w490, Scratch Detector


;Menu
Menu, FileMenu, Add, &Update Now, UpdateButton
Menu, FileMenu, Add, R&estart`tCtrl+R, Menu_File-Restart
Menu, FileMenu, Add, E&xit`tCtrl+Q, Menu_File-Quit
Menu, MenuBar, Add, &File, :FileMenu  ; Attach the sub-menu that was created above

Menu, HelpMenu, Add, &About, Menu_About
Menu, HelpMenu, Add, &Confluence`tCtrl+H, Menu_Confluence
Menu, MenuBar, Add, &Help, :HelpMenu

Gui, Menu, MenuBar
Return


MsgTotalScratches:
Msgbox, This shows the total number of coupled entry scratches
Return

MsgUnhandledScratches:
Msgbox, This shows the number of coupled entries that have not been handled
Return

MsgEffectedEntries:
Msgbox, This shows the number of coupled entries effected by scratches (1,1A,1X are considered a single entry)
Return

;Options
AutoUpdate:
GUI, Submit, NoHide
RefreshMilli := 0
RefreshMilli := Fn_QuickRegEx(GUI_RefreshAmmount,"(\d+)")

	If(RefreshMilli >= 10 && GUI_RefreshCheckBox = 1)
	{
	RefreshMilli := RefreshMilli * 60000
	GuiControl,, GUI_RefreshCheckBox, 1
	SetTimer, UpdateButton, %RefreshMilli%
	}
	If(GUI_RefreshCheckBox = 0)
	{
	GuiControl,, GUI_RefreshCheckBox, 0
	SetTimer, UpdateButton, Off
	}
Return


;Menu Shortcuts
Menu_Confluence:
Run http://confluence.tvg.com/pages/viewpage.action?pageId=11468878
Return

Menu_About:
Msgbox, Checks Equibase for coupled entry scratches. Crosschecks with RacingChannel. `n%Version_Name%
Return

Menu_File-Restart:
Reload
Menu_File-Quit:
ExitApp


ShiftNotes:
Today:= %A_Now%
FormatTime, CurrentDateTime,, MMddyy
Run \\tvgops\pdxshares\wagerops\Daily Shift Notes\%CurrentDateTime%.xlsx
Return

ResetDB:
Fn_DeleteDB()
Return
}

Fn_GUI_UpdateProgress(para_Progress1, para_Progress2 = 0)
{
	;Calculate progress if two parameters input. otherwise set if only one entered
	If (para_Progress2 = 0)
	{
	GuiControl,, UpdateProgress, %para_Progress1%+
	}
	Else
	{
	para_Progress1 := (para_Progress1 / para_Progress2) * 100
	GuiControl,, UpdateProgress, %para_Progress1%
	}

}


DoubleClick:
;Send Horsename to Json file so it won't be highlighted
	If A_GuiEvent = DoubleClick
	{		
		;Get the text from the row's fourth field. Runner Name
		LV_GetText(RowText, A_EventInfo, 4)
		
		If !InStr(RowText,"■")
		{
		;Load any existing DB from other Ops
		Fn_ImportDBData()
		;Get Max size of object imported and Add one
		X2 := SeenHorses_Array.MaxIndex()
		X2 += 1
		;Add the new name and Export
		SeenHorses_Array[X2,"HorseName"] := RowText
		Fn_ExportArray()
		}
		
		
;Put all Shift note formatted Scratches onto the clipboard if user double-clicked a '■ TrackName'
		If (InStr(RowText,"■"))
		{
		Clip =
		Ignore_Bool := True
		TrackName := Fn_QuickRegEx(RowText,"■ (.+)")
			;Cycle the entire Listview
			Loop % LV_GetCount()
			{
			;Hold each row in Buffer_ variables
			LV_GetText(Buffer_Name, A_Index, 4)
			LV_GetText(Buffer_Status, A_Index, 2)
			LV_GetText(Buffer_ProgramNumber, A_Index, 1)
			LV_GetText(Buffer_Race, A_Index, 5)
				;Reset ignore flag if a new track is loaded into memory
				If (InStr("■",Buffer_Name) && Ignore_Bool = False) ;NOTE - Note sure why but leave "■" as the haystack
				{
				Ignore_Bool := True
				}
				;Cycle all the way to the Row user double-clicked
				If (InStr(Buffer_Name,TrackName))
				{
				Ignore_Bool := False
				Continue
				}
				;Get the Race Number as a header, lead, thing
				If (!InStr(Buffer_Name,"■") && Buffer_ProgramNumber = "" && Buffer_Race = "" && Ignore_Bool = False)
				{
					If(Clip != "")
					{
					Clip := Clip . ")  "
					}
				Clip := Clip . Fn_QuickRegEx(Buffer_Name,"Race(\d+)")
				Clip := Clip . "-("
				FirstEntry_Bool := True
				}
				;Put each entry into the Clip; if its the first entry; don't put a comma in front
				If (Buffer_ProgramNumber != "" && Buffer_Status != "" && Ignore_Bool = False)
				{
					If(FirstEntry_Bool = True)
					{
					Clip := Clip . Buffer_ProgramNumber
					FirstEntry_Bool := False
					Continue
					}
				Clip := Clip . "," . Buffer_ProgramNumber
				}
			}
		If(Clip != "")
		{
		Clip := Clip . ")"
		}
		ClipBoard := Clip
		}
	}
Return


DiableAllButtons()
{
GuiControl, disable, Update
GuiControl, disable, Check Results
GuiControl, disable, Open Shift Notes
}


EnableAllButtons()
{
GuiControl, enable, Update
GuiControl, disable, Check Results
GuiControl, enable, Open Shift Notes
}


EndGUI()
{
global

Gui, Destroy
}


Fn_MouseToolTip("No RacingChannel Data Downloaded", 10)
MouseGetPos, M_PosX, M_PosY, WinID
ToolTip, "No RacingChannel Data Downloaded", M_PosX, M_PosY, 1
ToolTip
	
	
GuiClose:
ExitApp

;~~~~~~~~~~~~~~~~~~~~~
;Subroutines
;~~~~~~~~~~~~~~~~~~~~~

Sb_DownloadAllRacingChannel()
{
;Download TBred and Harness from RacingChannel
FileCreateDir, %A_ScriptDir%\data\temp\RacingChannel
FileCreateDir, %A_ScriptDir%\data\temp\RacingChannel\TBred
DownloadSpecified("http://tote.racingchannel.com/MEN----T.PHP","RacingChannel\TBred_Index.html")

	Loop, Read, %A_ScriptDir%\data\temp\RacingChannel\TBred_Index.html
	{
	REG = A HREF="(\S+)"><IMG SRC="\/images\/CHG.gif        ;"
	Buffer_TrackCode := Fn_QuickRegEx(A_LoopReadLine,REG)
		If (Buffer_TrackCode != "null")
		{
		UrlDownloadToFile, https://tote.racingchannel.com/%Buffer_TrackCode%, %A_ScriptDir%\data\temp\RacingChannel\TBred\%Buffer_TrackCode%
		}

	}

	FileCreateDir, %A_ScriptDir%\data\temp\RacingChannel
	FileCreateDir, %A_ScriptDir%\data\temp\RacingChannel\Harness
	DownloadSpecified("http://tote.racingchannel.com/MEN----H.PHP","RacingChannel\Harness_Index.html")

	Loop, Read, %A_ScriptDir%\data\temp\RacingChannel\Harness_Index.html
	{
	REG = A HREF="(\S+)"><IMG SRC="\/images\/CHG.gif        ;"
	Buffer_TrackCode := Fn_QuickRegEx(A_LoopReadLine,REG)
		If (Buffer_TrackCode != "null")
		{
		UrlDownloadToFile, https://tote.racingchannel.com/%Buffer_TrackCode%, %A_ScriptDir%\data\temp\RacingChannel\Harness\%Buffer_TrackCode%
		}
	}
}

Sb_FlashGUI()
{
SetTimer, FlashGUI, -1000
Return
FlashGUI:

	Loop, 6
	{
	Gui Flash
	Sleep 500  ;Do not change this value
	}
Return
}



;~~~~~~~~~~~~~~~~~~~~~
;Timers
;~~~~~~~~~~~~~~~~~~~~~

Fn_MouseToolTip(para_Message, 10)
{
Global The_Message := para_Message
ToolTip_X := 0
MouseToolTip:
SetTimer, MouseToolTip, 100
MouseGetPos, M_PosX, M_PosY, WinID
ToolTip, %The_Message%, M_PosX, M_PosY, 1
ToolTip_X += 1
	If(ToolTip_X = 100)
	{
	ToolTip
	SetTimer, MouseToolTip, Off
	}
return
}