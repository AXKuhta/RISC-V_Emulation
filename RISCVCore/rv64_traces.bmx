
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
	
	Field Insn:TInstruction[TRACE_INSN_COUNT]
	
	Field CPU:RV64i_core
End Type

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
	
	' Return the trace we decided to evict
	Return CPU.TraceCache[MinIndex]
End Function
