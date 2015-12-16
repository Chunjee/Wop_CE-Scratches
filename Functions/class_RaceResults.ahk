/*
DVR%A_Index% := New DVR(Name,BaseURL)
DVR%A_Index%.CheckStatus()
DVR%A_Index%.CheckStatistics()

;Update GUI Box of each DVR
DVR%A_Index%.UpdateGUI()

*/

Class RaceResults {
	
	__New(para_Name,para_Location) {
		this.Info_Array := []
	}
	
	
	
	
	ClearTemp() {
	FileRemoveDir, %A_ScriptDir%\Data\temp, 1
	FileCreateDir, %A_ScriptDir%\Data\temp\RacingChannel\TrackResults
	}
	
	
	
	
	Download_Tracks() {
	;Download each thing
	DownloadSpecified("http://tote.racingchannel.com/MEN----T.PHP","RacingChannel\TBred_Index.html")
	DownloadSpecified("http://tote.racingchannel.com/MEN----H.PHP","RacingChannel\Harness_Index.html")
	Results_Loc := A_ScriptDir . "\Data\temp\RacingChannel\TrackResults\"
	this.Results_Loc := Results_Loc
	
		Loop, Read, %A_ScriptDir%\Data\temp\RacingChannel\TBred_Index.html
		{
			REG = A HREF="(\S+)"><IMG SRC="\/images\/RES.gif
			;"
			Buffer_TrackCode := Fn_QuickRegEx(A_LoopReadLine,REG)
			If (Buffer_TrackCode != "null")
			{
				UrlDownloadToFile, https://tote.racingchannel.com/%Buffer_TrackCode%, %Results_Loc%%Buffer_TrackCode%
			}
		}
		Loop, Read, %A_ScriptDir%\Data\temp\RacingChannel\Harness_Index.html
		{
			REG = A HREF="(\S+)"><IMG SRC="\/images\/RES.gif
			;"
			Buffer_TrackCode := Fn_QuickRegEx(A_LoopReadLine,REG)
			If (Buffer_TrackCode != "null")
			{
				UrlDownloadToFile, https://tote.racingchannel.com/%Buffer_TrackCode%, %Results_Loc%%Buffer_TrackCode%
			}
		}
		
		Dir_TBred = %A_ScriptDir%\Data\temp\RacingChannel\TBred\*.PHP
	}
	
	
	
	
	
	GetHorseNamesFromPDF() {
		;\\tvgops\pdxshares\wagerops\Daily Recaps and Pool Defs\10-21-15 Reports
		TodaysDateRAW := A_Now
		TodaysDateRAW += -3, h
		FormatTime, TodaysDateDate, %TomorrowsDateRAW%, MMddyy
		FormatTime, TodaysDateDashes, %TomorrowsDateRAW%, MM-dd-yy
		this.TodaysDateDashes := TodaysDateDashes
		
		PDF_Loc := "\\tvgops\pdxshares\wagerops\Daily Recaps and Pool Defs\" . TodaysDateDashes . " Reports\" . TodaysDateDate . " Coupled Entries.pdf"
		TXT_Loc := A_ScriptDir . "\Data\temp\CEHorses.txt"
		
		;Export that pdf to TXT
		FileCopy, %A_ScriptDir%\Data\PDFtoTEXT, %A_ScriptDir%\Data\PDFtoTEXT.exe
		RunWait, %comspec% /c %A_ScriptDir%\Data\PDFtoTEXT.exe -raw "%PDF_Loc%" %A_ScriptDir%\Data\temp\CEHorses.txt,,Hide
		FileDelete, %A_ScriptDir%\Data\PDFtoTEXT.exe
		
		;Load Text into an array
		FileRead, The_MemoryFile, % TXT_Loc
		Txt_Array := StrSplit(The_MemoryFile, "`r`n")
		
		;Get Horse Names and Track out of the text
		X = 0
		Loop, % Txt_Array.MaxIndex() {
			If (A_Index = 1) {
			Continue ;Skip first line
			}
			Track := Fn_QuickRegEx(Txt_Array[A_Index],"([ \w]+) (\d+)")
			Race := Fn_QuickRegEx(Txt_Array[A_Index],"(\w+) (\d+)", 2)
			If (Track != "null") {
				Track_Saved := Track
				Race_Saved := Race
			}
			
			Entry := Fn_QuickRegEx(Txt_Array[A_Index],"(\d\w*) ([\w\s]+)")
			Name := Fn_QuickRegEx(Txt_Array[A_Index],"(\d\w*) ([\w\s]+)", 2)
			
			If (Name != "null") {
				X++
				this.Info_Array[X,"Entry"] := Entry
				this.Info_Array[X,"Name"] :=  Name
				this.Info_Array[X,"Track"] :=  Track_Saved
				this.Info_Array[X,"Race"] :=  Race_Saved
			}
		}
	}
	
	
	
	
	;blah blah blah, understand all the downloaded files
	ParseResults() {
		this.Results_Array := []
	
		Name_Saved := "null"
		Place := "null"
		X = 0
		Loop, Files, % this.Results_Loc . "*" 
		{
			FileRead, The_MemoryFile, % A_LoopFileFullPath
			Txt_Array := StrSplit(The_MemoryFile, "`r`n")
			Loop, % Txt_Array.MaxIndex() { 
				REG = NAME="1STNAME"><B>(.+)<\/B>
				Name := Fn_QuickRegEx(Txt_Array[A_Index],REG)
				If (Name != "null") {
					Name_Saved := Name
					Place = 1st
				}
				REG = NAME="2NDNAME"><B>(.+)<\/B>
				Name := Fn_QuickRegEx(Txt_Array[A_Index],REG)
				If (Name != "null") {
					Name_Saved := Name
					Place = 2nd
				}
				REG = NAME="3RDNAME"><B>(.+)<\/B>
				Name := Fn_QuickRegEx(Txt_Array[A_Index],REG)
				If (Name != "null") {
					Name_Saved := Name
					Place = 3rd
				}
				REG = NAME="4THNAME"><B>(.+)<\/B>
				Name := Fn_QuickRegEx(Txt_Array[A_Index],REG)
				If (Name != "null") {
					Name_Saved := Name
					Place = 4th
				}
				REG = NAME="5THNAME"><B>(.+)<\/B>
				Name := Fn_QuickRegEx(Txt_Array[A_Index],REG)
				If (Name != "null") {
					Name_Saved := Name
					Place = 5th
				}
				
				If (Name_Saved != "null") {
					X++
					this.Results_Array[X,"Name"] := Name_Saved
					this.Results_Array[X,"Place"] := Place
				}
				Name_Saved := "null"
			}
		}
		;Array_GUI(this.Results_Array)
	}
	
	
	
	
	CompareResults() {
		this.ListView_Array := []
		Y = 0
		
		;For Each Placing Horse...
		Loop, % this.Results_Array.MaxIndex() {
		X := A_Index
			;Check if it is in the Coupled Entries List
			Loop, % this.Info_Array.MaxIndex() {
				/*If (this.Results_Array[X,"Name"] = "Sunny Daze") {
					MSgbox, % this.Results_Array[X,"Name"] . "   " . this.Info_Array[A_Index,"Name"] . " - " . this.Results_Array[X,"Place"]
				}
				*/
				
				;If there is a match
				If (this.Results_Array[X,"Name"] = this.Info_Array[A_Index,"Name"])	{
					this.Info_Array[A_Index,"ListView"] = True
					this.Info_Array[A_Index,"Place"] := this.Results_Array[X,"Place"]
					/*;Nevermind - why make 3rd array?
					Y++
					
					ListView_Array[Y,"Entry"] = Info_Array[A_Index,"Entry"]
					ListView_Array[Y,"Name"] = Info_Array[A_Index,"Name"]
					ListView_Array[Y,"Place"] = Results_Array[X,"Place"]
					*/
				}
			}
		}
	}
	
	
	
	
	Export_into_ListView() {
	Global
		;Clear ListView
		OutPutBool = False
		
		Loop, % this.Info_Array.MaxIndex() {
			If (this.Info_Array[A_Index,"Place"] != "") {
				OutPutBool = True
				LV_Add("",this.Info_Array[A_Index,"Entry"],this.Info_Array[A_Index,"Place"],this.Info_Array[A_Index,"Track"],this.Info_Array[A_Index,"Name"],this.Info_Array[A_Index,"Race"])
			}
		}

		If (OutPutBool = False) {
			LV_Add("","","No Coupled Entries have placed on " . this.TodaysDateDashes,"","","")
		}
	}
}