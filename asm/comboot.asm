[bits 16]
[org 0x7c00]

;Store boot drive
mov [boot_drive], dl

call cls
mov si, mesg_greeting
call puts

jmp $

;Boot drive number
boot_drive: db 0

;Messages collection
mesg_greeting: db "Greetings!", 10, 13, 0

%include "stdio.asm"

;Padding and magic number
times 510 - ( $ - $$ ) db 0
dw 0xaa55
