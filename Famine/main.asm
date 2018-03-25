;-----------------------------------
;Descr  : My First 64-bit MASM program
;ml64 prog.asm /c
;golink /console /entry main prog.obj msvcrt.dll, or
;gcc -m64 prog.obj -o prog.exe (main/ret). This needs 64-bit GCC.
;-----------------------------------

includelib libcmt.lib
includelib libvcruntime.lib

extrn puts:proc
extrn exit:proc
extrn _open:proc
extrn printf:proc

.data
hello db 'Hello 64-bit world!',0ah,0
print_decimal db 'open : %d',0ah,0

; rbp
; 40-48 : alignment
; 32-40 : av[0]
; 00-32 : shadow space
; rsp 

.code
signature proc
	db 'Famine version 1.0 (c)oded by magouin-jcamhi',0ah,0h
signature endp

find_start_famine proc

find_start_famine endp

main proc
		push rbp
		mov rbp, rsp
		sub	rsp, 48

		mov rcx, [rdx]

		mov [rsp + 32], rcx

		lea rcx, signature
		call puts

		mov rcx, [rsp + 32]
		mov rdx, 8000h
		mov	r8, 0
		call _open

		lea rcx, print_decimal
		mov rdx, rax
		call printf

		mov rax, 0
		mov rsp, rbp
		pop rbp
		ret

main endp
end