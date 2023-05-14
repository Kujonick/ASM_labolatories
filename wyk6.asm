; BCD - pisanie na 4 bitach 0-9 (więc bajt moze przechowywać 99)


; ########## OPERACJE ARYTMETYCZNE

;----- DODAWANIE -------
; add - dodawanie
; adc - dodawanie z przeniesieniem zapisywany na 9 (bajt) albo 17 (word)
; inc
; aaa - poprawka po dodwawaniu w rozpakowanym kodzie BCD
; daa

;----- ODEJMOWANIE -------
; sub
; sbb - odejmowanie z pożyczką
; dec
; neg - odjęcie argumentu od 0 ( zmiana znaku argumentu)
; cmp ax, bx -> ax - bx, w rejestrze flag zostają zapisane 

; ----- MNOŻENIE -------

; mul
; imul - mnożenie ze znakiem
; aam - poprawka po mnożeniu BCD

; ----- MNOŻENIE -------

; div
; idiv
; aad - poprawka po dzieleniu BCD
; cbw - zamiana bajtu na słowo
; cwd - zamiana słowa na podwójne słowo



; ########## OPERACJE LOGICZNE

; ----- logiczne na bitach
; not - zamiana bitów na przeciwne
; and 
; or				: or al, al  <==> cmp al, 0
; xor 				: xor al, al  <==> mov al, 0
; test

; ----- przesunięcia

; shl/sal - logiczne.arytmetyczne przesunięcie w lewo
; shr - logiczne w prawo ( chcąc przesunąć więcej niż jeden trzeba użyć wartości w cl)
; sar - arytmetyczne w prawo
; rol - cykliczne w prawo  (bit wysuwany jest przekazywany na początek)
; ror - cykliczne w prawo
; rcl - cykliczne w lewo z przesunięciem
; rcr - cykliczne w prawo z przeniesieniem

; -----
; stc - set carry flag
; clc - clear carry flag (CF) - przy rotacyjnej



;##########################
; Rozkazy przetwarzające łańcuchy
; 	  - proste rozkazy realizujące pojedynczą operację
;	  - przedrostki deklarujace powtórzenie rozkazu prostego

; zawsze używaja tych samych rejestrów
; DS:SI - adres źródła danych
; ES:DI - adres przeznaczenia danych
; CX - rejestr powtórzenń

;1) pojedyncze operacje
;	 - MOVSB / MOVSW
		przepisanie pamęci elementu bloku danych [DS:SI] -> [ES:DI]
		
		lds 	si, dword ptr ds:[ZRODLO]
		les	 	di, dword ptr cs:[CEL]
		cld
		movsb			; kopia [DS:SI] -> [ES:DI], zwiększenie SI i DI o 1
		movsb
	- LODSB / LODSW
		załadowanie do akuulatora bajtu lub słowa z bloku [DS:SI]
		
		lds 	si, dword ptr ds:[ZRODLO]
		std
		LODSW
		mov 	bx, ax
		lodsw
		mov		cx, ax
		LODSW
		mov 	dx, ax
		
	- STOSB / STOSW
	zapisanie w pamięci bloku zawartośi akumulatora A -> [ES:DI]
		les	 	di, dword ptr cs:[CEL]
		cld
		mov		al, 020h
		STOSB
		STOSB
		STOSB
		
		
	- SCASB / SCASW 
	porównaie bajtu lub słowa bloku danych z zawartością akumuliatra
	
	- CMPSB / CMPSW
	porównaie bajltu lub słó dwóch bloków 
	
; przedrostki
	REP - powtarzanie operacji łańcuchowej aż cx == 0
		lds 	si, dword ptr ds:[ZRODLO]
		les	 	di, dword ptr cs:[CE]
		cld 
		mov 	cx, 10
		rep movsb ; przesłanie 10 bajtów
		
	REPZ lub REPE
	powtarzanie operacji łańcuchowej póki jest równość (albo nie skończy licznik)
	
		BLOK db "       tekst"
		cld 
		mov 	cx, 100
		mov 	al, ' '
		repz SCASB   ; znalezienie pierwszego znaku nie równego al (' ')
		
	REPNZ lub REPNE	
	powtarzanie operacji łańcuchowej dopóki jest nierówność (albo nie skończy licznik)
		STRING db "To jest tekst", 0, 40 dup(0)
		cld 
		mov 	cx, 100
		xor 	al, al
		repnz scasb 
		dec 	 di		; szukanie końca STRING ( bo ma na końcu zera)