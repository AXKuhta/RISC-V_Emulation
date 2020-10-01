
' Read a little-endian 32 bit value
Function ReadMemory32LE:Int(Addr:Byte Ptr)
	Local IntBE:Int = 0
	Local IntBEPtr:Byte Ptr = Varptr IntBE
	
	IntBEPtr[0] = Addr[3]
	IntBEPtr[1] = Addr[2]
	IntBEPtr[2] = Addr[1]
	IntBEPtr[3] = Addr[0]
	
	Return IntBE
End Function

' Read a 32 bit value
Function ReadMemory32:Int(Addr:Byte Ptr)
	Local IntBE:Int Ptr = Int Ptr(Addr)
	
	Return IntBE[0]
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