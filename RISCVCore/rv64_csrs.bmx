' Control And Status Registers
' Functions to read and write

Type RV64i_csr
	Field MScratch:Long
	Field MStatus:Long
	
	Field MTVec:Long
	Field MCause:Long
	Field MEPC:Long ' Program counter when the interrupt happened
	Field MTVal:Long ' Exception-specific info; unset for interrupts
	
	' Which machine interrupts are enabled
	' This is a register, not a flag
	Field MIE:Long
	
	' Which machine interrupts are pending (same field order as in `MIE`)
	Field MIP:Long
	
	Field PMPAddr0:Long
	Field PMPCfg0:Long
End Type

Const MISA_RV64 = $40000000 ' 64 bit machine

' Extension letters
Const MISA_A = %00000000000000000000000001
Const MISA_B = %00000000000000000000000010
Const MISA_C = %00000000000000000000000100
Const MISA_D = %00000000000000000000001000
Const MISA_E = %00000000000000000000010000
Const MISA_F = %00000000000000000000100000
Const MISA_G = %00000000000000000001000000
Const MISA_H = %00000000000000000010000000
Const MISA_I = %00000000000000000100000000
Const MISA_J = %00000000000000001000000000
Const MISA_K = %00000000000000010000000000
Const MISA_L = %00000000000000100000000000
Const MISA_M = %00000000000001000000000000
Const MISA_N = %00000000000010000000000000
' Etc etc etc...

' Disable F and D extensions for now, else we fail on FPU registers cleanup
Const MISA_RV64IMAFD = MISA_RV64 | MISA_I | MISA_M | MISA_A


' Fields of the MStatus CSR, aka the main CSR of a RISC-V processor
' Incomplete
' ======================================================================
Const MSTATUS_USER_INTERRUPT =		 	%0001
Const MSTATUS_SUPERVISOR_INTERRUPT = 	%0010
Const MSTATUS_MACHINE_INTERRUPT = 		%1000

Const MSTATUS_USER_INTERRUPT_PREV =			 	%00010000
Const MSTATUS_SUPERVISOR_INTERRUPT_PREV = 		%00100000
Const MSTATUS_MACHINE_INTERRUPT_PREV = 			%10000000
' ======================================================================


' Handers for changes of certain CSRs
' ======================================================================
' This function gets called when MStatus register is updated
Function MStatusUpdateNotification(CPU:RV64i_core, Value:Long)
	Print "CSR: MStatus CSR updated"
	
	' Use logic operations to get the enabled statuses
	Local UIE:Int = 0 < (Value & MSTATUS_USER_INTERRUPT)
	Local SIE:Int = 0 < (Value & MSTATUS_SUPERVISOR_INTERRUPT)
	Local MIE:Int = 0 < (Value & MSTATUS_MACHINE_INTERRUPT)
	
	' Complain if UIE or SIE were set
	' We only support MIE
	If (UIE Or SIE)
		Print "UIE or SIE set in MStatus -- we don't support anything but MIE"
		Input "(Press Enter to continue)"
	End If
		
	' Store the state and sync
	' It /will/ overwrite the CSR
	CPU.INTC.Enabled = MIE
	SyncMStatus(CPU)
	
	' Always update/handle pending interrupts
	ProcessInterrupts(CPU)
End Function

' Sets bits in MStatus based on the current state of the INTC
' Called from `rv64_interrupts.bmx`
Function SyncMStatus(CPU:RV64i_core)
	' Reset to zero
	CPU.CSR.Mstatus = 0
	
	' Set appropriate flags
	If CPU.INTC.Enabled Then CPU.CSR.Mstatus :| MSTATUS_MACHINE_INTERRUPT
	If CPU.INTC.EnabledPrevious Then CPU.CSR.Mstatus :| MSTATUS_MACHINE_INTERRUPT_PREV
End Function

' This function gets called when Interrupt Vector is updated
Function MTVecUpdateNotification(CPU:RV64i_core, Value:Long)
	CPU.CSR.MTVec = Value

	Select (CPU.CSR.MTVec & %11)
		Case 0
			Print "CSR: Interrupt mode is now DIRECT"
		Case 1
			Print "CSR: Interrupt mode is now VECTORED"
			
		Default
			Print "CSR: Unacceptable interrupt mode!"
			Input ""
	End Select
	
	' Delete two lower bits from the vector
	CPU.InterruptVector = CPU.CSR.MTVec & $FFFFFFFFFFFFFFFC
	
	Print "CSR: Interrupt vector is now 0x" + PrettyHex(CPU.InterruptVector)
End Function

' Only declare consts for machine mode for now
Const MIE_SOFTWARE_M = 	%000000001000
Const MIE_TIMER_M = 	%000010000000
Const MIE_EXTERNAL_M = 	%100000000000

Const MIP_SOFTWARE_M = 	%000000001000
Const MIP_TIMER_M = 	%000010000000
Const MIP_EXTERNAL_M = 	%100000000000

' Gets called when the list of enabled interrupts is updated
Function MIEUpdateNotification(CPU:RV64i_core, Value:Long)
	' A small safety check
	Local AllowedMask:Int = (MIE_SOFTWARE_M | MIE_TIMER_M | MIE_EXTERNAL_M)
	
	If (Value | AllowedMask) <> AllowedMask
		Print "CSR: Non machine-mode interrupt enable bits set in MIE!"
		Input "(Press Enter to continue)"
	End If
	
	' Set appropriate INTC flags
	CPU.INTC.SoftwareInterruptsEnabled = 0 < (Value | MIE_SOFTWARE_M) 
	CPU.INTC.TimerInterruptsEnabled = 0 < (Value | MIE_TIMER_M)
	CPU.INTC.ExternalInterruptsEnabled = 0 < (Value | MIE_EXTERNAL_M)
	
	' Keep the value
	CPU.CSR.MIE = Value
End Function

' Updates the pending interrupts register
Function SyncMIP(CPU:RV64i_core)
	CPU.CSR.MIP = 0
	
	If CPU.INTC.PendingSoftwareInterrupt Then CPU.CSR.MIP :| MIP_SOFTWARE_M
	If CPU.INTC.PendingTimerInterrupt Then CPU.CSR.MIP :| MIP_TIMER_M
	If CPU.INTC.PendingExternalInterrupt Then CPU.CSR.MIP :| MIP_EXTERNAL_M
End Function

' This function gets called when Physical Memory Protection stuff is
' updated
Function PMPUpdateNotification(CPU:RV64i_core)
	Print "CSR: Physical Memory Protection settings updated"
	Print "CSR: PMPAddr0 is now 0x" + PrettyHex(CPU.CSR.PMPAddr0)
	Print "CSR: PMPCfg0 is now 0x" + PrettyHex(CPU.CSR.PMPCfg0)
End Function
' ======================================================================


' List of known CSRs
' ======================================================================
Const CSR_MHARTID = $F14 ' ID of the current processor

Const CSR_MSTATUS = $300 ' Machine status
Const CSR_MISA = 	$301 ' Machine ISA -- read only
Const CSR_MIE = 	$304 ' Machine Interrupts Enabled -- enabled interrupts
Const CSR_MTVEC = 	$305 ' Machine Interrupt Vector + mode flag

Const CSR_MSCRATCH = $340 ' Machine Status Scratchpad?
Const CSR_MEPC = 	 $341
Const CSR_MCAUSE =	 $342
Const CSR_MTVAL = 	 $343
Const CSR_MIP = 	 $344 ' Machine Interrupts Pending

Const CSR_PMPADDR0 = 944 ' Physical Memory Protection
Const CSR_PMPCFG0 = 928 ' Physical Memory Protection


' ======================================================================


' CSR Read and Write + Notify
' ======================================================================
Function WarnUnknownCSR(CSR_ID:Int)
	Print "CSR: Unknown CSR write: " + CSR_ID
	Input "CSR: (Press Enter to continue)"
End Function

Function WarnReadonlyCSR(CSR_Name:String)
	Print "CSR: Attempted to write a read only CSR: " + CSR_Name
	Input "CSR: (Press Enter to continue)"
End Function

Function WriteCSR(CSR_ID:Int, Value:Long, CPU:RV64i_core)
	Select CSR_ID
		Case CSR_MIE
			MIEUpdateNotification(CPU, Value)
			
		Case CSR_MIP
			WarnReadonlyCSR("mip")
			
		Case CSR_MCAUSE
			WarnReadonlyCSR("mcause")
			
		Case CSR_MTVAL
			WarnReadonlyCSR("mtval")
			
		Case CSR_MSCRATCH 
			CPU.CSR.MScratch = Value
			
		Case CSR_MEPC
			CPU.CSR.MEPC = Value
			
		Case CSR_MISA
			WarnReadonlyCSR("misa")
			
		Case CSR_MSTATUS
			MStatusUpdateNotification(CPU, Value)
			
		Case CSR_MTVEC
			MTVecUpdateNotification(CPU, Value)
		
		' RV64 provides 16 memory regions for PMP
		' Also, we should trim upper 10 bits
		Case CSR_PMPADDR0 
			CPU.CSR.PMPAddr0 = Value
			PMPUpdateNotification(CPU)
		
		' RV64 provides 2 PMP CFG registers, each one packing settings for 8 regions
		Case CSR_PMPCFG0 
			CPU.CSR.PMPCfg0 = Value
			PMPUpdateNotification(CPU)
			
		Case CSR_MHARTID
			WarnReadonlyCSR("mhartid")
			
		Default
			WarnUnknownCSR(CSR_ID)
			
	End Select
	
End Function

Function ReadCSR:Long(CSR_ID:Int, CPU:RV64i_core)
	Select CSR_ID
		Case CSR_MIE
			Return CPU.CSR.MIE
			
		Case CSR_MIP
			Return CPU.CSR.MIP
			
		Case CSR_MCAUSE
			Return CPU.CSR.MCause
			
		Case CSR_MTVAL
			Return CPU.CSR.MTVal
			
		Case CSR_MSCRATCH
			Return CPU.CSR.MScratch
			
		Case CSR_MEPC
			Return CPU.CSR.MEPC
			
		Case CSR_MISA
			Return MISA_RV64IMAFD
			
		Case CSR_MSTATUS
			Return CPU.CSR.MStatus
			
		Case CSR_MTVEC
			Return CPU.CSR.MTVec
			
		Case CSR_PMPADDR0
			Return CPU.CSR.PMPAddr0
			
		Case CSR_PMPCFG0
			Return CPU.CSR.PMPCfg0
			
		Case CSR_MHARTID
			Return CPU.ProcessorID
			
		Default
			WarnUnknownCSR(CSR_ID)
			
	End Select
End Function
' ======================================================================
