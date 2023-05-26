	
data1 segment 

; dame punktu 
x 		dw 		?		; współrzędna x
y 		dw 		?		; współrzędna y
k		db 		?		; kolor

;
previous_key 	db 	0 	; poprzedni klawisz

; paramentry elipsy
a		dw 		0
b		dw 		0	
a2		dw		?	; do kwadratu
b2		dw		?

; zmienne Algorytmie Brasenhama

delta  		dd 	 	?		;zmiana względem początkowego punktu
delta_A 	dd 		?		; pojedyncza zmiana "w dół"
delta_B 	dd 		?		; pojedyncza zmiana "w prawo"

; backup zmiennych
delta0		dd		?
delta_A0	dd		?
delta_B0	dd		?
;##


change_A 		dd		?	; zmiana deltyA po przesunięciu
change_B_pos 	dd 		?	; zmiany deltyB po przesunięciu (w zależności od ruchu)
change_B_neg	dd 		?

tmp 	dw		?			; zmienna tymczasowa ( do przechowywania współczynnika )

limit  	dw		?			; granica pracy algorytmu
	
; wartości współrzędnych układu - (0,0) na środku ekranu
curr_x  dw 		?			
curr_y  dw 		?

; miejsce na flagi FPU
flags	dw 		?

;
; zmienna przechowująca offset do funkcji rysującej punkty ( są dwie, dlatego potrzebujemy
; 					sposobu na zapisanie ich jednym przypisaniem
arch_points_function  	dw 		?

; funkcja przydzielający kolor do piksela ( get_black czyści )
color_function			dw		?

; argumenty programu - bufor
buffer 		db		'$', 256	dup(7)

; informacje błedu
err_arg_amount	db		"Zla ilosc argumentow (przewidywana - 2)", 10, 13, '$'
err_wrong_arg   db 		"Argumenty moga byc jedynie liczbami z przedzialu 0-200", 10, 13, '$'
data1 ends
		.387
code1 segment
start1:		
		; ustawienie stosu
		
		mov		ax, seg stos1 		
		mov 	ss, ax 				
		mov 	sp, offset wstos1	
		
		; odzyskanie parametrów programu
		mov 	ax, seg data1
		mov 	es, ax
		mov 	si, 082h
		mov		di, offset buffer + 2
		xor 	ch,ch				
		mov 	cl, byte ptr ds:[080h]
		rep 	movsb

		
		call 	find_digit		; znajdz pierwszy argument od końca
		cmp 	al, '$'			; jeśli koniec -> za mało argumentów
		je 		Err_wrg_amout

		;argument b
		mov 	si, offset b
		call 	parse
		cmp		word ptr es:[b], 200
		jg		Err_wrg_arg
		
		call 	find_digit		; znajdz drugi argument od końca
		cmp 	al, '$'			; jeśli koniec -> za mało argumentów
		je 		Err_wrg_amout
		
		;argument a
		mov 	si, offset a
		call 	parse
		cmp		word ptr es:[a], 200
		jg		Err_wrg_arg

		call 	find_digit		; znajdz kolejny argument
		cmp 	al, '$'			; jeśli nie koniec -> za dużo argumentów
		jne 	Err_wrg_amout
		
		; podzielenie przez dwa ( z racji iż a i b to półosie, a nie osie)
		shr 	byte ptr es:[a],1
		shr 	byte ptr es:[b],1
		
		; sprawdzanie poprawności parametrów
		cmp		byte ptr es:[b], 100	; jeżeli b == 100 zmniejszamy o jeden, gdyż maksymalna półoś pionowa jest 99
		jne 	ok
		dec		byte ptr es:[b]
ok:		
		
		cmp		byte ptr es:[a], 0 		; sprawdzanie czy wynik jest 0 ( nie możemy sobie pozwolić ze względu na wystepowanie w mianowniku)
		jne 	ok2
		inc		byte ptr es:[a]
ok2:	cmp		byte ptr es:[b], 0
		jne 	ok3
		inc		byte ptr es:[b]
		
ok3:
		; ustawienie segmentu danych 		
		mov 	ax, seg data1
		mov 	ds, ax
		
		; początkowy adres segmentu graficznego
		mov 	ax, 0A000h				
		mov 	es, ax
	
		;zmiana na tryb graficzny
		mov		al, 13h					; 13 - graficzny 320x200 256 kolorów
		mov 	ah, 0					; zmien tryb graficzny, na podany w al 
		int 	10h						

		mov 	word ptr ds:[arch_points_function], get_points_blue
		
		;------
loop_start:
		mov		word ptr ds:[color_function], get_color
		
		mov 	word ptr ds:[arch_points_function], get_points_blue
		call 	draw_elipse
		call 	switch_a_b
		mov 	word ptr ds:[arch_points_function], get_points_red
		
		call 	draw_elipse
		call 	switch_a_b

input_start:
		in		al, 60h		
		cmp		al, 1		;escape
		je 		stop
		
		cmp		al, byte ptr cs:[previous_key]
		je		input_start
		mov		byte ptr cs:[previous_key], al
		

left:
		cmp 	al, 75					; <- - 75
		jne		right
		
		cmp		byte ptr ds:[a], 1		; jeżeli jest == 1 nie pozwalamy na mniejszą
		je		input_start
		
		call	changed
		dec 	byte ptr ds:[a]
		jmp 	loop_start
		
		
		

right:									
		cmp 	al, 77					; -> - 77
		jne		up
		
		cmp		byte ptr ds:[a], 159	; jeżeli jest == 159 nie pozwalamy na więcej
		je		input_start
		
		call	changed
		inc 	byte ptr ds:[a]
		jmp 	loop_start

		
up:
		cmp 	al, 72					; ^ - 72
		jne		down
		cmp		byte ptr ds:[b], 99	; jeżeli jest == 159 nie pozwalamy na więcej
		je		input_start
		
		call	changed
		inc 	byte ptr ds:[b]
		jmp 	loop_start

down:									
		cmp 	al, 80					; V - 80
		jne		input_start
		cmp		byte ptr ds:[b], 1		; jeżeli jest == 1 nie pozwalamy na mniejszą
		je		input_start
		
		call	changed
		dec 	byte ptr ds:[b]
		jmp 	loop_start



; -----------------------
; funkcja która rysuje ponownie elipse tylko czarnym kolorem - "usuwa starą"
changed:	
		mov		word ptr ds:[color_function], get_black				; ustawienie funkcji poboru koloru dla printu
		
		mov 	word ptr ds:[arch_points_function], get_points_red	; ustawienie funkcji wyboru punktu 
		call 	switch_a_b											; zamiana a z b ( teraz a = b, b = a)
		call 	draw_optimised
		
		call 	switch_a_b											; ( teraz a = a, b = b)
		mov 	word ptr ds:[arch_points_function], get_points_blue 
		call 	draw_elipse
		
		ret
		
; --------- Złe wprowadzone Argumenty ---------
Err_wrg_amout:
		mov	 	dx, offset err_arg_amount
		jmp 	print
		
Err_wrg_arg:
		mov	 	dx, offset err_wrong_arg
		jmp 	print
		
print:
		mov 	ax, es
		mov 	ds, ax
		mov 	ah, 9 									
		int		21h 
		jmp		exit

; --------- wyjście ---------
stop:		
		; powrót do trybu tekstowego
		xor 	ah, ah
		mov		al, 3
		int 	10h
		; try
exit:		
		mov 	ax, 4c00h				; funkcja koncząca program
		int 	21h
;--------------------------------

; zamiana wartości a i b
switch_a_b:
		mov 	al, byte ptr ds:[a]
		mov 	ah, byte ptr ds:[b]
		mov 	byte ptr ds:[a], ah
		mov 	byte ptr ds:[b], al
		ret

;--------------------------------
; wyszukuje pierwszej wartości w bufforze nie będącej znakiem białym
find_digit:
		mov		al, byte ptr es:[di]
		dec 	di
		cmp		al, 32
		jle		find_digit
		inc 	di
		ret

; parsuje liczby pisemne na bitowe	
parse:
		mov 	bl, 10
		mov 	cx, 1					; mnożnik ( na którym jestesmy miejscu)

parse_loop:	
		mov 	al, byte ptr es:[di]	; ustawienie z bufora cyfry do al
		
		cmp		al, 32				; jeśli znak biały -> koniec tej liczby
		jle		end_of_number
		
		cmp 	cx, 1000			; jeśli 1000 i nie jest koniec - za duża liczba -> błąd
		jge		Err_wrg_arg	
		
		cmp		al, 30h				; jesli poniżej 30h albo powyżej 39h - nie jest to cyfra -> bład
		jl		Err_wrg_arg
		cmp		al, 39h
		jg		Err_wrg_arg
		
		sub	 	al, 30h				; 30h = 0, 31h = 1 ... 
		mul 	cl
		add 	word ptr es:[si], ax ; dodanie do odpowiedniego parametru
		
		mov 	al, cl				; pomnożenie cx przez 10
		mul 	bl
		mov 	cx, ax
		
		dec 	di					; przejście na kolejny znak
		jmp 	parse_loop
		
end_of_number:
		ret

; --------- rysowanie elipsy ---------
; zooptymalizowan funkcja, wykorzystująca wcześniejsze parametry
draw_optimised:
		push 	es
		mov 	ax, seg data1
		mov		es, ax
		mov		si, offset delta0
		mov		di, offset delta
		cld
		mov 	cx, 6
		rep 	movsw
		pop 	es
		jmp 	shortcut

; rysowanie pełne elipsy, wraz z liczeniem parametrów
draw_elipse:
		; ustaw kwadraty 
		mov		al, byte ptr ds:[a]
		mul 	al
		mov		word ptr ds:[a2], ax
		
		mov		al, byte ptr ds:[b]
		mul 	al
		mov		word ptr ds:[b2], ax
		
; ustawienie delta
		finit
		mov		word ptr ds:[tmp], 4
		; delta = 4*b2 - 4*b*a2 + a2	
		fild 	word ptr ds:[a2]
		
		fild 	word ptr ds:[a2]
		fimul	word ptr ds:[b]
		fimul	word ptr ds:[tmp]
		fchs	;zmien znak
		
		fild	word ptr ds:[b2]
		fimul	word ptr ds:[tmp]
		
		faddp   st(1), st(0)
		faddp   st(1), st(0)
		
		fistp 	dword ptr ds:[delta]
		
		; delta_A = 4*3*b2	
		fild 	word ptr ds:[b2]
		mov		word ptr ds:[tmp], 12
		fimul	word ptr ds:[tmp]
		
		fist 	dword ptr ds:[delta_A]		; nie cofamy, bo jest następny taki sam człon

		; delta_B = 4*(3*b2 - 2*b*a2 + 2*a2) = 12*b2 - 8*b*a2 +8*a2
		
		mov 	word ptr ds:[tmp], 8
		fild 	word ptr ds:[a2]
		fimul	word ptr ds:[b]
		fimul	word ptr ds:[tmp]
		fchs							;zmien znak
		
		fild 	word ptr ds:[a2]
		fimul 	word ptr ds:[tmp]
		
		faddp   st(1), st(0)
		faddp   st(1), st(0)
		
		fist 	dword ptr ds:[delta_B]
		
		; zapis do backupu
		push 	es
		mov 	ax, seg data1
		mov		es, ax
		mov		si, offset delta
		mov		di, offset delta0
		cld
		mov 	cx, 6
		rep 	movsw
		pop 	es
		
; pozostałe paramentry elipsy
		; limit = (a2*a2)/(a2+b2)
		fild 	word ptr ds:[a2]
		fimul 	word ptr ds:[a2]
		fild 	word ptr ds:[b2]
		fiadd 	word ptr ds:[a2]
		fdivp 	st(1), st(0)
		
		fistp 	word ptr ds:[limit]
		
		; change_A i B_neg = 4*2*b2
		fild 	word ptr ds:[b2]
		mov		word ptr ds:[tmp], 8
		fimul 	word ptr ds:[tmp]
		fist	dword ptr ds:[change_A]
		fist 	dword ptr ds:[change_B_neg]
		
		; change_B_pos
		fild 	word ptr ds:[a2]
		fimul 	word ptr ds:[tmp]
		faddp   st(1), st(0)
		fistp 	dword ptr ds:[change_B_pos]	

shortcut:	
		; ustawianie początkowych x, y
		mov 	word ptr ds:[curr_x], 0		; x
		mov		ax, word ptr ds:[b]			; y
		mov		word ptr ds:[curr_y], ax
		

		

; ----------------------------
; 	rysowanie pojedynczego łuku niebieskiego/czerwonego 
arch:	
		; konwersja wspórzędnych układu współrzędnych na wsp. ekranu
		call 	draw_multiple_points
		
		; sprawdzenie warunku rysowania
		
		mov		ax, word ptr ds:[curr_x]
		mul 	al					; w ax jest teraz x 
		cmp		ax, word ptr ds:[limit]
		jnb		arch_end			; jeśli x*x >= limit kończ
		
		inc 	word ptr ds:[curr_x]

		; wybór kierunku rysowania
		finit
		fild 	dword ptr ds:[delta]
		ftst
		call 	check_FPU_flags
		ja		d_positive				; jeśli delta > 0
		
		; jeśli delta <= 0
		fiadd	dword ptr ds:[delta_A]	; delta += delta_A
		fistp 	dword ptr ds:[delta]
		
		fild 	dword ptr ds:[delta_A]
		fiadd	dword ptr ds:[change_A]	; delta_A += change_A
		fistp 	dword ptr ds:[delta_A]
		
		fild 	dword ptr ds:[delta_B]	; delta_B += change_B_neg
		fiadd	dword ptr ds:[change_B_neg]
		fistp	dword ptr ds:[delta_B]
		jmp 	arch
		
d_positive:
		fiadd	dword ptr ds:[delta_B]		; delta += delta_A
		fistp 	dword ptr ds:[delta]
		
		fild	dword ptr ds:[delta_B]
		fiadd	dword ptr ds:[change_B_pos]	; delta_A += change_A
		fistp 	dword ptr ds:[delta_B]
		
		fild 	dword ptr ds:[delta_A]	; delta_B += change_B_neg
		fiadd	dword ptr ds:[change_A]
		fistp	dword ptr ds:[delta_A]
		; sprawdzenie czy y == 0 ( jeśli tak to już nie zmniejszamy
		cmp		byte ptr ds:[curr_y],0
		je 		arch
		dec 	word ptr ds:[curr_y]
		
		jmp 	arch
		
arch_end:
		ret


;------------------------------------------

; funkcja kopiująca flagi FPU do flag CPU
check_FPU_flags:
		fstsw 	word ptr ds:[flags]   	
		mov 	ax, word ptr ds:[flags]	;  kopiujemy rejestr flag koprocesora do ax 
		sahf       						;  AH zapisane do flag
		ret

;------------------------------------------

; funkcja rysująca kilka punktów naraz ( ze względu na symetrię łuków elipsy są to cztery niebieskie i cztery czerwone łuki)
draw_multiple_points:
		; wywołanie funkcji przypisującej
		call 	word ptr ds:[arch_points_function]
		; I ćwiartka
		mov		word ptr ds:[y], 99
		sub 	word ptr ds:[y], di
		
		mov 	word ptr ds:[x], 160
		add		word ptr ds:[x], si
		call 	draw_point
		
		; II ćwiartka
		mov		word ptr ds:[y], 99
		sub 	word ptr ds:[y], di
		
		mov 	word ptr ds:[x], 159
		sub		word ptr ds:[x], si
		call 	draw_point
		
		; III ćwiartka
		mov		word ptr ds:[y], 100
		add 	word ptr ds:[y], di
		
		mov 	word ptr ds:[x], 159
		sub		word ptr ds:[x], si
		call 	draw_point
		
		; IV ćwiartka
		mov		word ptr ds:[y], 100
		add 	word ptr ds:[y], di
		
		mov 	word ptr ds:[x], 160
		add		word ptr ds:[x], si
		call 	draw_point
		ret

; funkcje przypisujące x i y w zależności czy rysujemy niebieski łuk czy czerwony

get_points_blue:
		mov		si,word ptr ds:[curr_x]		
		mov		di, word ptr ds:[curr_y]
		ret

get_points_red:
		mov		di,word ptr ds:[curr_x]
		mov		si, word ptr ds:[curr_y]
		ret


;---------------------------------------------

; funkcja rysująca pojedynczy punkt na ekranie 
draw_point:
		mov 	ax, word ptr ds:[y]		;<- y
		mov 	bx, 320
		mul 	bx						; dx:ax = ax*bx, wyzeruje dx
		mov 	bx, word ptr ds:[x]		;<- x
		add 	bx, ax					; bx = bx + ax
		;mov		al, byte ptr ds:[k]
		call 	word ptr ds:[color_function]
		mov 	byte ptr es:[bx], al	; zmieniamy kolor punktu 
		ret

; pobieranie koloru w zależności od odległości od środka
get_color:
		push 	bx
		; liczenie przekątnej z 
		mov 	ax, word ptr ds:[x]		
		sub 	ax, 160

		imul 	ax
		mov		bx, ax

		mov 	ax, word ptr ds:[y]	
		sub 	ax, 100

		imul 	ax
		add		ax, bx

		mov		bx, 2250
		div		bx
		add 	ax, 40
		pop		bx
		ret

; pobiera czarny kolor ( do czyszczenia )
get_black:
		mov		al, 0
		ret
		
		
;------------------------------------------
		
code1 ends





stos1 segment stack
		dw		300 dup(?)		
wstos1	dw		?			
stos1 ends



end start1			