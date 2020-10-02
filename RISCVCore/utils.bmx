Import BRL.Retro

' Read a 16 bit value in little-endian order
Function ReadMemory16LE:Short(Addr:Byte Ptr)
	Local ShortBE:Short = 0
	Local ShortBEPtr:Byte Ptr = Varptr ShortBE
	
	ShortBEPtr[0] = Addr[1]
	ShortBEPtr[1] = Addr[0]
		
	Return ShortBE
End Function

' Write a 16 bit value in little-endian order
Function WriteMemory16LE(ShortBE:Short, Addr:Byte Ptr)
	Local ShortBEPtr:Byte Ptr = Varptr ShortBE
	
	Addr[0] = ShortBEPtr[1]
	Addr[1] = ShortBEPtr[0]
End Function

' Read a 32 bit value (normal)
Function ReadMemory32:Int(Addr:Byte Ptr)
	Local IntBE:Int Ptr = Int Ptr(Addr)
	
	Return IntBE[0]
End Function

' Read a 32 bit value in little-endian order
Function ReadMemory32LE:Int(Addr:Byte Ptr)
	Local IntBE:Int = 0
	Local IntBEPtr:Byte Ptr = Varptr IntBE
	
	IntBEPtr[0] = Addr[3]
	IntBEPtr[1] = Addr[2]
	IntBEPtr[2] = Addr[1]
	IntBEPtr[3] = Addr[0]
	
	Return IntBE
End Function

' Write a 32 bit value in little-endian order
Function WriteMemory32LE(IntBE:Int, Addr:Byte Ptr)
	Local IntBEPtr:Byte Ptr = Varptr IntBE
	
	Addr[0] = IntBEPtr[3]
	Addr[1] = IntBEPtr[2]
	Addr[2] = IntBEPtr[1]
	Addr[3] = IntBEPtr[0]
End Function

' Read a 64 bit value in little-endian order
Function ReadMemory64LE:Long(Addr:Byte Ptr)
	Local LongBE:Long = 0
	Local LongBEPtr:Byte Ptr = Varptr LongBE
	
	LongBEPtr[0] = Addr[7]
	LongBEPtr[1] = Addr[6]
	LongBEPtr[2] = Addr[5]
	LongBEPtr[3] = Addr[4]
	LongBEPtr[4] = Addr[3]
	LongBEPtr[5] = Addr[2]
	LongBEPtr[6] = Addr[1]
	LongBEPtr[7] = Addr[0]
		
	Return LongBE
End Function

' Write a 64 bit value in little-endian order
Function WriteMemory64LE(LongBE:Long, Addr:Byte Ptr)
	Local LongBEPtr:Byte Ptr = Varptr LongBE
	
	Addr[0] = LongBEPtr[7]
	Addr[1] = LongBEPtr[6]
	Addr[2] = LongBEPtr[5]
	Addr[3] = LongBEPtr[4]
	Addr[4] = LongBEPtr[3]
	Addr[5] = LongBEPtr[2]
	Addr[6] = LongBEPtr[1]
	Addr[7] = LongBEPtr[0]
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
	Wend
	
	Return Mid(HexText, i + 1)
End Function
