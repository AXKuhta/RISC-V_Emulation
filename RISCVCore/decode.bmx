Import BRL.Retro

Import "instruction.bmx"
Import "handlers.bmx"

' Will decode SourceA, SourceB, Dest, etc...
' Will then walk the instruction tree to determine the handler
'
' This function contains the bulk of the computations
'
Function Decode(Insn:TInstruction)
	' Stage 1: decode various fields
	
	' Basic fields
	' ====================================================================
	Insn.OP = (Insn.Entire & %1111111)
	
	Insn.Destination = (Insn.Entire & %111110000000) Shr 7
	
	Insn.Funct3 = (Insn.Entire & %111000000000000) Shr 12
	
	Insn.SourceA = (Insn.Entire & %0000011111000000000000000) Shr 15
	Insn.SourceB = (Insn.Entire & %1111100000000000000000000) Shr 20
	
	Insn.Funct7 = (Insn.Entire & %11111110000000000000000000000000) Shr 25
	' ====================================================================
	
	' Combo fields
	' ====================================================================
	Insn.LUI_Argument20 = (Insn.Entire & $FFFFF000) Shr 12
	'Insn.JMP_Argument20 = ...
	Insn.Argument12 = (Insn.Entire & $FFF00000) Shr 20
	
	Insn.LUI_Argument20 = SignExt(Insn.LUI_Argument20, 20)
	'Insn.JMP_Argument20 = SignExt(...)
	Insn.Argument12 = SignExt(Insn.Argument12, 12)
	' ====================================================================
	
	
	
	' Stage 2: determine the handler
	Select Insn.OP
		Case OP_ALU_AxR
			' =================================
			Select Insn.Funct3
				Case ALU_ADD
					Insn.Handler = ADDI_Handler
				Case ALU_SLT
					Insn.Handler = Test_Handler
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
		
		Default
			Print "Unknown opcode: 0x" + Hex(Insn.OP)
			Return 0
			
	End Select
	
	
	Return 1
End Function



