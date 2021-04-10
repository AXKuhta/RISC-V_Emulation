Import "utils.bmx"
Import "../Devices/8250.bmx"

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
	
	' Interrupt controller
	Field INTC:RV64i_intc
	
	' Serial controller
	Field Serial8250:TSerial8250
	
	' Decoded instruction cache
	Field TraceCache:TTrace[64]
	
	' Link to the currently executing trace
	Field CurrentTrace:TTrace
	
	
	' Debugging variables
	' ====================================
	' The breakpoint address
	Field Breakpoint:Long
	
	' Flag that the breakpoint was hit
	' Set if PC equals Breakpoint
	' Can also be set by EBREAK handler
	Field BreakpointHit:Int
	
	' Used by the text-mode screen
	' Set in `Emulator.bmx` on startup
	' Later overwritten from `AddressThroughMMU()` if an MMIO write is detected
	Field ScreenAddress:Long
	
	' Time of latest breakpoint break/resume in host milliseconds
	Field ResumeMS:ULong
	' ====================================
End Type

' Include allows you to import the source code without compiling it first
' Good for cyclic dependencies, bad for quick recompiles
Include "rv64_regs.bmx"
Include "rv64_mmu.bmx"
Include "rv64_csrs.bmx"
Include "rv64_traces.bmx"
Include "rv64_instructions.bmx"
Include "rv64_interrupts.bmx"

' TODO: When we convert the thing to proper object oriented style, with functions like AddressThroughMMU() a method, we need to compare the performance with the old-style version
' So please implement anything with high impact on performance, like Translation Blocks, BEFORE starting to cram functions into types

