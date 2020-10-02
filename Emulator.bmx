Framework BRL.StandardIO
Import BRL.Retro

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
CPU.MemorySize = 8 * 1024 * 1024
CPU.Memory = MemAlloc(CPU.MemorySize)

' Init stack pointer
' Stack grows backwards, so put it at the edge of the memory
CPU.Registers[2] = 8 * 1024 * 1024

' Parse and load the sections
' Also store the entry point
CPU.PC = LoadELF(ELFFile, CPU.Memory)

' Close the ELF file now
CloseFile(ELFFile)

Print "~r~n~r~n"
Print "Starting the Fetch-Decode-Execute now!"
Print "======================================"

' Jump notification system
Local PreviousPC:Long
Local JumpWarning:String = "[e]"

Local Insn:TInstruction
Local Status:Int


' Main loop (No support for translation blocks/handler chaining yet)
While True
	' Print the address
	WriteStdout("0x" + Shorten(LongHex(CPU.PC)) + " : " + JumpWarning + " : ")

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
Wend

Input("Press enter to exit")