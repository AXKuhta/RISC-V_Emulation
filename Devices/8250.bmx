Import "8250_regs.bmx"

' Enable interrupts for various events
Const IER_RX_AVAIL = %00000001
Const IER_TX_EMPTY = %00000010


' Interrupt identification
Const IIR_INTERRUPT_PENDING = %00000001
Const IIR_TX_EMPTY = %00000010
Const IIR_RX_AVAIL = %00000100

Const LCR_DLAB_ENABLE = %10000000

' Line status
Const LSR_TX_EMPTY = %01100000 ' Note that we set two bits: the kernel need both Holding Register and Transmit Register to be empty
Const LSR_RX_AVAIL = %00000001

Type TSerial8250
	Field TX:Byte
	Field RX:Byte

	Field IER:Byte ' Interrupt enable
	Field IIR:Byte ' Interrupt identification
	
	Field FCR:Byte ' FIFO control
	Field LCR:Byte ' Line control
	Field MCR:Byte ' Modem control
	Field LSR:Byte ' Line status
	Field MSR:Byte ' Modem status

	Field InterruptPending:Int
	
	' Variable that will be read as output
	Field BusOutput:Byte
	
	' A memory-hole
	' We already have what we need from Handle8250Write()
	Field Zero:Byte
	
	
	' Address where the port will flush the TX'd data
	Field DestinationAddress:Byte Ptr
	Field DestinationOffset:Int
	
	' Used to break lines on '\n'
	Field DestinationWidth:Int
	
	' Used to determine when to scroll
	Field DestinationLength:Int
End Type


Function Handle8250Write(Port:TSerial8250, Offset:ULong, Value:Byte)
	' Determine wheter DLAB was / is set
	Local DLAB:Int = 0 < (Port.LCR & LCR_DLAB_ENABLE)
	
	' If it is, and this operation is not unsetting it, just exit
	If DLAB And Offset <> OFFSET_LCR
		Print "8250: Divisor configuration in progress -- early return"
		Return
	End If
	
	Select Offset
		Case OFFSET_TX
			' Instantly eat the data that was delivered
			Handle8250DestinationWrite(Port, Value)
			
			' Inform line status that we ate all the data
			Port.LSR = LSR_TX_EMPTY
			
			' Keep the value in the internal state, for no reason in particular
			Port.TX = Value
			
			' Check whether sending a `TX_EMPTY` interrupt is allowed
			If 0 < (Port.IER & IER_TX_EMPTY)
				
				' Set the interrupt pending flag and the cause
				Port.InterruptPending = 1
				Port.IIR = IIR_TX_EMPTY
				
			End If
		
		Case OFFSET_LCR
			Port.LCR = Value ' This could enable DLAB
			
		Case OFFSET_IER
			Port.IER = Value
			
		Case OFFSET_MCR
			Port.MCR = Value ' We ignore this register
			
		Case OFFSET_FCR
			Assert(Value = 0) ' 8250 does not support FIFO /at all/
			Port.FCR = Value
			
		Default
			Print "8250: write into an unknown register: `" + register_name_8250_write(Offset) + "` value " + Value
			Input "(Press Enter to continue)"

	End Select
	
End Function

Function Handle8250Read(Port:TSerial8250, Offset:ULong)
	Select Offset
		Case OFFSET_RX
			Port.BusOutput = $FF ' Just wave it off for now
		Case OFFSET_IER
			Port.BusOutput = Port.IER
		Case OFFSET_IIR
			Port.BusOutput = Port.IIR
		Case OFFSET_LSR
			Port.BusOutput = Port.LSR
		Case OFFSET_MSR
			Port.BusOutput = Port.MSR
		
		Default
			Port.BusOutput = $FF
			Print "8250: read from an unknown register: `" + register_name_8250_read(Offset) + "`"
			Input "(Press Enter to continue)"

	End Select
	
End Function

' Handles the output to visual endpoint
Function Handle8250DestinationWrite(Port:TSerial8250, Value:Byte)
	Port.DestinationAddress[Port.DestinationOffset] = Value
	Port.DestinationOffset :+ 1
	
	' Handle newlines
	If Value = $0A
		Port.DestinationOffset :+ (Port.DestinationWidth - (Port.DestinationOffset Mod Port.DestinationWidth))
	End If
	
	' Handle scrolling
	If Port.DestinationOffset >= Port.DestinationLength
		' Scroll
		MemCopy(Port.DestinationAddress, Port.DestinationAddress + Port.DestinationWidth, Size_T(Port.DestinationOffset - Port.DestinationWidth))
		
		' Return cursor to the start of the last line
		Port.DestinationOffset = Port.DestinationLength - Port.DestinationWidth
		
		' Clear the last line
		MemClear(Port.DestinationAddress + Port.DestinationOffset, Size_T(Port.DestinationWidth))
	End If
End Function
