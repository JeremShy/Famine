Bonjour, nous du futur. J'espere que tout va bien. <3


Du coup :

Pour chaque dll:
Il y a la OFT et la FT :

Ces deux choses sont des tableaux de pointeurs vers des structure avec un hint (ons'enfout) et le nom de la fonction.
Il faut donc :
	Rajouter chaque fonction dans la oft et la ft de la dll qui lui correspond, et aussi son nom et un hint pourri (genre 0000) dans le tableau IMAGE_IMPORT_BY_NAME. En esperant qu'il y a de la place dans ces 3 tableaux.
	Il faudra aussi jumper vers l'endroit de la ft (en dereferencant)


Adresse du jump a travers les sections : 60CE - On transforme ca en virtual address : 60CE - 400 + 1000 = 6cce.
On ajoute la valeur de l'offset de jump : 6CCE + 7934A = 80018
Ca appartient a idata : On tranforme ca en addresse physique en soustrayant la Virtual Address et en ajoutant le pointer to raw data : 80018 - 80000 + 7C200 = 7C218
7C218 est donc l'addresse de la FT.



label debut:
Notre code
label fin:
Notre code + 17fa = un jump dans une autre section

Un bordel

Est ce que la dll est dans le fichier
	Si non, c'est la merde

	Si oui, est ce que la fonction qu'on va utiliser est importee
		si oui, on trouve l'adresse a ecrire
		Si non, on cree une entree dans la OFT,une entree dans la FT, un nom et un hint dans le tableau et tout ce qui faut.. on recypere la bonne addresse
	On ecrit la bonne adresse au bon endroit

extrn puts:proc  
extrn printf:proc

extrn FindFirstFileA:proc	; Kernel32.dll
extrn FindNextFileA:proc	; Kernel32.dll
extrn ReadFile:proc			; Kernel32.dll
extrn CreateFileA:proc		; Kernel32.dll
extrn GetFileSize:proc		; Kernel32.dll
extrn SetFilePointer:proc	; Kernel32.dll
extrn WriteFile:proc		; Kernel32.dll

extrn GetProcessHeap:proc	; 
extrn HeapAlloc:proc

Parcourir les sections pour trouver idata

Trouver le data directory : "PE\0\0" + 0x88
Trouver le champ ImportDirectoryRva : datad directory + 8
Transformer la valeur en addresse physique 

FFEC113B

00007FF66F536014
	

13EEC5


offset : 10614 - Address : 00007FF66F536014
offset : 53B -	Address :  00007FF66F52113B

debut main - (VA de famine + entrypoint) (Par exemple : 00007FF66F536000 - 26000 + 1113B)

100D9

Begin Entrypoint : 1513b
