; pomysł:
; 	1) kalkulator przyjmuje wyrażenie i zapisuje do bufora
;	2) funkcja "szukaj_słowa" znajduje pierwszy znak nie będący znakiem terminalnym (>31)
;	3) potem funkcja "find_digit" szuka wśród 0-9 cyfry wpisane
;		a) jeśli znajdzie to wrzuca na stos wartość
; 		b) w przeciwnym wypadku wysyła do zakończenia programu przez błąd
; 	4) potem funkcja "find_operator" szuka który operator został użyty
; 	5) znowu funkcja "find_digit"
;	6) jeżeli bezproblemowo minęły punkty 3)-5) to zostaje wykonane działanie
; 	7) wyprintowanie wyniku


;Struktura pamięci:
; digits 		- zapisane pokolei nazwy cyfr 0-9 oraz 10-19 słownie
; digits_ptr	- offsety poszczególnych wartości w tablicy digits (można się do nich odwoływać poprzez liczba*2 = numer indeksu
; tens 			- opisane kolejne 20, 30... 80 słownie
; tens_ptr	 	- wskaźniki na dziesiątki 


data1 segment
;					"zero jeden dwa trzy cztery piec szesc siedem osiem dziewiec "
digits 		db 		"zero$jeden$dwa$trzy$cztery$piec$szesc$siedem$osiem$dziewiec$"

;					"dziesiec jedenascie dwanascie trzynascie czternascie pietnascie szesnascie siedemnasie osiemnascie dziewietnascie "
			db 		"dziesiec$jedenascie$dwanascie$trzynascie$czternascie$pietnascie$szesnascie$siedemnasie$osiemnascie$dziewietnascie$"
digits_ptr 	dw		0h, 05h, 0Bh, 0Fh, 014h, 01Bh, 020h, 026h, 02Dh, 033h, 03Ch, 045h, 050h, 05Ah, 065h, 071h, 07Ch, 087h, 093h, 09Fh
digits_sort	dw		014h, 0Bh, 033h, 05h, 02Dh, 01Bh, 026h, 020h, 0Fh, 0h
;					"dwadziescia trzydziesci czterdziesci piecdziesiat szescdziesiat siedemdziesiat osiemdziesiat"
tens		db		"dwadziescia$trzydziesci$czterdziesci$piecdziesiat$szescdziesiat$siedemdziesiat$osiemdziesiat$"
tens_ptr 	dw		?, ?, 0, 0Ch, 018h, 025h, 032h, 040h, 04Fh

space 		db 		" $"




buff	db	32, ?, 40 dup('$')				; [ile znaków], [bajt zarezerwowany dla systemu, ile jest rzeczywiscie zajęte], prawidłowy buffor 
data1 ends






code1 segment
start1: 
; ustawienie stosu
		mov		ax, seg stack1										
		mov 	ss, ax 				
		mov 	sp, offset wstos1
; ustawienie segmentu danych 		
		mov 	ax, seg data1
		mov 	ds, ax
		
; wczytywanie wartości od użytkownika
		mov		dx, offset buff
		mov 	ah, 0ah
		int		21h

		mov		di, offset digits
		mov		si, offset buff + 2
		call	compare_strings

		
		mov 	ax, 2
		call 	print_tens
		mov		dx, offset space
		call 	print_text
		mov		ax, 9
		call 	print_digit
		


; funkcja koncząca program
stop:	
		mov		al, 0				
		mov 	ah, 4ch				
		int 	21h
;===========================================


; funkcja porównująca dwa wyrazy
; di i si posiadają wskaźniki obydwa wyrazy
; di na tablicowy, si z buffora


;zraca:
;	al = 1, ah = 0 jeśli takie same
;	al = 0 jeśli różne
;		ah = 1 jeśli buffor mniejszy niż słowo
;		ah = 2 jeśli większy
compare_strings:
		mov		al, byte ptr ds:[si]
		inc 	si
		mov		ah, byte ptr ds:[di]	
		inc 	di
		cmp 	al, 32				; jeśli buffor się skończy
		jle		end_buffor
		cmp 	ah, '$'				; jeśli słowo z tablicy się skończy
		je		end_string
		cmp		al, ah				; porównanie czy znaki są równe
		je		compare_strings
		; różne
		mov 	ax, 0
		jl		different_less
		jg		different_greater
		
different_less:
		mov 	ah, 1
		ret
		
different_greater:
		mov 	ah, 2
		ret	

end_buffor:						; trzeba sprawdzić czy słowo też się skończyło
		cmp 	ah, '$'
		je		identical
		mov 	ax, 0
		mov		ah, 1
		ret

end_string:						; jeśli doszło tutaj znaczy że słowo się skończyło przed bufforem -> buffor > słowo
		mov 	ax, 0
		mov		ah, 2


identical:						;(1 - są takie same)
		mov		ax, 1
		ret		

;--------------------------------

;funkcja przeszukująca buffor do nowej litery innej niż biały znak
find_letter:
		mov		al, byte ptr ds:[si]
		inc 	si
		cmp		al, 32
		jle		find_letter
		dec		si
		ret

;--------------------------------
; funkcja zamieniajaca slowo w cyfrę, lub sygnalizująca że nie jest to poprawne słowo
; si - wskaźnik na buffor
; wynik podany w es
parse_digit:				
		mov 	di, offset digits
		mov		bl, 0
		mov		bh, 9
loop_parse: 
		; szukanie indexu
		mov 	ax, 0
		add		al, bl
		add		al, bh
		shr	 	al, 1 		; dzielenie całkowite przez 2
		mov		es, ax		; zapis wyniku
		shl 	al, 1 		; mnożenie przez 2
		
		; ustawienie di
		push	si
		mov 	cx, offset digits_sort
		add 	cl, al
		mov		si, cx
		mov		di, word ptr ds:[si]
		pop 	si
		; porównanie stringów
		push	si						; musimy zapamiętać di i si, aby przy nieudanym porównaniu wrócić z nim na miejsce
		call	compare_strings			
		cmp		al, 1
		pop		si
		je		found		
		; jeśli nie znaleziono należy przemieścić się w odpowiednią stronę
		mov		cx, es		;odczyt zapisu
		cmp		ah, 1
		je		compare_lower
		jne		compare_higher
		
found:
		mov		ax, es
		mov		al, 1
		
compare_lower:	
		cmp		bl, cl
		je		not_found
		mov		bh, cl
		jmp		loop_parse

compare_higher:
		dec		bh
		cmp		bl, bh
		je		final_loop
		inc		bh
		mov		bl, cl
		jmp		loop_parse
final_loop:
		inc		bh
		move 	bl, bh
		jmp		loop_parse
not_found:
;--------------------------------

print_tens: ; ax - cyfra 2-8 reprezentujaca  20 - 80
		mov 	di, offset tens_ptr
		mov		dx, offset tens
		call	prep_print
		call 	print_text
		ret

; piszę cyfre słownie z ax - cyfra 0-9 (rozszerzone do 10-19)
print_digit: 
		mov 	di, offset digits_ptr
		mov		dx, offset digits
		call	prep_print
		call 	print_text
		ret
; przygotowuje wartości do wyświetlenia
; di - offset wskaźników
; dx - offset tablicy
prep_print:
		push 	bx						; zapewniamy że bx nie zostanie naruszone
		mov		bl, 2					; mnożenie przez 2 ponieważ offsety zachowywane są na 2 Bitach
		mul		bl
		add		di, ax
		add		dx,	word ptr ds:[di]
		pop		bx
		ret

print_text:		; in dx - offset tekstu - trzeba umieścić offset napisu do dx
;		mov		ax, seg code1 	; ze względu na to że zmienne są w segmencie kodu 			
;		mov		ds, ax
		mov 	ah, 9 									
		int		21h 	
	
		ret				
code1 ends





stack1 segment stack
		dw		256 dup(?)					
wstos1	dw		?

stack1 ends

end start1