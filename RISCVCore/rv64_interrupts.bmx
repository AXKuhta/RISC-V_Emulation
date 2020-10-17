
' RV64 interrupt controller
Type RV64i_intc
	' Interrupt Controller Enable Flag
	' Stored into `EnabledPrevious` on an interrupt
	' Restored on `MRET` instruction
	Field Enabled:Int
	
	' Previous state of enable flag
	Field EnabledPrevious:Int
	
	' This flag is set when a write to `mtimecmp` occured
	' Unset when the time is reached
	Field TimerArmed:Int
	
	' To what address do we return on `MRET`
	Field InterruptReturnAddress:Long
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



' Interrupt codes
' ======================================================================
Const TRAP_TYPE_INTERRUPT:Long = $8000000000000000

Const SOFTWARE_INTERRUPT_U = 0
Const SOFTWARE_INTERRUPT_S = 1
'Const RESERVED = 2
Const SOFTWARE_INTERRUPT_M = 3

Const TIMER_INTERRUPT_U = 4
Const TIMER_INTERRUPT_S = 5
'Const RESERVED = 6
Const TIMER_INTERRUPT_M = 7

Const EXTERNAL_INTERRUPT_U = 8
Const EXTERNAL_INTERRUPT_S = 9
'Const RESERVED = 10
Const EXTERNAL_INTERRUPT_M = 11
' ======================================================================


' Exception codes
' ======================================================================
Const TRAP_TYPE_EXCEPTION:Long = $0000000000000000

Const EXCEPTION_INSN_ADDR_MISALIGN = 0
Const EXCEPTION_INSN_ACCESS_FAULT = 1
Const EXCEPTION_UD = 2
Const EXCEPTION_BREAKPOINT = 3
Const EXCEPTION_LOAD_ADDR_MISALIGN = 4
Const EXCEPTION_LOAD_ACCESS_FAULT = 5
Const EXCEPTION_AMO_ADDR_MISALIGN = 6
Const EXCEPTION_AMO_ACCESS_FAULT = 7
Const EXCEPTION_ECALL_FROM_U = 8
Const EXCEPTION_ECALL_FROM_S = 9
' Const RESERVED = 10
Const EXCEPTION_ECALL_FROM_M = 11
Const EXCEPTION_INSN_PAGE_FAULT = 12
Const EXCEPTION_LOAD_PAGE_FAILT = 13
' Const RESERVED = 14
Const EXCEPTION_STORE_AMO_PAGE_FAULT = 15
' ... etc etc etc
' See privileged spec page 37
' ======================================================================


' Checks if interrupts are enabled and whether there are any pending
' Proceeds to handle the interrupt if so
Function ProcessInterrupts(CPU:RV64i_core)
	' Early return if interrupts disabled
	If CPU.INTC.Enabled = 0 Then Return
	
	' Process the timer interrupt with highest priority
	If CPU.INTC.TimerArmed = 1
		' Check for timer trip
		If MilliSecs() >= ReadMemory64(CPU.MMU.INTC + INTC_TIME_CMP)
			' Unset the armed status first thing
			CPU.INTC.TimerArmed = 0
			
			
			' Has to go into HandleInterrupt()
			' =========================================
			Print "Timer interrupt tripped!"
			Input "(Press Enter to continue)"
			CPU.BreakpointHit = 1
						
			' Can't enter the interrupt handler if the
			' interrupt are off!
			Assert(CPU.INTC.Enabled = 1)
			
			' Disable the interrupts during handling
			' Restored later by `MRET` instruction
			SetMIE(CPU, 0)
						
			' Fill out the cause information
			CPU.CSR.MCause = TRAP_TYPE_INTERRUPT | TIMER_INTERRUPT_M
			CPU.CSR.MEPC = CPU.PC ' Do we need to subtract 4??
			CPU.CSR.MTVal = 0
			
			' Store the return address
			CPU.INTC.InterruptReturnAddress = CPU.PC
			
			' Finally alter the Program Counter
			CPU.PC = CPU.CSR.MTVec | CPU.MMU.ForcedMask
			' =========================================
			
			Return
		End If
	End If
End Function

' Used to enable/disable machine interrupts
' State = 1 is Enable
' State = 0 is Disable
Function SetMIE(CPU:RV64i_core, State:Int)
	CPU.INTC.EnabledPrevious = CPU.INTC.Enabled
	CPU.INTC.Enabled = State
	
	SyncMStatus(CPU)
End Function

' Restores the previous machine interrupt state
Function RestorePreviousMIEState(CPU:RV64i_core)
	Local Temp:Int
	
	' Swap the flags
	Temp = CPU.INTC.Enabled
	CPU.INTC.Enabled = CPU.INTC.EnabledPrevious
	CPU.INTC.EnabledPrevious = Temp
	
	' Synchronize MStatus CSR
	SyncMStatus(CPU)
End Function
