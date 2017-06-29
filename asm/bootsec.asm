[bits 16]
[org 0x7c00]

;Setup stack
mov bp, 0xffff
mov sp, bp

;Put dx (including boot drive number) on stack
push dx

call cls
mov si, mesg_greeting
call puts

;Load rest of program into memory
diskload_attempts equ 4
diskload:
	mov si, mesg_diskload_try	;Print message about disk access
	call puts					;
	mov ah, 0					;Reset disk
	int 0x13					;
	mov ah, 0x2					;Read sectors from disk
	mov al, 17					;Read 17 sectors
	mov ch, 00					;c = 0
	mov dh, 0					;h = 0
	mov cl, 2					;s = 2
	mov bx, 0x0000				;Clear es
	mov es, bx					;
	mov bx, 0x0500				;Setup destination address
	int 0x13					;
	jnc diskload_end			;If no carry flag is set - success
	mov ax, [diskload_cnt]		;Read error counter
	inc ax						;Increment it
	mov [diskload_cnt], ax		;And store it
	cmp ax, diskload_attempts	;Check if there are any attempts left
	jb diskload					;Try again
	mov si, mesg_diskload_fail	;Print error message
	call puts					;
	jmp $						;Endless loop
	diskload_end:

;Print success message
mov si, mesg_success
call puts

;Jump into freshly loaded program
jmp 0x500
jmp $

diskload_cnt: dw 0

;Messages collection
mesg_diskload_try:
	db "loading data from disk...", 10, 13
	db 0
mesg_diskload_fail:
	db "disk error...", 10, 13
	db "aborting...", 10, 13
	db 0
mesg_greeting:
	db "---comboot bootloader v0.1", 10, 13
	db 0
mesg_success:
	db "success...", 10, 13
	db "starting...", 10, 13
	db 0

%include "stdio.asm"

;Padding and magic number
times 510 - ( $ - $$ ) db 0
dw 0xaa55
