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
	Field JAL_Argument20:Int ' 20 bit with different encoding;
	
	Field SD_Argument12:Int ' 12 argument for SD; combo of Funct7 + Dest
	Field Argument12:Int ' 12 bit argument; combo of Funct7 + SrcB
	
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


' Call opcodes
'=======================================
Const OP_JAL = $6F
'=======================================


' Value-building opcodes
'=======================================
Const OP_LUI = $37
'=======================================
