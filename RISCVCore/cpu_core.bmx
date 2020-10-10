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
	
	' Memory Management Unit
	Field MMU:RV64i_mmu
	
	' Control and Status registers
	Field CSR:RV64i_csr
	
End Type

' Include allows you to import the source code without compiling it first
' Good for cyclic dependencies, bad for quick recompiles
Include "rv64_regs.bmx"
Include "rv64_mmu.bmx"
Include "rv64_csrs.bmx"


' TODO: When we convert the thing to proper object oriented style, with functions like AddressThroughMMU() a method, we need to compare the performance with the old-style version
' So please implement anything with high impact on performance, like Translation Blocks, BEFORE starting to cram functions into types

