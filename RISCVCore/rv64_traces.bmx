'Import "instruction.bmx"

Const TRACE_SIZE = 4*1024
Const TRACE_INSN_COUNT = TRACE_SIZE / 4

Type TTrace
	' Set when trace is not dirty
	Field AllowedToRun:Int
	
	' Determined from StartAddress / TRACE_SIZE
	Field LinearIndex:Int
	
	' Used for optimized is-in-range checks
	Field StartAddress:Long
	Field EndAddress:Long
	
	Field Insn:TInstruction[TRACE_INSN_COUNT]
	
	Field CPU:RV64i_core
End Type
