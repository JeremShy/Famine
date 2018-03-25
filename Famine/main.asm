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
extrn memset:proc



.code
label_debut:
db 'Famine version 1.0 (c)oded by magouin-jcamhi',0ah,0h

hello db 'Hello 64-bit world!',0ah,0
print_decimal db 'open : %d',0ah,0
print_ptr db 'ptr : %p',0ah,0
TMP_1 db 'C:\Users\moi\AppData\Local\Temp\test',0h

; rbp
; 40-400	: structure WIN32_FIND_DATA dirent
; 32-40		: folder_name
; 00-32		: shadow
; rsp

infect_folder proc ; parametres : char *folder_name
		push rbp
		mov rbp, rsp
		sub	rsp, 400

		mov [rsp + 32], rcx
		call puts

		mov rcx, [rsp + 32]
		lea rdx, [rsp + 40]
		call FindFirstFileA

		;mov rcx, rsp
		;add rcx, 40
		;mov rdx, 0
		;mov r8, 612
		;call memset

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