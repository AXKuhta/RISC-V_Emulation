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

Function AND_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] & CPU.Registers[SrcB]
	End If
End Function

Function OR_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] | CPU.Registers[SrcB]
	End If
End Function

Function XOR_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] ~ CPU.Registers[SrcB]
	End If
End Function

Function SLL_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] Shl (CPU.Registers[SrcB] & %111111)
	End If
End Function

Function SRL_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] Shr (CPU.Registers[SrcB] & %111111)
	End If
End Function

Function SRA_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] Sar (CPU.Registers[SrcB] & %111111)
	End If
End Function

' Set Less Than
Function SLT_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	Local Result:Int = 1 & (CPU.Registers[SrcA] < CPU.Registers[SrcB])

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function

' Set Less Than (Unsigned)
Function SLTU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	' Note the cast to ULong
	Local Arg1:ULong = CPU.Registers[SrcA]
	Local Arg2:ULong = CPU.Registers[SrcB]
	
	Local Result:Int = 1 & (Arg1 < Arg2)

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function
' ======================================================================


' Register + Register ALU Operations (32 bit)
' ======================================================================
Function ADDW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	' 1. Cast the sources to Int (Will lose upper bits)
	' 2. Perform the operation
	' 3. Sign extension is not required when casting to Long from Int
	
	Local Result:Int = Int(CPU.Registers[SrcA]) + Int(CPU.Registers[SrcB])
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function

Function SUBW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
		
	Local Result:Int = Int(CPU.Registers[SrcA]) - Int(CPU.Registers[SrcB])
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function

Function SLLW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	Local Result:Int = Int(CPU.Registers[SrcA]) Shl Int(CPU.Registers[SrcB] & %11111)

	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function

Function SRLW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	Local Result:Int = Int(CPU.Registers[SrcA]) Shr Int(CPU.Registers[SrcB] & %11111)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function

Function SRAW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	Local Result:Int = Int(CPU.Registers[SrcA]) Sar Int(CPU.Registers[SrcB] & %11111)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function
' ======================================================================


' Register + Register ALU Operations (M Extension)
' ======================================================================
' Multiply
Function MUL_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] * CPU.Registers[SrcB]
	End If
End Function

' Multiply and store higher bits (Unsigned x Unsigned)
Function MULHU_Handler(Insn:TInstruction, CPU:RV64i_core)
	' Broken: do not use
	' TODO: Research if we can use 128 bit math
	' Hook a C function?
	' SIMD intrinsics?
End Function

' Division (Unsigned)
Function DIVU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	' Note the cast to ULong
	Local Arg1:ULong = CPU.Registers[SrcA]
	Local Arg2:ULong = CPU.Registers[SrcB]
	
	' Only write if the destination is not the `zero`
	If Dest
		' Also handle division by zero
		If Arg2 = 0
			CPU.Registers[Dest] = (2^64) - 1
		Else
			CPU.Registers[Dest] = Arg1 / Arg2
		End If
	End If
End Function

' Remainder (Unsigned)
Function REMU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	' Note the cast to ULong
	Local Arg1:ULong = CPU.Registers[SrcA]
	Local Arg2:ULong = CPU.Registers[SrcB]
	
	' Only write if the destination is not the `zero`
	If Dest
		' Also handle remainder by zero
		If Arg2 = 0
			CPU.Registers[Dest] = Arg1
		Else
			CPU.Registers[Dest] = Arg1 Mod Arg2
		End If
	End If
End Function
' ======================================================================


' Register + Register ALU Operations (M Extension) (32 bit)
' ======================================================================
' Multiply (32 bit)
Function MULW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	Local Arg1:Int = CPU.Registers[SrcA] & $FFFFFFFF
	Local Arg2:Int = CPU.Registers[SrcB] & $FFFFFFFF
	
	Local Result:Int = Arg1 * Arg2
	
	' Only write if the destination is not the `zero`
	If Dest
		' Casting Int to Long should sign extend
		CPU.Registers[Dest] =  Result
	End If
End Function

' Division (Unsigned) (32 bit)
Function DIVUW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination
	
	' Note the cast to UInt
	Local Arg1:UInt = CPU.Registers[SrcA]
	Local Arg2:UInt = CPU.Registers[SrcB]
	
	Local Result:UInt
	
	' Only write if the destination is not the `zero`
	If Dest
		' Also handle division by zero
		If Arg2 = 0
			CPU.Registers[Dest] = (2^64) - 1
		Else
			Result = Arg1 / Arg2
			
			CPU.Registers[Dest] = Int(Result)
		End If
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

' SLTI, aka Set if Less Than Immediate (`Argument12`)
Function SLTI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Arg1:Long = CPU.Registers[SrcA]
	Local Arg2:Long = Insn.Argument12
	
	Local Result:Int = 1 & (Arg1 < Arg2)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result	
	End If
End Function

' SLTIU, aka Set if Less Than Immediate (`Argument12`) (unsigned)
Function SLTIU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	' Note the cast to ULong
	Local Arg1:ULong = CPU.Registers[SrcA]
	Local Arg2:ULong = Insn.Argument12
	
	Local Result:Int = 1 & (Arg1 < Arg2)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result	
	End If
End Function
' ======================================================================


' Bit shifts
' ======================================================================
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

' Shift Right Arithmetic Immediate
Function SRAI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	Local Amount:Int = Insn.AxR_Shift_Amount
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = CPU.Registers[SrcA] Sar Amount
	End If
End Function
' ======================================================================


' Bit shifts (32 bit)
' ======================================================================
' Shift Left Logical Immediate (32 bit)
Function SLLIW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	' Amount is stored in the SourceB field
	Local Amount:Int = Insn.SourceB
	
	' Calculate into ULong to prevent BlitzMax from sign-extending
	Local Result:ULong = Int(CPU.Registers[SrcA]) Shl Amount
		
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function

' Shift Right Logical Immediate (32 bit)
Function SRLIW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	' Amount is stored in the SourceB field
	Local Amount:Int = Insn.SourceB
	
	' Calculate into ULong to prevent BlitzMax from sign-extending
	Local Result:ULong = Int(CPU.Registers[SrcA]) Shr Amount
		
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function

' Shift Right Arithmetic Immediate (32 bit)
Function SRAIW_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local Dest:Int = Insn.Destination
	Local SrcA:Int = Insn.SourceA
	
	' Amount is stored in the SourceB field
	Local Amount:Int = Insn.SourceB
	
	' Calculate into ULong to prevent BlitzMax from sign-extending
	Local Result:ULong = Int(CPU.Registers[SrcA]) Sar Amount
		
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Result
	End If
End Function
' ======================================================================


' Load Data Instructions
' ======================================================================
' LBU, aka Load Data (8 bit; zero extended)
Function LBU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
		
	' We can then read 8 bits directly
	' Note the ULong cast
	Local Value:ULong = MMUReadMemory8(Addr, CPU)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function

' LB, aka Load Data (8 bit; sign extended)
Function LB_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	' We can then read 8 bits directly (also sign extending them)
	Local Value:Long = SignExt(MMUReadMemory8(Addr, CPU), 8)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function

' LHU, aka Load Data (16 bit; zero extended)
Function LHU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
		
	' Note the ULong cast
	Local Value:ULong = MMUReadMemory16(Addr, CPU)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function

' LH, aka Load Data (16 bit; sign extended)
Function LH_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
	
	' Read and sign extend
	Local Value:Long = SignExt(MMUReadMemory16(Addr, CPU), 16)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
End Function

' LWU, aka Load Data (32 bit; zero extended)
Function LWU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA ' Register with base address from where to load
	Local Dest:Int = Insn.Destination ' Where to load
		
	' Calculate the target addr
	Local Offset:Int = Insn.Argument12
	Local Addr:Long = CPU.Registers[SrcA] + Offset
		
	' Note the ULong cast
	Local Value:ULong = MMUReadMemory32(Addr, CPU)
		
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
	
	' Sign extension will happen automatically with cast from Int to Long
	Local Value:Long = MMUReadMemory32(Addr, CPU)
		
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
		
	Local Value:Long = MMUReadMemory64(Addr, CPU)
	
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
		
	MMUWriteMemory8(Value, Addr, CPU)
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
	
	MMUWriteMemory16(Value, Addr, CPU)
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
		
	MMUWriteMemory32(Value, Addr, CPU)
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
	
	MMUWriteMemory64(Value, Addr, CPU)
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
	
	' Shift higher, will zero-extend and should also obtain signedness
	Arg :Shl 12
		
	' (PC - 4) + Argument
	Result = (CPU.PC - 4) + Arg
	
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
	
	' Check the address just in case
	' But do not alter the register state!
	AddressThroughMMU(Addr, 4, CPU)
		
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
	
	' Check the address just in case
	' But do not alter the register state!
	AddressThroughMMU(Addr, 4, CPU)
		
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
	
	' Check the address just in case
	' But do not alter the register state!
	AddressThroughMMU(Addr, 4, CPU)
	
	If CPU.Registers[SrcA] >= CPU.Registers[SrcB]
		CPU.PC = Addr
	End If
End Function

' BGE, aka Branch If Greater or Equal (Unsigned)
Function BGEU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	
	' The address has to be calculated from the unadjusted PC
	' But we already made it point to the next instruction, so we have to subtract 4
	Local Addr:Long = CPU.PC - 4 + Insn.BR_Argument
	
	' Check the address just in case
	' But do not alter the register state!
	AddressThroughMMU(Addr, 4, CPU)
	
	If ULong(CPU.Registers[SrcA]) >= ULong(CPU.Registers[SrcB])
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
	
	' Check the address just in case
	' But do not alter the register state!
	AddressThroughMMU(Addr, 4, CPU)
	
	If CPU.Registers[SrcA] < CPU.Registers[SrcB]
		CPU.PC = Addr
	End If
End Function

' BLT, aka Branch If Less Than (Unsigned)
Function BLTU_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	
	' The address has to be calculated from the unadjusted PC
	' But we already made it point to the next instruction, so we have to subtract 4
	Local Addr:Long = CPU.PC - 4 + Insn.BR_Argument
	
	' Check the address just in case
	' But do not alter the register state!
	AddressThroughMMU(Addr, 4, CPU)
	
	If ULong(CPU.Registers[SrcA]) < ULong(CPU.Registers[SrcB])
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
	
	' Check the address just in case
	' But do not alter the register state!
	AddressThroughMMU(Addr, 4, CPU)
	
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
	
	' Check the address just in case
	' But do not alter the register state!
	AddressThroughMMU(Addr, 4, CPU)
	
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

' CSR Save into register and [SET BITS with register]
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

' CSR Save into register and [CLEAR BITS with register]
Function CSRRC_Handler(Insn:TInstruction, CPU:RV64i_core)
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
		' Notice that we invert the value
		CPU.CSR[TargetCSR] = CPU.CSR[TargetCSR] & (Value ~ $FF)
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

' CSR Save into register and [SET BITS with argument]
Function CSRRSI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local TargetCSR:Int = Insn.CSR_Argument12
	Local SrcA:Int = Insn.SourceA
	Local Dest:Int = Insn.Destination
	
	' The value to load is stored in the SourceA field
	Local Value:Byte = Insn.SourceA

	' Spec says we must always read the CSR with this instruction
	' But doing so would taint our `zero` register
	' So don't do it!
	If Dest
		CPU.Registers[Dest] = CPU.CSR[TargetCSR]
	End If
	
	' Write only if the argument is not 0
	If Value
		CPU.CSR[TargetCSR] = CPU.CSR[TargetCSR] | Value
	End If
End Function

' CSR Save into register and [CLEAR BITS from argument]
Function CSRRCI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local TargetCSR:Int = Insn.CSR_Argument12
	Local SrcA:Int = Insn.SourceA
	Local Dest:Int = Insn.Destination
	
	' The value to load is stored in the SourceA field
	Local Value:Byte = Insn.SourceA

	' Spec says we must always read the CSR with this instruction
	' But doing so would taint our `zero` register
	' So don't do it!
	If Dest
		CPU.Registers[Dest] = CPU.CSR[TargetCSR]
	End If
	
	' Write only if the argument is not 0
	If Value
		' Notice that we invert the value
		CPU.CSR[TargetCSR] = CPU.CSR[TargetCSR] & (Value ~ $FF)
	End If
End Function
' ======================================================================


' Multiprocessor synchronization
' ======================================================================
' Dummy handler for now
Function FENCE_Handler(Insn:TInstruction, CPU:RV64i_core)

End Function

' Atomic AND (64 bit)
' 1. Addr = SrcA
' 2. Value = [Addr]
' 3. rd = Value
' 4. [Addr] = Value + SrcB
Function AMOAND_D_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	Local Addr:Long = CPU.Registers[SrcA]
	
	Local Value:Long = MMUReadMemory64(Addr, CPU)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
	
	MMUWriteMemory64(Value & CPU.Registers[SrcB], Addr, CPU)
End Function

' Atomic OR (64 bit)
' 1. Addr = SrcA
' 2. Value = [Addr]
' 3. rd = Value
' 4. [Addr] = Value + SrcB
Function AMOOR_D_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	Local Addr:Long = CPU.Registers[SrcA]
	
	Local Value:Long = MMUReadMemory64(Addr, CPU)
	
	' Only write if the destination is not the `zero`
	If Dest
		CPU.Registers[Dest] = Value
	End If
	
	MMUWriteMemory64(Value | CPU.Registers[SrcB], Addr, CPU)
End Function

' Atomic ADD (32 bit)
' 1. Addr = SrcA
' 2. Value = [Addr]
' 3. rd = Value ' Note: value /does/ need to retain sign
' 4. [Addr] = Value + SrcB
Function AMOADD_W_Handler(Insn:TInstruction, CPU:RV64i_core)
	Local SrcA:Int = Insn.SourceA
	Local SrcB:Int = Insn.SourceB
	Local Dest:Int = Insn.Destination

	Local Addr:Long = CPU.Registers[SrcA]
	
	Local Value:Int = MMUReadMemory32(Addr, CPU)
	
	' Only write if the destination is not the `zero`
	If Dest
		' Int to Long cast should sign extend
		CPU.Registers[Dest] = Value
	End If
	
	' Should we cut high bits from SrcB? Not sure
	MMUWriteMemory32(Value + Int(CPU.Registers[SrcB]), Addr, CPU)
End Function

' ======================================================================

