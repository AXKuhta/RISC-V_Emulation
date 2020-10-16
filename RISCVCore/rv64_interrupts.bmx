
' RV64 interrupt controller
Type RV64i_intc
	' Machine Interrupt Enabled flag
	Field MIE:Int
	
	' Previous state of MIE
	' MIE is stored into MIEP on interrupt
	' And restored back on `MRET` instruction
	Field MIEP:Int
	
	' This flag is set when a write to `mtimecmp` occured
	' Unset when the time is reached
	Field TimerArmed:Int
End Type


Const INTC_IPI = $0
Const INTC_TIME_CMP = $4000
Const INTC_TIME_VAL = $BFF8

' Updates the INTC memory on impending read/write
Function INTCNotify(CPU:RV64i_core, Offset:ULong, Mode:Int)
	' Print the offset first
	Print "INTC Access; Offset: 0x" + Shorten(LongHex(Long(Offset)))

	' Check the offset
	' Complain on unknown offsets
	Select Offset
		Case INTC_IPI
			' Do nothing for now
			
		Case INTC_TIME_CMP
			' Set the TimerArmed flag if a write to mtimecmp is to occur
			' /DO NOT/ set it if the register was simply read
			If Mode = MMU_WRITE
				CPU.INTC.TimerArmed = 1
			End If
			
		Case INTC_TIME_VAL
			' Update the time
			WriteMemory64(MilliSecs(), CPU.MMU.INTC + Offset)
			
		Default
			Print "Unknown INTC memory offset: 0x" + Shorten(LongHex(Long(Offset)))
			Input "(Press Enter to continue)"
			
	End Select
	
End Function