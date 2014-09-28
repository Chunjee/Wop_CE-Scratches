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
Version_Name = v0.16.1

;Dependencies
#Include %A_ScriptDir%\Functions
#Include sort_arrays
#Include json_obj

;For Debug Only
#Include util_arrays

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;PREP AND STARTUP
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Sb_GlobalNameSpace()
;###Invoke and set Global Variables
StartInternalGlobals()

;FileRead, MemoryFile, %A_ScriptDir%\DB.json
;AllHorses_Array := Fn_JSONtooOBJ(MemoryFile)
;MemoryFile := ;Blank


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
;Clear the GUI Listview (Contains all found Coupled Entries) and AllHorses Array
LV_Delete()
AllHorses_Array := []

;Import Existing Seen Horses DB File
Fn_ImportDBData()

;Switch comment here for live or testing
;Download XML of all TB Track Changes
GetNewXML("Today_XML.xml")
;UseExistingXML()


;###Invoke and set Global Variables
StartInternalGlobals()

;###Read XML previously downloaded to FILECONTENTS Var
FileRead, File_TB_XML, %A_ScriptDir%\data\temp\Today_XML.xml
StringReplace, File_TB_XML, File_TB_XML, `<,`n`<, All
FileAppend, %File_TB_XML%, %A_ScriptDir%\data\temp\ConvertedXML.txt
FileContents = ;Free the memory after being written to file.


	;###This does nothing but count the number of lines to be used in progress bar calculations
	Loop, read, %A_ScriptDir%\data\temp\ConvertedXML.txt
	{
	TotalTXTLines += 1
	}
	
	;###Read Each line of Converted XML. Valued Information is extracted put into an array
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
		
		REG = <new_value>(Y)
		RegexMatch(ReadLine, REG, RE_Scratch)
		If (RE_Scratch1 != "")
		{
		The_ScratchStatus := 1
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
		}
		;RegexMatch(ReadLine, "Coupled (Type)", RE_Scratch)
		;If (RE_Scratch1 != "")
		;{
		;The_ScratchStatus := ""
		;}
		
		
	;CleanXML("Coupled Type","COUPLED",44,1)
	;CleanXML("program_number","PN",16,2)
	;CleanXML("horse_name","HN",12,2)
	;CleanXML("Scratched N","SC",0,3)
	;CleanXML("new_value>N<","UNSCRATCH",0,0)
	;WriteTBtoExcel()
	;Fn_WriteToArray()

	TotalWrittentoExcel += 1
	vProgressBar := 100 * (TotalWrittentoExcel / TotalTXTLines)
	GuiControl,, UpdateProgress, %vProgressBar%
	}

;AllHorses_Array := {TrackName:"", HorseName:"", ProgramNumber:"", EntryNumber:"", RaceNumber:"", Scratched:"" , Seen:""}


;Download TBred from RacingChannel
FileCreateDir, %A_ScriptDir%\data\temp\RacingChannel
FileCreateDir, %A_ScriptDir%\data\temp\RacingChannel\TBred
DownloadSpecified("http://tote.racingchannel.com/MEN----T.PHP","RacingChannel\TBred_Index.html")
Loop, Read, %A_ScriptDir%\data\temp\RacingChannel\TBred_Index.html
{
REG = A HREF="(\S+)"><IMG SRC="\/images\/CHG.gif        ;"
Alf := Fn_QuickRegEx(A_LoopReadLine,REG)
	If (Alf != "null")
	{
	UrlDownloadToFile, https://tote.racingchannel.com/%Alf%, %A_ScriptDir%\data\temp\RacingChannel\TBred\%Alf%
	}
}

X := 0
RacingChannel_Array := []
;Read each RacingChannel file
Loop, %A_ScriptDir%\data\temp\RacingChannel\TBred\*.PHP
{
	Loop, Read, %A_LoopFileFullPath%
	{
	;Msgbox, %A_LoopReadLine%
	;TrackName
	RegExFound := Fn_QuickRegEx(A_LoopReadLine,"<TITLE>(\D+)<\/TITLE>")
		If (RegExFound != "null")
		{
		TrackName := RegExFound
		}
	;RaceNumber
	RegExFound := Fn_QuickRegEx(A_LoopReadLine,"A name=race(\d+)>")
		If (RegExFound != "null")
		{
		RaceNumber := RegExFound
		}
	;ProgramNumber
	REG = <TD WIDTH="20"><B>(\d+)<
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
		If (RegExFound != "null")
		{
		HorseStatus := 1
		}
	;Write Out
	REG = (<TD><\/TD>)
	RegExFound := Fn_QuickRegEx(A_LoopReadLine,REG)
		If (RegExFound != "null" && HorseName != "" && HorseStatus = 1)
		{
		X += 1
		RacingChannel_Array[X,"TrackName"] := TrackName
		RacingChannel_Array[X,"RaceNumber"] := RaceNumber
		RacingChannel_Array[X,"ProgramNumber"] := ProgramNumber
		RacingChannel_Array[X,"HorseName"] := HorseName
		RacingChannel_Array[X,"Status"] := HorseStatus
			Loop, % AllHorses_Array.MaxIndex()
			{
				If (AllHorses_Array[A_Index,"HorseName"] = RacingChannel_Array[X,"HorseName"])
				{
				AllHorses_Array[A_Index,"RCConfirm"] := "/"
				}
				;Else ;switch back to this if a binary system is needed
				;{
				;AllHorses_Array[A_Index,"RCConfirm"] := 0
				;}
			}
		HorseStatus := 0
		}

	}

}




;Fn_Sort2DArray(AllHorses_Array, "EntryNumber")
	;Fn_Sort2DArray(AllHorses_Array, "ProgramNumber")
;Fn_Sort2DArray(AllHorses_Array, "RaceNumber")
;Fn_Sort2DArray(AllHorses_Array, "TrackName")




;For index, obj in AllHorses_Array
;	list3 .= AllHorses_Array[index].ProgramNumber . "    " . AllHorses_Array[index].HorseName . "`n"
	
;FileAppend, %list3%, %A_ScriptDir%\allllll.txt


;For Array Visualization
;Array_Gui(AllHorses_Array)
;FileAppend, % Array_Print(AllHorses_Array), %A_ScriptDir%\alf.txt


;### Look through Excel and send scratched CE to Listview for User to see
Fn_ReadtoListview(AllHorses_Array)



;### Show number of effected Races so user knows if there is a new change.
;Gui, Tab, Scratches
guicontrol, Text, GUI_EffectedEntries, % "Effected Entries: " . The_EffectedEntries


;Modify Race Column to fit whole title (4th column, 40 pixels/units)
LV_ModifyCol(3, 20)
LV_ModifyCol(5, 40)


EnableAllButtons()
Return


F3::
Array_Gui(AllHorses_Array)
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
FileDelete, %A_ScriptDir%\data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\HN_%CurrentDate%.xlsx
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

Sb_GlobalNameSpace()
{
global

The_IgnoredProgramNumber = 0
;Ignore any entry over this number, example: don't look for Entry 9 or 9A. An experiment at running faster. Should be uneeded now that they are stored in an array


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

Fn_WriteOutCE(Obj)
{
Global SeenHorses_Array
Global Current_Track := ""
Global Current_Race := ""
Global The_EffectedEntries := 0

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
				Loop, % SeenHorses_Array.MaxIndex()
				{
					;skip out of showing this runner if it has been entered but not if it has been re-livened
					If (SeenHorses_Array[A_Index,"HorseName"] = CurrentHorse && ReLivened != 1)
					{
					Continue 2
					}
				}
		;Msgbox, % Obj[A_Index,"ConfirmScratch"] ;Uncomment to see what RacingChannel says for each entry.
			If (Current_Track != Obj[1,"TrackName"])
			{
				If (The_EffectedEntries != 1)
				{
				LV_AddBlank()
				}
			LV_Add("","","","",Obj[1,"TrackName"],"")
			Current_Track := Obj[1,"TrackName"]
			Current_Race := ""
			}
			If (Current_Race != Obj[1,"RaceNumber"])
			{
			LV_Add("","","","","Race" . Obj[1,"RaceNumber"],"")
			Current_Race := Obj[1,"RaceNumber"]
			}
		LV_Add("",Obj[A_Index,"ProgramNumber"],Status,Obj[A_Index,"ConfirmScratch"],Obj[A_Index,"HorseName"],Obj[A_Index,"RaceNumber"])
		LV_ModifyCol(1)
		LV_ModifyCol(2)
		LV_ModifyCol(3)
		LV_ModifyCol(4)
		LV_ModifyCol(5)
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
		If (Obj[A_Index,"ProgramNumber"] > 9)
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
		
		;If the first entry number is in the current entry; and the race number is the same; they are part of the same coupled entry. (1 is in 1A)
		If (InStr(Obj[A_Index,"ProgramNumber"],CE_Array[1,"ProgramNumber"], false) && Obj[A_Index,"RaceNumber"] = CE_Array[1,"RaceNumber"])
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









Old_ReadtoListview()
{
global

Scratch_Counter = 0
FirstHorse_Toggle = 1
CE_FirstFound = 0
ReRead = 0

;DEPRECIATED Find Total Horses for iterations for excel checking. TrackCounter is added since it will read a blank line for every track.
;DEPRECIATED TotalExcelIterations := (TrackCounter + HorseCounter)
	
							AllHorses_ArraX := 0
							MaxArraySize := AllHorses_Array.MaxIndex()
							Loop, %MaxArraySize%
							{
								If (The_HorseName = AllHorses_Array[A_Index, "HorseName"] && The_ScratchStatus != 0)
								{
								;Alf
								}
							}
	
	
	While (FinishedReading != 1)
	{
	;traytip, alf, %Number%, 10, 1
	;Msgbox, alf, %Number%
	If (AllHorses_ArraX >= MaxArraySize)
	{
	FinishedReading := 1
	}
		If (ReRead != 1)
		{
		AllHorses_ArraX += 1
		Number := AllHorses_Array[AllHorses_ArraX,"ProgramNumber"]
		Name := AllHorses_Array[AllHorses_ArraX,"HorseName"]
		Status := AllHorses_Array[AllHorses_ArraX,"Scratched"]
		Race := AllHorses_Array[AllHorses_ArraX,"RaceNumber"]
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
		;Msgbox, %Number% %Name% %AllHorses_ArraX%
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
		;NewRace := Race
		;If (NewRace != LastRace)
		;{
		;LastRace := Race
		;Blank_Counter += 1
			;If (Blank_Counter >= 2)
			;{
			;CE_FirstFound = 0 ;Set next track to have found no Coupled Entries
			;Blank_Counter = 0
			;Continue
			;}	
		;}
		;FIRST HORSE GOING INTO ARRAY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		If (FirstHorse_Toggle = 1 && Name != "")
		{
			If (ArrX >= 2) 
			{
			WriteTrackToListView()
			FirstHorse_Toggle = 1
			CE_Arr := [[x],[y]]
			ArrX = 0
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
	Loop %ArrX%, ;Uh ok this needs to be changed to MaxIndex(Array) not some dumb variable
	{
	x += 1
	
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
FileCopy, %XMLPath%, %A_ScriptDir%\data\temp\EquibaseXML.xml, 1
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
}



DownloadSpecified(para_FileToDownload,para_FileName)
{
SaveLocation = %A_ScriptDir%\data\temp\%para_FileName%
UrlDownloadToFile, %para_FileToDownload%, %SaveLocation%
Return
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
		StringReplace, FileContents, FileContents,",+, All ;"
		
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
A_LF := "`n"
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
;Gui, Tab, Scratches
Gui, Add, Button, x2 y30 w100 h30 gUpdateButton, Update
Gui, Add, Button, x102 y30 w100 h30 gCheckHarness, Check Harness Tracks
Gui, Add, Button, x202 y30 w100 h30 gShiftNotes, Open Shift Notes
Gui, Add, Text, x390 y40 w200 vGUI_EffectedEntries, Effected Entries:
Gui, Add, ListView, x2 y70 w490 h536 Grid NoSortHdr gDoubleClick, #|Status|RC|Name|Race
Gui, Add, Progress, x2 y60 w100 h10 vUpdateProgress, 1
Gui, Add, Text, x388 y3 w100 +Right, %Version_Name%
;Gui, Tab, Options
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
}

DoubleClick:
	If A_GuiEvent = DoubleClick
	{
	;Load any existing DB from other Ops
	Fn_ImportDBData()

		LV_GetText(RowText, A_EventInfo, 4)  ; Get the text from the row's first field.
		;Msgbox, You double-clicked row number %A_EventInfo%. Text: "%RowText%"
		X2 := SeenHorses_Array.MaxIndex()
		X2 += 1
		SeenHorses_Array[X2,"HorseName"] := RowText
		Fn_ExportArray()
	}
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
ExitApp

;~~~~~~~~~~~~~~~~~~~~~
;Timers
;~~~~~~~~~~~~~~~~~~~~~
ProgressBarTimer:
SetTimer, ProgressBarTimer, -250
GuiControl,, UpdateProgress, %vProgressBar%
Return