;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Downloads and Parses Equibase XML and all Racing Channel change pages into Arrays. 
; Then reads them looking for coupled entry scratches, pool changes, or Re-livened runners.
; 


;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
SetBatchLines -1 ;Go as fast as CPU will allow
StartUp()
ComObjError(False) ; Ignore http timeouts / Don't let COM delays to stall out the script
The_VersionName = 0.39.0
The_ProjectName = Scratch Detector

;Dependencies
#Include %A_ScriptDir%\Functions

#Include util_misc.ahk
#Include sort_arrays.ahk
#Include json_obj.ahk
#Include json.ahk
#Include inireadwrite.ahk
#Include class_RaceResults.ahk
;#Include LVA (Listed under Functions)

;For Encryption
; #Include Crypt.ahk

;For Debug Only
#Include util_arrays.ahk



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;PREP AND STARTUP
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
Sb_RemoteShutDown() ;Allows for remote shutdown
Sb_SettingsImport()

;Read settings.json for global settings
FileRead, The_MemoryFile, % A_ScriptDir "/settings.json"
Config := JSON.parse(The_MemoryFile)
The_MemoryFile := ""

;~~~~~~~~~~~~~~~~~~~~~
;GUI
;~~~~~~~~~~~~~~~~~~~~~
BuildGUI()
LVA_ListViewAdd("GUI_Listview")

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;MAIN PROGRAM STARTS HERE
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
UpdateButton:
Sb_GlobalNameSpace() ;;Invoke and set Global Variables

;Do nothing between 24-05 for wallboard version only
if (Fn_StripleadingZero(A_Hour) < 4 && CLI_Arg = "Wallboard") {
	;Set gui to "-" so its more clear whats going on
	GuiControl, Text, GUI_UnhandledScratches, -
	Return
}

DiableAllButtons() ;;Immediately disable all GUI buttons to prevent user from pressing them again
BusyVar = 1
Fn_GUI_UpdateProgress(1)
;Clear the GUI Listview (Contains all found Coupled Entries) and AllHorses Array\
LVA_EraseAllCells("GUI_Listview")
LV_Delete()
LVA_Refresh("GUI_Listview")
AllHorses_Array := []
Current_Track := ""

;;Import Existing Seen Horses DB File
Fn_ImportDBData()


;Do special stuff if demo mode is selected
If (Settings.Misc.DemoMode = "1") {
	Loop, %A_ScriptDir%\*.xml
	{
		If (A_LoopFileFullPath) {
			UseExistingXML(A_LoopFileFullPath)
		}
	}
	;Sb_DownloadAllRacingChannel()
	TodaysFile_RC = %A_ScriptDir%\Data\temp\RacingChannelHTML.html
	;Fn_CreateArchiveDir(TodaysFile_RC)
} Else {
	;;Download XML of all TB Track Changes
	Equibase_MemoryFile := Fn_DownloadtoFile("http://www.equibase.com/premium/eqbLateChangeXMLDownload.cfm")
	Fn_ArchiveMemory(Equibase_MemoryFile,"EquibaseXML.txt")
	
	;;Get Harness Track Data from racing channel offered tracks
	Sb_DownloadAllRacingChannel()
}


;Uncomment to select previous race data
;UseExistingXML()

;Assign Var to the file
TodaysFile_Equibase = %A_ScriptDir%\Data\temp\ConvertedXML.txt

;DEPRECIATED - Read XML previously downloaded to File_TB_XML Var
;FileDelete, % TodaysFile_Equibase
;StringReplace, Equibase_MemoryFile, Equibase_MemoryFile, `<,`n`<, All
;FileAppend, %Equibase_MemoryFile%, % TodaysFile_Equibase



;;Counts the number of lines to be used in progress bar calculations and compiles all of RacingChannels HTML to a single file
TB_TXT_Array := StrSplit(Equibase_MemoryFile,"<")
The_EquibaseTotalTXTLines := TB_TXT_Array.MaxIndex()

RacingChannel_bool := False ;RC shut down, skip RC stuff as best as possible
If (RacingChannel_bool) {
		The_RCTotalTXTLines := 0
		TodaysFile_RC = %A_ScriptDir%\Data\temp\RacingChannelHTML.html
	Loop, %A_ScriptDir%\Data\temp\RacingChannel\*.*, 0, 1 ;Recurse into all subfolders (TBred and Harness)
	{
		FileRead, MemoryFile, %A_LoopFileFullPath%
		FileAppend, %MemoryFile%, %TodaysFile_RC%
		Loop, Read, %A_LoopFileFullPath%
		{
			The_RCTotalTXTLines += 1
		}
	}
	Fn_CreateArchiveDir(TodaysFile_RC)
}


;Array_Gui(TB_TXT_Array)

;;Read Each line of Converted Equibase XML to an object containing every horse; their program number, scratch status, etc
Loop, % TB_TXT_Array.MaxIndex() {
	ReadLine := TB_TXT_Array[A_Index]
	;Msgbox, % ReadLine
	/*
		The_HorseName := Fn_QuickRegEx(ReadLine,"horse_name=\x22(.+)\x22\s")
		The_TrackName := Fn_QuickRegEx(ReadLine,"track_name=\x22(.*)\x22 id")
		The_RaceNumber := Fn_QuickRegEx(ReadLine,"race_number=\x22(.*)\x22>")
		RegexMatch(ReadLine, "\sprogram_number=\x22(.*)\x22>", RE_ProgramNumber)
	*/
	
	RegexMatch(ReadLine, "horse_name=\x22(.+)\x22\s", RE_HorseName)
	If (RE_HorseName1 != "") {
		The_HorseName := RE_HorseName1
	}
	
	RegexMatch(ReadLine, "track_name=\x22(.*)\x22 id", RE_TrackName)
	If (RE_TrackName1 != "") {
		The_TrackName := RE_TrackName1
	}
	
	RegexMatch(ReadLine, "race_number=\x22(.*)\x22>", RE_RaceNumber)
	If (RE_RaceNumber1 != "") {
		The_RaceNumber := RE_RaceNumber1
	}
	
	RegexMatch(ReadLine, "\sprogram_number=\x22(.*)\x22>", RE_ProgramNumber)
	If (RE_ProgramNumber1 != "") {
		The_ProgramNumber := RE_ProgramNumber1
		The_EntryNumber := Fn_ConvertEntryNumber(RE_ProgramNumber1)
		The_EntryNumber := The_RaceNumber * 1000 + The_EntryNumber
	}
	
	RegexMatch(ReadLine, "change_description>(\w+)", RE_Scratch)
	If (RE_Scratch1 = "Scratched") {
		The_ScratchGate := 1
	}
	If (RE_Scratch1 = "First") { ;"First Start Since Reported as Gelding" does not allow The_ScratchGate to be entered
		The_ScratchGate := 0
	}
	
	RegexMatch(ReadLine, "new_value>(Y)", RE_Scratch)
	If (RE_Scratch1 != "") {
		If (The_ScratchGate = 1) {
			The_ScratchStatus := 1
		}
	}
	
	RegexMatch(ReadLine, "new_value>(N)", RE_Scratch)
	If (RE_Scratch1 != "") { ;In this case changing to a new_value of 'No' would mean the runner has been livened
		The_ScratchStatus := 9
	}
	
	RegexMatch(ReadLine, "(\/horse>)", RE_Change)
	If (RE_Change1 != "") {
		Fn_InsertHorseData()
		The_HorseName := ""
		The_ScratchStatus := 0
		The_EntryNumber := ""
		The_ProgramNumber := ""
		The_ScratchGate := 0
	}
	Fn_GUI_UpdateProgress(A_Index,The_EquibaseTotalTXTLines)
}


;Create RC Array and Dirs to read from
RacingChannel_Array := []
Dir_TBred = %A_ScriptDir%\Data\temp\RacingChannel\TBred\*.PHP
Dir_Harness = %A_ScriptDir%\Data\temp\RacingChannel\Harness\*.PHP

;;Parse Racing Channel tracks into their own object; also compares to TB AllHorses_Array trying to find matches
Fn_ParseRacingChannel(RacingChannel_Array, TodaysFile_RC)
;Fn_ParseRacingChannel(RacingChannel_Array, Dir_Harness)


;UNUSED SORTING
;Fn_Sort2DArray(AllHorses_Array, "EntryNumber")
;Fn_Sort2DArray(AllHorses_Array, "ProgramNumber")
;Fn_Sort2DArray(AllHorses_Array, "RaceNumber")
;Fn_Sort2DArray(AllHorses_Array, "TrackName")

;For index, obj in AllHorses_Array
;	list3 .= AllHorses_Array[index].ProgramNumber . "    " . AllHorses_Array[index].HorseName . "`n"	
;FileAppend, %list3%, %A_ScriptDir%\allllll.txt


;;Look through the provided array and send scratched CE entries to GUI Listview for User to see
if (Settings.General.AllScratches) {
	Fn_ReadAllScratches(AllHorses_Array)
} else {
	Fn_ReadtoListview(AllHorses_Array)
}

;Add three blank lines between Equibase and Racing Channel Sections 
LV_AddBlank(3)

;;Now look through the RacingChannel Array for any CE entries that may have been missed. Also handles Harness Scratches
RC_AreaAdds := 0
Loop, % RacingChannel_Array.MaxIndex() {
	
	;Added Pools
	if (RacingChannel_Array[A_Index,"AddedWager"] != "") {
		RC_AreaAdds++
		if (RC_AreaAdds = 1) {
			LV_Add("","","","","■  Harness / Racing Channel Only","")
		}
		LV_Add("","","","","► " . RacingChannel_Array[A_Index,"AddedWager"] . " added at " RacingChannel_Array[A_Index,"TrackName"],RacingChannel_Array[A_Index,"RaceNumber"])
	}
	
	;Scratches
	if (RacingChannel_Array[A_Index,"OtherScratch"] = 1) {
		RC_AreaAdds++
		if (RC_AreaAdds = 1) {
			LV_Add("","","","","■ Harness / Racing Channel Only","")
		}
		LV_Add("",RacingChannel_Array[A_Index,"ProgramNumber"],"Scratched","",RacingChannel_Array[A_Index,"HorseName"] . " at " RacingChannel_Array[A_Index,"TrackName"],RacingChannel_Array[A_Index,"RaceNumber"])
	}
}

;;Show number of effected Races so user knows if there is a new change.
guicontrol, Text, GUI_EffectedEntries, % The_EffectedEntries


;;Read listview and color accordingly. This is a subroutine as I want to be able to do it on demand
Sb_RecountRecolorListView()

;;Warn User if there are no racingchannel files

If (RacingChannel_bool) {
	IfNotExist, %A_ScriptDir%\Data\temp\RacingChannel\TBred\*.PHP
	{
		Fn_MouseToolTip("No RacingChannel Data Downloaded. Login and Retry", 10)
	}
	IfNotExist, %A_ScriptDir%\Data\temp\RacingChannel\Harness\*.PHP
	{
		Fn_MouseToolTip("No RacingChannel Data Downloaded. Login and Retry", 10)
	}
}
if (TB_TXT_Array.MaxIndex() < 40) {
	Fn_MouseToolTip("EQUIBASE Data is very small. Check that site is accessible", 10)
}


;;END, Re-enable all GUI buttons
Fn_GUI_UpdateProgress(100)
EnableAllButtons()
BusyVar = 0
Return

;~~~~~~~~~~~~~~~~~~~~~
;Check Results
;~~~~~~~~~~~~~~~~~~~~~
; See class_RaceResults
CheckResults:
Msgbox, This does not work now that Racing Channel shut down
Return

DiableAllButtons()
Fn_GUI_UpdateProgress(1,100)
RaceResultsObj := New RaceResults
RaceResultsObj.ClearTemp()
RaceResultsObj.Download_Tracks()
Fn_GUI_UpdateProgress(25,100)
RaceResultsObj.GetHorseNamesFromPDF()
Fn_GUI_UpdateProgress(50,100)
RaceResultsObj.ParseResults()
RaceResultsObj.CompareResults()

LVA_EraseAllCells("GUI_Listview")
LV_Delete()
RaceResultsObj.Export_into_ListView()
EnableAllButtons()
LV_ModifyCol()
LV_ModifyCol(5, 40)
Fn_GUI_UpdateProgress(100,100)
Return


$F1::
WinActivate, %The_ProjectName%
Goto UpdateButton
Return

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; FUNCTIONS
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
#Include LVA.ahk

Sb_GlobalNameSpace()
{
	global
	
	CE_Arr := [[x],[y]]
	ArrX = 0
	
	AllHorses_Array := []
	Ignored_CE = 4
	
	ScratchCounter := 0
	The_EffectedEntries := 0
	
	FileCreateDir, % Settings.General.SharedLocation . "\Data\archive\DBs"
	A_LF := "`n"
	Return
}


Fn_DownloadtoFile(para_URL)
{
	;Download Page directly to memory
	httpObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1") ;Create the Object
	httpObject.Open("GET",para_URL) ;Open communication
	httpObject.Send() ;Send the "get" request
	Response := httpObject.ResponseText ;Set the "text" variable to the response
	If (Response != "") {
		Return % Response
	} Else {
		Return "null"
	}
}

;Imports Existing Seen Horses DB File
Fn_ImportDBData()
{
	global

	FormatTime, A_Today, , yyyyMMdd
	FileRead, MemoryFile, % Settings.General.SharedLocation . "\Data\archive\DBs\" . A_Today . "_" . The_VersionName . "DB.json"
	SeenHorses_Array := Fn_JSONtooOBJ(MemoryFile)
	MemoryFile := ;Blank
}

;Export Array as a JSON file
Fn_ExportArray()
{
	global
	MemoryFile := Fn_JSONfromOBJ(SeenHorses_Array)
	FileDelete, % Settings.General.SharedLocation . "\Data\archive\DBs\" . A_Today . "_" . The_VersionName . "DB.json"
	FileAppend, %MemoryFile%, % Settings.General.SharedLocation . "\Data\archive\DBs\" . A_Today . "_" . The_VersionName . "DB.json"
	MemoryFile := ;Blank
}



Fn_SeenBeforeChecker(para_Obj)
{
	FormatTime, A_Today, , yyyyMMdd
	FileRead, MemoryFile, % Settings.General.SharedLocation . "\Data\archive\DBs\" . A_Today . "_" . The_VersionName . "DB.json"
	SeenHorses_Array := Fn_JSONtooOBJ(MemoryFile)
	MemoryFile := ;Blank
}

Fn_InsertHorseData()
{
	global
	
	;The_HorseNameLength := StrLen(The_HorseName)
	
	X := AllHorses_Array.MaxIndex() 
	
	If (The_HorseName != "") {
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

Fn_StripleadingZero(para_input)
{
	OutputVar := Fn_QuickRegEx(para_input,"0(\d+)")
	If (OutputVar = "null") {
		return % para_input
	} else {
		return % OutputVar
	}
}

Fn_TitleCase(para_String)
{
	StringUpper, l_ReturnValue, para_String, T
	return %l_ReturnValue%
}


Fn_TrackTitle(para_String)
{
	StringUpper, l_ReturnValue, para_String, T
	Return % "■ " . l_ReturnValue
}

Fn_ParseRacingChannel(para_Array, para_File)
{
	Global AllHorses_Array
	Global The_RCTotalTXTLines
	X := 0
	
	;Read eachline RacingChannel file
	Loop, Read, %para_File%
	{
		Fn_GUI_UpdateProgress(A_Index,The_RCTotalTXTLines)
		;TrackName
		RegExFound := Fn_QuickRegEx(A_LoopReadLine,"<TITLE>(\D+) Changes<\/TITLE>")
		If (RegExFound != "null")
		{
			TrackName := RegExFound
		}
		;RaceNumber    ;<A name=race(\d+) also works
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
		
		;Wagering Added		
		Options_ShowAddedWagers = 1
		If (Options_ShowAddedWagers = 1)
		{
			;Superfecta
			If (InStr(A_LoopReadLine,"superfecta") && InStr(A_LoopReadLine,"add"))
			{
				X++
				para_Array[X,"TrackName"] := TrackName
				para_Array[X,"RaceNumber"] := RaceNumber
				para_Array[X,"AddedWager"] := "Superfecta"
			}
			
			;Trifecta
			If (InStr(A_LoopReadLine,"trifecta") && InStr(A_LoopReadLine,"add"))
			{
				X++
				para_Array[X,"TrackName"] := TrackName
				para_Array[X,"RaceNumber"] := RaceNumber
				para_Array[X,"AddedWager"] := "Trifecta"
			}
			
			;Daily Double
			If (InStr(A_LoopReadLine,"daily double") && InStr(A_LoopReadLine,"add"))
			{
				X++
				para_Array[X,"TrackName"] := TrackName
				para_Array[X,"RaceNumber"] := RaceNumber
				para_Array[X,"AddedWager"] := "Daily Double"
			}
		}
		
		;Status
		REG = scratched (\(part of entry\))
		RegExFound := Fn_QuickRegEx(A_LoopReadLine,REG)
		If (RegExFound != "null" && HorseName != "")
		{
			HorseStatus := 1
			
			X++
			para_Array[X,"TrackName"] := TrackName
			para_Array[X,"RaceNumber"] := RaceNumber
			para_Array[X,"ProgramNumber"] := ProgramNumber
			para_Array[X,"HorseName"] := HorseName
			para_Array[X,"Status"] := HorseStatus
			
			ProgramNumber := "", HorseName := "" , HorseStatus := "" ;Clear all vars
			
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
		If (Obj[A_Index,"Scratched"] = 1) {
			ScratchCheck += 1
		}
		If (Obj[A_Index,"Scratched"] = 9) {
			ReLivened := 1
		} else {
			ReLivened := 0
		}
	}
	
	
	;Only allow scratched or re-lieved entries
	If (ScratchCheck != 0) {
		The_EffectedEntries += 1
		Loop, % Obj.MaxIndex() {
			CurrentHorse := Obj[A_Index,"HorseName"]
			If (Obj[A_Index,"Scratched"] = 0) {
				Status := ""
			}
			If (Obj[A_Index,"Scratched"] = 1) {
				Status := "Scratched"
			}
			If (Obj[A_Index,"Scratched"] = 9) {
				Status := "RE-LIVENED"
			}

			
			;Msgbox, % Obj[A_Index,"ConfirmScratch"] ;Uncomment to see what RacingChannel says for each entry.
			If (Current_Track != Obj[1,"TrackName"]) {
				If (The_EffectedEntries != 1) {
					LV_AddBlank(3)
				}
				LV_Add("","","","",Fn_TrackTitle(Obj[1,"TrackName"]),"")
				Current_Track := Obj[1,"TrackName"]
				Current_Race := ""
			}
			If (Current_Race != Obj[1,"RaceNumber"]) {
				LV_Add("","","","","Race" . Obj[1,"RaceNumber"],"")
				Current_Race := Obj[1,"RaceNumber"]
			}
			LV_Add("",Obj[A_Index,"ProgramNumber"],Status,"",Obj[A_Index,"HorseName"],Obj[A_Index,"RaceNumber"])
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
	Loop, % Obj.MaxIndex() + 1 ;Plus one required if there is a coupled entry at the very end of the array
	{
		;ReRead is needed to review each new horse as the possible 1st entry. that is; each 
		ReRead:

		;If this is the first horse of an entry and the horsename is not blank; put it into the CE_Array0 so that it is remembered
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
		
		;If the two runners numbers match; AND the race number is the same; AND tracknames match
		If (Fn_ComparetwoRunners(Obj[A_Index,"ProgramNumber"],CE_Array[1,"ProgramNumber"]) && Obj[A_Index,"RaceNumber"] = CE_Array[1,"RaceNumber"] && Obj[A_Index,"TrackName"] = CE_Array[1,"TrackName"])
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
		If (CE_Array.MaxIndex() >= 2) ;If 2 or more runners in the entry
		{
			Fn_WriteOutCE(CE_Array)
			CE_Array := []
		}
		FirstHorse_Toggle = 1
		CE_Array := []
		ArrX := 0
		ReRead = 1
		;This Goto can be replaced if a second ArrX variable is used instead of A_Index. Later perhaps.
		Goto ReRead
	}
}


Fn_ComparetwoRunners(para_one,para_two)
{ ;this just simplifies comparison of coupled entries as there are some unique weaknesses in comparing InStr(runner2,runner1)
	runnernumber1 := Fn_QuickRegEx(para_one,"(\d+)")
	runnernumber2 := Fn_QuickRegEx(para_two,"(\d+)")

	if (runnernumber1 = runnernumber2) {
		return true
	} else {
		return false
	}
}


Fn_ReadAllScratches(Obj)
{
	Scratch_Counter := 0
	CE_FirstFound = 0
	ReRead = 0
	FirstHorse_Toggle := 1
	
	;Loop a total time of all horses
	Loop, % Obj.MaxIndex() + 1 ;Plus one required if there is a coupled entry at the very end of the array
	{
		ReRead2:
		;If this is the first horse of an entry and the horsename is not blank; put it into the CE_Array0 so that it is remembered
		;Obj[A_Index,"Scratched"] contains 1 or 0
		If (Obj[A_Index,"Scratched"] = 1 && Obj[A_Index,"HorseName"] != "")
		{ ;Horse going into Scratched Array because it is scratched
			Scratch_Array := []
			ArrX := 1
			Scratch_Array[ArrX,"HorseName"] := Obj[A_Index,"HorseName"]
			Scratch_Array[ArrX,"Scratched"] := Obj[A_Index,"Scratched"]
			Scratch_Array[ArrX,"ProgramNumber"] := Obj[A_Index,"ProgramNumber"]
			Scratch_Array[ArrX,"TrackName"] := Obj[A_Index,"TrackName"]
			Scratch_Array[ArrX,"RaceNumber"] := Obj[A_Index,"RaceNumber"]
			Scratch_Array[ArrX,"ConfirmScratch"] := Obj[A_Index,"RCConfirm"]
			FirstHorse_Toggle := 0
			Continue
		}
		
		;Catchall for any other instances; Runners not a part of an entry will end up here; triggering the next Program Number to be checked.
		If (Scratch_Array.MaxIndex() >= 1) ;If 2 or more runners in the entry
		{
			Fn_WriteOutCE(Scratch_Array)
			Scratch_Array := []
		}
		FirstHorse_Toggle = 1
		Scratch_Array := []
		ArrX := 0
		ReRead = 1
		;This Goto can be replaced if a second ArrX variable is used instead of A_Index. Later perhaps.
		;Goto ReRead2
	}
}


LV_AddBlank(para_number)
{
	Loop, %para_number% {
		LV_Add("", "", "", "", "")
	}
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
	
	FileRemoveDir, %A_ScriptDir%\Data\temp, 1
	FileCreateDir, %A_ScriptDir%\Data\temp
	FileDelete, %A_ScriptDir%\Data\temp\ConvertedXML.txt
	UrlDownloadToFile, http://www.equibase.com/premium/eqbLateChangeXMLDownload.cfm, %A_ScriptDir%\Data\temp\%para_FileName%
	;Copy to Archive
	FileCopy %A_ScriptDir%\Data\temp\%para_FileName%, %A_ScriptDir%\Data\archive\%CurrentYear%\%CurrentMonth%\%CurrentDay%\EquibaseXML_%CurrentDate%.xml, 1
}

UseExistingXML(para_file = "none")
{
	global
	FileRemoveDir, %A_ScriptDir%\Data\temp, 1
	FileCreateDir, %A_ScriptDir%\Data\temp
	FileDelete, %A_ScriptDir%\Data\temp\ConvertedXML.txt
	If (para_file = "none") {
		FileSelectFile, XMLPath,,, Please select an Equibase XML file
		para_file := XMLPath
	}
	FileCopy, %para_file%, %A_ScriptDir%\Data\temp\Today_XML.xml, 1
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
	
	savetime := Settings.General.SharedLocation
	l_ArchivePath = %savetime%\Data\archive\%CurrentYear%\%CurrentMonthNumber%-%CurrentMonth%\%CurrentDay%\
	FileCreateDir, %l_ArchivePath%
	FileCopy, %para_FileToArchive%, %l_ArchivePath%, 1
	Return %l_ArchivePath%
}


Fn_ArchiveMemory(para_VarToArchive,para_Label)
{
	global
	savetime := Settings.General.SharedLocation

	FormatTime, CurrentDate,, MMddyy
	FormatTime, CurrentYear,, yyyy
	FormatTime, CurrentMonth,, MMMM
	FormatTime, CurrentMonthNumber,, MM
	FormatTime, CurrentDay,, dd
	
	l_ArchivePath = %savetime%\Data\archive\%CurrentYear%\%CurrentMonthNumber%-%CurrentMonth%\%CurrentDay%\%para_Label%

	FileDelete, %l_ArchivePath%
	FileAppend, %para_VarToArchive%, % l_ArchivePath
	Return %l_ArchivePath%
}


DownloadSpecified(para_FileToDownload,para_FileName)
{
	SaveLocation = %A_ScriptDir%\Data\temp\%para_FileName%
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
	FileDelete, % Settings.General.SharedLocation . "\Data\archive\DBs\" . A_Today . "_" . The_VersionName . "DB.json"
}


;~~~~~~~~~~~~~~~~~~~~~
; Variables
;~~~~~~~~~~~~~~~~~~~~~

StartUp()
{
	#NoEnv
	#NoTrayIcon
	#SingleInstance force
}


;~~~~~~~~~~~~~~~~~~~~~
;GUI
;~~~~~~~~~~~~~~~~~~~~~

BuildGUI()
{
	Global
	
	CLI_Arg = %1%
	if (CLI_Arg = "Wallboard") {
		guiheight := 70
		guiwidth := 330
		
		guiunhandledtextx := 10
		guiversiontextx := 220
		Gui +AlwaysOnTop
	} else {
		guiheight := 600
		guiwidth := 490
		guiunhandledtextx := 360
		guiversiontextx := 380
	}
	
	
	Gui, Add, Text, x%guiversiontextx% y3 w100 +Right, % "v" The_VersionName
	Gui, Add, Tab, x2 y0 w630 h700 , Scratches|Options
	;Gui, Tab, Scratches
	Gui, Add, Button, x2 y30 w100 h30 gUpdateButton vUpdateButton, Update
	Gui, Add, Button, x102 y30 w100 h30 gCheckResults vCheckResults, Check Results
	; if (Settings.General.ShiftNotesLocation != "") {
	; 	Gui, Add, Button, x202 y30 w100 h30 gShiftNotes vShiftNotes, Open Shift Notes
	; }
	Gui, Add, Button, x202 y30 w100 h30 gSendEmail , Email List
	Gui, Add, Button, x302 y30 w50 h30 gResetDB vResetDB, Reset DB
	Gui, Add, ListView, x2 y70 w490 h536 Grid NoSort +ReDraw gDoubleClick vGUI_Listview, #|Status|Entered|Name|Race|
	Gui, Add, Progress, x2 y60 w100 h10 vUpdateProgress, 1
	
	
	;w200
	Gui, Font, s30 w700, Arial
	Gui, Add, Text, x%guiunhandledtextx% y24 w42 +Right vGUI_UnhandledScratches gMsgUnhandledScratches,
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
	Gui, Add, text, x160 y30, minutes (cannot be lower than 10 mins)
	GUI, Submit, NoHide
	
	;Gui, Add, Button, x2 y30 w100 h30 gUpdateButton, Update
	;Option_Refresh
	;Gui, Add, ListView, x2 y70 w490 h580 Grid Checked, #|Status|Name|Race
	
	;Menu
	Menu, FileMenu, Add, &Update Now, UpdateButton
	Menu, FileMenu, Add, R&estart`tCtrl+R, Menu_File-Restart
	Menu, FileMenu, Add, E&xit`tCtrl+Q, Menu_File-Quit
	Menu, MenuBar, Add, &File, :FileMenu  ; Attach the sub-menu that was created above
	
	Menu, HelpMenu, Add, &About, Menu_About
	Menu, HelpMenu, Add, &Confluence`tCtrl+H, Menu_Confluence
	Menu, MenuBar, Add, &Help, :HelpMenu
	
	Gui, Menu, MenuBar
	
	
	if (CLI_Arg = "Wallboard") {
		GuiControl, Hide, UpdateButton
		GuiControl, Hide, UpdateProgress
		GuiControl, Hide, CheckResults
		GuiControl, Hide, ShiftNotes
		GuiControl, Hide, ResetDB
		;Check for new scratches every 15 mins
		SetTimer, UpdateButton, 900000
		
		;Update Wallboard display number every 30 seconds
		SetTimer, UpdateListView, 30000
		Sb_RecountRecolorListView()
	} else {
		
	}
	Gui, Show, h%guiheight% w%guiwidth%, %The_ProjectName%
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
	
	If (RefreshMilli >= 10 && GUI_RefreshCheckBox = 1) {
		RefreshMilli := RefreshMilli * 60000
		GuiControl,, GUI_RefreshCheckBox, 1
		SetTimer, UpdateButton, -100
		Sleep 300
		SetTimer, UpdateButton, %RefreshMilli%
	}
	If (GUI_RefreshCheckBox = 0) {
		GuiControl,, GUI_RefreshCheckBox, 0
		SetTimer, UpdateButton, Off
	}
	Return
	
	
	;Menu Shortcuts
	Menu_Confluence:
	Run https://betfairus.atlassian.net/wiki/display/wog/Ops+Tool+-+Scratch+Detector
	Return
	
	Menu_About:
	Msgbox, Checks Equibase for coupled entry scratches. Crosschecks with RacingChannel. `n%The_VersionName%
	Return
	
	Menu_File-Restart:
	Reload
	Menu_File-Quit:
	ExitApp
	
	
	ShiftNotes:
	Today:= %A_Now%
	FormatTime, CurrentDateTime,, MMddyy
	Run % Settings.General.ShiftNotesLocation . "\" . CurrentDateTime . ".xlsx"
	Return
	
	ResetDB:
	Fn_DeleteDB()
	Fn_ImportDBData()
	Sb_RecountRecolorListView()
	Return

	SendEmail:
	MailObj := {}
	MailObj.html := Sb_GenerateHTMLMail()
	MailObj.subject := "Coupled Entry Scratches - " A_Today
	MailObj.to := Config.mailto
	; para_MailObj := "{""to"":""user@domain.com"", ""subject"": ""hello"", ""html"": ""<br><strong>hi</strong></br>"" }"
	; msgbox, % Fn_JSONfromOBJ(MailObj)
	clipboard := JSON.stringify(MailObj)
	Fn_SendHTTPMail(JSON.stringify(MailObj),"http://wogutilityd01:8080/mail")
	Return
	
	UpdateListView:
	If (BusyVar != 1 && Fn_StripleadingZero(A_Hour) > 4 && CLI_Arg = "Wallboard") {
		Fn_ImportDBData()
		Sb_RecountRecolorListView()
	}
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
		FormatTime, CurrentTime,, Time
		SeenHorses_Array[X2,"HorseName"] := RowText
		SeenHorses_Array[X2,"ScratchedonTVGTimeStamp"] := CurrentTime
		Fn_ExportArray()
		Sb_RecountRecolorListView()
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
			If (InStr(Buffer_Name,"Racing Channel"))
			{
				Ignore_Bool := True
			}
			;Get the Race Number as a header, lead, thing
			If (!InStr(Buffer_Name,"■") && Buffer_ProgramNumber = "" && Ignore_Bool = False)
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
	GuiControl, enable, Check Results
	GuiControl, enable, Open Shift Notes
}


EndGUI()
{
	global
	
	Gui, Destroy
}

;Racing Channel Shut Down. Do not bother the user------------------------------
;Fn_MouseToolTip("No RacingChannel Data Downloaded", 10)
;MouseGetPos, M_PosX, M_PosY, WinID
;ToolTip, "No RacingChannel Data Downloaded", M_PosX, M_PosY, 1
;ToolTip


GuiClose:
ExitApp

;~~~~~~~~~~~~~~~~~~~~~
;Subroutines
;~~~~~~~~~~~~~~~~~~~~~

Sb_RecountRecolorListView()
{
	global
	Data_UnHandledRunners := 0
	Data_TotalScratches := 0
	LVA_EraseAllCells("GUI_Listview")
	
	Loop % LV_GetCount() {
		The_OuterIndex := A_Index
		LV_GetText(Buffer_ProgramNumber, A_Index, 1)
		LV_GetText(Buffer_Status, A_Index, 2)
		LV_GetText(Buffer_Name, A_Index, 4) ;Commonly the Horsename but sometimes not. 
		If (InStr(Buffer_Name,"■"))	{
			LVA_SetCell("GUI_Listview", A_Index, 0, "f0f0f0") ;Set to grey if this is a track header
			Continue
		}
		If (InStr(Buffer_Name, "►")) {
			LVA_SetCell("GUI_Listview", A_Index, 0, "b7ffb7") ;Set to light green if this is an added wager pool
			Continue
		}
		If (Buffer_ProgramNumber != "") {
			If (Buffer_Status != "") {
				Data_TotalScratches += 1
			}
			
			Loop, % SeenHorses_Array.MaxIndex()	{
				If (SeenHorses_Array[A_Index,"HorseName"] = Buffer_Name) {
					LV_Modify(The_OuterIndex, , , , SeenHorses_Array[A_Index,"ScratchedonTVGTimeStamp"])
					If (Buffer_Status = "RE-LIVENED") {
						LVA_SetCell("GUI_Listview", The_OuterIndex, 0, "red") ;Set to Red if it is a "RE-LIVENED" Horse
						Data_UnHandledRunners += 1
					}
					Continue 2
				}
			}
			If (Buffer_Status = "Scratched")	{
				LVA_SetCell("GUI_Listview", A_Index, 0, "ff7f27") ;Set to Orange if this horse hasn't been doubleclicked yet.
				Data_UnHandledRunners += 1
			}
			If (Buffer_Status = "RE-LIVENED") {
				LVA_SetCell("GUI_Listview", A_Index, 0, "red") ;Set to Red if it is a "RE-LIVENED" Horse
			}
		}
	}
	
	;Fix Default Size of all Columns in Listview
	LV_ModifyCol(1)
	LV_ModifyCol(2)
	LV_ModifyCol(3, 60)
	LV_ModifyCol(4)
	LV_ModifyCol(5, 40)
	LV_ModifyCol(6, 100)
	
	;Refresh the Listview colors (Redraws the GUI Control
	LVA_Refresh("GUI_Listview")
	OnMessage("0x4E", "LVA_OnNotify")
	Guicontrol, +ReDraw, GUI_Listview
	LVA_Refresh("GUI_Listview")
	LVA_Refresh("GUI_Listview")
	
	
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
}

Sb_GenerateHTMLMail()
{
	global
	
	;;Generate e-mail HTML
	FormatTime, LongDate,, LongDate
	EmailBody := "Coupled Entry Scratches " . LongDate . ":<br><br>"
	EmailBody = %EmailBody% <style type="text/css">
	EmailBody := EmailBody . ".tg  {border-collapse:collapse;border-spacing:0;border-color:#ccc;}"
	EmailBody := EmailBody . ".tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#ccc;color:#333;background-color:#fff;}"
	EmailBody := EmailBody . ".tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#ccc;color:#333;background-color:#f0f0f0;}"
	EmailBody := EmailBody . ".tg .tg-4eph{background-color:#f9f9f9}"
	EmailBody = %EmailBody% </style>
	<table class="tg">
	<tbody>
	<tr>
	<th class="tg-031e">#</th>
	<th class="tg-031e">Status</th>
	<th class="tg-031e"></th>
	<th class="tg-031e">Name</th>
	</tr>

	Loop % LV_GetCount() {
		The_OuterIndex := A_Index
		LV_GetText(Buffer_ProgramNumber, A_Index, 1)
		LV_GetText(Buffer_Status, A_Index, 2)
		LV_GetText(Buffer_Name, A_Index, 4) ;Commonly the Horsename but sometimes not. 
		
		
		;Alternate the Table color style
		Alternate := Mod(A_Index, 2)
		If (Alternate = 1) {
			HTMLClass = class="tg-031e"
		} Else {
			HTMLClass = class="tg-4eph"
		}
		
		StringReplace, Buffer_Name, Buffer_Name, ■, , All
		EmailBody = %EmailBody%<tr>
		<td %HTMLClass%>%Buffer_ProgramNumber%</td>
		<td %HTMLClass%>%Buffer_Status%</td>
		<td %HTMLClass%> </td>
		<td %HTMLClass%>%Buffer_Name%</td>
		</tr>
	}

	EmailBody = %EmailBody%	</tbody>
	</table>

	EmailBody = %EmailBody%<br><br><br><strong> TVG Wager Operations</strong><br>
	EmailBody = %EmailBody%&#128222;(503) 748-3823<br>
	EmailBody = %EmailBody%<small>This email (which includes any attachment and any subsequent reply) is sent for and on behalf of one or more operating entities in the Betfair Group, details of which are available <a href="http://corporate.betfair.com/about-us.aspx">here</a>. The information in this e-mail is confidential. As such it is intended only for the named recipient(s). This e-mail may not be disclosed or used by any person other than the addressee, nor may it be copied in any way. If you are not a named recipient please notify the sender immediately and delete any copies of this email. Any unauthorized copying, disclosure or distribution of the material in this e-mail is strictly forbidden. Any view or opinions expressed do not reflect those of the author and do not necessarily represent those of the Betfair Group. Betfair&#174; and the BETFAIR LOGO are registered trademarks of The Sporting Exchange Limited.</small><br>

	return EmailBody
}


SC_NotifyNewScratches(para_RandomInput)
{
	global
	;Create storage if not existing yet
	If (Scratches_Array = "") {
		Scratches_Array := []
	}
	Scratches_Array.push(para_RandomInput)
	;8 seconds
	SetTimer, EmailChanges, -8000
	Return


	EmailChanges:
	Email_Array := []
	;loop all coupled entry horsenames
	Loop, Scratches_Array.MaxIndex() {
		If (Fn_SeenBeforeChecker(Scratches_Array[A_Index])) {
			Email_Array.push(Scratches_Array[A_Index])
		}
	}

	If (Email_Array.MaxIndex() != 0) {
		;Fn_SendEmail(Email_Array)
	}
}

Sb_SettingsImport()
{
	global
	
	SettingsFile = %A_ScriptDir%\Settings.ini
	if !(Settings := Fn_IniRead(SettingsFile))
	{
		Settings =
		( LTrim
		[General]`n`r
		SharedLocation = \\tvgops\pdxshares\wagerops\Tools\Scratch-Detector`n`r
		ShiftNotesLocation = \\tvgops\pdxshares\wagerops\Daily Shift Notes`n`r
		)
		
		File := FileOpen(SettingsFile, "w")
		File.Write(Settings), File.Close()
		
		MsgBox, There was a problem reading your settings file. A new Settings.ini was generated.`nRe-running the program will now use default settings.
		
		ExitApp
	}
	
}


Sb_DownloadAllRacingChannel()
{
	;Clear Dir
	FileRemoveDir, %A_ScriptDir%\Data\temp, 1
	FileCreateDir, %A_ScriptDir%\Data\temp

	;Download TBred and Harness from RacingChannel
	FileCreateDir, %A_ScriptDir%\Data\temp\RacingChannel
	FileCreateDir, %A_ScriptDir%\Data\temp\RacingChannel\TBred
	DownloadSpecified("http://tote.racingchannel.com/MEN----T.PHP","RacingChannel\TBred_Index.html")
	
	
	;Download each racing channel page that is part of the index page
	Loop, Read, %A_ScriptDir%\Data\temp\RacingChannel\TBred_Index.html
	{
		REG = A HREF="(\S+)"><IMG SRC="\/images\/CHG.gif        ;"
		Buffer_TrackCode := Fn_QuickRegEx(A_LoopReadLine,REG)
		If (Buffer_TrackCode != "null")
		{
			UrlDownloadToFile, https://tote.racingchannel.com/%Buffer_TrackCode%, %A_ScriptDir%\Data\temp\RacingChannel\TBred\%Buffer_TrackCode%
		}
	}
	
	FileCreateDir, %A_ScriptDir%\Data\temp\RacingChannel
	FileCreateDir, %A_ScriptDir%\Data\temp\RacingChannel\Harness
	DownloadSpecified("http://tote.racingchannel.com/MEN----H.PHP","RacingChannel\Harness_Index.html")
	
	Loop, Read, %A_ScriptDir%\Data\temp\RacingChannel\Harness_Index.html
	{
		REG = A HREF="(\S+)"><IMG SRC="\/images\/CHG.gif        ;"
		Buffer_TrackCode := Fn_QuickRegEx(A_LoopReadLine,REG)
		If (Buffer_TrackCode != "null")
		{
			UrlDownloadToFile, https://tote.racingchannel.com/%Buffer_TrackCode%, %A_ScriptDir%\Data\temp\RacingChannel\Harness\%Buffer_TrackCode%
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
