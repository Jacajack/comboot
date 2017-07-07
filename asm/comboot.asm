[bits 16]
[org 0x500]

pop dx
mov ax, dx
call puthexw
mov [boot_drive], dl

;Display greeting message
call cls
mov si, mesg_greeting
call puts

;Display available memory size
mov si, mesg_mem
call puts
int 0x12
call puthexw
mov si, mesg_mem2
call puts

;Display message telling user to insert new floppy disk
mov si, mesg_newfloppy
call puts

;Wait for keypress
call getc

;Init serial port
mov ax, 0x3f8
mov bx, 12
mov cl, 0x03
call cominit
call comclibuf

;Receiving begins
mov si, mesg_recv
call puts

;Settings for memcrawl
teststas equ 0x0000
testends equ teststas+(1024*100/16)
teststao equ 0x1e700
testendo equ teststao
mov ax, teststas
mov es, ax
mov ax, teststao
mov bx, testends
mov fs, bx
mov bx, testendo
pusha

;Reception part
recv:
	call kbhit				;Check if any key has been pressed
	cmp al, 0				;
	je recv_nokey			;
	call getc				;If so, get the key value
	cmp al, 'f'				;Check if they key is 'f'
	jne recv_nokey			;If not, assume no key was pressed
	jmp recv_end			;If 'f' has been pressed quit reception loop
	recv_nokey:				;We land here if user doesn't do anything
	call comckin			;Check COM buffer
	cmp al, 0				;If empty - loop
	je recv					;
	call comrecv			;Else, get the character
	mov [combyte], 	al		;Store character in memory
	popa					;Restore configuration for memcrawl from stack
	mov cl, [combyte]		;Restore byte received from COM
	push bx					;Store bx
	mov bx, ax				;Move current offset into bx
	mov [es:bx], cl			;Write received byte into memory
	pop bx					;Restore bx
	mov dx, 001				;Move 1 byte forward
	call memcrawl			;Perform memcrawl on pointers
	pusha					;Store pointers
	cmp cl, 0				;Check memcrawl exit code
	jne recv_end			;If we reached the end - exit reception loop
	push ax					;Store ax
	test ax, 0x0001			;Check youngest bit of current memory offset
	jz recv_indicate_h		;Display horizontal indicator
	mov al, '|'				;Display vertical indicator
	call putc				;
	jmp recv_indicate_cr	;Go straight to the CR part
	recv_indicate_h:		;Display horizontal indicator
	mov al, '-'				;
	call putc				;
	recv_indicate_cr:		;Carriage return
	mov al, `\r`			;
	call putc				;
	pop ax					;Restore ax
	jmp recv				;Loop
	recv_end:				;Exit point
	mov si, mesg_recv_end	;Display message
	call puts				;
	call getc				;Wait for keypress


mov ax, teststas			;Restore memcrawl settings
mov es, ax					;
mov ax, teststao			;
mov cx, 0					;
diskflush:					;Flush received data to floppy disk
	push ax					;Store ax
	push es					;Store segment register
	mov ax, teststas		;Write data from the begining of the memory to the disk
	mov es, ax				;
	mov bx, teststao		;
	mov ax, [seccnt]		;Written sector number depends on value stored in memory
	mov dl, [boot_drive]	;Get boot drive number
	mov dh, 1				;Write only 1 sector
	call diskwlba			;Write data to disk
	inc ax					;Increment sector counter
	mov [seccnt], ax		;
	call puthexw			;Display current sector number

	mov al, `\r`			;Print carraige return
	call putc				;
	pop es					;Restore segment register
	pop ax					;Restore ax

	mov dx, 512				;Perform 512b memory crawl
	mov bx, testends		;Load memcrawl limits
	mov fs, bx				;
	mov bx, testendo		;
	call memcrawl			;Memcrawl, yay!
	cmp cl, 0				;Check if we've reached the limit
	jne diskflush_end		;If so, quit the loop

	pusha					;Store all registers
	push ds					;Store segment registers
	push es					;
	mov bx, es				;Indirectly move es into ds
	mov ds, bx				;
	mov si, ax				;
	mov bx, teststas		;Move start segment into es
	mov es, bx				;
	mov di, teststao		;And start offset into di
	mov cx, 512				;Perform 512 memcopy from crawling address to the begining address
	call memcpy				;
	pop es					;Restore segment registers
	pop ds					;
	popa					;Restore the rest
	jmp diskflush			;Loop
	diskflush_end:
	mov si, mesg_diskflush_end
	call puts

call getc				;Wait for keypress
jmp 0xFFFF:0			;Reboot

jmp $

seccnt: dw 0

combyte: db 0

newchar: db 0
boot_drive: db 0

;Messages collection
mesg_greeting:
	db "---comboot v0.45 `a bit more functional disaster`", 10, 13
	db 0

mesg_mem:
	db "available memory: "
	db 0
mesg_mem2:
	db "h KB", 10, 13
	db 0

mesg_newfloppy:
	db "please insert new floppy disk and press any key afterwards...", 10, 13
	db 0

mesg_recv:
	db "clearing input buffer...", 10, 13
	db "receiving data at 9600 baud, 8 bits data, 1 bit stop...", 10, 13
	db "data flow is shown by indicator below...", 10, 13
	db "please press 'f' key when all data has been received...", 10, 13
	db 0

mesg_ok:
	db "ok...", 10, 13
	db 0

mesg_loop:
	db "loop...", 10, 13
	db 0

mesg_recv_end:
	db "done receiving the data...", 10, 13
	db "press any key to flush it to the disk...", 10, 13
	db 0

mesg_diskflush_end:
	db "done writing disk...", 10, 13
	db "press any key to reboot...", 10, 13
	db 0

mesg_nl: db 10, 13, 0

%include "stdio.asm"
%include "disk.asm"
%include "com.asm"
%include "mem.asm"
