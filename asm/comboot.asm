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

;mov al, [boot_drive]
;call puthexb


mov ax, teststas
mov es, ax
mov ax, teststao
mov bx, testends
mov fs, bx
mov bx, testendo
pusha


recv:
call kbhit
cmp al, 0
je nokey
call getc
cmp al, 'f'
jne nokey

jmp gaga

nokey:
call comckin
cmp al, 0
je recv
call comrecv
mov [newchar], al
mov [temp], al

popa
mov cl, [temp]
push bx
mov bx, ax
mov [es:bx], cl
pop bx
mov dx, 001
call memcrawl
cmp cl, 0
jne gaga
pusha

pusha
mov al, [newchar]
call puthexb
mov al, `\r`
call putc
popa

jmp recv

gaga:
mov si, mesg_eor
call puts
call getc
gigi:


mov si, mesg_nl
call puts

;mov si, mesg_ok
;call puts

mov ax, teststas
mov es, ax
mov ax, teststao
mov cx, 0


wloop:
	push ax
	push es

	mov ax, teststas
	mov es, ax
	mov bx, teststao

	mov ax, [seccnt]
	mov dl, [boot_drive]
	mov dh, 1
	call diskwlba
	inc ax
	mov [seccnt], ax
	call puthexw
	push ax
	mov al, `\r`
	call putc
	pop ax
	pop es
	pop ax

	mov dx, 512
	mov bx, testends
	mov fs, bx
	mov bx, testendo
	call memcrawl
	cmp cl, 0
	je contwloop
	jmp wloop_end
	contwloop:

	pusha
	push ds
	push es

	mov bx, es
	mov ds, bx
	mov si, ax

	mov bx, teststas
	mov es, bx
	mov di, teststao
	mov cx, 512

	call memcpy
	pop es
	pop ds
	popa

	jmp wloop


wloop_end:
mov si, mesg_ok
call puts

teststas equ 0x0000
testends equ teststas+(1024*100/16)
teststao equ 0x0b00
testendo equ teststao

jmp $

seccnt: dw 0

temp: db 0

newchar: db 0
boot_drive: db 0

;Messages collection
mesg_greeting:
	db "---comboot v0.3 testing", 10, 13
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
	db "receiving data at 9600 baud, 8 bits data, 1 bit stop...", 10, 13
	db 0

mesg_ok:
	db "ok...", 10, 13
	db 0

mesg_loop:
	db "loop...", 10, 13
	db 0

mesg_eor:
	db "end of read. press any key", 10, 13
	db 0

mesg_nl: db 10, 13, 0

%include "stdio.asm"
%include "com.asm"
%include "disk.asm"
%include "mem.asm"
