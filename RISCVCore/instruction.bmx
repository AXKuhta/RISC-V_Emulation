Import "cpu_core.bmx"
Import "utils.bmx"

Type TInstruction
	' Entire 4 bytes of the instruction
	Field Entire:Int
	
	' Decoded parts of the instruction
	Field OP:Int
	
	Field SourceA:Int
	Field SourceB:Int
	Field Destination:Int
	
	Field Funct3:Int
	Field Funct7:Int
	
	' Optional combo-fields
	Field LUI_Argument20:Int ' 20 bit argument for LUI/AUIPC; combo of Funct7 + SrcB + SrcA + Funct3
	Field JAL_Argument20:Int ' 21 bit with different encoding;
	
	Field Argument12:Int ' 12 bit argument; combo of Funct7 + SrcB
	Field CSR_Argument12:Int ' 12 bit argument, not sign extented
	Field SD_Argument12:Int ' 12 argument for SD; combo of Funct7 + Dest
	Field BR_Argument:Int ' 13 bit with different encoding
	
	' Special encoding for shifts unique to RV64
	Field AxR_Shift_Mode:Int ' 6 bit
	Field AxR_Shift_Amount:Int ' 6 bit
	
	' ========== Proposal ==========
	' RISC-V encoding is super messy
	' I propose a rework:
	'
	' | rd | rs1 | rs2 | aux | opcode |
	' | 5  | 5   | 5   | 7   | 10     |
	'
	
	
	' Handler pointer
	Field Handler:Int(Insn:TInstruction, CPU:RV64i_core)
End Type

' Returns an instruction
' Does not increment PC
Function Fetch:TInstruction(CPU:RV64i_core)
	Local Insn:TInstruction = New TInstruction
	
	Insn.Entire = ReadMemory32(CPU.Memory + CPU.PC)
	
	Return Insn
End Function 


' Opcodes
' Naming convention:
' A = Argument
' R = Register
'

' ALU-using opcodes
'=======================================
Const OP_ALU_AxR = $13
Const OP_ALU_RxR = $33

Const OP_ALU_AxR_32BIT = $1B
'=======================================


' ALU operations
'=======================================
' Basic math
' Discern via Funct7
Const ALU_ADD = %000
Const ALU_SUB = %000

' Bitwise
Const ALU_XOR = %100
Const ALU_OR = %110
Const ALU_AND = %111

' Left shift
Const ALU_SLL = %001

' Right shift
' Discern via Funct7
Const ALU_SRL = %101
Const ALU_SRA = %101

' Set Less Than / Set Less Than Unsigned
Const ALU_SLT = %010
Const ALU_SLTU = %011
'=======================================


' Memory access opcodes
'=======================================
Const OP_LD = $03
Const OP_SD = $23
'=======================================


' Call / Ret opcodes
'=======================================
Const OP_JAL = $6F
Const OP_JALR = $67
'=======================================


' Value-building opcodes
'=======================================
Const OP_LUI = $37
Const OP_AUIPC = $17
'=======================================


' Conditional branch opcodes
'=======================================
Const OP_BRANCH = $63

Const BR_BEQ = %000
Const BR_BNE = %001
Const BR_BLT = %100
Const BR_BGE = %101
Const BR_BLTU = %110
Const BR_BGEU = %111
'=======================================


' Control and Status registers read/write
'=========================================
Const OP_CSR = $73

Const CSR_RW = %001
Const CSR_RS = %010
Const CSR_RC = %011
Const CSR_RWI = %101
Const CSR_RSI = %110
Const CSR_RCI = %110
'=========================================


' Multiprocessor / IO synchronization
'=========================================
Const OP_FENCE = $0F
'=========================================
