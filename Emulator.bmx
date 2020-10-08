Framework BRL.StandardIO
Import BRL.Retro
Import BRL.GLMax2D

Import "ELFLoader/elfloader.bmx"
Import "RISCVCore/utils.bmx"
Import "RISCVCore/cpu_core.bmx"
Import "RISCVCore/instruction.bmx"
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

' Init our core
Local CPU:RV64i_core = New RV64i_core

' Allocate some system memory
CPU.MMU.MemorySize = 64 * 1024 * 1024
CPU.MMU.Memory = MemAlloc(CPU.MMU.MemorySize)

' Maximum MMU capability of 2GB
CPU.MMU.AddressBusMask = $7FFFFFFF

' Allocate some MMIO memory (A 80x25 text-mode screen)
CPU.MMU.MMIOSize = 80*25
CPU.MMU.MMIO = MemAlloc(CPU.MMU.MMIOSize)

' Mark MMIO to start at 0x100B8000
CPU.MMU.MMIOStart = $100B8000

' Init stack pointer
' Put the stack at 48th megabyte
CPU.Registers[2] = 48 * 1024 * 1024

' Parse and load the sections
' Also store the entry point
Local ELFMetadata:ELFLoaderMetadata = LoadELF(ELFFile, CPU.MMU.Memory)

' Set the entry point and the global pointer
CPU.PC = ELFMetadata.EntryPoint
CPU.Registers[3] = ELFMetadata.LastLoadedSection + $800 - 4

' Check for invalid entry point info
' Attempt to execute from 0x0 if invalid
' Required to run `vmlinux`
If CPU.PC > CPU.MMU.MemorySize
	Print "Invalid entry point: 0x" + Shorten(LongHex(CPU.PC))
	Print "Will start execution from 0x0"
	CPU.PC = 0
End If

' Close the ELF file now
CloseFile(ELFFile)


' Graphics startup
AppTitle = "RISC-V Emulator. Hold F to disable graphics updates. Press / to set breakpoint"
Graphics 1200, 600

Print "~r~n~r~n"
Print "Starting the Fetch-Decode-Execute now!"
Print "======================================"

' Jump notification system
Local PreviousPC:Long
Local JumpWarning:String = "[e]"

' MMU address-has-meaningless-bits warning
Local MMUWarning:String = "[ ]"

Local Insn:TInstruction
Local Status:Int

Local Breakpoint:String = "" '"1e5114" <__memcpy>:
Local StepMode:Int = 0


' Main loop (No support for translation blocks/handler chaining yet)
While True
	If StepMode
		Input "Press Enter"
	End If
	
	If Lower(Shorten(LongHex(CPU.PC))) = Breakpoint
		Print "Breakpoint"
		Input "Press Enter"
		'StepMode = 1
	End If
	
	
	' Warn if current address has meaningless bits
	If CPU.PC > CPU.MMU.AddressBusMask
		MMUWarning = "[!]"
	Else
		MMUWarning = "[ ]"
	End If
	
	' Warn if PC has changed
	If (PreviousPC + 4 = CPU.PC)
		JumpWarning = "[ ]"
	Else
		JumpWarning = "[x]"
	End If
	
	
	' Print the address
	WriteStdout("0x" + Shorten(LongHex(CPU.PC)) + " : " + MMUWarning + " : " + JumpWarning + " : ")
	
	
	' Fetch-Decode-Execute chain
	' Fetch
	Insn = Fetch(CPU)
	PreviousPC = CPU.PC
	CPU.PC :+ 4
	
	' Decode
	Status = Decode(Insn)
	
	If Status = 0
		Print "Couldn't decode instruction"
		Exit
	End If
	
	' Execute
	Insn.Handler(Insn, CPU)
	
	
	' Graphics
	If Not KeyDown(KEY_F)
		Cls
		
		ShowScreen(CPU)
		DrawRegisters(CPU)
		ShowMemoryDump(CPU)
		
		' By default Flip will limit the main loop to 60 Hz (Or whatever the monitor refresh rate is)
		' You can disable than by passing 0 as an argument
		' But we'll leave it at 60 Hz for now for the aesthetic value
		Flip
	End If
	
	' Breakpoint
	If KeyHit(KEY_SLASH)
		Breakpoint = Input("[!] Please type the breakpoint address (in lowercase shortened hex): 0x")
	End If

Wend

Input("Press enter to exit")


' Draw a 80x25 screendump
Function ShowScreen(CPU:RV64i_core)
	Local Character:String
	
	DrawLine 0, 260, 800, 260
	DrawLine 800, 0, 800, 260
	
	For Local j:Int = 0 To (25 - 1)
		For Local i:Int = 0 To (80 - 1)
			Character = Chr(CPU.MMU.MMIO[80*j + i])
			
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
	Local PosX:Int = 0
	Local PosY:Int = 0
	
	For Local i:Int = 0 To 31
		PosY = i Mod 8
		PosX = i / 8
	
		DrawText register_name(i) + ": " + Shorten(LongHex(CPU.Registers[i])), PosX*300, 270 + PosY*10
	Next
	
	DrawText "Latest read: " + Shorten(LongHex(Long(CPU.MMU.LatestReadAddress))), 0, 370
	DrawText "Latest write: " + Shorten(LongHex(Long(CPU.MMU.LatestWriteAddress))), 0, 380
End Function

' Draw the short dump of the latest read memory address
Function ShowMemoryDump(CPU:RV64i_core)	
	DrawText "Memory dump: ", 0, 538
	DrawLine 0, 550, 800, 550
	DrawLine 800, 550, 800, 600
		
	' Warn on bad address
	If CPU.MMU.LatestReadAddress & CPU.MMU.AddressBusMask = 0
		DrawText "Zero address", 0, 550
		Return
	End If
	
	Local DumpAddr:Byte Ptr = AddressThroughMMU(Long(CPU.MMU.LatestReadAddress), 1, CPU)
	Local Character:String
	
	For Local j:Int = 0 To (5 - 1)
		For Local i:Int = 0 To (80 - 1)
			Character = Chr(DumpAddr[80*j + i])
			
			Select Character
				Case "~0"
					Continue
				Case "~n"
					Continue
				
				Default
					DrawText Character, i*10, 550 + j*10
			End Select
		Next
	Next
End Function
