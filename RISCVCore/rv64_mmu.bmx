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
		Return CPU.MMU.MMIO + (TranslatedAddress - CPU.MMU.MMIOStart)
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
End Function

Function MMUWriteMemory32(Value:Int, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Int Ptr = AddressThroughMMU(Addr, 4, CPU)

	CPU.MMU.LatestWriteAddress = Addr

	HostAddr[0] = Value
End Function

Function MMUWriteMemory64(Value:Long, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Long Ptr = AddressThroughMMU(Addr, 8, CPU)
	
	CPU.MMU.LatestWriteAddress = Addr

	HostAddr[0] = Value
End Function

