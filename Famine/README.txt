Bonjour, nous du futur. J'espere que tout va bien. <3


Du coup :

Pour chaque dll:
Il y a la OFT et la FT :

Ces deux choses sont des tableaux de pointeurs vers des structure avec un hint (ons'enfout) et le nom de la fonction.
Il faut donc :
	Rajouter chaque fonction dans la oft et la ft de la dll qui lui correspond, et aussi son nom et un hint pourri (genre 0000) dans le tableau IMAGE_IMPORT_BY_NAME. En esperant qu'il y a de la place dans ces 3 tableaux.
	Il faudra aussi jumper vers l'endroit de la ft (en dereferencant)



807a0

72f6 + 794AA

7ef6 + 794AA = 813a0

813a0 - 81000 + 7d400 = 7d7a0



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
