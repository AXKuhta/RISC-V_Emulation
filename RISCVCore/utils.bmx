Import BRL.Retro

' Read a 16 bit value (normal)
Function ReadMemory16:Short(Addr:Byte Ptr)
	Local ShortPtr:Short Ptr = Short Ptr(Addr)
	
	Return ShortPtr[0]
End Function

' Read a 16 bit value in reverse endian order
Function ReadMemory16RE:Short(Addr:Byte Ptr)
	Local ShortValue:Short = 0
	Local ShortPtr:Byte Ptr = Varptr ShortValue
	
	ShortPtr[0] = Addr[1]
	ShortPtr[1] = Addr[0]
		
	Return ShortValue
End Function

' Write a 16 bit value (normal)
Function WriteMemory16(ShortValue:Short, Addr:Byte Ptr)
	Local MemPtr:Short Ptr = Short Ptr(Addr)
	
	MemPtr[0] = ShortValue
End Function

' Write a 16 bit value in reverse endian order
Function WriteMemory16RE(ShortValue:Short, Addr:Byte Ptr)
	Local ShortPtr:Short Ptr = Varptr ShortValue
	
	Addr[0] = ShortPtr[1]
	Addr[1] = ShortPtr[0]
End Function

' Read a 32 bit value (normal)
Function ReadMemory32:Int(Addr:Byte Ptr)
	Local IntPtr:Int Ptr = Int Ptr(Addr)
	
	Return IntPtr[0]
End Function

' Read a 32 bit value in reverse endian order
Function ReadMemory32RE:Int(Addr:Byte Ptr)
	Local IntValue:Int = 0
	Local IntPtr:Byte Ptr = Varptr IntValue
	
	IntPtr[0] = Addr[3]
	IntPtr[1] = Addr[2]
	IntPtr[2] = Addr[1]
	IntPtr[3] = Addr[0]
	
	Return IntValue
End Function

' Write a 32 bit value (normal)
Function WriteMemory32(IntValue:Int, Addr:Byte Ptr)
	Local MemPtr:Int Ptr = Int Ptr(Addr)
	
	MemPtr[0] = IntValue
End Function

' Write a 32 bit value in reverse endian order
Function WriteMemory32RE(IntValue:Int, Addr:Byte Ptr)
	Local IntPtr:Byte Ptr = Varptr IntValue
	
	Addr[0] = IntPtr[3]
	Addr[1] = IntPtr[2]
	Addr[2] = IntPtr[1]
	Addr[3] = IntPtr[0]
End Function

' Read a 64 bit value (normal)
Function ReadMemory64:Long(Addr:Byte Ptr)
	Local LongPtr:Long Ptr = Long Ptr(Addr)
	
	Return LongPtr[0]
End Function

' Read a 64 bit value in reverse endian order
Function ReadMemory64RE:Long(Addr:Byte Ptr)
	Local LongValue:Long = 0
	Local LongPtr:Byte Ptr = Varptr LongValue
	
	LongPtr[0] = Addr[7]
	LongPtr[1] = Addr[6]
	LongPtr[2] = Addr[5]
	LongPtr[3] = Addr[4]
	LongPtr[4] = Addr[3]
	LongPtr[5] = Addr[2]
	LongPtr[6] = Addr[1]
	LongPtr[7] = Addr[0]
		
	Return LongValue
End Function

' Write a 64 bit value (normal)
Function WriteMemory64(LongValue:Long, Addr:Byte Ptr)
	Local MemPtr:Long Ptr = Long Ptr(Addr)
	
	MemPtr[0] = LongValue
End Function

' Write a 64 bit value in reverse endian order
Function WriteMemory64RE(LongValue:Long, Addr:Byte Ptr)
	Local LongPtr:Byte Ptr = Varptr LongValue
	
	Addr[0] = LongPtr[7]
	Addr[1] = LongPtr[6]
	Addr[2] = LongPtr[5]
	Addr[3] = LongPtr[4]
	Addr[4] = LongPtr[3]
	Addr[5] = LongPtr[2]
	Addr[6] = LongPtr[1]
	Addr[7] = LongPtr[0]
End Function

' Can parse a 12 bit negative value into a coherent representation
' Takes the value and the bitcount of the value
Function SignExt:Long(Value:Long, Bits:Int)
	If Value & (%1 Shl (Bits - 1)) <> 0
		Return -((2^Bits) - Value)
	Else
		Return Value
	End If
End Function

' Shortens hex strings by removing all the leading zeroes from the string
Function Shorten:String(HexText:String)
	Local CHR_0:Int = Asc("0")
	Local i:Int = 0
		
	While (HexText[i] = CHR_0)
		i :+ 1
		
		' If the entire string turned out to be made of zeroes, return a single zero
		If i >= HexText.length
			Return "0"
		End If
	Wend
	
	Return Mid(HexText, i + 1)
End Function
