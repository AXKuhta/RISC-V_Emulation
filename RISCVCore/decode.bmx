Import BRL.Retro

Import "instruction.bmx"
Import "handlers.bmx"


' Logs Argument+Register instructions
Function Log_AxR(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + register_name(Insn.SourceA) + ", " + Insn.Argument12
End Function

' Logs LUI instructions
Function Log_LUI(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", 0x" + Shorten(Hex(Insn.LUI_Argument20))
End Function

' Logs LD instructions
Function Log_LD(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + Insn.Argument12 + "(" + register_name(Insn.SourceA) + ")"
End Function

' Logs SD instructions
Function Log_SD(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.SourceB) + ", " + Insn.SD_Argument12 + "(" + register_name(Insn.SourceA) + ")"
End Function

' Logs Jump And Link instructions
Function Log_JAL(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", offset " + Insn.JAL_Argument20
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
	' ==========================================================
	Insn.OP = (Insn.Entire & OP_MASK)
	
	Insn.Destination = (Insn.Entire & DESTINATION_MASK) Shr 7
	
	Insn.Funct3 = (Insn.Entire & FUNCT3_MASK) Shr 12
	
	Insn.SourceA = (Insn.Entire & SOURCE_A_MASK) Shr 15
	Insn.SourceB = (Insn.Entire & SOURCE_B_MASK) Shr 20
	
	Insn.Funct7 = (Insn.Entire & FUNCT7_MASK) Shr 25
	' ==========================================================
	
	' Combo fields
	' ==========================================================
	Insn.Argument12 = (Insn.Entire & $FFF00000) Shr 20
	Insn.SD_Argument12 = (Insn.Funct7 Shl 5) | Insn.Destination
	Insn.LUI_Argument20 = (Insn.Entire & $FFFFF000) Shr 12
	
	Insn.Argument12 = SignExt(Insn.Argument12, 12)
	Insn.SD_Argument12 = SignExt(Insn.SD_Argument12, 12)
	
	Insn.JAL_Argument20 = DecodeJALArgument(Insn.LUI_Argument20)
	' ==========================================================
	
	
	' Stage 2: determine the handler
	Select Insn.OP
		Case OP_LUI
			' Load Uppper Immediate
			' =================================
			Insn.Handler = LUI_Handler
			Log_LUI("LUI", Insn)
			
			
	
		Case OP_ALU_AxR
			' Argument + Register operation
			' =================================
			' Check the operation type
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
		
		
		Case OP_LD
			' Load operation
			' =================================
			' Check the load width
			Select Insn.Funct3
				Case %000
					Log_LD("LB", Insn)
					Return 0
				Case %001
					Log_LD("LH", Insn)
					Return 0
				Case %010
					Log_LD("LW", Insn)
					Return 0
				Case %011
					Insn.Handler = LD_Handler
					Log_LD("LD", Insn)
				
				Default
					Print "Unacceptable load width"
					Return 0

			End Select
		
		
		Case OP_SD
			' Store operation
			' =================================
			' Check the store width
			Select Insn.Funct3
				Case %000
					Log_SD("SB", Insn)
					Return 0
				Case %001
					Log_SD("SH", Insn)
					Return 0
				Case %010
					Log_SD("SW", Insn)
					Insn.Handler = SW_Handler
				Case %011
					Insn.Handler = SD_Handler
					Log_SD("SD", Insn)
				
				Default
					Print "Unacceptable store width"
					Return 0
				
			End Select
			
			
		Case OP_JAL
			' Jump And Link operation
			' =================================
			Insn.Handler = JAL_Handler
			Log_JAL("JAL", Insn)
			

		
		Default
			Print "Unknown opcode: 0x" + Hex(Insn.OP)
			Return 0
			
	End Select
	
	' Stage 3: Report success
	Return 1
End Function


' Performs the magic transformations on the Argument20
' Note: passed Argument20 must not be sign-extended!  
Function DecodeJALArgument:Int(Argument20:Int)
	Local Argument:Int = 0
	
	' Cut the slices
	Local SliceA:Int = Argument20 & %10000000000000000000
	Local SliceB:Int = Argument20 & %01111111111000000000
	Local SliceC:Int = Argument20 & %00000000000100000000
	Local SliceD:Int = Argument20 & %00000000000011111111
	
	' Align the slices
	Local ArgumentA:Int = SliceA
	Local ArgumentB:Int = SliceD Shl 11
	Local ArgumentC:Int = SliceC Shl 2
	Local ArgumentD:Int = SliceB Shr 9
	
	' Glue together
	Argument = ArgumentA | ArgumentB | ArgumentC | ArgumentD
	
	' Extend to 21 bits
	Argument :Shl 1
	
	' Critical: rightmost bit always needs to be zero
	Argument :& %111111111111111111110
	
	' Convert to a proper signed value
	Argument = SignExt(Argument, 21)
		
	Return Argument
End Function
