' Control And Status Registers
' Functions to read and write

Type RV64i_csr
	Field MScratch:Long
	Field MStatus:Long
	Field MTVec:Long
	Field MIE:Long
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
' This function get called when MStatus register is updated
Function MStatusUpdateNotification(CPU:RV64i_core)
	Print "MStatus CSR updated"
End Function

' This function get called when Interrupt Vector is updated
Function MTVecUpdateNotification(CPU:RV64i_core)
	Select (CPU.CSR.MTVec & %11)
		Case 0
			Print "Interrupt mode is now DIRECT"
		Case 1
			Print "Interrupt mode is now VECTORED"
			
		Default
			Print "Unacceptable interrupt mode!"
			Input ""
	End Select
	
	' Delete two lower bits from the vector
	CPU.InterruptVector = CPU.CSR.MTVec & $FFFFFFFFFFFFFFFC
	
	Print "Interrupt vector is now 0x" + Shorten(LongHex(CPU.InterruptVector))
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
' ======================================================================


' CSR Read and Write + Notify
' ======================================================================
Function WarnUnknownCSR(CSR_ID:Int)
	Print "Unknown CSR write: " + CSR_ID
	Input "(Press Enter to continue)"
End Function

Function WarnReadonlyCSR(CSR_Name:String)
	Print "Attempted to write a read only CSR: " + CSR_Name
	Input "(Press Enter to continue)"
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
			
		Default
			WarnUnknownCSR(CSR_ID)
			
	End Select
End Function
' ======================================================================
