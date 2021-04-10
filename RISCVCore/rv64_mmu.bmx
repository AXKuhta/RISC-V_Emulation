
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
	Field Serial8250Size:Size_T
	
	' Address of the guest memory where INTC and MMIO zones start
	Field INTCStart:ULong
	Field MMIOStart:ULong
	Field Serial8250Start:ULong
End Type

' Various modes
' MMU_TEST is intended for dry-run type checks
Const MMU_READ = 1
Const MMU_WRITE = 2
Const MMU_EXECUTE = 3
Const MMU_TEST = 4

' MMU translation function
' Receives an address /of the guest memory/
' Returns an address /of the host memory/ that the caller should read
' Has a hardcoded implementation of MMIO remapping right now
Function AddressThroughMMU:Byte Ptr(Addr:Long, Width:Int, CPU:RV64i_core, Mode:Int, Verbose:Int = 1, Value:Long = 0)
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
				Print "Offending instruction address: 0x" + PrettyHex(CPU.PC - 4)
				Input "(Press Enter to continue)"
			End If
		End If
	
		Return CPU.MMU.Memory + TranslatedAddress
	End If
	
	' ### Option 2: MMIO access
	' Check whether we are hitting our MMIO address range
	Local IsMMIO:Int = TranslatedAddress >= CPU.MMU.MMIOStart And TranslatedAddress < (CPU.MMU.MMIOStart + CPU.MMU.MMIOSize)
	
	If IsMMIO
		' Switch the screen to display MMIO if an MMIO access is detected
		' 8250 bypasses this check
		If CPU.ScreenAddress <> CPU.MMU.MMIOStart
			CPU.ScreenAddress = CPU.MMU.MMIOStart			
		End If
	
		Return CPU.MMU.MMIO + (TranslatedAddress - CPU.MMU.MMIOStart)
	End If
	
	' ### Option 3: INTC access
	' Check whether we are hitting INTC address range
	Local IsINTC:Int = TranslatedAddress >= CPU.MMU.INTCStart And TranslatedAddress < (CPU.MMU.INTCStart + CPU.MMU.INTCSize)
		
	If IsINTC		
		' Notify what offset was accessed
		INTCNotify(CPU, TranslatedAddress - CPU.MMU.INTCStart, Mode:Int)
		
		Return CPU.MMU.INTC + (TranslatedAddress - CPU.MMU.INTCStart)
	End If
	
	' ### Option 4: 8250 controller access
	Local Is8250:Int = TranslatedAddress >= CPU.MMU.Serial8250Start And TranslatedAddress < (CPU.MMU.Serial8250Start + CPU.MMU.Serial8250Size)
	
	If Is8250
		' 8250 implementation proposal here:
		
		Assert(Width = 1)
		
		Select Mode
			Case MMU_WRITE
				Handle8250Write(CPU.Serial8250, (TranslatedAddress - CPU.MMU.Serial8250Start), Byte(Value))
				Return Varptr CPU.Serial8250.Zero
			Case MMU_READ
				Handle8250Read(CPU.Serial8250, (TranslatedAddress - CPU.MMU.Serial8250Start))
				Return Varptr CPU.Serial8250.BusOutput
		End Select
	End If
	
	' ### Option 5: Out of bounds access
	' Warn about that
	If Verbose
		Print "MMU: Error: out of bounds memory access!"
		Print "Offending instruction address: 0x" + PrettyHex(CPU.PC - 4)
		Print "Offending access address: 0x" + PrettyHex(Addr)
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
	Local HostAddr:Byte Ptr = AddressThroughMMU(Addr, 1, CPU, MMU_WRITE, 1, Value)
	
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


' Translate virtual to physical
Function TranslateAddress:Long(VirtualAddress:Long, CPU:RV64i_core)
	Local L1_Entries:Long Ptr = HostMemory( (CPU.CSR.SATP & $FFFFFFFFFFF) Shl 12, CPU )
	' 512 8-byte entries
	' 4 KB total
	
	' The offset into the page
	Local Offset:Int = VirtualAddress & $FFF
	
	' Extract L1, L2 and L3 keys
	Local L1:Int = (VirtualAddress Shr 30) & $1FF
	Local L2:Int = (VirtualAddress Shr 21) & $1FF
	Local L3:Int = (VirtualAddress Shr 12) & $1FF

	' Just sorta manually traverse it
	Local Entry_L1:Long = L1_Entries[L1]
	
	Local Valid = Entry_L1 & %00000001
	Local RWX 	= Entry_L1 & %00001110
	
	If Not Valid Then Return Null
	
	If RWX
		Return (Entry_L1 & $FFFFFFFFFFF000) + Offset
	End If
	
	' Traversing level 2 now
	Local L2_Entries:Long Ptr = HostMemory( Entry_L1 & $FFFFFFFFFFF000, CPU )
	Local Entry_L2:Long = L2_Entries[L2]
	
	Valid 	= Entry_L2 & %00000001
	RWX 	= Entry_L2 & %00001110
	
	If Not Valid Then Return Null
	
	If RWX
		Return (Entry_L2 & $FFFFFFFFFFF000) + Offset
	End If

	' Traversing level 3 now
	Local L3_Entries:Long Ptr = HostMemory( Entry_L2 & $FFFFFFFFFFF000, CPU )
	Local Entry_L3:Long = L3_Entries[L3]
	
	Valid 	= Entry_L3 & %00000001
	RWX 	= Entry_L3 & %00001110

	If Not Valid Then Return Null
	
	If RWX
		Return (Entry_L3 & $FFFFFFFFFFF000) + Offset
	End If
	
	RuntimeError "TranslateAddress: burned through all the levels but didn't find anything"
End Function

Function HostMemory:Byte Ptr(Addr:Long, CPU:RV64i_core)
	If Addr >= CPU.MMU.MemorySize
		RuntimeError "Out of bounds memory access"
	End If
	
	Return CPU.MMU.Memory + Addr
End Function

' Page Table Entry flags
Const PTE_V = %00000001
Const PTE_R = %00000010
Const PTE_W = %00000100
Const PTE_X = %00001000
Const PTE_U = %00010000
Const PTE_G = %00100000
Const PTE_A = %01000000
Const PTE_D = %10000000
