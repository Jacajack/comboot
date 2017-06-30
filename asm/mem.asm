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


;Copies data between places in memory
;ds:si - source
;es:di - destination
;cx - data length
memcpy:
	pushf
	pusha
	cld
	rep movsb
	popa
	popf
	ret
