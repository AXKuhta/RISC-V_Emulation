
' RV64 interrupt controller
Type RV64i_intc
	' Interrupt Controller Enable Flag
	' Stored into `EnabledPrevious` on an interrupt
	' Restored on `MRET` instruction
	Field Enabled:Int
	
	' Previous state of enable flag
	Field EnabledPrevious:Int
	
	' Interrupt Enable flags for various sources
	Field SoftwareInterruptsEnabled:Int
	Field TimerInterruptsEnabled:Int
	Field ExternalInterruptsEnabled:Int
	
	Field PendingSoftwareInterrupt:Int
	Field PendingTimerInterrupt:Int
	Field PendingExternalInterrupt:Int
	
	' To what address do we return on `MRET`
	' Unused for now in favor of MEPC CSR
	Field InterruptReturnAddress:Long
End Type


Const INTC_IPI = $0
Const INTC_TIME_CMP = $4000
Const INTC_TIME_VAL = $BFF8

' Updates the INTC memory on impending read/write
Function INTCNotify(CPU:RV64i_core, Offset:ULong, Mode:Int)
	' Check the offset
	' Complain on unknown offsets
	Select Offset
		Case INTC_IPI
			Print "INTC: IPI access"
			' Do nothing for now
			
		Case INTC_TIME_CMP
			' Do nothing: timer enable is controlled by `mie` now
			
		Case INTC_TIME_VAL
			' Update the time
			WriteMemory64(MilliSecs(), CPU.MMU.INTC + Offset)
			
		Default
			Print "Unknown INTC memory offset: 0x" + PrettyHex(Offset)
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
	' ### Stage 1
	' Determine what interrupts are pending
	' TODO: Simplify the logic
	CPU.INTC.PendingTimerInterrupt = MilliSecs() >= ReadMemory64(CPU.MMU.INTC + INTC_TIME_CMP)
	CPU.INTC.PendingExternalInterrupt = 0
	
	' Take the 8250 into account only if its interrupts are enabled by its IER
	' Right now we only support TXing from this port
	' No check for IER_RX_AVAIL
	If (CPU.Serial8250.IER & IER_TX_EMPTY)
		CPU.INTC.PendingExternalInterrupt = 0 < CPU.Serial8250.InterruptPending
	End If
	
	' ### Stage 2
	' Update the pending interrupts
	SyncMIP(CPU)

	
	' ### Stage 3
	' Early return if interrupts disabled
	If CPU.INTC.Enabled = 0 Then Return
	
	
	' ### Stage 4
	' Process whatever is pending:
	
	' # Priority A
	' The timer
	If CPU.INTC.TimerInterruptsEnabled
		If CPU.INTC.PendingTimerInterrupt
			Print "Timer interrupt tripped!"
			
			CPU.INTC.PendingTimerInterrupt = 0
			SyncMIP(CPU)
			
			HandleInterrupt(CPU, TRAP_TYPE_INTERRUPT | TIMER_INTERRUPT_M)
			Return
		End If
	End If
	
	' # Priority B
	' External device (The 8250 serial port)
	If CPU.INTC.ExternalInterruptsEnabled
		If CPU.INTC.PendingExternalInterrupt
			
			CPU.INTC.PendingExternalInterrupt = 0
			SyncMIP(CPU)
		
			If CPU.Serial8250.InterruptPending
				' We will now handle the interrupt
				' Unset the pending flag
				CPU.Serial8250.InterruptPending = 0
				
				Print "Handle 8250 TX empty interrupt"
				Input ">"
				
				' Untested
				HandleInterrupt(CPU, TRAP_TYPE_INTERRUPT | EXTERNAL_INTERRUPT_M, 10)
				Return
			End If
			
			' Potentially other external interrupts could go in here
		End If
	End If
	
End Function

' Function that will fill out the interrupt information and jump to handler vector
' Requires the CPU to have `CurrentTrace` set to something
Function HandleInterrupt(CPU:RV64i_core, MCause:Long, MTVal:ULong = 0)
	' Remove the permission to run from the current trace:
	' we will be jumping to a new location
	CPU.CurrentTrace.AllowedToRun = 0
	
	' Disable the interrupts during handling
	' Restored later by `MRET` instruction
	InterruptSetMIE(CPU)
	
	' Fill out the cause information
	CPU.CSR.MCause = MCause
	CPU.CSR.MEPC = CPU.PC ' Do we need to subtract 4??
	CPU.CSR.MTVal = MTVal
	
	' Store the return address (Unused for now in favor of MEPC)
	CPU.INTC.InterruptReturnAddress = CPU.PC
	
	' Finally alter the Program Counter
	CPU.PC = CPU.CSR.MTVec | CPU.MMU.ForcedMask
End Function

' Will basically store the previous state and disable interrupts
' On interrupt handler, 1 will be the previous state
' On trap handler, 0 /could/ be the previous state
Function InterruptSetMIE(CPU:RV64i_core)
	CPU.INTC.EnabledPrevious = CPU.INTC.Enabled
	CPU.INTC.Enabled = 0
	
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

' Should be called if a bad instruction was encountered
' Will attempt to recover
' We don't care about Interrupt Enable flags in case of an exception
Function UndefinedInstructionException(CPU:RV64i_core)
	InterruptSetMIE(CPU)

	CPU.CSR.MCause = TRAP_TYPE_EXCEPTION | EXCEPTION_UD
	CPU.CSR.MEPC = CPU.PC
	CPU.CSR.MTVal = 0
	
	CPU.INTC.InterruptReturnAddress = CPU.PC
	
	CPU.PC = CPU.CSR.MTVec | CPU.MMU.ForcedMask
End Function
