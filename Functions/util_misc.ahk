; Version 0.5 of all around useful functions

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Quick RegEx for quick matches. Remember to include match parenthesis (\d+).+ Returns matched value
;Fn_QuickRegEx(A_LoopRealLine,"(\d+)")
Fn_QuickRegEx(para_Input,para_RegEx,para_ReturnValue := 1)
{
	RegExMatch(para_Input, para_RegEx, RE_Match)
	If (RE_Match%para_ReturnValue% != "") {
		ReturnValue := RE_Match%para_ReturnValue%
		Return %ReturnValue%
	}
Return "null"
}

Fn_ReplaceString(para_1,para_2,para_String)
{
	Return	StrReplace(para_String, para_1, para_2)
}

Fn_InArray(Obj,para_Search,para_Table := "")
{
	If (para_Table = "") {
		Loop % Obj.MaxIndex() {
			If(Obj[A_Index] = para_Search)	{
			Return 1
			}
		}
		;Return 0 if the search did not find any match
		Return 0
	}
	
	If (para_Table != "") {
		Loop % Obj.MaxIndex() {
			If(Obj[A_Index,para_Table] = para_Search)	{
			Return 1
			}
		}
		;Return 0 if the search did not find any match
		Return 0
	}
Return 0
}

Fn_SearchArrayReturnOther(Obj,para_Search,para_SearchTable,para_ReturnTable)
{
	Loop % Obj.MaxIndex() {
		If(Obj[A_Index,para_SearchTable] = para_Search)	{
		Return Obj[A_Index,para_ReturnTable]
		}
	}
Return "null"
}


Fn_SearchArrayReturnTrue(Obj,para_Search,para_SearchTable)
{
	Loop % Obj.MaxIndex() {
		If(Obj[A_Index,para_SearchTable] = para_Search) {
		Return true
		}
	}
Return false
}


Fn_SearchSimpleArray(Obj,para_Search)
{
	Loop % Obj.MaxIndex() {
		If (Obj[A_Index] = para_Search) {
		Return true
		}
	}
Return false
}


Fn_DateParser(str)
{
	date_array := []
	d_array := []

	;remove all spaces and non-numbers
	str := regexreplace(regexreplace(regexreplace(str
                  , "[^,\d]+", " ")
                  , ",", "")
                  , "^\s*(\S.*\S|\S)\s*$", "$1")

	try {
		RegExMatch(str, "(\d{8})", RE_Match)
		if (RE_Match1 != "") {
			FormatTime, local_date, %RE_Match1%000000, yyyyMMddHHmmss
			if (Fn_IsValidDate(local_date)) {
				date_array.push(StringTrimRight(local_date,6))
			}
		}
	}
	catch {
	}
	
	try {
		RegExMatch(str, "(\d{4}).*(\d{2}).*(\d{2})", RE_Match)
		if (RE_Match3 != "") {
			FormatTime, local_date, %RE_Match1%%RE_Match2%%RE_Match3%000000, yyyyMMddHHmmss
			if (Fn_IsValidDate(local_date)) {
				date_array.push(StringTrimRight(local_date,6))
			}
			FormatTime, local_date, %RE_Match1%%RE_Match3%%RE_Match2%000000, yyyyMMddHHmmss
			if (Fn_IsValidDate(local_date)) {
				date_array.push(StringTrimRight(local_date,6))
			}
		}
	}
	catch {
	}

	try {
		RegExMatch(str, "(\d{2}).*(\d{2}).*(\d{4})", RE_Match)
		if (RE_Match3 != "") {
			FormatTime, local_date, %RE_Match3%%RE_Match1%%RE_Match2%000000, yyyyMMddHHmmss
			if (Fn_IsValidDate(local_date)) {
				date_array.push(StringTrimRight(local_date,6))
			} 
			FormatTime, local_date, %RE_Match3%%RE_Match2%%RE_Match1%000000, yyyyMMddHHmmss
			if (Fn_IsValidDate(local_date)) {
				date_array.push(StringTrimRight(local_date,6))
			}
		}
	}
	catch {
	}
	

	try {
		static e2 = "i)(?:(\d{1,2}+)[\s\.\-\/,]+)?(\d{1,2}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*)[\s\.\-\/,]+(\d{2,4})"
		str := RegExReplace(str, "((?:" . SubStr(e2, 42, 47) . ")\w*)(\s*)(\d{1,2})\b", "$3$2$1", "", 1)
		if RegExMatch(str, "i)^\s*(?:(\d{4})([\s\-:\/])(\d{1,2})\2(\d{1,2}))?"
			. "(?:\s*[T\s](\d{1,2})([\s\-:\/])(\d{1,2})(?:\6(\d{1,2})\s*(?:(Z)|(\+|\-)?"
			. "(\d{1,2})\6(\d{1,2})(?:\6(\d{1,2}))?)?)?)?\s*$", i)
			d3 := i1, d2 := i3, d1 := i4, t1 := i5, t2 := i7, t3 := i8
		Else if !RegExMatch(str, "^\W*(\d{1,2}+)(\d{2})\W*$", t)
			RegExMatch(str, "i)(\d{1,2})\s*:\s*(\d{1,2})(?:\s*(\d{1,2}))?(?:\s*([ap]m))?", t)
				, RegExMatch(str, e2, d)
		f = %A_FormatFloat%
		SetFormat, Float, 02.0
		d := (d3 ? (StrLen(d3) = 2 ? 20 : "") . d3 : A_YYYY)
			. ((d2 := d2 + 0 ? d2 : (InStr(e2, SubStr(d2, 1, 3)) - 40) // 4 + 1.0) > 0
				? d2 + 0.0 : A_MM) . ((d1 += 0.0) ? d1 : A_DD) . t1
				+ (t1 = 12 ? t4 = "am" ? -12.0 : 0.0 : t4 = "am" ? 0.0 : 12.0) . t2 + 0.0 . t3 + 0.0
		SetFormat, Float, %f%
		date_array.push(StringTrimRight(d,6))
	}
	catch {
	}

	Loop, % date_array.MaxIndex() {
		d_array[A_Index,"date"] := date_array[A_Index]
		d_array[A_Index,"distance"] := DateDiff(date_array[A_Index], A_Now,"days")
	}
	Fn_Sort2DArray(d_array,"date")
	Fn_Sort2DArray(d_array,"distance")
	; Array_Gui(d_array)
	;return tomorrows date if exists
	TomorrowsDate := A_Now
	TomorrowsDate += 1, days
	Loop, % d_array.MaxIndex() {
		if (d_array[A_Index,"date"] = FormatTime(TomorrowsDate, "yyyyMMdd")) {
			; msgbox, % "returning tom: " . d_array[A_Index,"date"] . " for: " . str
			return d_array[A_Index,"date"]
		}
	}
	;return first possible positive date (including today)
	Loop, % d_array.MaxIndex() {
		if (d_array[A_Index,"distance"] >= 1 && d_array[A_Index,"distance"] < 30) {
			; msgbox, % "returning other: " . d_array[A_Index,"date"] . " for: " . str
			return d_array[A_Index,"date"]
		}
	}
	;return false if no good results
	return false
}

DateDiff(DateTime1, DateTime2, TimeUnits)
{
    EnvSub DateTime1, %DateTime2%, %TimeUnits%
    return DateTime1
}

Fn_IsValidDate(para_Input) {
	FormatTime, local_date, %para_Input%, yyyyMMddHHmmss
	if (local_date != 000000) {
		return true
	} else {
		return false
	}
}

Fn_HasVal(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return -1
	for index, value in haystack
		if (value = needle)
			return index
	return -1
}

Fn_IndexOf(para_array,para_Input,para_Key := false) {
	; non-key version first
	if (para_Key = false) {
		loop % para_array.MaxIndex() {
			if (para_array[A_Index] = para_Input) {
				return A_Index
			}
		}
		return -1
	}

	; key version
	loop % para_array.MaxIndex() {
		if (para_array[A_Index,para_Key] = para_Input) {
			return A_Index
		}
	}
	return -1
}

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Allows for remote shutdown
Sb_RemoteShutDown()
{
SetTimer, RemoteShutDown, 2520000 ;42 mins
Return
RemoteShutDown:
l_Shutdownfile = %A_ScriptDir%\shutdown.cmd
	If (FileExist(l_Shutdownfile)) {
	ExitApp
	}
Return
}

;Debug_Msg is for showing a variable or two instead of msgbox
Debug_Msg(message)
{
Progress, 100, %message%, , , 
}
