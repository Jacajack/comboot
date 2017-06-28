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
