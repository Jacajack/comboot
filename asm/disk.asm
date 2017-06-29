disk_n_s equ 18				;Sectors per track
disk_n_h equ 2				;Heads per cylinder
disk_err_threshold equ 5	;Error threshold

;Reads data from disk
;ax - LBA
;dl - drive number
;dh - sector count
;es:bx - data addresses
diskrlba:
	pushf
	pusha
	push dx							;Store dx value
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_s				;Divide LBA by sector per track count
	div cx							;
	inc dx							;Increment reminder
	mov [diskrlba_s], dx			;Save reminder as sector number
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_h				;Divide LBA by heads per cylinder count
	div cx							;
	mov [diskrlba_h], dx			;Reminder is head number
	mov [diskrlba_c], ax			;Quotient is cylinder number
	pop dx							;Restore dx
	mov al, dh						;Load sectors amount into al
	mov cl, [diskrlba_s]			;Load CHS
	mov ch, [diskrlba_c]			;
	mov dh, [diskrlba_h]			;
	diskrlba_l:						;
		mov ah, 0					;Reset disk
		int 0x13					;
		mov ah, 0x2 				;Sector read
		int 0x13					;Disk interrupt
		jnc diskrlba_end			;If carry flag is not set (no error, quit)
		mov cx, [diskrlba_cnt]		;Increment error counter
		inc cx						;
		mov [diskrlba_cnt], cx		;
		cmp cx, disk_err_threshold	;Check if error count is below threshold
		jle diskrlba_l				;If so, try again
		call diskerr				;Else, call disk error handler
	diskrlba_end:					;
	mov cx, 0						;Clear error counter
	mov [diskrlba_cnt], cx			;
	popa
	popf
	ret
	diskrlba_cnt: dw 0			;Disk error counter
	diskrlba_s: dw 0			;Sector number
	diskrlba_h: dw 0			;Head number
	diskrlba_c: dw 0			;Cylinder number

;Writes data to disk
;ax - LBA
;dl - drive number
;dh - sector count
;es:bx - data addresses
diskwlba:
	pushf
	pusha
	push dx							;Store dx value
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_s				;Divide LBA by sector per track count
	div cx							;
	inc dx							;Increment reminder
	mov [diskwlba_s], dx			;Save reminder as sector number
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_h				;Divide LBA by heads per cylinder count
	div cx							;
	mov [diskwlba_h], dx			;Reminder is head number
	mov [diskwlba_c], ax			;Quotient is cylinder number
	pop dx							;Restore dx
	mov al, dh						;Load sectors amount into al
	mov cl, [diskwlba_s]			;Load CHS
	mov ch, [diskwlba_c]			;
	mov dh, [diskwlba_h]			;
	diskwlba_l:						;
		mov ah, 0					;Reset disk
		int 0x13					;
		mov ah, 0x3 				;Sector write
		int 0x13					;Disk interrupt
		jnc diskwlba_end			;If carry flag is not set (no error, quit)
		mov cx, [diskwlba_cnt]		;Increment error counter
		inc cx						;
		mov [diskwlba_cnt], cx		;
		cmp cx, disk_err_threshold	;Check if error count is below threshold
		jle diskwlba_l				;If so, try again
		call diskerr				;Else, call disk error handler
	diskwlba_end:					;
	mov cx, 0						;Clear error counter
	mov [diskwlba_cnt], cx			;
	popa
	popf
	ret
	diskwlba_cnt: dw 0			;Disk error counter
	diskwlba_s: dw 0			;Sector number
	diskwlba_h: dw 0			;Head number
	diskwlba_c: dw 0			;Cylinder number

;Disk error handler
diskerr:
	pushf
	pusha
	mov si, diskerr_mesg	;Load message address into si
	mov ah, 0xE				;Setup ah for interrupt
	diskerr_l1:				;Puts loop
		mov al, [si]		;Load into al
		cmp al, 0			;Compare character with 0
		je diskerr_end		;If equal, end run
		int 0x10			;Run interrupt
		inc si				;Increment counter
		jmp diskerr_l1		;Loop
	diskerr_end:
	jmp $
	popa
	popf
	ret
	diskerr_mesg:
		db "[critical] disk fault!", 10, 13
		db 0
