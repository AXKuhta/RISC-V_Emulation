Import BRL.Filesystem
Import BRL.Retro

Type ELFLoaderMetadata
	' Where to jump to start executing
	Field EntryPoint:Long
	
	' Last section that was populated with data
	Field LastLoadedSection:Long
	
	' Last section that could be used (Stack section, for example)
	Field LastAllocatedSection:Long
	
	' The point where you should be safe to load any additional stuff
	Field AllocationsEnd:Long
End Type

' 64 bit ELF program header (AKA virtual and physical addresses)
Type ELFProgramHeader
	Field PType:Int
	Field Flags:Int
	Field FileOffset:Long
	Field VirtMemAddr:Long
	Field PhysMemAddr:Long
	Field Size:Long
	Field SizeInMemory:Long
	Field Alignment:Long
End Type

' 64 bit ELF section header
Type ELFSectionHeader
	Field NameOffset:Int
	Field SType:Int
	Field Flags:Long
	Field MemAddr:Long
	Field FileOffset:Long
	Field Size:Long
	Field SizeInMemory:Long
	Field Alignment:Long
	
	Field Name:String
End Type

' Returns the entry point addr on success
' Returns null on failure
Function LoadELF:ELFLoaderMetadata(FileStream:TStream, Memory:Byte Ptr)
	If $7F454C46 <> ReadBytesBE(FileStream, 4)
		Print "ELF Magic code invalid"
		Return Null
	End If
	
	Local ELFClass:Byte = ReadByte(FileStream)
	Local ELFData:Byte = ReadByte(FileStream)
	Local ELFVersion:Byte = ReadByte(FileStream)
	Local ELFPadding:Byte = ReadByte(FileStream)
		
	If ELFData <> 1
		Print "Big-endian ELFs are not supported yet"
		Return Null
	End If
	
	ReadBytesBE(FileStream, 12) ' Skip 10 bytes of not intresting stuff
	
	If ReadBytesLE(FileStream, 4) <> 1
		Print "Some sort of misalign must've happened (ELF version2 <> 1)"
		Return Null
	End If
	
	Local CodeEntryPoint:Long = ReadBytesLE(FileStream, 8)
	Local ProgramHeaderOffset:Long = ReadBytesLE(FileStream, 8)
	Local SectionHeaderOffset:Long = ReadBytesLE(FileStream, 8)
	Local CPUFlags:Long = ReadBytesLE(FileStream, 4)
	Local ELFHeaderSize:Long = ReadBytesLE(FileStream, 2)
	
	Local ProgramHeaderEntrySize:Long = ReadBytesLE(FileStream, 2)
	Local ProgramHeaderEntries:Long = ReadBytesLE(FileStream, 2)
	
	Local SectionHeaderEntrySize:Long = ReadBytesLE(FileStream, 2)
	Local SectionHeaderEntries:Long = ReadBytesLE(FileStream, 2)
	
	Local StringsSectionHeaderIndex:Long = ReadBytesLE(FileStream, 2)
	
	Print "ELF code entry point virtual addr: 0x" + LongHex(CodeEntryPoint)
			
	' Load all of the section headers
	Local Headers:ELFSectionHeader[SectionHeaderEntries]
	
	For Local i=0 To (SectionHeaderEntries - 1)
		SeekStream(FileStream, SectionHeaderOffset + SectionHeaderEntrySize*i)
		Headers[i] = New ELFSectionHeader
		
		Headers[i].NameOffset = ReadBytesLE(FileStream, 4) ' Offset from the StringTableOffset
		Headers[i].SType = ReadBytesLE(FileStream, 4)
		Headers[i].Flags = ReadBytesLE(FileStream, 8)
		Headers[i].MemAddr = ReadBytesLE(FileStream, 8)
		Headers[i].FileOffset = ReadBytesLE(FileStream, 8)
		Headers[i].Size = ReadBytesLE(FileStream, 8)
	Next
	
	Local Segments:ELFProgramHeader[ProgramHeaderEntries]
	
	For Local i=0 To (ProgramHeaderEntries - 1)
		SeekStream(FileStream, ProgramHeaderOffset + ProgramHeaderEntrySize*i)
		Segments[i] = New ELFProgramHeader

		Segments[i].PType = ReadBytesLE(FileStream, 4)
		Segments[i].Flags = ReadBytesLE(FileStream, 4)
		Segments[i].FileOffset = ReadBytesLE(FileStream, 8)
		Segments[i].VirtMemAddr = ReadBytesLE(FileStream, 8)
		Segments[i].PhysMemAddr = ReadBytesLE(FileStream, 8)
		Segments[i].Size = ReadBytesLE(FileStream, 8)
		Segments[i].SizeInMemory = ReadBytesLE(FileStream, 8)
		Segments[i].Alignment = ReadBytesLE(FileStream, 8)
	Next
	
	Print Headers.length + " sections detected"
	Print Segments.length + " segments detected"
	Print "ELF format seemed good at first, but then this section/segment crap happened"
	
	' Load the section names
	Local StringTableOffset:Long = Headers[StringsSectionHeaderIndex].FileOffset
	
	For Local Header:ELFSectionHeader = EachIn Headers
		SeekStream(FileStream, StringTableOffset + Header.NameOffset)
		
		Header.Name = ReadCString(FileStream)
	Next
	
	' Create a return structure
	Local Metadata:ELFLoaderMetadata = New ELFLoaderMetadata
	
	' List all the sections present in the file
	' Take note of the last ALLOC section
	For Local Header:ELFSectionHeader = EachIn Headers
		Print "Section name: " + Header.Name
			
		If (Header.Flags & $2) <> 0
			Print "Section size: " + Unit(Header.Size)
			Print "Located at: " + Unit(Header.MemAddr)
			Print "Address: 0x" + LongHex(Header.MemAddr)
			
			' Dump section type and flags
			Print "Section type: " + LongBin(Header.SType)
			Print "Flags: " + LongBin(Header.Flags)
			
			
			If Header.SType = 1
				' Store the address of this section
				' We need the address of the last loaded section to determine the RISC-V global pointer
				' Yes, this is indeed a hack; crt0.S is supposed to do that
				Metadata.LastLoadedSection = Header.MemAddr
			Else
				' We still should keep track of non-PROGBITS sections
				Metadata.LastAllocatedSection = Header.MemAddr
				Metadata.AllocationsEnd = Header.MemAddr + Header.Size
				
				Print "Not a code section. Not loading it."
			End If
		Else
			' We completely ignore non-alloc sections
			Print "Non-alloc section, ignoring it"	
		End If
		
		Print "==============="
	Next
	
	For Local Segment:ELFProgramHeader = EachIn Segments
		If Segment.PType = 1
			Print "Loading " + Unit(Segment.Size) + " segment at " + Unit(Segment.PhysMemAddr)
		
			SeekStream(FileStream, Segment.FileOffset)
			FileStream.Read(Memory + Segment.PhysMemAddr, Segment.Size)
		Else 
			Print "Non-LOAD segment ignored"
		End If
	Next
	
	Print "==============="
	
	' Finish by filling in the entry point addr and returning
	Metadata.EntryPoint = CodeEntryPoint
	
	Return Metadata
	
End Function


Function ReadBytesBE:Long(FileStream:TStream, Length:Int)
	Local ReturnValue:Long = 0
	
	For Local i=0 To Length - 1
		ReturnValue :Shl 8
		ReturnValue :| ReadByte(FileStream)
	Next
	
	Return ReturnValue
End Function

Function ReadBytesLE:Long(FileStream:TStream, Length:Int)
	Local ReturnValue:Long = 0
	
	For Local i=0 To Length - 1
		ReturnValue :| (ReadByte(FileStream) Shl (8*i))
	Next
	
	Return ReturnValue
End Function

' Adds an appropriate unit (bytes / KB / MB) to the value
Function Unit:String(Value:Long)
	If Value < 1024
		Return Value + " bytes"
	ElseIf Value < 1024*1024
		Return (Value / 1024) + " KB"
	Else
		Return (Value / 1024 / 1024) + " MB"
	End If
End Function

' Reads a null-terminated string from a stream
' Operates with a 128 byte buffer
' Somewhat inefficient: reading 128 bytes is unnecessary
' Also it can underflow on EOF (At least it can't crash, thanks to the gentle .Read()...)
Function ReadCString:String(File:TStream)
	Local Buffer:Byte[128]
	
	File.Read(Buffer, 128)
	
	' Ensure that null-terminator is always present
	Buffer[127] = 0
	
	Return String.FromCString(Buffer)
End Function

' Takes an address and attempts to load `EntryCount` of null-terminated strings from it
' Beware: in ELF header it is the index of one of the headers specified, not the address of the string array
' The address you gotta extract from the FileOffset field of said header
'
' DEPRECATION: Turns out the .Name field of the section header specifies the offset of the string into the string table and essentially makes this function unnecesarry
'
Function LoadSectionNames:String[](File:TStream, Addr:Long, EntryCount:Long)
	Local Buffer:Byte Ptr = MemAlloc(16 * 1024) ' Use a 16KB buffer. Let's hope all the strings are short enough.
	Local Names:String[EntryCount]
	
	Local TerminatorCount:Int = 0
	Local Offset:Long = 0
	
	Local LastByte:Byte = 0
	Local i:Long = 0
	
	SeekStream(File, Addr)
	
	While TerminatorCount < EntryCount
		' Load the byte
		LastByte = ReadByte(File)
		
		' Store it
		Buffer[i] = LastByte
		i :+ 1
		
		' Check if it's a null terminator
		If LastByte = 0
			Names[TerminatorCount] = String.FromCString(Buffer + Offset)
			TerminatorCount :+ 1
			
			Offset = i
		End If
	Wend
	
	MemFree Buffer
	
	Return Names
End Function
