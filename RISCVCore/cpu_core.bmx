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
	
	If (Addr = 0)
		Print "Access to 0x0! Null pointer error?"
		
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
RV64_REGISTER_NAMES[3] = "gp"
RV64_REGISTER_NAMES[4] = "tp"
RV64_REGISTER_NAMES[5] = "t0"
RV64_REGISTER_NAMES[6] = "t1"
RV64_REGISTER_NAMES[7] = "t2"
RV64_REGISTER_NAMES[8] = "s0"
RV64_REGISTER_NAMES[9] = "s1"
RV64_REGISTER_NAMES[10] = "a0"
RV64_REGISTER_NAMES[11] = "a1"
RV64_REGISTER_NAMES[12] = "a2"
RV64_REGISTER_NAMES[13] = "a3"
RV64_REGISTER_NAMES[14] = "a4"
RV64_REGISTER_NAMES[15] = "a5"
RV64_REGISTER_NAMES[16] = "a6"
RV64_REGISTER_NAMES[17] = "a7"
RV64_REGISTER_NAMES[18] = "s2"
RV64_REGISTER_NAMES[19] = "s3"
RV64_REGISTER_NAMES[20] = "s4"
RV64_REGISTER_NAMES[21] = "s5"
RV64_REGISTER_NAMES[22] = "s6"
RV64_REGISTER_NAMES[23] = "s7"
RV64_REGISTER_NAMES[24] = "s8"
RV64_REGISTER_NAMES[25] = "s9"
RV64_REGISTER_NAMES[26] = "s10"
RV64_REGISTER_NAMES[27] = "s11"
RV64_REGISTER_NAMES[28] = "t3"
RV64_REGISTER_NAMES[29] = "t4"
RV64_REGISTER_NAMES[30] = "t5"
RV64_REGISTER_NAMES[31] = "t6"


' Returns a string containing the text name of the supplied register number
Function register_name:String(RegisterNumber:Int)
	Return RV64_REGISTER_NAMES[RegisterNumber]
End Function