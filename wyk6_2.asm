dane1 segment  		; maksymalny rozmiar segmentu 64kB

nazwa_pliku 	db 	"plik.txt", 0
wsk_p			dw 	?
buffor 			db	200 dup('$')
dane1 ends



code1 segment
start1:					 
		mov		ax, seg stos1 		
		mov 	ss, ax 				
		mov 	sp, offset wstos1	
		
		
		; open
		mov 	ax, seg nazwa_pliku
		mov 	ds, ax
		mov		dx, offset nazwa_pliku
		
		mov 	ah, 3dh				; otwórz plik ds:dx = wskaźnik nazwy pliku
		int 	21h					; otwiera plik i zwraca czy się udało
									; CF = 0 - otwarty
		mov 	word ptr ds:[wskaznik_pliku], ax 	; zapis wskaźnika pliku do pamięci

;##
		; read
		mov 	ax, seg buffor
		mov 	ds, ax
		mov		dx, offset buffor
		
		mov 	ah, 3dh				; otwórz plik ds:dx = wskaźnik nazwy pliku
		int 	21h					; otwiera plik i zwraca czy się udało
									; CF = 0 - otwarty
		mov 	word ptr ds:[wskaznik_pliku], ax 	; zapis wskaźnika pliku do pamięci
;##
		; close
		mov 	bx, word ptr ds:[wskaznik_pliku]	; bx - wsk. pliku otwartego
		mov 	ah, 3eh				
		int 	21h
		
		
		mov		al, 0				
		mov 	ah, 4ch				
		int 	21h
		
code1 ends





stos1 segment stack
		dw		300 dup(?)		; dlatego że musimy mieć puste miejsce dla stosu, aby nie zaczął nadpisywać segmentu kodu
								; dup - duplikuje podany element - jeśli byłoby '5' to byłyby piątki
								; 300 mówi o ilości powtórzeń
wstos1	dw		?				;definicja 'worda', czyli 2B  '0' zapełnia nam miejsce zerem, a '?' oznacze ze jest nam obojętne
stos1 ends



end start1			; zapewniamy że kompilator zacznie program od start1