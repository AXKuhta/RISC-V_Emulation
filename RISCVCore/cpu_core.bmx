Import "utils.bmx"

Type RV64i_core
	' Some highlights:
	' r0: zero register; always zero
	' r1: return address; user by `ret` and `jal` 
	' r2: stack pointer
	Field Registers:Long[32]
	
	' Additional Program Counter register
	Field PC:Long
	
	' Interrupt Vector controlled by MTVec CSR
	Field InterruptVector:Long
	
	' Processor ID
	Field ProcessorID:Int
	
	' Memory Management Unit
	Field MMU:RV64i_mmu
	
	' Control and Status registers
	Field CSR:RV64i_csr
	
	' Decoded instruction cache
	Field TraceCache:TTrace[8]
	
	' Link to the currently executing trace
	Field CurrentTrace:TTrace
	
	' The breakpoint address
	Field Breakpoint:Long
	
	' Flag that the breakpoint was hit
	' Set if PC equals Breakpoint
	' Can also be set by EBREAK handler
	Field BreakpointHit:Int
End Type

' Include allows you to import the source code without compiling it first
' Good for cyclic dependencies, bad for quick recompiles
Include "rv64_regs.bmx"
Include "rv64_mmu.bmx"
Include "rv64_csrs.bmx"
Include "rv64_traces.bmx"
Include "rv64_instructions.bmx"

' TODO: When we convert the thing to proper object oriented style, with functions like AddressThroughMMU() a method, we need to compare the performance with the old-style version
' So please implement anything with high impact on performance, like Translation Blocks, BEFORE starting to cram functions into types

