dane1 segment  		
; traktujemy te wartości jako zmienne własne funkcji zapal_punkt (podejście obiektowe, oczywiście możemy dalej się do nich dostać kiedy chcemy)
x 		dw 		?		; współrzędna x
y 		dw 		?		; współrzędna y
k		db 		?		; kolor

a 		dw 		? 		; długość linii
dane1 ends

; w trybie graficznym punkty są traktowane jak I ćwiartka układu współrzędnych obróconych pionowo
; x,y (0,0) w lewym górnym, rosnąco x w prawo, y w dół

; pamięć graficzna znajduje się pod adresem segmentowym A000 (A000 0 jeśli liczyć offset)
; wszystkie liczby w ASM muszą się zaczynać od cyfry

; segment pamięci graficznej ma 64kB, dlatego dla większych rozdzielczości niż 320x200
; należy wprowadzać usprawnienia rozdzielające pamięć karty graficznej na mniejsze części

; A000 : 0 - pierwszy punkt ekranu
; A000 : 319 - ostatni punkt pierwszego rzędu
; A000 : 320 - pierwszy punkt drugiego rzędu
; A000 : y*320 + x

code1 segment
start1:				
		mov		ax, seg stos1 		
		mov 	ss, ax 				
		mov 	sp, offset wstos1	
		
		
		mov		al, 13h					; numer trybu który chcemy włączyć ( 3 - tekstowy, 12h - 640x480 16kol ( osobny segment na kolory),
										; 13 - graficzny 320x200 256 kolorów) więcej w standardzie FGA
		mov 	ah, 0					; zmien tryb graficzny, na podany w al 
		int 	10h						; używanie przez BIOS do obsługi trybu graficznego
		
		; rozpoczęcie rysowania
										; używając dodatkowych miejsc w pamięci możemy w łatwy sposób przekazywać wartości do funkcji

		mov 	word ptr ds:[y], 50		; teraz do y
		mov 	word ptr ds:[a], 256
		
		mov 	cx, 100
p0:		push 	cx
		mov 	word ptr ds:[x], 0	 	; wpisanie do x wartości
		mov		cx, 255
		call 	linia
		pop 	cx
		inc 	word ptr ds:[y]
		loop	p0
		
		
		
		xor 	ax, ax
		int 	16h						; czekaj na dowolny klawisz
		
		; kończenie
		mov 	al, 3h
		mov 	ah, 0
		int 	10h
		
		mov 	ax, 4c00h				; funkcja koncząca program
		int 	21h


;------------------------------------------
zapal_punkt:
		mov 	ax, 0A000h				; początkowy adres segmentu graficznego
		mov 	es, ax
		mov 	ax, word ptr ds:[y]		;<- y
		mov 	bx, 320
		mul 	bx						; dx:ax = ax*bx, wyzeruje dx, gdyż mul jest uniwersalną funkcją i nie wie że 
										; że liczby podane mieszczą się na 16 bitach
		mov 	bx, word ptr ds:[x]		;<- x
		add 	bx, ax					; bx = bx + ax
										; zmieniamy kolejność, ze względu na fakt że ax nie może zostać użyty jako rejestr
										; adresowy do pamięci
		mov		al, byte ptr ds:[k]
		mov 	byte ptr es:[bx], al	; zmieniamy kolor punktu 
		ret

;------------------------------------------
linia:
		mov 	cx, word ptr ds:[a]		; ilość przewidzianych pętli <- długość linii
p1:		push 	cx						; początek pętli
		;dodatowa zmiana koloru
		mov 	al, byte ptr ds:[x]		; wczytujemy tylko młodszą część x
		mov		byte ptr ds:[k], al		; i uzależniamy od niej kolor linii
		;
		call	zapal_punkt				; wywołanie funkcje
		pop  	cx
		inc 	word ptr ds:[x]			; zwiększamy wartość zapisaną pod zmienną x
		loop	p1						; cx = cx-1  ; jeśli cx>0 wraca do p1
		ret
code1 ends





stos1 segment stack
		dw		300 dup(?)		
wstos1	dw		?			
stos1 ends



end start1			