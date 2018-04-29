Bonjour, nous du futur. J'espere que tout va bien. <3


Du coup :

Pour chaque dll:
Il y a la OFT et la FT :

Ces deux choses sont des tableaux de pointeurs vers des structure avec un hint (ons'enfout) et le nom de la fonction.
Il faut donc :
	Rajouter chaque fonction dans la oft et la ft de la dll qui lui correspond, et aussi son nom et un hint pourri (genre 0000) dans le tableau IMAGE_IMPORT_BY_NAME. En esperant qu'il y a de la place dans ces 3 tableaux.
	Il faudra aussi jumper vers l'endroit de la ft (en dereferencant)