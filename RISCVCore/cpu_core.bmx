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
	
	' Memory and MMIO pointer
	Field Memory:Byte Ptr
	Field MMIO:Byte Ptr
	
	' How many bytes of memory and MMIO is available
	Field MemorySize:Size_T
	Field MMIOSize:Size_T
	
	' Address of the guest memory where the MMIO starts
	Field MMIOStart:ULong
End Type

' MMU translation function
' Receives an address /of the guest memory/
' Returns an address /of the host memory/ that the caller should read
' Has a hardcoded implementation of MMIO remapping right now
Function AddressThroughMMU:Byte Ptr(Addr:Long, Width:Int, CPU:RV64i_core)
	Local TranslatedAddress:ULong = 0
	
	' Remove meaningless bits
	TranslatedAddress = ULong(Addr) & CPU.MMU.AddressBusMask
	
	' Warn on misaligned accesses
	If TranslatedAddress Mod Width <> 0 Then Print "MMU: Warning: misaligned access for width " + Width
	
	' Check whether we are hitting our MMIO address range
	Local IsMMIO:Int = TranslatedAddress >= CPU.MMU.MMIOStart And TranslatedAddress <= (CPU.MMU.MMIOStart + CPU.MMU.MMIOSize)
	
	If IsMMIO
		Return CPU.MMU.MMIO + (CPU.MMU.MMIOStart - TranslatedAddress)
	Else
		ValidateAddress(TranslatedAddress, CPU)
		
		Return CPU.MMU.Memory + TranslatedAddress
	End If
	
End Function

' Error check function that will warn about possible problems with the supplied address
' Takes adderss
' Returns nothing
Function ValidateAddress(Addr:ULong, CPU:RV64i_core)
	' Warn if access will overflow memory
	If (Addr > CPU.MMU.MemorySize)
		Print "MMU: Error: out of bounds memory access!"
		Print "Offending address: 0x" + Shorten(LongHex(Long(Addr)))
		
		Input "(Press Enter to continue)"
	End If
	
	' Warn if access to null
	If (Addr = 0)
		Print "MMU: Error: Access to 0! Null pointer error?"
		
		Input "(Press Enter to continue)"
	End If
End Function

' Wrappers that will run the address through the MMU before reading/writing
Function MMUReadMemory8:Byte(Addr:Long, CPU:RV64i_core)
	Local HostAddr:Byte Ptr = AddressThroughMMU(Addr, 1, CPU)
	
	CPU.MMU.LatestReadAddress = Addr
	
	Return HostAddr[0]
End Function

Function MMUReadMemory16:Short(Addr:Long, CPU:RV64i_core)
	Local HostAddr:Short Ptr = AddressThroughMMU(Addr, 2, CPU)

	CPU.MMU.LatestReadAddress = Addr

	Return HostAddr[0]
	'Return ReadMemory16(CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUReadMemory32:Int(Addr:Long, CPU:RV64i_core)
	Local HostAddr:Int Ptr = AddressThroughMMU(Addr, 4, CPU)

	CPU.MMU.LatestReadAddress = Addr

	Return HostAddr[0]
	'Return ReadMemory32(CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUReadMemory64:Long(Addr:Long, CPU:RV64i_core)
	Local HostAddr:Long Ptr = AddressThroughMMU(Addr, 8, CPU)

	CPU.MMU.LatestReadAddress = Addr
	
	Return HostAddr[0]
	'Return ReadMemory64(CPU.MMU.Memory + TranslatedAddr)
End Function


Function MMUWriteMemory8(Value:Byte, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Byte Ptr = AddressThroughMMU(Addr, 1, CPU)
	
	CPU.MMU.LatestWriteAddress = Addr
	
	HostAddr[0] = Value
End Function

Function MMUWriteMemory16(Value:Short, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Short Ptr = AddressThroughMMU(Addr, 2, CPU)

	CPU.MMU.LatestWriteAddress = Addr

	HostAddr[0] = Value
	'WriteMemory16(Value, CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUWriteMemory32(Value:Int, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Int Ptr = AddressThroughMMU(Addr, 4, CPU)

	CPU.MMU.LatestWriteAddress = Addr

	HostAddr[0] = Value
	'WriteMemory32(Value, CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUWriteMemory64(Value:Long, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Long Ptr = AddressThroughMMU(Addr, 8, CPU)
	
	CPU.MMU.LatestWriteAddress = Addr

	HostAddr[0] = Value
	'WriteMemory64(Value, CPU.MMU.Memory + TranslatedAddr)
End Function

