Import "utils.bmx"

Type RV64i_core
	' Some highlights:
	' r0: zero register; always zero
	' r1: return address; user by `ret` and `jal` 
	' r2: stack pointer
	Field Registers:Long[32]
	
	' Additional Program Counter register
	Field PC:Long
	
	' Control and Status registers
	Field CSR:Byte[1024]
	
	' Memory pointer
	Field Memory:Byte Ptr
	
	' How many bytes of memory is available
	Field MemorySize:Size_T

End Type

' Will warn if supplied address is bad
Function CheckAddress(Addr:Long, CPU:RV64i_core)
	If (Addr > CPU.MemorySize) Or (Addr < 0)
		Print "Out of bounds memory access!"
		Print "Offending address: 0x" + LongHex(Addr)
		
		Input "(Press Enter to continue)"
	End If
End Function

' TODO: When we convert the thing to proper object oriented style, with functions like CheckAddress() a method, we need to compare the performance with the old-style version
' So please implement anything with high impact on performance, like Translation Blocks, BEFORE starting to cram functions into types

'
' Naming convention:
' - Constants are in all caps
' - Functions that relay constants are all lowercase
' 
Global RV64_REGISTER_NAMES:String[32]

RV64_REGISTER_NAMES[0] = "zero"
RV64_REGISTER_NAMES[1] = "ra"
RV64_REGISTER_NAMES[2] = "sp"
RV64_REGISTER_NAMES[3] = "r3"
RV64_REGISTER_NAMES[4] = "r4"
RV64_REGISTER_NAMES[5] = "r5"
RV64_REGISTER_NAMES[6] = "r6"
RV64_REGISTER_NAMES[7] = "r7"
RV64_REGISTER_NAMES[8] = "r8"
RV64_REGISTER_NAMES[9] = "r9"
RV64_REGISTER_NAMES[10] = "r10"
RV64_REGISTER_NAMES[11] = "r11"
RV64_REGISTER_NAMES[12] = "r12"
RV64_REGISTER_NAMES[13] = "r13"
RV64_REGISTER_NAMES[14] = "r14"
RV64_REGISTER_NAMES[15] = "r15"
RV64_REGISTER_NAMES[16] = "r16"
RV64_REGISTER_NAMES[17] = "r17"
RV64_REGISTER_NAMES[18] = "r18"
RV64_REGISTER_NAMES[19] = "r19"
RV64_REGISTER_NAMES[20] = "r20"
RV64_REGISTER_NAMES[21] = "r21"
RV64_REGISTER_NAMES[22] = "r22"
RV64_REGISTER_NAMES[23] = "r23"
RV64_REGISTER_NAMES[24] = "r24"
RV64_REGISTER_NAMES[25] = "r25"
RV64_REGISTER_NAMES[26] = "r26"
RV64_REGISTER_NAMES[27] = "r27"
RV64_REGISTER_NAMES[28] = "r28"
RV64_REGISTER_NAMES[29] = "r29"
RV64_REGISTER_NAMES[30] = "r30"
RV64_REGISTER_NAMES[31] = "r31"


' Returns a string containing the text name of the supplied register number
Function register_name:String(RegisterNumber:Int)
	Return RV64_REGISTER_NAMES[RegisterNumber]
End Function