
Const TRACE_SIZE = 4*1024
Const TRACE_INSN_COUNT = TRACE_SIZE / 4

' Mask for the bits that are meaningful to determine the offset into the trace
' Be sure to update this if you ever change the TRACE_SIZE
Const TRACE_OFFSET_MASK = $FFF


Type TTrace
	' Set when PC is in range of this trace
	Field AllowedToRun:Int
	
	' Set when trace is up to date
	' Dirty traces are not allowed to run
	Field NotDirty:Int
	
	' Determined from StartAddress / TRACE_SIZE
	Field LinearIndex:Int
	
	' Used for optimized is-in-range checks
	Field StartAddress:Long
	Field EndAddress:Long
	
	' Last time (in top level loop iterations) ExecuteTrace() was called on this trace
	Field LastExecuted:ULong
	
	' The chain of instructions with handlers
	Field Insn:TInstruction[TRACE_INSN_COUNT]
		
	Field CPU:RV64i_core
End Type


' Run the instruction handlers that belong to the chain
Function ExecuteTrace(Trace:TTrace, TopLevelCounter:ULong, MaxIterationCount:Int)
	Local InsnIdx:Int
	Local PC:Long
	Local i:Int
	
	' Pull in as variable for code cleanliness
	Local CPU:RV64i_core = Trace.CPU
	Local PCMask:ULong = CPU.MMU.AddressBusMask
	
	CPU.CurrentTrace = Trace
	
	' Check that we are allowed to run
	Assert(Trace.AllowedToRun)
	Assert(Trace.NotDirty)
	
	' Update the LastExecuted field of the trace
	Trace.LastExecuted = TopLevelCounter
	
	' Dispatch Loop
	' Run while we are in range of the trace
	For i = 1 To MaxIterationCount
		' [Optional] log the Program Counter
		' LogToFile(Hex(Int(CPU.PC)))
	
		' Calculate the index of instruction in the trace
		' This is our equivalent of the Fetch stage
		InsnIdx = (CPU.PC & TRACE_OFFSET_MASK) / 4
		
		' Increment the program counter
		CPU.PC :+ 4
		
		' Execute
		Trace.Insn[InsnIdx].Handler(Trace.Insn[InsnIdx], CPU)
		
		' If we hit a breakpoint, set the flag and exit
		' This check needs to be the first one
		If CPU.PC & PCMask = CPU.Breakpoint
			CPU.BreakpointHit = 1
			Exit
		End If
		
		' If we lost the permission to run, exit immidiately
		If Trace.AllowedToRun = 0 Then Exit
		
		' If we are now out of bound of the trace, exit immidiately
		If CPU.PC & PCMask >= Trace.EndAddress Then Exit
	Next
	
	' Check for any pending interrupts now that we have some free time
	ProcessInterrupts(CPU)
	
	' Responsibly remove the AllowedToRun flag on exit
	Trace.AllowedToRun = 0
	
	CPU.CurrentTrace = Null
End Function

' Will walk through the traces and disable AllowedToRun flag UNLESS:
' 1. `Addr` belongs to this trace
' 2. AllowedToRun is set
Function JumpNotify(Addr:Long, CPU:RV64i_core)
	Local i:Int
	
	Addr = MMUTrim(Addr, CPU)
	
	For i = 0 Until CPU.TraceCache.Length
		If Not CPU.TraceCache[i] Then Continue
		
		If (Addr >= CPU.TraceCache[i].StartAddress) And (Addr < CPU.TraceCache[i].EndAddress)
			' Leave the AllowedToRun flag intact
		Else
			' Zero the AllowedToRun flag
			CPU.TraceCache[i].AllowedToRun = 0
		End If
	Next
End Function

' This function will check for cache entries overlapping with the write and invalidate them
Function WriteNotify(Addr:Long, CPU:RV64i_core)
	Local i:Int
	
	Addr = MMUTrim(Addr, CPU)
	
	For i = 0 Until CPU.TraceCache.Length
		' Check if entry is not null first
		' Skip if so
		If Not CPU.TraceCache[i] Then Continue
		
		' Otherwise check for overlap
		If (Addr >= CPU.TraceCache[i].StartAddress) And (Addr < CPU.TraceCache[i].EndAddress)
			
			' Check if entry was active / ready to run
			' Complain loudly if so
			If CPU.TraceCache[i].AllowedToRun = 1
				Print "TRACE: Invalidating ACTIVE entry " + i + " because of overlapping memory write (0x" + PrettyHex(Addr) + ")"
				Input ""
			End If
			
			' Invalidate
			CPU.TraceCache[i].AllowedToRun = 0
			CPU.TraceCache[i].NotDirty = 0
		End If
	Next

End Function

' Looks through the CPU cache to find the requested trace
' Returns Null if not found
Function FindCachedTrace:TTrace(TargetIndex:Int, CPU:RV64i_core)
	Local i:Int
	
	For i = 0 Until CPU.TraceCache.Length
		' Check if entry is not null first
		' Skip if so
		If Not CPU.TraceCache[i] Then Continue
		
		' Otherwise check for index match
		If CPU.TraceCache[i].LinearIndex = TargetIndex Then Return CPU.TraceCache[i]
	Next
	
	Return Null
End Function

' Inserts a new trace entry into the cache and returns it
' Prefers uninitialized entries first
' Otherwise evicts the least recently used trace
Function InsertNewTrace:TTrace(CPU:RV64i_core)
	Local LastExecMin:ULong = $FFFFFFFFFFFFFFFF
	Local MinIndex:Int = -1
	Local i:Int = 0
	
	For i = 0 Until CPU.TraceCache.Length
		' Check if entry is not null first
		' If so, create and return
		If Not CPU.TraceCache[i]
			Print "TRACE: initializing entry " + i 
		
			CPU.TraceCache[i] = New TTrace
			Return CPU.TraceCache[i]
		End If
		
		' Otherwise keep comparing
		If CPU.TraceCache[i].LastExecuted < LastExecMin
			LastExecMin = CPU.TraceCache[i].LastExecuted
			MinIndex = i
		End If
	Next
	
	
	If MinIndex = -1
		' If we somehow didn't find anything, fall back To trace 0
		' This happens if the app is running too fast (faster that the resolution of microseconds() ) and all timestamps get smeared with the same value
		' We will have to fix this at some point, create some alternative selection system
		MinIndex = 0
		
		Print "Trace cache eviction failed to evict anything!"
		
		' Complain loudly if this was encountered in debug mode
		Assert(0)
	End If
	
	'Print "TRACE: evicting entry " + MinIndex
	
	' Return the trace we decided to evict
	Return CPU.TraceCache[MinIndex]
End Function

' Returns a next instruction to be executed from the trace
' For debugging purposes
Function GetNextInstruction:TInstruction(Trace:TTrace)
	Local InsnIdx:Int
	
	' Ensure that the trace in question is active
	Assert(Trace.AllowedToRun)
	
	' Pull in as variable for code cleanliness
	Local CPU:RV64i_core = Trace.CPU
	
	InsnIdx = (MMUTrim(CPU.PC, CPU) - Trace.StartAddress) / 4
	
	Assert(InsnIdx > 0)
	Assert(InsnIdx < TRACE_INSN_COUNT)
	
	Return Trace.Insn[InsnIdx]
End Function
