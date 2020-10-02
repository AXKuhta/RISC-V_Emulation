Import BRL.Retro
Import "instruction.bmx"

'
' Below are various instruction handlers
' Each takes a specific instruction that is not memory or processor bound
' Each also takes the CPU whose state it will alter
'


' ADDI, aka ADD Immediate (`Argument12`)
Function ADDI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Arg:Long = Insn.Argument12
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] + Arg	
	End If
End Function

' Load Data Instructions
' ======================================================================
' LW, aka Load Data (32 bit)
Function LW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	If (Addr > CPU.MemorySize) Or (Addr < 0)
		Print "Out of bounds read!"
		Print "Offending address: 0x" + LongHex(Addr)
	End If
	
	Local Value:Long = ReadMemory32LE(CPU.Memory + Addr)
	
	' For LW, we have to sign-extend the value
	Value = SignExt(Value, 32)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function

' LD, aka Load Data (Full width)
Function LD_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	If (Addr > CPU.MemorySize) Or (Addr < 0)
		Print "Out of bounds read!"
		Print "Offending address: 0x" + LongHex(Addr)
	End If
	
	Local Value:Long = ReadMemory64LE(CPU.Memory + Addr)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function
' ======================================================================


' Store Data Instructions
' ======================================================================
' SW, aka Store Data (32 bit)
Function SW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with address where to store
	Local SrcB:Int = Insn.SourceB ' Register to store
	
	' Get the value (lower bits)
	Local Value:Int = Int(CPU.Registers[SrcB])
	
	' Calculate the target addr
	Local Offset:Int = Insn.SD_Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	If (Addr > CPU.MemorySize) Or (Addr < 0)
		Print "Out of bounds write!"
		Print "Offending address: 0x" + LongHex(Addr)
	End If
	
	WriteMemory32LE(Value, CPU.Memory + Addr)
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
	
	If (Addr > CPU.MemorySize) Or (Addr < 0)
		Print "Out of bounds write!"
		Print "Offending address: 0x" + LongHex(Addr)
	End If
	
	WriteMemory64LE(Value, CPU.Memory + Addr)
End Function
' ======================================================================

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

' LUI, aka Load Upper Immediate, aka load value into upper bits of the register
Function LUI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	
	Local Result:Long = 0
	Local Zero:Int = 0
	Local Arg:Int = Insn.LUI_Argument20
	
	Arg :Shl 12
	
	Result = SignExt(Arg | Zero, 32)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function
