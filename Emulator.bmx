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
CPU.MemorySize = 32 * 1024 * 1024
CPU.Memory = MemAlloc(CPU.MemorySize)

' Init stack pointer
' Put the stack at 24th megabyte
CPU.Registers[2] = 24 * 1024 * 1024

' Parse and load the sections
' Also store the entry point
Local ELFMetadata:ELFLoaderMetadata = LoadELF(ELFFile, CPU.Memory)

' Set the entry point and the global pointer
CPU.PC = ELFMetadata.EntryPoint
CPU.Registers[3] = ELFMetadata.LastLoadedSection + $7FC '$800

' Check for invalid entry point info
' Attempt to execute from 0x0 if invalid
' Required to run `vmlinux`
If CPU.PC > CPU.MemorySize
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

Local Insn:TInstruction
Local Status:Int

Local Breakpoint:String = "" '"1e5114" <__memcpy>:
Local StepMode:Int = 0


' Main loop (No support for translation blocks/handler chaining yet)
While True
	If StepMode
		Input "Press Enter"
	End If

	' Print the address
	WriteStdout("0x" + Shorten(LongHex(CPU.PC)) + " : " + JumpWarning + " : ")
		
	If Lower(Shorten(LongHex(CPU.PC))) = Breakpoint
		Print "Breakpoint"
		Input "Press Enter"
		StepMode = 1
	End If
	
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
	
	' Check if PC is intact
	If (PreviousPC + 4 = CPU.PC)
		JumpWarning = "[ ]"
	Else
		JumpWarning = "[x]"
	End If
	
	' Graphics
	If Not KeyDown(KEY_F)
		Cls
		
		ShowScreen(CPU)
		
		DrawRegisters(CPU)
		
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
	Local SCREEN_BASE:Int = $8B00 '$244DF0 '$242600 ' $8B00
	Local Character:String
	
	DrawLine 0, 260, 800, 260
	DrawLine 800, 0, 800, 260
	
	For Local j:Int = 0 To (25 - 1)
		For Local i:Int = 0 To (80 - 1)
			Character = Chr(CPU.Memory[SCREEN_BASE + 80*j + i])
			
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
End Function