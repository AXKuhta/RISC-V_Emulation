Import BRL.Retro

Import "instruction.bmx"
Import "handlers.bmx"

' TODO: Move the InstuctionName selection into the Log_###() functions themselves
' Would allow us to detect and print pseudoinstructions like `ret` and `sext`

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

' Logs Jump And Link Register instructions
Function Log_JALR(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", addr (" + register_name(Insn.SourceA) + " + " + Insn.Argument12 + ")"
End Function

' Logs BR Conditional Branch instructions
Function Log_BR(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.SourceA) + ", " + register_name(Insn.SourceB) + ", " + Insn.BR_Argument
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
	' Some of these are expensive to calculate
	' Calculate only on demand?

	Insn.Argument12 = (Insn.Entire & $FFF00000) Shr 20
	Insn.SD_Argument12 = (Insn.Funct7 Shl 5) | Insn.Destination
	Insn.LUI_Argument20 = (Insn.Entire & $FFFFF000) Shr 12
	
	Insn.Argument12 = SignExt(Insn.Argument12, 12)
	Insn.SD_Argument12 = SignExt(Insn.SD_Argument12, 12)
	
	Insn.JAL_Argument20 = DecodeJALArgument(Insn.LUI_Argument20)
	Insn.BR_Argument = DecodeBranchArgument(Insn.Entire)
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
					
				Case ALU_XOR
					Log_AxR("XORI", Insn)
					Return 0
				Case ALU_OR
					Log_AxR("ORI", Insn)
					Return 0
				Case ALU_AND
					Log_AxR("ANDI", Insn)
					Return 0
					
				Case ALU_SLT
					Log_AxR("SLTI", Insn)
					Return 0
				Case ALU_SLTU
					Log_AxR("SLTIU", Insn)
					Return 0
				
				'Case ALU_SLL
				'	Log_AShift("SLLI", Insn)
				'	Return 0
				'	
				'Case ALU_SRL, ALU_SRA
				'	Log_AShift("SRLI/SRAI", Insn)
				'	Return 0
				
				
			Default
				Print "Unacceptable type of Argument+Register ALU instruction"
				Return 0
				
			End Select
			
		Case OP_ALU_AxR_32BIT
			' Argument + Register operation
			' 32 bit `.W` flavour
			' =================================
			' Check the operation type
			Select Insn.Funct3
				Case ALU_ADD
					Insn.Handler = ADDIW_Handler
					Log_AxR("ADDIW", Insn)
										
			Default
				Print "Unacceptable type of Argument+Register 32 bit ALU instruction"
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
					Insn.Handler = LW_Handler
					Log_LD("LW", Insn)
				Case %011
					Insn.Handler = LD_Handler
					Log_LD("LD", Insn)
				Case %100
					Insn.Handler = LBU_Handler
					Log_LD("LBU", Insn)
				Case %101
					Insn.Handler = LHU_Handler
					Log_LD("LHU", Insn)
				
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
					Insn.Handler = SW_Handler
					Log_SD("SW", Insn)
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
			
			
		Case OP_JALR
			' Register Jump And Link operation
			' =================================
			Insn.Handler = JALR_Handler
			Log_JALR("JALR", Insn)
			
			
		Case OP_BRANCH
			' Conditional branch operation
			' =================================
			' Check the branch type
			Select Insn.Funct3
				Case BR_BEQ
					Log_BR("BEQ", Insn)
					Return 0
				Case BR_BNE
					Insn.Handler = BNE_Handler
					Log_BR("BNE", Insn)
				Case BR_BLT
					Insn.Handler = BLT_Handler
					Log_BR("BLT", Insn)
				Case BR_BGE
					Insn.Handler = BGE_Handler
					Log_BR("BGE", Insn)
				Case BR_BLTU
					Log_BR("BLTU", Insn)
					Return 0
				Case BR_BGEU
					Log_BR("BGEU", Insn)
					Return 0
			
				Default
					Print "Unacceptable branch type width"
					Return 0
					
			End Select

		
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

' More magic
Function DecodeBranchArgument:Int(Entire:Int)
	Local Argument:Int = 0
	
	' Cut the slices
	Local SliceA:Int = Entire & %10000000000000000000000000000000
	Local SliceB:Int = Entire & %01111110000000000000000000000000
	Local SliceC:Int = Entire & %00000000000000000000111100000000
	Local SliceD:Int = Entire & %00000000000000000000000010000000
	
	' Align the slices
	Local ArgumentA:Int = SliceA Shr 20
	Local ArgumentB:Int = SliceD Shl 3
	Local ArgumentC:Int = SliceB Shr 21
	Local ArgumentD:Int = SliceC Shr 8

	' Glue together
	Argument = ArgumentA | ArgumentB | ArgumentC | ArgumentD
	
	' Extend to 13 bits
	Argument :Shl 1
	
	' Critical: rightmost bit always needs to be zero
	Argument :& %1111111111110
	
	' Convert to a proper signed value
	Argument = SignExt(Argument, 13)
	
	Return Argument
End Function

