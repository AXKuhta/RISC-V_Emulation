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
	
	' Memory Management Unit
	Field MMU:RV64i_mmu
	

End Type

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

Type RV64i_mmu
	Field LatestReadAddress:ULong
	Field LatestWriteAddress:ULong
	
	' Limit the meaningful address bits
	' Be sure to initialize this value!
	Field AddressBusMask:ULong
	
	' Memory pointer
	Field Memory:Byte Ptr
	
	' How many bytes of memory is available
	Field MemorySize:Size_T
End Type

' Will return an address that went through the MMU translation
Function AddressThroughMMU:ULong(Addr:Long, Width:Int, CPU:RV64i_core)
	Local TranslatedAddress:ULong = 0
	
	' Warn if exscessive bits were detected
	If Addr > CPU.MMU.AddressBusMask
		Print "MMU: Warning: address has meaningless bits"
		Print "Offending address: 0x" + Shorten(LongHex(Addr))
	End If
	
	TranslatedAddress = ULong(Addr) & CPU.MMU.AddressBusMask
	
	' Warn if access will overflow memory
	If (TranslatedAddress > CPU.MMU.MemorySize)
		Print "MMU: Error: out of bounds memory access!"
		Print "Offending address: 0x" + Shorten(LongHex(Long(TranslatedAddress)))
		
		Input "(Press Enter to continue)"
	End If
	
	' Warn if access to null
	If (TranslatedAddress = 0)
		Print "MMU: Error: Access to 0! Null pointer error?"
		
		Input "(Press Enter to continue)"
	End If
	
	' Warn on misaligned accesses
	If TranslatedAddress Mod Width <> 0
		Print "MMU: Warning: misaligned access for width " + Width
	End If
	
	Return TranslatedAddress
End Function

' Wrappers that will run the address through the MMU before reading/writing
Function MMUReadMemory8:Byte(Addr:Long, CPU:RV64i_core)
	Local TranslatedAddr:ULong = AddressThroughMMU(Addr, 1, CPU)
	
	CPU.MMU.LatestReadAddress = TranslatedAddr
	
	Return CPU.MMU.Memory[TranslatedAddr]
End Function

Function MMUReadMemory16:Short(Addr:Long, CPU:RV64i_core)
	Local TranslatedAddr:ULong = AddressThroughMMU(Addr, 2, CPU)

	CPU.MMU.LatestReadAddress = TranslatedAddr

	Return ReadMemory16(CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUReadMemory32:Int(Addr:Long, CPU:RV64i_core)
	Local TranslatedAddr:ULong = AddressThroughMMU(Addr, 4, CPU)

	CPU.MMU.LatestReadAddress = TranslatedAddr

	Return ReadMemory32(CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUReadMemory64:Long(Addr:Long, CPU:RV64i_core)
	Local TranslatedAddr:ULong = AddressThroughMMU(Addr, 8, CPU)

	CPU.MMU.LatestReadAddress = TranslatedAddr

	Return ReadMemory64(CPU.MMU.Memory + TranslatedAddr)
End Function


Function MMUWriteMemory8(Value:Byte, Addr:Long, CPU:RV64i_core)
	Local TranslatedAddr:ULong = AddressThroughMMU(Addr, 1, CPU)
	
	CPU.MMU.LatestWriteAddress = TranslatedAddr
	
	CPU.MMU.Memory[TranslatedAddr] = Value
End Function

Function MMUWriteMemory16(Value:Short, Addr:Long, CPU:RV64i_core)
	Local TranslatedAddr:ULong = AddressThroughMMU(Addr, 2, CPU)

	CPU.MMU.LatestWriteAddress = TranslatedAddr

	WriteMemory16(Value, CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUWriteMemory32(Value:Int, Addr:Long, CPU:RV64i_core)
	Local TranslatedAddr:ULong = AddressThroughMMU(Addr, 4, CPU)

	CPU.MMU.LatestWriteAddress = TranslatedAddr

	WriteMemory32(Value, CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUWriteMemory64(Value:Long, Addr:Long, CPU:RV64i_core)
	Local TranslatedAddr:ULong = AddressThroughMMU(Addr, 8, CPU)
	
	CPU.MMU.LatestWriteAddress = TranslatedAddr

	WriteMemory64(Value, CPU.MMU.Memory + TranslatedAddr)
End Function

