
Const TRACE_SIZE = 4*1024
Const TRACE_INSN_COUNT = TRACE_SIZE / 4

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
	
	' Last time (in milliseconds) ExecuteTrace() was called on this trace
	Field LastExecuted:Long
	
	' The chain of instructions with handlers
	Field Insn:TInstruction[TRACE_INSN_COUNT]
		
	Field CPU:RV64i_core
End Type


' Run the instruction handlers that belong to the chain
Function ExecuteTrace(Trace:TTrace, MaxIterationCount:Int)
	Local InsnIdx:Int
	Local PC:Long
	Local i:Int
	
	' Check that we are allowed to run
	Assert(Trace.AllowedToRun)
	Assert(Trace.NotDirty)
	
	' Update the LastExecuted field of the trace
	Trace.LastExecuted = MilliSecs()
	
	' Run while we are in range of the trace
	For i = 1 To MaxIterationCount
		' Calculate the index of instruction in the trace
		' This is our equivalent of the Fetch stage
		InsnIdx = (MMUTrim(Trace.CPU.PC, Trace.CPU) - Trace.StartAddress) / 4
				
		' Increment the program counter
		Trace.CPU.PC :+ 4
		
		' Execute
		Trace.Insn[InsnIdx].Handler(Trace.Insn[InsnIdx], Trace.CPU)
		
		' If we lost the permission to run, exit immidiately
		If Trace.AllowedToRun = 0 Then Exit
		
		' If we are now out of bound of the trace, exit immidiately
		If MMUTrim(Trace.CPU.PC, Trace.CPU) >= Trace.EndAddress Then Exit
	Next
	
	' Responsibly remove the AllowedToRun flag on exit
	Trace.AllowedToRun = 0
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
	Local MinMillisecs:Long = MilliSecs()
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
		If CPU.TraceCache[i].LastExecuted < MinMillisecs
			MinMillisecs = CPU.TraceCache[i].LastExecuted
			MinIndex = i
		End If
	Next
	
	' Fail if we somehow didn't find anything
	Assert(MinIndex > -1)
	
	Print "TRACE: evicting entry " + MinIndex
	
	' Return the trace we decided to evict
	Return CPU.TraceCache[MinIndex]
End Function
