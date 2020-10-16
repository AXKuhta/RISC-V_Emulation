
Const INTC_IPI = $0
Const INTC_TIME_CMP = $4000
Const INTC_TIME_VAL = $BFF8

' Updates the INTC memory on impending read/write
Function INTCNotify(CPU:RV64i_core, Offset:ULong)
	' Print the offset first
	Print "INTC Access; Offset: 0x" + Shorten(LongHex(Long(Offset)))

	' Check the offset
	' Complain on unknown offsets
	Select Offset
		Case INTC_IPI
			' Do nothing for now
			
		Case INTC_TIME_CMP
			' Do nothing for now
			Print "TIME_CMP read/write!"
			Input "(Press Enter to continue)"
			
		Case INTC_TIME_VAL
			' Update the time
			WriteMemory64(MilliSecs(), CPU.MMU.INTC + Offset)
			
		Default
			Print "Unknown INTC memory offset: 0x" + Shorten(LongHex(Long(Offset)))
			Input "(Press Enter to continue)"
			
	End Select
	
End Function