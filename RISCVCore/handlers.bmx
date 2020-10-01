Import "instruction.bmx"

'
' Below are various instruction handlers
' Each takes a specific instruction that is not memory or processor bound
' Each also takes the CPU whose state it will alter
'


' ADDI, aka ADD Intermediate (`Argument12`)
Function ADDI_Handler(Insn:TInstruction, CPU:RV64i_core)
	Print "Hello from ADDI"
	
	Print "Source register: " + register_name(Insn.SourceA)
	Print "Target register: " + register_name(Insn.Destination)
	Print "Argument value: " + Insn.Argument12
	
End Function

