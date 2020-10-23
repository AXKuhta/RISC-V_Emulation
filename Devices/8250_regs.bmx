
' With DLAB bit set
' Read/write
' [0] - DLAB low byte
' [1] - DLAB high byte

' Otherwise
' When reading:
' [0] - Received byte
' [1] - Interrupt enable register
' [2] - Interrupt identification register
' [3] - Line Control register
' [4] - Modem Control register
' [5] - Line Status register
' [6] - Modem Status register
' [7] - Scratch register

' When writing
' [0] - Transmission buffer
' [1] - Interrupt enable register
' [2] - FIFO control register
' [3] - Line Control register
' [4] - Modem Control register
' [7] - Scratch register

Global REGISTER_NAMES_8250_R:String[] = ["RX", "IER", "IIR", "LINECTL", "MODEMCTL", "LINESTATUS", "MODEMSTATUS", "SCRATCH"]
Global REGISTER_NAMES_8250_W:String[] = ["TX", "IER", "FIFOCTL", "LINECTL", "MODEMCTL", "...", "...", "SCRATCH"]

Function register_name_8250_read:String(Offset:ULong)
	Return REGISTER_NAMES_8250_R[Offset]
End Function

Function register_name_8250_write:String(Offset:ULong)
	Return REGISTER_NAMES_8250_W[Offset]
End Function

Const OFFSET_TX = 0
Const OFFSET_RX = 0
Const OFFSET_IER = 1
Const OFFSET_IIR = 2
Const OFFSET_FCR = 2
Const OFFSET_LCR = 3
Const OFFSET_MCR = 4
Const OFFSET_LSR = 5
Const OFFSET_MSR = 6
Const OFFSET_SCR = 7
