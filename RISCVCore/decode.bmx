Import BRL.Retro

Import "cpu_core.bmx"
Import "handlers.bmx"

' TODO: Move the InstuctionName selection into the Log_###() functions themselves
' Would allow us to detect and print pseudoinstructions like `ret` and `sext`

' Logs Register+Register instructions
Function Log_RxR(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + register_name(Insn.SourceA) + ", " + register_name(Insn.SourceB)
End Function

' Logs Argument+Register instructions
Function Log_AxR(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + register_name(Insn.SourceA) + ", " + Insn.Argument12
End Function

' Logs Argument+Register Shift instructions
Function Log_AxR_Shift(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + register_name(Insn.SourceA) + ", " + Insn.AxR_Shift_Amount
End Function

' Logs Argument+Register Shift instructions
Function Log_AxR_Shift_32bit(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + register_name(Insn.SourceA) + ", " + Insn.SourceB
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

' Logs `register <- CSR <- register` operations
Function Log_RxR_CSR(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + Insn.CSR_Argument12 + ", " + register_name(Insn.SourceA)
End Function

' Logs `register <- CSR <- argument` operations
Function Log_AxR_CSR(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + Insn.CSR_Argument12 + ", " + Insn.SourceA
End Function

' Logs FENCE instructions
' Dummy log
Function Log_FENCE(InstructionName:String, Insn:TInstruction)
	Print InstructionName
End Function

' Logs Atomic instructions
Function Log_AMO(InstructionName:String, Insn:TInstruction)
	Print InstructionName + " " + register_name(Insn.Destination) + ", " + register_name(Insn.SourceB) + ", (" + register_name(Insn.SourceA) + ")"
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
	Insn.AMO_Funct5 = Insn.Funct7 Shr 2

	Insn.Argument12 = (Insn.Entire & $FFF00000) Shr 20
	Insn.SD_Argument12 = (Insn.Funct7 Shl 5) | Insn.Destination
	Insn.CSR_Argument12 = Insn.Argument12
	Insn.LUI_Argument20 = (Insn.Entire & $FFFFF000) Shr 12
	
	Insn.Argument12 = SignExt(Insn.Argument12, 12)
	Insn.SD_Argument12 = SignExt(Insn.SD_Argument12, 12)
	
	Insn.JAL_Argument20 = DecodeJALArgument(Insn.LUI_Argument20)
	Insn.BR_Argument = DecodeBranchArgument(Insn.Entire)
	
	Insn.AxR_Shift_Mode = Insn.Funct7 Shr 1
	Insn.AxR_Shift_Amount = (Insn.Entire & $03F00000) Shr 20
	' ==========================================================
	
	
	' Stage 2: determine the handler
	Select Insn.OP
		Case OP_LUI
			' Load Uppper Immediate
			' =================================
			Insn.Handler = LUI_Handler
			Log_LUI("LUI", Insn)
			
			
			
		Case OP_AUIPC
			' Add Uppper Immediate to PC
			' (And store into a register)
			' =================================
			Insn.Handler = AUIPC_Handler
			Log_LUI("AUIPC", Insn)
			
			
			
		Case OP_ALU_RxR
			' Register + Register operation
			' =================================
			' Check the operation type
			Select Insn.Funct7
				Case %0000000
					Select Insn.Funct3
						Case ALU_ADD
							Insn.Handler = ADD_Handler
							Log_RxR("ADD", Insn)
							
						Case ALU_XOR
							Insn.Handler = XOR_Handler
							Log_RxR("XOR", Insn)
						Case ALU_OR
							Insn.Handler = OR_Handler
							Log_RxR("OR", Insn)
						Case ALU_AND
							Insn.Handler = AND_Handler
							Log_RxR("AND", Insn)
							
						Case ALU_SLT
							Insn.Handler = SLT_Handler
							Log_RxR("SLT", Insn)
						Case ALU_SLTU
							Insn.Handler = SLTU_Handler
							Log_RxR("SLTU", Insn)
							
						Case ALU_SLL
							Insn.Handler = SLL_Handler
							Log_RxR("SLL", Insn)
						Case ALU_SRL
							Insn.Handler = SRL_Handler
							Log_RxR("SRL", Insn)
						
						Default
							Print "Unknown RxR ALU Instruction (%0000000)"
							Return 0
						
					End Select
					
				Case %0100000
					Select Insn.Funct3
						Case ALU_SUB
							Insn.Handler = SUB_Handler
							Log_RxR("SUB", Insn)
							
						Case ALU_SRA
							Insn.Handler = SRA_Handler
							Log_RxR("SRA", Insn)
							
						Default
							Print "Unknown RxR ALU Instruction (%0100000)"
							Return 0
								
					End Select
					
				Case %0000001
					Select Insn.Funct3
						Case ALU_MUL
							Insn.Handler = MUL_Handler
							Log_RxR("MUL", Insn)
						Case ALU_MULH
							Log_RxR("MULH", Insn)
							Return 0
						Case ALU_MULHSU
							Log_RxR("MULHSU", Insn)
							Return 0
						Case ALU_MULHU
							Log_RxR("MULHU", Insn)
							Return 0
						Case ALU_DIV
							Insn.Handler = DIV_Handler
							Log_RxR("DIV", Insn)
						Case ALU_DIVU
							Insn.Handler = DIVU_Handler
							Log_RxR("DIVU", Insn)
						Case ALU_REM
							Log_RxR("REM", Insn)
							Return 0
						Case ALU_REMU
							Insn.Handler = REMU_Handler
							Log_RxR("REMU", Insn)
						
						Default
							Print "Unknown RxR ALU Instruction (%0000001)"
							Return 0
							
					End Select
				
				Default
					Print "Unacceptable type of Register+Register ALU instruction"
					Return 0
					
			End Select

	
	
		Case OP_ALU_RxR_32BIT
			' Register + Register operation
			' 32 bit `.W` flavour
			' =================================
			Select Insn.Funct7
				Case %0000000
					Select Insn.Funct3
						Case ALU_ADD
							Insn.Handler = ADDW_Handler
							Log_RxR("ADDW", Insn)
							
						Case ALU_SLL
							Insn.Handler = SLLW_Handler
							Log_RxR("SLLW", Insn)
							
						Case ALU_SRL
							Insn.Handler = SRLW_Handler
							Log_RxR("SRLW", Insn)
						
						Default
							Print "Unknown 32 bit RxR ALU Instruction (%0000000)"
							Return 0
							
					End Select
					
				Case %0100000
					Select Insn.Funct3
						Case ALU_SUB
							Insn.Handler = SUBW_Handler
							Log_RxR("SUBW", Insn)
							
						Case ALU_SRA
							Insn.Handler = SRAW_Handler
							Log_RxR("SRAW", Insn)
							
						Default
							Print "Unknown 32 bit RxR ALU Instruction (%0100000)"
							Return 0
							
					End Select
					
				Case %0000001
					Select Insn.Funct3
						Case ALU_MUL
							Insn.Handler = MULW_Handler
							Log_RxR("MULW", Insn)
							
						Case ALU_DIV
							Insn.Handler = DIVW_Handler
							Log_RxR("DIVW", Insn)
							
						Case ALU_DIVU
							Insn.Handler = DIVUW_Handler
							Log_RxR("DIVUW", Insn)
							
						Case ALU_REM
							Insn.Handler = REMW_Handler
							Log_RxR("REMW", Insn)
							
						Case ALU_REMU
							Log_RxR("REMUW", Insn)
							Return 0
						
						Default
							Print "Unknown 32 bit RxR ALU Instruction (%0000001)"
							Return 0
							
					End Select
				
				Default
					Print "Unacceptable type of 32 bit Register+Register ALU instruction"
					Return 0

			End Select



		Case OP_ALU_AxR
			' Argument + Register operation
			' =================================
			' Check the operation type
			Select Insn.Funct3
				Case ALU_ADD
					Insn.Handler = ADDI_Handler
					Log_AxR("ADDI", Insn)
					
				Case ALU_XOR
					Insn.Handler = XORI_Handler
					Log_AxR("XORI", Insn)
				Case ALU_OR
					Insn.Handler = ORI_Handler
					Log_AxR("ORI", Insn)
				Case ALU_AND
					Insn.Handler = ANDI_Handler
					Log_AxR("ANDI", Insn)
					
				Case ALU_SLT
					Insn.Handler = SLTI_Handler
					Log_AxR("SLTI", Insn)
				Case ALU_SLTU
					Insn.Handler = SLTIU_Handler
					Log_AxR("SLTIU", Insn)
				
				Case ALU_SLL
					Insn.Handler = SLLI_Handler
					Log_AxR_Shift("SLLI", Insn)
					
				Case ALU_SRL, ALU_SRA
					' Check the type of shift
					' Logical / Arithmetic
					Select Insn.AxR_Shift_Mode
						Case %000000
							Insn.Handler = SRLI_Handler
							Log_AxR_Shift("SRLI", Insn)
						Case %010000
							Insn.Handler = SRAI_Handler
							Log_AxR_Shift("SRAI", Insn)
						
						Default
							Print "Unacceptable type of shift"
							Return 0
							
					End Select
							
				
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
					
				Case ALU_SLL
					Log_AxR_Shift_32bit("SLLIW", Insn)
					Insn.Handler = SLLIW_Handler
				Case ALU_SRL, ALU_SRA
					Select Insn.Funct7
						Case %0000000
							Insn.Handler = SRLIW_Handler
							Log_AxR_Shift_32bit("SRLIW", Insn)
						Case %0100000
							Insn.Handler = SRAIW_Handler
							Log_AxR_Shift_32bit("SRAIW", Insn)
						
						Default
							Print "Unacceptable type of SRLIW/SRAIW"
							Return 0
					
					End Select
			
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
					Insn.Handler = LB_Handler
					Log_LD("LB", Insn)
				Case %100
					Insn.Handler = LBU_Handler
					Log_LD("LBU", Insn)
				Case %001
					Insn.Handler = LH_Handler
					Log_LD("LH", Insn)
				Case %101
					Insn.Handler = LHU_Handler
					Log_LD("LHU", Insn)
				Case %010
					Insn.Handler = LW_Handler
					Log_LD("LW", Insn)
				Case %110
					Insn.Handler = LWU_Handler
					Log_LD("LWU", Insn)
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
					Insn.Handler = SB_Handler
					Log_SD("SB", Insn)
				Case %001
					Insn.Handler = SH_Handler
					Log_SD("SH", Insn)
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
					Insn.Handler = BEQ_Handler
					Log_BR("BEQ", Insn)
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
					Insn.Handler = BLTU_Handler
					Log_BR("BLTU", Insn)
				Case BR_BGEU
					Insn.Handler = BGEU_Handler
					Log_BR("BGEU", Insn)
			
				Default
					Print "Unacceptable branch type width"
					Return 0
					
			End Select
			
		
		Case OP_CSR
			' CSR register read/write
			' =================================
			' Check for the operation type
			Select Insn.Funct3
				Case CSR_RW
					Insn.Handler = CSRRW_Handler
					Log_RxR_CSR("CSRRW", Insn)
				Case CSR_RS
					Insn.Handler = CSRRS_Handler
					Log_RxR_CSR("CSRRS", Insn)
				Case CSR_RC
					Insn.Handler = CSRRC_Handler
					Log_RxR_CSR("CSRRC", Insn)
					
				Case CSR_RWI
					Insn.Handler = CSRRWI_Handler
					Log_AxR_CSR("CSRRWI", Insn)
				Case CSR_RSI
					Insn.Handler = CSRRSI_Handler
					Log_AxR_CSR("CSRRSI", Insn)
				Case CSR_RCI
					Insn.Handler = CSRRCI_Handler
					Log_AxR_CSR("CSRRCI", Insn)
				
				Default
					Print "Unacceptable type of CSR instruction"
					Return 0
					
			End Select
			
			
		Case OP_FENCE
			' Multiprocessor synchronization?
			' =================================
			' Dummy handler for now
			Insn.Handler = FENCE_Handler
			Log_FENCE("FENCE", Insn)
			
			
		Case OP_AMO
			' Atomics
			' =================================
			' Check the width (32/64 bit)
			Select Insn.Funct3
				Case %010
					Select Insn.AMO_Funct5
						Case AMO_LR
							Insn.Handler = LR_W_Handler
							Log_AMO("LR.W", Insn)
						Case AMO_SC
							Insn.Handler = SC_W_Handler
							Log_AMO("SC.W", Insn)
						Case AMO_SWAP
							Insn.Handler = AMOSWAP_W_Handler
							Log_AMO("AMOSWAP.W", Insn)
						Case AMO_ADD
							Insn.Handler = AMOADD_W_Handler
							Log_AMO("AMOADD.W", Insn)
						Case AMO_AND
							Log_AMO("AMOAND.W", Insn)
							Return 0
						Case AMO_OR
							Log_AMO("AMOOR.W", Insn)
							Return 0
						Case AMO_XOR
							Log_AMO("AMOXOR.W", Insn)
							Return 0
						Case AMO_MIN
							Log_AMO("AMOMIN.W", Insn)
							Return 0
						Case AMO_MAX
							Log_AMO("AMOMAX.W", Insn)
							Return 0
						Case AMO_MINU
							Log_AMO("AMOMINU.W", Insn)
							Return 0
						Case AMO_MAXU
							Log_AMO("AMOMAXU.W", Insn)
							Return 0
						
						Default
							Print "Unacceptable type of atomic op (32 bit)"
							Return 0
							
					End Select
				Case %011
					Select Insn.AMO_Funct5
						Case AMO_LR
							Insn.Handler = LR_D_Handler
							Log_AMO("LR.D", Insn)
						Case AMO_SC
							Insn.Handler = SC_D_Handler
							Log_AMO("SC.D", Insn)
						Case AMO_SWAP
							Insn.Handler = AMOSWAP_D_Handler
							Log_AMO("AMOSWAP.D", Insn)
						Case AMO_ADD
							Log_AMO("AMOADD.D", Insn)
							Return 0
						Case AMO_AND
							Insn.Handler = AMOAND_D_Handler
							Log_AMO("AMOAND.D", Insn)
						Case AMO_OR
							Insn.Handler = AMOOR_D_Handler
							Log_AMO("AMOOR.D", Insn)
						Case AMO_XOR
							Log_AMO("AMOXOR.D", Insn)
							Return 0
						Case AMO_MIN
							Log_AMO("AMOMIN.D", Insn)
							Return 0
						Case AMO_MAX
							Log_AMO("AMOMAX.D", Insn)
							Return 0
						Case AMO_MINU
							Log_AMO("AMOMINU.D", Insn)
							Return 0
						Case AMO_MAXU
							Log_AMO("AMOMAXU.D", Insn)
							Return 0
						
						Default
							Print "Unacceptable type of atomic op (64 bit)"
							Return 0
							
					End Select
			
				Default
					Print "Unacceptable atomic operation width"
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

