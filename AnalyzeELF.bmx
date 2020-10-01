Framework BRL.StandardIO

Import "ELFLoader/elfloader.bmx"

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

' Allocate some system memory
Local Memory:Byte Ptr = MemAlloc(8 * 1024 * 1024)

' Parse and load the sections
LoadELF(ELFFile, Memory)


' Deinit and wait
CloseFile(ELFFile)
MemFree Memory

Input "Press enter to close"
