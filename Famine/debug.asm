;-----------------------------------
;Descr  : My First 64-bit MASM program
;ml64 prog.asm /c
;golink /console /entry main prog.obj msvcrt.dll, or
;gcc -m64 prog.obj -o prog.exe (main/ret). This needs 64-bit GCC.
;-----------------------------------

extrn printf:proc
extrn GetLastError:proc

.code
message_error db 'Error code : %d',0ah,0h

print_last_error proc
	push rbp
	mov rbp, rsp
	sub rsp, 32

	call GetLastError

	lea rcx, message_error
	mov rdx, rax
	call printf

	mov rsp, rbp
	pop rbp
	ret
print_last_error endp

end