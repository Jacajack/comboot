;Configure serial port
;ax - port address
;bx - baud rate divisor
;cl - transmission settings (parity, etc.)
cominit:
	pushf
	pusha
	mov [com_addr], ax			;Store configuration
	mov [com_div], bx			;
	mov [com_conf], cl			;
	mov dx, [com_addr]			;Disable interrupts
	add dx, 1					;
	mov al, 0					;
	out dx, al					;
	mov dx, [com_addr]			;Enable baud rate divisor
	add dx, 3					;
	mov al, 0x80				;
	out dx, al					;
	mov dx, [com_addr]			;Set baud rate divisor
	add dx, 0					;
	mov al, [com_div]			;
	out dx, al					;
	mov dx, [com_addr]			;Baud rate divisor high byte
	add dx, 1					;
	mov al, [com_div + 1]		;
	out dx, al					;
	mov dx, [com_addr]			;No parity, data: 8, stop: 1
	add dx, 3					;
	mov al, [com_conf]			;
	out dx, al					;
	mov dx, [com_addr]			;FIFO enabled, 14-byte threshold
	add dx, 2					;
	mov al, 0xc7				;
	out dx, al					;
	mov dx, [com_addr]			;IRQs - RTS, DSR
	add dx, 4					;
	mov al, 0x0b				;
	out dx, al					;
	popa
	popf
	ret
	com_addr: dw 0
	com_div: dw 0
	com_conf: db 0

;Checks if there are any characters awaiting in COM buffer
;return al - buffer status (0-empty, 1-awaiting characters)
comckin:
	pushf
	pusha
	mov dx, [com_addr]		;Access serial port
	add dx, 5				;
	in ax, dx				;Read IRQs register
	and ax, 0x01			;Get youngest bit
	mov [comckin_b], al		;Store it in RAM
	popa					;
	mov al, [comckin_b]		;And bring back from it
	popf
	ret
	comckin_b: db 0

;Receives byte from serial port
;return al - received byte
comrecv:
	pushf
	pusha
	mov dx, [com_addr]		;Access serial port
	in ax, dx				;Read data register
	mov [comrecv_b], al		;Store char in RAM
	popa					;
	mov al, [comrecv_b]		;Bring the char back
	popf
	ret
	comrecv_b: db 0

;Receives byte from serial port (with waiting)
;return al - received byte
comwrecv:
	pushf
	pusha
	comwrecv_l:				;
		call comckin		;Check buffer
		cmp al, 0			;
		je comwrecv_l		;Loop until buffer is not empty
	call comrecv			;Receive character
	mov [comwrecv_b], al	;Temporarily store character in RAM
	popa					;Restore all registers
	mov al, [comwrecv_b]	;Write character to al
	popf
	ret
	comwrecv_b: db 0

;Clears serial port input buffer
comclibuf:
	pushf
	pusha
	comclibuf_l:			;
		call comckin		;Check buffer
		cmp al, 0			;
		je comclibuf_end	;Loop until buffer is empty
		call comrecv		;Receive and ignore character from buffer
		jmp comclibuf_l		;
	comclibuf_end:
	popa
	popf
	ret
