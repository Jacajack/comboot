[bits 16]
[org 0x500]

pop dx
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
;call getc

;Init serial port
mov ax, 0x3f8
mov bx, 12
mov cl, 0x03
call cominit
call comclibuf

;Receiving begins
mov si, mesg_recv
call puts

mov ax, 0x0000
mov es, ax
mov ax, 0x0001

mov bx, 0x0
mov fs, bx
mov bx, 0x000f

mov dx, 0x0010

call memcrawl
mov bx, ax
mov ax, es
call puthexw
mov al, ':'
call putc
mov ax, bx
call puthexw

jmp $

;es:ax - current address
;fs:bx - end address
;dx - offset
;return es:ax - new address
;return cl - crawl performed (0 - ok)
memcrawl:
	pushf
	pusha
	push dx					;
							;Calculate real address of given pointer
	mov dx, es				;Load segment into dx
	shr dh, 4				;Get oldest 4 bits of segment number
	mov cl, dh				;Store them in cl
	mov dx, es				;Load es into dx again
	shl dx, 4				;Shift segment register 4 bytes to the left
	add ax, dx				;Add it to offset
	adc cl, 0				;Increment oldest address byte depending on carry flag
	mov [memcrawl_c+2], cl	;Update values in memory
	mov [memcrawl_c], ax	;
							;Calculate real address of end pointer
	mov dx, fs				;Load segment into dx
	shr dh, 4				;Get oldest 4 bits of segment number
	mov ch, dh				;Store them in ch
	mov dx, fs				;Load es into dx again
	shl dx, 4				;Shift segment register 4 bytes to the left
	add bx, dx				;Add it to offset
	adc ch, 0				;Increment oldest address byte depending on carry flag
	mov [memcrawl_e+2], ch	;Update values in memory
	mov [memcrawl_e], bx	;
	sub bx, ax				;Substract both pointers to calculate maximum allowed jump
	sbb ch, cl				;
	pop dx					;Get step size
	mov cl, 1				;Assume crawl to be failed
	mov [memcrawl_bnd], cl	;
	mov cl, [memcrawl_c+2]	;Get original pointer from memory
	mov ax, [memcrawl_c]	;
	cmp ch, 0				;Compare requested step with distance to end pointer
	jne memcrawl_jok		;
	cmp dx, bx				;
	jb memcrawl_jok			;
	mov bx, 0				;If pointer cannot be incremented
	mov ch, 0				;
	jmp memcrawl_jbad		;
	memcrawl_jok:			;Increment pointer
	mov ch, 0				;Crawl successfull
	mov [memcrawl_bnd], ch	;
	add ax, dx				;Add jump value with carry
	adc cl, 0				;
	memcrawl_jbad:			;Pointer cannot be incremented
	mov bx, 0				;Copy 4 oldest address bits
	shl cl, 4				;To highest bits of segment register
	mov bh, cl				;
	mov dx, ax				;Get 4 youngest bits of real address as offset
	and dx, 0xF				;
	shr ax, 4				;Shift the rest 4 bits to the right and add it to segment register
	add bx, ax				;
	jnc memcrawl_nocarry	;If no carry flag is set - exit
	shl bx, 4				;Shift segment register 4 bits to the left
	add dx, bx				;Add it to offset register
	mov bx, 0xffff			;Fill segment register with highest value possible
	memcrawl_nocarry:		;
	mov [memcrawl_seg], bx	;Store segment
	mov [memcrawl_off], dx	;Store offset
	popa					;
	mov ax, [memcrawl_seg]	;Restore all values that should be retuned from memory
	mov es, ax				;
	mov ax, [memcrawl_off]	;
	mov cl, [memcrawl_bnd]	;
	popf
	ret
	memcrawl_c: times 3 db 0
	memcrawl_e: times 3 db 0
	memcrawl_seg: dw 0
	memcrawl_off: dw 0
	memcrawl_bnd: db 0



boot_drive: db 0

;Messages collection
mesg_greeting:
	db "---comboot v0.2", 10, 13
	db 0

mesg_mem:
	db "available memory: "
	db 0
mesg_mem2:
	db "h KB", 10, 13
	db 0

mesg_newfloppy:
	db "please insert new flopyy disk and press any key afterwards...", 10, 13
	db 0

mesg_recv:
	db "receiving data at 9600 baud, 8 bits data, 1 bit stop...", 10, 13
	db 0

mesg_ok:
	db "ok...", 10, 13
	db 0

mesg_nl: db 10, 13, 0

%include "stdio.asm"
%include "com.asm"
%include "disk.asm"
