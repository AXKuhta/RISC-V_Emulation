Import BRL.Retro

Import "instruction.bmx"
Import "handlers.bmx"


' Logs Argument+Register instructions
Function Log_AxR(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + register_name(Insn.SourceA) + ", " + Insn.Argument12
End Function

' Logs SD instructions
Function Log_SD(InstructionName:String, Insn:TInstruction)

End Function

' Pretty masks
Const OP_MASK:Int = 		 %00000000000000000000000001111111
Const DESTINATION_MASK:Int = %00000000000000000000111110000000
Const FUNCT3_MASK:Int = 	 %00000000000000000111000000000000
Const SOURCE_A_MASK:Int = 	 %00000000000011111000000000000000
Const SOURCE_B_MASK:Int = 	 %00000001111100000000000000000000
Const FUNCT7_MASK:Int = 	 %11111110000000000000000000000000

' Will decode SourceA, SourceB, Dest, etc...
' Will then walk the instruction tree to determine the handler
'
' This function contains the bulk of the computations
'
Function Decode(Insn:TInstruction)
	' Stage 1: decode various fields
	
	' Basic fields
	' =========================================================
	Insn.OP = (Insn.Entire & OP_MASK)
	
	Insn.Destination = (Insn.Entire & DESTINATION_MASK) Shr 7
	
	Insn.Funct3 = (Insn.Entire & FUNCT3_MASK) Shr 12
	
	Insn.SourceA = (Insn.Entire & SOURCE_A_MASK) Shr 15
	Insn.SourceB = (Insn.Entire & SOURCE_B_MASK) Shr 20
	
	Insn.Funct7 = (Insn.Entire & FUNCT7_MASK) Shr 25
	' =========================================================
	
	' Combo fields
	' =========================================================
	Insn.Argument12 = (Insn.Entire & $FFF00000) Shr 20
	Insn.SD_Argument12 = (Insn.Funct7 Shl 5) | Insn.Destination
	Insn.LUI_Argument20 = (Insn.Entire & $FFFFF000) Shr 12
	'Insn.JMP_Argument20 = ...
	
	
	Insn.Argument12 = SignExt(Insn.Argument12, 12)
	Insn.SD_Argument12 = SignExt(Insn.SD_Argument12, 12)
	Insn.LUI_Argument20 = SignExt(Insn.LUI_Argument20, 20)
	'Insn.JMP_Argument20 = SignExt(...)
	' =========================================================
	
	
	
	' Stage 2: determine the handler
	Select Insn.OP
		Case OP_ALU_AxR
			' =================================
			Select Insn.Funct3
				Case ALU_ADD
					Insn.Handler = ADDI_Handler
					Log_AxR("ADDI", Insn)
										
				Case ALU_SLT
					Return 0
				Case ALU_SLTU
					Return 0
				Case ALU_XOR
					Return 0
				Case ALU_OR
					Return 0
				Case ALU_AND
					Return 0
				
			Default
				Print "Unacceptable type of Argument+Register ALU instruction"
				Return 0
				
			End Select
			' =================================
			
		Case OP_SD
			' =================================
			Return 0
			' =================================
		
		Default
			Print "Unknown opcode: 0x" + Hex(Insn.OP)
			Return 0
			
	End Select
	
	
	Return 1
End Function



