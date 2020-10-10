' Control And Status Registers
' Functions to read and write

Type RV64i_csr
	Field MScratch:Long
	Field MStatus:Long
	Field MTVec:Long
	Field MIE:Long
	
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


' Handers for changes of certain CSRs
' ======================================================================
' This function gets called when MStatus register is updated
Function MStatusUpdateNotification(CPU:RV64i_core)
	Print "CSR: MStatus CSR updated"
End Function

' This function gets called when Interrupt Vector is updated
Function MTVecUpdateNotification(CPU:RV64i_core)
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
	
	Print "CSR: Interrupt vector is now 0x" + Shorten(LongHex(CPU.InterruptVector))
End Function

' This function gets called when Physical Memory Protection stuff is
' updated
Function PMPUpdateNotification(CPU:RV64i_core)
	Print "CSR: Physical Memory Protection settings updated"
	Print "CSR: PMPAddr0 is now 0x" + Shorten(LongHex(CPU.CSR.PMPAddr0))
	Print "CSR: PMPCfg0 is now 0x" + Shorten(LongHex(CPU.CSR.PMPCfg0))
End Function
' ======================================================================


' List of known CSRs
' ======================================================================
Const CSR_MIE = 772 ' Machine Interrupt Enable -- enabled interrupts
Const CSR_MIP = 836 ' Machine Interrupt Pending -- same mapping as MIE
Const CSR_MSCRATCH = 832 ' Machine Scratch -- ???
Const CSR_MISA = 769 ' Machine ISA -- read only
Const CSR_MSTATUS = 768 ' Machine status
Const CSR_MTVEC = 773 ' Machine Interrupt Vector + mode flag

Const CSR_PMPADDR0 = 944 ' Physical Memory Protection
Const CSR_PMPCFG0 = 928 ' Physical Memory Protection

Const CSR_MHARTID = 3860 ' ID of the current processor
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
		Case CSR_MIE, CSR_MIP
			CPU.CSR.MIE = Value
			
		Case CSR_MSCRATCH 
			CPU.CSR.MScratch = Value
			
		Case CSR_MISA
			WarnReadonlyCSR("misa")
			
		Case CSR_MSTATUS
			CPU.CSR.MStatus = Value
			MStatusUpdateNotification(CPU)
			
		Case CSR_MTVEC
			CPU.CSR.MTVec = Value
			MTVecUpdateNotification(CPU)
		
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
		Case CSR_MIE, CSR_MIP
			Return CPU.CSR.MIE
			
		Case CSR_MSCRATCH
			Return CPU.CSR.MScratch
			
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
