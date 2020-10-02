Import BRL.Retro
Import "instruction.bmx"

'
' Below are various instruction handlers
' Each takes a specific instruction that is not memory or processor bound
' Each also takes the CPU whose state it will alter
'


' ADDI, aka ADD Intermediate (`Argument12`)
Function ADDI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Arg:Long = Insn.Argument12
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] + Arg	
	End If
End Function

' SD, aka Store Data (Full width)
Function SD_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with address where to store
	Local SrcB:Int = Insn.SourceB ' Register to store
	
	' Get the value
	Local Value:Long = CPU.Registers[SrcB]
	
	' Calculate the target addr
	Local Offset:Int = Insn.SD_Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	If Addr > CPU.MemorySize
		Print "Out of bounds write!"
		Print "Offending address: 0x" + LongHex(Addr)
	End If
	
	WriteMemory64BE(Value, CPU.Memory + Addr)
End Function

' JAL, aka Jump And Link
Function JAL_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	
	Local Offset:Int = Insn.JAL_Argument20
	
	' The address has to be calculated from the unadjusted PC
	' But we already made it point to the next instruction, so we have to subtract 4
	Local Addr:Long = CPU.PC - 4 + Offset
	
	If (Addr > CPU.MemorySize) Or (Addr < 0)
		Print "Out of bounds jump!"
		Print "Offending address: 0x" + LongHex(Addr)
	End If
		
	' Only store PC if the destination is not the `zero`
	' Thankfully the adjusted PC is useful here
	If Dest
		CPU.Registers[Dest] = CPU.PC
	End If
	
	' Finally perform the jump itself
	CPU.PC = Addr
End Function
