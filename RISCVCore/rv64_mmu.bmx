
Type RV64i_mmu
	Field LatestReadAddress:ULong
	Field LatestWriteAddress:ULong
	
	' Limit the meaningful address bits
	' Be sure to initialize this value!
	Field AddressBusMask:ULong
	
	' Used to hold the 32nd bit high in the internal state
	Field ForcedMask:ULong
	
	' Memory, interrupt controller and MMIO pointer
	Field Memory:Byte Ptr
	Field INTC:Byte Ptr
	Field MMIO:Byte Ptr
	Field Zero:Byte Ptr
	
	' How many bytes of memory is available for each one
	Field MemorySize:Size_T
	Field INTCSize:Size_T
	Field MMIOSize:Size_T
	
	' Address of the guest memory where INTC and MMIO zones start
	Field INTCStart:ULong
	Field MMIOStart:ULong
End Type

Const MMU_READ = 1
Const MMU_WRITE = 2
Const MMU_EXECUTE = 3
Const MMU_TEST = 4

' MMU translation function
' Receives an address /of the guest memory/
' Returns an address /of the host memory/ that the caller should read
' Has a hardcoded implementation of MMIO remapping right now
Function AddressThroughMMU:Byte Ptr(Addr:Long, Width:Int, CPU:RV64i_core, Mode:Int, Verbose:Int = 1)
	Local TranslatedAddress:ULong = 0
	
	' Remove meaningless bits
	TranslatedAddress = MMUTrim(Addr, CPU)
	
	' Warn on misaligned accesses
	' If TranslatedAddress Mod Width <> 0 Then Print "MMU: Warning: misaligned access for width " + Width
	
	' ### Option 1: RAM access
	' Optimization: assume RAM starts from 0x0 and all other areas are placed beyond the RAM address space
	Local IsMemory:Int = TranslatedAddress < CPU.MMU.MemorySize
	
	If IsMemory
		' Warn on null accesses
		If TranslatedAddress = 0
			If Verbose
				Print "MMU: Error: Access to 0! Null pointer error?"
				Input "(Press Enter to continue)"
			End If
		End If
	
		Return CPU.MMU.Memory + TranslatedAddress
	End If
	
	' ### Option 2: MMIO access
	' Check whether we are hitting our MMIO address range
	Local IsMMIO:Int = TranslatedAddress >= CPU.MMU.MMIOStart And TranslatedAddress < (CPU.MMU.MMIOStart + CPU.MMU.MMIOSize)
	
	If IsMMIO
		Return CPU.MMU.MMIO + (TranslatedAddress - CPU.MMU.MMIOStart)
	End If
	
	' ### Option 3: INTC access
	' Check whether we are hitting INTC address range
	Local IsINTC:Int = TranslatedAddress >= CPU.MMU.INTCStart And TranslatedAddress < (CPU.MMU.INTCStart + CPU.MMU.INTCSize)
		
	If IsINTC		
		' Notify what offset was accessed
		INTCNotify(CPU, TranslatedAddress - CPU.MMU.INTCStart)
		
		Return CPU.MMU.INTC + (TranslatedAddress - CPU.MMU.INTCStart)
	End If
	
	' ### Option 4: Out of bound access
	' Warn about that
	If Verbose
		Print "MMU: Error: out of bounds memory access!"
		Print "Offending address: 0x" + Shorten(LongHex(Long(Addr)))
		Input "(Press Enter to continue)"
	End If
	
	' Return our special 8 bytes long zero-bank if address is bad
	' This is done to prevent crashing
	Return CPU.MMU.Zero
End Function

' Removes meaningless bits from the address
Function MMUTrim:Long(Addr:Long, CPU:RV64i_core)
	Return Addr & CPU.MMU.AddressBusMask
End Function

' Wrappers that will run the address through the MMU before reading/writing
Function MMUReadMemory8:Byte(Addr:Long, CPU:RV64i_core)
	Local HostAddr:Byte Ptr = AddressThroughMMU(Addr, 1, CPU, MMU_READ)
	
	CPU.MMU.LatestReadAddress = Addr
	
	Return HostAddr[0]
End Function

Function MMUReadMemory16:Short(Addr:Long, CPU:RV64i_core)
	Local HostAddr:Short Ptr = AddressThroughMMU(Addr, 2, CPU, MMU_READ)

	CPU.MMU.LatestReadAddress = Addr

	Return HostAddr[0]
End Function

Function MMUReadMemory32:Int(Addr:Long, CPU:RV64i_core)
	Local HostAddr:Int Ptr = AddressThroughMMU(Addr, 4, CPU, MMU_READ)

	CPU.MMU.LatestReadAddress = Addr

	Return HostAddr[0]
	'Return ReadMemory32(CPU.MMU.Memory + TranslatedAddr)
End Function

Function MMUReadMemory64:Long(Addr:Long, CPU:RV64i_core)
	Local HostAddr:Long Ptr = AddressThroughMMU(Addr, 8, CPU, MMU_READ)

	CPU.MMU.LatestReadAddress = Addr
	
	Return HostAddr[0]
End Function


Function MMUWriteMemory8(Value:Byte, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Byte Ptr = AddressThroughMMU(Addr, 1, CPU, MMU_WRITE)
	
	CPU.MMU.LatestWriteAddress = Addr
	
	WriteNotify(Addr, CPU)
	
	HostAddr[0] = Value
End Function

Function MMUWriteMemory16(Value:Short, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Short Ptr = AddressThroughMMU(Addr, 2, CPU, MMU_WRITE)

	CPU.MMU.LatestWriteAddress = Addr
	
	WriteNotify(Addr, CPU)

	HostAddr[0] = Value
End Function

Function MMUWriteMemory32(Value:Int, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Int Ptr = AddressThroughMMU(Addr, 4, CPU, MMU_WRITE)

	CPU.MMU.LatestWriteAddress = Addr
	
	WriteNotify(Addr, CPU)

	HostAddr[0] = Value
End Function

Function MMUWriteMemory64(Value:Long, Addr:Long, CPU:RV64i_core)
	Local HostAddr:Long Ptr = AddressThroughMMU(Addr, 8, CPU, MMU_WRITE)
	
	CPU.MMU.LatestWriteAddress = Addr
	
	WriteNotify(Addr, CPU)

	HostAddr[0] = Value
End Function


' PMPCFG entry fields
' Unused for now
Const PMP_R = %00000001 ' Read permission
Const PMP_W = %00000010 ' Write permission
Const PMP_X = %00000100 ' Execute (i.e. Fetch) permission
Const PMP_A = %00011000 ' Length calculation mode
Const PMP_L = %10000000 ' Lock the entry (can only unlock with machine reset)

Const PMP_ADDR_OFF = 0 ' Disable region
Const PMP_ADDR_TOR = 1 ' Top Of Range. This PMPADDR is the top of the region, preceding PMPADDR is the bottom
Const PMP_ADDR_NA4 = 2 ' 4 bytes fixed length
Const PMP_ADDR_NAPOT = 3 ' Use lower bits of PMPADDR to determine the length
