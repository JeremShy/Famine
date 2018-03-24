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

.data
hello db 'Hello 64-bit world!',0ah,0

.code
main proc
		push rbp
		mov rbp, rsp
		sub	rsp, 24

		mov rcx, [rdx]
		mov [rsp + 16], rcx
		call puts


		mov rax, 0
		mov rsp, rbp
		pop rbp
		ret

main endp
end