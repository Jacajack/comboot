;Very basic set of stdio tools

;Print single character on screen
;al - character to print
putc:
	pushf
	pusha
	mov ah, 0xE	;Put character on screen
	int 0x10	;Interrupt 10h
	popa
	popf
	ret

;Print null terminated string on screen
;si - string address
puts:
	pushf
	pusha
	mov ah, 0xE
	puts_l1:
		cmp [si], byte 0
		je puts_end
		mov al, [si]
		int 0x10
		inc si
		jmp puts_l1
	puts_end:
	popa
	popf
	ret

;Clear screen in text mode
cls:
	pushf
	pusha
	mov al, 0x02	;Change gfx mode to text mode (that should be enough)
	mov ah, 0		;
	int 0x10		;
	popa
	popf
	ret

;Fetch keystroke (wait)
;return al - ASCII code
;return ah - BIOS scancode
getc:
	pushf					;Push registers
	pusha					;
	mov al, 0x00			;Get character
	mov ah, 0x00			;
	int 0x16				;Call interrupt
	mov [getc_key], ax		;Store key in memory
	popa					;Pop registers
	popf					;
	mov ax, [getc_key]		;Get key into register
	ret
	getc_key: dw 0
