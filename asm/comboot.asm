[bits 16]
[org 0x500]

;Display greeting message
call cls
mov si, mesg_greeting
call puts
mov si, mesg_anykey
call puts


;Configure serial
mov dx, [port_addr]			;Disable interrupts
add dx, 1					;
mov al, 0					;
out dx, al					;
mov dx, [port_addr]			;Enable baud rate divisor
add dx, 3					;
mov al, 0x80				;
out dx, al					;
mov dx, [port_addr]			;Set baud rate divisor
add dx, 0					;
mov al, [port_conf_div]		;
out dx, al					;
mov dx, [port_addr]			;Baud rate divisor high byte
add dx, 1					;
mov al, [port_conf_div + 1]	;
out dx, al					;
mov dx, [port_addr]			;No parity, data: 8, stop: 1
add dx, 3					;
mov al, 0x03				;
out dx, al					;
mov dx, [port_addr]			;FIFO enabled, 14-byte threshold
add dx, 2					;
mov al, 0xc7				;
out dx, al					;
mov dx, [port_addr]			;IRQs - RTS, DSR
add dx, 4					;
mov al, 0x0b				;
out dx, al					;

call getc

mov si, mesg_ok
call puts

aa:
call comckin
cmp al, 0
je aa
call comrecv
call putc

jmp aa

jmp $

comckin:
	pushf
	pusha
	mov dx, [port_addr]
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
	mov dx, [port_addr]
	in ax, dx
	mov [comrecv_b], al
	popa
	mov al, [comrecv_b]
	popf
	ret
	comrecv_b: db 0

;Chosen serial port address
port_addr: dw 0x3f8
port_conf_div: dw 1

;Messages collection
mesg_greeting:
	db "comboot v0.1", 10, 13
	db 0

mesg_anykey:
	db "please press any key to continue...", 10, 13
	db 0

mesg_ok:
	db "ok...", 10, 13
	db 0

%include "stdio.asm"
