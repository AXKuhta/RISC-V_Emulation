Import BRL.Retro
Import "instruction.bmx"

'
' Below are various instruction handlers
' Each takes a specific instruction that is not memory or processor bound
' Each also takes the CPU whose state it will alter
'


' Register + Register ALU Operations
' ======================================================================
Function ADD_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] + CPU.Registers[SrcB]
	End If
End Function

Function SUB_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] - CPU.Registers[SrcB]
	End If
End Function
' ======================================================================


' Argument + Register ALU Operations
' ======================================================================
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

' ADDIW, aka ADD Immediate (`Argument12`) and 32 bit sign extend
Function ADDIW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Arg:Long = Insn.Argument12
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = SignExt(CPU.Registers[SrcA] + Arg, 32)
	End If
End Function

' XORI, aka logical XOR Immediate (`Argument12`)
' TODO: xor -1 should perform inversion
' Check if that's actually the case with BlitzMax
Function XORI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Arg:Long = Insn.Argument12
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] ~ Arg	
	End If
End Function

' ORI, aka logical OR Immediate (`Argument12`)
Function ORI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Arg:Long = Insn.Argument12
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] | Arg	
	End If
End Function

' ANDI, aka logical AND Immediate (`Argument12`)
Function ANDI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Arg:Long = Insn.Argument12
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] & Arg	
	End If
End Function
' ======================================================================


' Bit shifts
' ======================================================================
' Shift Right Logical Immediate
Function SRLI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Amount:Int = Insn.AxR_Shift_Amount
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] Shr Amount
	End If
End Function

' Shift Left Logical Immediate
Function SLLI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Amount:Int = Insn.AxR_Shift_Amount
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] Shl Amount
	End If
End Function
' ======================================================================


' Load Data Instructions
' ======================================================================
' LBU, aka Load Data (8 bit)
Function LBU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	CheckAddress(Addr, CPU)
	
	' Make sure we init to 0
	Local Value:Long = 0
	
	' We can then read 8 bits directly
	Value = CPU.Memory[Addr]
		
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function

' LHU, aka Load Data (16 bit)
Function LHU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	CheckAddress(Addr, CPU)
	
	' Make sure we init to 0
	Local Value:Long = 0
	
	' We can then read 8 bits directly
	Value = ReadMemory16LE(CPU.Memory + Addr)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function

' LW, aka Load Data (32 bit; sign extended)
Function LW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	CheckAddress(Addr, CPU)
	
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
	
	CheckAddress(Addr, CPU)
	
	Local Value:Long = ReadMemory64LE(CPU.Memory + Addr)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function
' ======================================================================


' Store Data Instructions
' ======================================================================
' SB, aka Store Data (8 bit)
Function SB_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with address where to store
	Local SrcB:Int = Insn.SourceB ' Register to store
	
	' Get the value (lower bits)
	Local Value:Byte = Byte(CPU.Registers[SrcB])
	
	' Calculate the target addr
	Local Offset:Int = Insn.SD_Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	CheckAddress(Addr, CPU)
	
	' We can store 8 bits directly
	CPU.Memory[Addr] = Value
End Function

' SH, aka Store Data (16 bit)
Function SH_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with address where to store
	Local SrcB:Int = Insn.SourceB ' Register to store
	
	' Get the value (lower bits)
	Local Value:Short = Short(CPU.Registers[SrcB])
	
	' Calculate the target addr
	Local Offset:Int = Insn.SD_Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	CheckAddress(Addr, CPU)
	
	WriteMemory16LE(Value, CPU.Memory + Addr)
End Function

' SW, aka Store Data (32 bit)
Function SW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with address where to store
	Local SrcB:Int = Insn.SourceB ' Register to store
	
	' Get the value (lower bits)
	Local Value:Int = Int(CPU.Registers[SrcB])
	
	' Calculate the target addr
	Local Offset:Int = Insn.SD_Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	CheckAddress(Addr, CPU)
	
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
	
	CheckAddress(Addr, CPU)
	
	WriteMemory64LE(Value, CPU.Memory + Addr)
End Function
' ======================================================================


' Address Building Instructions
' ======================================================================
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

' AUIPC, aka Add Upper Immediate and PC (and store the result into a register)
Function AUIPC_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	
	Local Result:Long = 0
	Local Zero:Int = 0
	Local Arg:Int = Insn.LUI_Argument20
	Local LongArg:Long = 0
	
	' Shift higher, will zero-extend
	Arg :Shl 12
	
	' Sign-extension to 64 bits is required
	LongArg = SignExt(Arg, 32)
	
	' Extended Immediate + PC
	Result = LongArg + CPU.PC
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function
' ======================================================================


' Call and Ret Instructions
' ======================================================================
' JAL, aka Jump And Link
' Offset based
Function JAL_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	
	Local Offset:Int = Insn.JAL_Argument20
	
	' The address has to be calculated from the unadjusted PC
	' But we already made it point to the next instruction, so we have to subtract 4
	Local Addr:Long = CPU.PC - 4 + Offset
	
	CheckAddress(Addr, CPU)
		
	' Only store PC if the destination is not the `zero`
	' Thankfully the adjusted PC is useful here
	If Dest
		CPU.Registers[Dest] = CPU.PC
	End If
	
	' Finally perform the jump itself
	CPU.PC = Addr
End Function

' JAL, aka RET, aka Register Jump And Link 
' Absolute based
Function JALR_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local Dest:Int = Insn.Destination
	
	Local Addr:Long = CPU.Registers[SrcA] + Insn.Argument12
	
	CheckAddress(Addr, CPU)
		
	' Only store PC if the destination is not the `zero`
	' Thankfully the adjusted PC is useful here
	If Dest
		CPU.Registers[Dest] = CPU.PC
	End If
	
	' Finally perform the jump itself
	CPU.PC = Addr
End Function
' ======================================================================


' Conditional Branch Instructions
' ======================================================================
' BGE, aka Branch If Greater or Equal
Function BGE_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	
	' The address has to be calculated from the unadjusted PC
	' But we already made it point to the next instruction, so we have to subtract 4
	Local Addr:Long = CPU.PC - 4 + Insn.BR_Argument
	
	CheckAddress(Addr, CPU)
	
	If CPU.Registers[SrcA] >= CPU.Registers[SrcB]
		CPU.PC = Addr
	End If
End Function

' BLT, aka Branch If Less Than
Function BLT_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	
	' The address has to be calculated from the unadjusted PC
	' But we already made it point to the next instruction, so we have to subtract 4
	Local Addr:Long = CPU.PC - 4 + Insn.BR_Argument
	
	CheckAddress(Addr, CPU)
	
	If CPU.Registers[SrcA] < CPU.Registers[SrcB]
		CPU.PC = Addr
	End If
End Function

' BEQ, aka Branch If Equal
Function BEQ_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	
	' The address has to be calculated from the unadjusted PC
	' But we already made it point to the next instruction, so we have to subtract 4
	Local Addr:Long = CPU.PC - 4 + Insn.BR_Argument
	
	CheckAddress(Addr, CPU)
	
	If CPU.Registers[SrcA] = CPU.Registers[SrcB]
		CPU.PC = Addr
	End If
End Function

' BGE, aka Branch If Not Equal
Function BNE_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	
	' The address has to be calculated from the unadjusted PC
	' But we already made it point to the next instruction, so we have to subtract 4
	Local Addr:Long = CPU.PC - 4 + Insn.BR_Argument
	
	CheckAddress(Addr, CPU)
	
	If CPU.Registers[SrcA] <> CPU.Registers[SrcB]
		CPU.PC = Addr
	End If
End Function
' ======================================================================


' Control and Status Registers Read/Write
' ======================================================================
' CSR [Save into register] and load from register
Function CSRRW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local TargetCSR:Int = Insn.CSR_Argument12
	Local SrcA:Int = Insn.SourceA
	Local Dest:Int = Insn.Destination
	
	Local Value:Byte = CPU.Registers[SrcA]
	
	' We must only read the CSR if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.CSR[TargetCSR]
	End If
	
	' We then overwrite the CSR
	CPU.CSR[TargetCSR] = Value
End Function

' CSR Save into register and [logical OR with register]
Function CSRRS_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local TargetCSR:Int = Insn.CSR_Argument12
	Local SrcA:Int = Insn.SourceA
	Local Dest:Int = Insn.Destination

	Local Value:Byte = CPU.Registers[Insn.SourceA]

	' Spec says we must always read the CSR with this instruction
	' But doing so would taint our `zero` register
	' So don't do it!
	If Dest
		CPU.Registers[Dest] = CPU.CSR[TargetCSR]
	End If
	
	' Write only if the source is not `zero`
	If SrcA
		CPU.CSR[TargetCSR] = CPU.CSR[TargetCSR] | Value
	End If
End Function


' CSR [Save into register] and load from argument
Function CSRRWI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local TargetCSR:Int = Insn.CSR_Argument12
	Local SrcA:Int = Insn.SourceA
	Local Dest:Int = Insn.Destination
	
	' The value to load is stored in the SourceA field
	Local Value:Byte = Insn.SourceA

	' We must only read the CSR if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.CSR[TargetCSR]
	End If
	
	' We then overwrite the CSR
	CPU.CSR[TargetCSR] = Value
End Function
' ======================================================================


' Multiprocessor synchronization
' ======================================================================
' Dummy handler for now
Function FENCE_Handler(Insn:TInstruction, CPU:RV64i_core)

End Function
' ======================================================================

