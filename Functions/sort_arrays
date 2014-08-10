;Fn_Sort2DArrayFast Notes
; the sort command only takes a fraction of the function time, the rest is spent
; iterating and copying the data
; Test:
; Object: 
/*
    loop 10000
         a.insert({ "key": rand(1,10), "another": "b"})
*/
; Old Bubble Search
; Bubble took 54,032 ms
; New sort took 26.7 ms (2,023x Faster!)
Fn_Sort2DArrayFast(byRef a, key, Ascending := True)
{
    for index, obj in a
        out .= obj[key] "+" index "|" ; "+" allows for sort to work with just the value
    ; out will look like:   value+index|value+index|

    v := a[a.minIndex(), key]
    if v is number 
        type := " N "
    StringTrimRight, out, out, 1 ; remove trailing | 
    Sort, out, % "D| " type  (!Ascending ? " R" : " ")
    aStorage := []
    loop, parse, out, |
       aStorage.insert(a[SubStr(A_LoopField, InStr(A_LoopField, "+") + 1)])
    a := aStorage
    return
}




;Fn_Sort2DArray Notes. Use This if you need to sort by two keys or more
; A modified bubble search
; This is slow, but very useful.
; If called in the correct sequence, you can completely order 
; a 2 dimensional array by as many keys as you want (and in any order)!
; i.e. some keys can be ascending, while others can be descending 

; to achieve this, simply call the function multiple times
; beginning with the lowest priority key, and ending with the highest priority key 

; Note: Bubble sorts become increasingly slower as the number of items increase



; Note: Their original index values will be lost
;       the final object will have indices from 1 to the number of items in the original object
;
; Note: If the object being passed resides within another object,
; byRef wont affect it - so need to use the returned object e.g. aObject := reverse2DArray(aObject)
Fn_Sort2DArray(Byref a, key, ascending := True) 
{
    aStorage := []
    unsorted := True 
    While unsorted 		                        
	{           					            
        unsorted := False                      
        For index, in a  		 
		{
            if (lastIndex = index)          ; This speeds it up (almost halves the time)
                break                  
            if (A_Index > 1) &&  (ascending 
                                    ? (a[prevIndex, key] > a[index, key]) 
                                    : (a[prevIndex, key] < a[index, key])) 
			{       
                ; making this a single line expression saves ~20 ms on a 1000 index array
                aStorage := a[index]
                , a[index] := a[prevIndex]
                , a[prevIndex] := aStorage
                , unsorted := True			
            }         
            prevIndex := index
        }  
        lastIndex := prevIndex ; previous maxIndex reached (i.e. position of the last moved highest/lowest number)
        ; on each pass through the current highest number will be moved to 1 spot before 'lastIndex'
        ; i.e. towards the right
        ; As we know these values at the end are already the sorted
        ; we can break, and don't have to worry about comparing them again
    }
}





;Fn_ReverseArray Notes
/*
; A slower way to achieve same result
; This is ~7.5X slower
reverseArraySort(Byref a)
{
    for index, in a
        lIndex .= index ","
    StringTrimRight, lIndex, lIndex, 1 
    sort, lIndex, D`, N R 
    aStorage := []
    loop, parse, lIndex, `,
        aStorage.insert(a[A_LoopField]) 
    a := aStorage
    return aStorage
}
An even slower way is to use AHKs Object.Insert(1, Value)
But this is really really slow, as it has to re-adjust every 
value's position when another one is added.
reverseArrayInsert(Byref a)
{
    aStorage := []
    for index, v in a
        aStorage.insert(1, V)
     a := aStorage
    return aStorage
}

This is ~930x slower for a 10,000 key object.
And probably becomes exponentially slower as the number of keys
increase.
*/
Fn_ReverseArray(Byref a)
{
    aIndices := []
    for index, in a
        aIndices.insert(index)
    aStorage := []
    loop % aIndices.maxIndex() 
       aStorage.insert(a[aIndices[aIndices.maxIndex() - A_index + 1]]) 
    a := aStorage
    return aStorage
}









;Fn_RandomiseArray Notes
; This can only be used if you want to order the array
; by one key, and you dont care about how any of the other key values
; are ordered (when there are multiple sorted keys with the same value)
; eg sort could result in something like this:

; sortedKey:     1     associatedKey:   0
; sortedKey:     2     associatedKey:   2*   Higher
; sortedKey:     2     associatedKey:   1*   Lower
; sortedKey:     2     associatedKey:   3
; sortedKey:     3     associatedKey:   12

; (the associated keys will still be paired with their associated sorted key)   
; Keys/Values should not contain the chars + or |
Fn_RandomiseArray(byref a)
{
    aIndicies := []
    for i, in a 
         aIndicies.insert(i)
    for index, in a
    {
        Random, i, 1, aIndicies.MaxIndex()
        storage := a[aIndicies[i]]
        , a[aIndicies[i]] := a[index]
        , a[index] := storage   
    }
    return
}