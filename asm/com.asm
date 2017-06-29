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

comckin:
	pushf
	pusha
	mov dx, [com_addr]
	add dx, 5
	in ax, dx
	and ax, 0x01
	mov [comckin_b], al
	popa
	mov al, [comckin_b]
	popf
	ret
	comckin_b: db 0

comrecv:
	pushf
	pusha
	mov dx, [com_addr]
	in ax, dx
	mov [comrecv_b], al
	popa
	mov al, [comrecv_b]
	popf
	ret
	comrecv_b: db 0
