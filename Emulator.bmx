Framework BRL.StandardIO
Import BRL.Retro
Import BRL.GLMax2D

Import "ELFLoader/elfloader.bmx"
Import "RISCVCore/utils.bmx"
Import "RISCVCore/cpu_core.bmx"
Import "RISCVCore/decode.bmx"

' Check whether arguments are empty
If AppArgs.length < 2
	Print "Please drag and drop the binary or supply the filename via commandline"
	Return
End If

' Open the supplied file
Local Filename:String = AppArgs[1]
Local ELFFile:TStream = ReadFile(Filename)

If Not ELFFile
	Print "Couldn't open " + Filename + "!"
	Return
Else
	Print "Opened " + Filename
End If


' Processor core initialization
' ======================================================================
Local CPU:RV64i_core = New RV64i_core

CPU.MMU = New RV64i_mmu
CPU.CSR = New RV64i_csr
CPU.Serial8250 = New TSerial8250

' Allocate some system memory
CPU.MMU.MemorySize = 128 * 1024 * 1024
CPU.MMU.Memory = MemAlloc(CPU.MMU.MemorySize)

' Maximum MMU capability of 2GB
CPU.MMU.AddressBusMask = $7FFFFFFF:ULong
CPU.MMU.ForcedMask = $80000000:ULong

' Allocate some integrated interrupt controller memory
CPU.MMU.INTCSize = 64 * 1024
CPU.MMU.INTC = MemAlloc(CPU.MMU.INTCSize)

' INTC memory to start at 0x10010000
' And End at 0x1001FFFF
CPU.MMU.INTCStart = $10010000

' Allocate some MMIO memory (A 160x70 text-mode screen)
CPU.MMU.MMIOSize = 160*70
CPU.MMU.MMIO = MemAlloc(CPU.MMU.MMIOSize)

' Mark MMIO to start at 0x100B8000
CPU.MMU.MMIOStart = $100B8000

' Initialize our 8250 serial port
' 8 bytes at 0x20000000
CPU.MMU.Serial8250Size = 8
CPU.MMU.Serial8250Start = $20000000

' Put the serial port output into our MMIO
CPU.Serial8250.DestinationAddress = CPU.MMU.MMIO
CPU.Serial8250.DestinationLength = 160*70
CPU.Serial8250.DestinationWidth = 160

' Initialize the zero bank
CPU.MMU.Zero = MemAlloc(8)

' Init stack pointer
' Put the stack at 48th megabyte
CPU.Registers[2] = 48 * 1024 * 1024

' Assing the hart ID
CPU.ProcessorID = 0
' ======================================================================


' ELF loading and hacks
' ======================================================================
' Parse and load the sections
' Also store the entry point
Local ELFMetadata:ELFLoaderMetadata = LoadELF(ELFFile, CPU.MMU.Memory)

' Set the entry point and the global pointer
CPU.PC = ELFMetadata.EntryPoint | CPU.MMU.ForcedMask
CPU.Registers[3] = ELFMetadata.LastLoadedSection + $800 - 4

' Check for invalid entry point info
' Attempt to execute from 0x0 if invalid
' Required to run `vmlinux`
If ELFMetadata.EntryPoint > CPU.MMU.MemorySize
	Print "Invalid entry point: 0x" + Shorten(LongHex(CPU.PC))
	Print "Will start execution from 0x80000000"
	CPU.PC = $80000000:ULong
	
	' Because we now we are loading linux, load the device tree also
	' I believe DTB pointer is passed via `a1` by the bootloader
	' Place it right after the last `allocated` section
	CPU.Registers[11] = ELFMetadata.AllocationsEnd
	
	' We then load the .dtc file; plop it right next to the executable
	Local DTCFile:TStream = ReadFile("riscvemu.dtc")
	
	' Load right after the last allocated kernel section
	Local DTCAddr:Long = ELFMetadata.AllocationsEnd
	
	Local Status:Int
	
	If Not DTCFile
		Print "Couldn't open riscvemu.dtc; Aborting dtc load"
	Else
		Status = DTCFile.Read(CPU.MMU.Memory + DTCAddr, StreamSize(DTCFile))
		
		Print "DTC: loaded " + Unit(Status) + " at 0x" + PrettyHex(DTCAddr)
		
		CloseFile(DTCFile)
	End If
	
	' Additionally, load the initrd
	Local InitRDFile:TStream = ReadFile("ext2.img")
	
	' Load at the next megabyte-aligned address after the DTC
	Local InitRDAddr:Long = (((DTCAddr + Status) / 1024 / 1024) + 1) * 1024 * 1024
	
	If Not InitRDFile
		Print "Couldn't open ext2.img; aborting initrd load"
	Else
		Status = InitRDFile.Read(CPU.MMU.Memory + InitRDAddr, StreamSize(InitRDFile))
		
		Print "InitRD: loaded " + Unit(Status) + " at 0x" + PrettyHex(InitRDAddr)
		
		CloseFile(InitRDFile)
	End If
End If

' Close the ELF file now
CloseFile(ELFFile)

' Serial initialization hack
' Should go into Flush8250()
CPU.Serial8250.LSR = LSR_TX_EMPTY

' This is the only time Modem Status register appears to be used
' I think the kernel samples it for entropy
CPU.Serial8250.MSR = $80 
' ======================================================================


' Exhibit A:
' /the only/ proper way to prevent sign extension
' ======================================================================
' CPU.Registers[11] = $FFFFFFFF:ULong
' ======================================================================


' Graphics startup
AppTitle = "RISC-V Emulator. Hold S for slow mode."
Graphics 1920, 1080

Print "~r~n~r~n"
Print "Starting the trace-based execution!"
Print "==================================="

Local StepMode:Int = 0

Local Trace:TTrace
Local Insn:TInstruction ' For single instruction debugging

CPU.StartTime = MilliSecs()

CPU.ScreenAddress = $20F500
' Locations of interest
' $20F500	printk output buffer

CPU.Breakpoint = -1
' Locations of interest:
' $627b4	<printk>
' $549c		<workqueue_init_early>

' Currently missing:
' - Setting breakpoints while running

While True	
	' Check whether 8250 port started writing something
	' If so, switch the display to port destination
	If CPU.Serial8250.DestinationOffset > 0
		CPU.ScreenAddress = $100B8000
	End If
	
	If CPU.BreakpointHit
		Print "Breakpoint!"
		
		CPU.BreakpointHit = 0
		StepMode = 1	
	End If
	
	If StepMode
		Print "Step mode -- press Enter to step, C to continue normal execution"
		
		While True
			UpdateScreen(CPU, 0)
		
			If KeyHit(KEY_ENTER)
				Exit
			End If
			
			If KeyHit(KEY_C)
				StepMode = 0
				Exit
			End If
		Wend 
		
	End If
	
	Trace = NextTrace(CPU)
	
	' In step mode, execute at most 1 instruction
	' In fast mode, execute at most 300000 instructions
	If StepMode Or KeyDown(KEY_S)
	
		' In slow mode, also spill out instructions
		WriteStdout("0x" + PrettyHex(CPU.PC) + " : ")
		
		Insn = GetNextInstruction(Trace)
		Insn.Verbose = 1
		Decode(Insn)
		
		ExecuteTrace(Trace, 1)
	Else
		ExecuteTrace(Trace, 300000)
	End If
		
	
	' Graphics
	UpdateScreen(CPU, Not KeyDown(KEY_S))
Wend

Input("Press enter to exit")


' Update the graphical part of the emulator
Function UpdateScreen(CPU:RV64i_core, Fast:Int = 1)
	' In fast mode, update only on each 16th millisecond
	' Do not even start drawing anything otherwise
	If Fast
		If MilliSecs() Mod 16 <> 0 Then Return
	End If
	
	' Clear the screen
	Cls
	
	' Screen at the top
	SetOrigin 0, 0
	ShowScreen(CPU, 160, 70)
	
	' Registers below the screen
	SetOrigin 0, 730
	DrawRegisters(CPU)
	
	' Interrupts below the registers
	SetOrigin 0, 730 + 180
	DrawInterruptInformation(CPU)
	
	' Memory dump at the bottom
	SetOrigin 0, GraphicsHeight() - 50
	ShowMemoryDump(CPU)
	
	If Fast
		' Draw ASAP
		Flip 0
	Else
		' Draw on the next VBlank
		Flip
	End If
End Function

' Draw a 80x25 screendump
Function ShowScreen(CPU:RV64i_core, Width:Int = 80, Height:Int = 25)
	Local Character:String
		
	DrawLine 0, 10*(Height+1), Width*10, 10*(Height+1)
	DrawLine Width*10, 0, Width*10, 10*(Height+1)
	
	Local ScreenMemory:Byte Ptr = AddressThroughMMU(CPU.ScreenAddress, 1, CPU, MMU_READ, 0)
	
	For Local j:Int = 0 Until Height
		For Local i:Int = 0 Until Width
			Character = Chr( ScreenMemory[Width*j + i] )
			
			Select Character
				Case "~0"
					Continue
				Case "~n"
					Continue
				
				Default
					DrawText Character, i*10, j*10
			End Select
		Next
	Next
End Function

' Dumps registers
Function DrawRegisters(CPU:RV64i_core)
	Local HorizontalStep:Int = 300
	Local Rows:Int = 8
	
	Local OffsetX:Int
	Local OffsetY:Int
	
	Local RightEdge:Int = (32 / Rows) * HorizontalStep
	
	DrawText "Register state: ", 0, -12
	DrawLine 0, 0, RightEdge, 0
	DrawLine RightEdge, 0, RightEdge, (Rows + 7) * 10
	DrawLine 0, (Rows + 7) * 10, RightEdge, (Rows + 7) * 10
	
	For Local i:Int = 0 To 31
		OffsetY = i Mod Rows
		OffsetX = i / Rows
	
		DrawText register_name(i) + ": " + PrettyHex(CPU.Registers[i]), OffsetX*HorizontalStep, OffsetY*10
	Next
	
	DrawText "Latest read: " + PrettyHex(CPU.MMU.LatestReadAddress), 0, 10*(Rows + 2)
	DrawText "Latest write: " + PrettyHex(CPU.MMU.LatestWriteAddress), 0, 10*(Rows + 3)
	DrawText "Program Counter: " + PrettyHex(CPU.PC), 0, 10*(Rows + 5)
End Function

' Draw interrupt enable states and vectors
Function DrawInterruptInformation(CPU:RV64i_core)
	DrawText "Interrupt state: ", 0, -12
	DrawLine 0, 0, 400, 0
	DrawLine 400, 0, 400, 80
	DrawLine 0, 80, 400, 80
	
	' Registers
	DrawText "MStatus: 0b" + Shorten(LongBin(CPU.CSR.MStatus)), 0, 0
	DrawText "MTVec: 0x" + PrettyHex(CPU.CSR.MTVec), 0, 10
	
	' Memory-mapped registers
	DrawText "INTC_Timeval: 0x" + PrettyHex(ReadMemory64(CPU.MMU.INTC + INTC_TIME_VAL)), 0, 20
	DrawText "INTC_Timecmp: 0x" + PrettyHex(ReadMemory64(CPU.MMU.INTC + INTC_TIME_CMP)), 0, 30
	
	' Enabled and pending sources
	Local EnabledSources:String = ""
	Local PendingSources:String = ""
	
	If CPU.INTC.SoftwareInterruptsEnabled Then EnabledSources :+ "SOFTWARE "
	If CPU.INTC.TimerInterruptsEnabled Then EnabledSources :+ "TIMER "
	If CPU.INTC.ExternalInterruptsEnabled Then EnabledSources :+ "EXTERNAL "
	
	If CPU.INTC.PendingSoftwareInterrupt Then PendingSources :+ "SOFTWARE "
	If CPU.INTC.PendingTimerInterrupt Then PendingSources :+ "TIMER "
	If CPU.INTC.PendingExternalInterrupt Then PendingSources :+ "EXTERNAL "
	
	DrawText "Enabled: " + EnabledSources, 0, 50
	DrawText "Pending: " + PendingSources, 0, 60
End Function

' Draw the short dump of the latest read memory address
Function ShowMemoryDump(CPU:RV64i_core)	
	Local Character:String
	
	DrawText "Memory dump: ", 0, -12
	DrawLine 0, 0, 800, 0
	DrawLine 800, 0, 800, 50
		
	' Warn on bad address
	If CPU.MMU.LatestReadAddress & CPU.MMU.AddressBusMask = 0
		DrawText "Zero address", 0, 0
		Return
	End If
	
	Local DumpAddr:Byte Ptr = AddressThroughMMU(Long(CPU.MMU.LatestReadAddress), 1, CPU, MMU_TEST, 0)
	
	' Also disengage right off if the address points to zero bank
	' It is only 8 bytes long and we are going to read way more than that
	' Problem: we still cause pauses on behalf of calling AddressThroughMMU()
	If DumpAddr = CPU.MMU.Zero
		DrawText "Invalid address (MMU redirecting to zero bank)", 0, 0
		Return
	End If
	
	For Local j:Int = 0 To (5 - 1)
		For Local i:Int = 0 To (80 - 1)
			Character = Chr(DumpAddr[80*j + i])
			
			Select Character
				Case "~0"
					Continue
				Case "~n"
					Continue
				
				Default
					DrawText Character, i*10, j*10
			End Select
		Next
	Next
End Function
