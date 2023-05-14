; Opis ogólny
; 	1) kalkulator przyjmuje wyrażenie i zapisuje do bufora
;	2) znajduje pierwszy znak nie będący znakiem terminalnym (>31)
;	3) szuka wśród 0-9 cyfry wpisane
;		a) jeśli znajdzie to wrzuca na stos wartość
; 		b) w przeciwnym wypadku wysyła do zakończenia programu przez błąd
; 	4) szuka który operator został użyty
; 	5) ponownie punkt 3)
;	6) jeżeli bezproblemowo minęły punkty 3)-5) to zostaje wykonane działanie
; 	7) wyprintowanie wyniku


;Struktura pamięci:
; digits 		- zapisane pokolei nazwy cyfr 0-9 oraz 10-19 słownie
; digits_ptr	- offsety poszczególnych wartości w tablicy digits (można się do nich odwoływać poprzez liczba*2 = numer indeksu
; tens 			- opisane kolejne 20, 30... 80 słownie  
; tens_ptr	 	- wskaźniki na dziesiątki (dwa znaki bufforu z przodu aby można było się odwołać indeksem i - i*10)
; signs 		- możliwe słowa operacji matematycznych +, -, *
; signs_ptr 	- wskaźniki na słowa operacji


data1 segment
;					"zero jeden dwa trzy cztery piec szesc siedem osiem dziewiec "
digits 		db 		"zero$jeden$dwa$trzy$cztery$piec$szesc$siedem$osiem$dziewiec$"

;					"dziesiec jedenascie dwanascie trzynascie czternascie pietnascie szesnascie siedemnasie osiemnascie dziewietnascie "
			db 		"dziesiec$jedenascie$dwanascie$trzynascie$czternascie$pietnascie$szesnascie$siedemnasie$osiemnascie$dziewietnascie$"
digits_ptr 	dw		0h, 05h, 0Bh, 0Fh, 014h, 01Bh, 020h, 026h, 02Dh, 033h, 03Ch, 045h, 050h, 05Ah, 065h, 071h, 07Ch, 087h, 093h, 09Fh

;					"dwadziescia trzydziesci czterdziesci piecdziesiat szescdziesiat siedemdziesiat osiemdziesiat"
tens		db		"dwadziescia$trzydziesci$czterdziesci$piecdziesiat$szescdziesiat$siedemdziesiat$osiemdziesiat$"
tens_ptr 	dw		?, ?, 0, 0Ch, 018h, 025h, 032h, 040h, 04Fh

space 		db 		" $"

input_msg	db		"wprowadz dzialanie: $"

output_msg	db		"wynik:	$"

negative_msg db		"ujemne $"

signs		db		"plus$minus$razy$"
sings_ptr	dw		0h, 05h, 0Bh

; wiadomość przy niepoprawnym wpisaniu danych
messege_err	db		"slowo nie poprawne$"

; "poprawny enter"
new_line	db		13, 10, '$'

; hasło wyjścia
exit		db		"exit$"

; buffor na wejście od użytkownika
buff	db	64, 0, 70 dup('$')				; [ile znaków], [ile jest rzeczywiscie zajęte], prawidłowy buffor 
data1 ends






code1 segment
start1: 
; ustawienie stosu
		mov		ax, seg stack1										
		mov 	ss, ax 				

; ustawienie segmentu danych 		
		mov 	ax, seg data1
		mov 	ds, ax
		

start2:	mov 	sp, offset wstos1			; reset stosu - jeżeli wystąpił błąd trzeba powrócić ze stosem do stanu początkowego
		call	clear_buffor				; reset bufora - aby nie zostały pozostałości po poprzedniej operacji
		; wczytywanie wartości od użytkownika
		call	print_newline
		call 	print_input_msg
		mov		dx, offset buff
		mov 	ah, 0ah
		int		21h
		
		call	print_newline
		
		; wyszukanie poleceń
		mov		si, offset buff + 2			; przesuwamy na trzecią pozycje bufora - na pierwszy znak
		call	find_letter					; za każdym razem szukamy pierwszego niebiałego znaku
		
		call	parse_digit					; zamiana cyfry i zapis do cx
		push 	cx
		
		call	find_letter					
		
		call	parse_sign
		push 	cx
		
		call	find_letter					
		
		call	parse_digit					 
		
		; sprawdzenie czy nie zostało wrowadzone za dużo
		call	find_letter		
		xor		ah, ah
		mov		al, byte ptr ds:[si]
		cmp 	al, '$'
		jne		print_error
		
		; wykonanie operacji, jeżeli wprowadzona komenda była jasna
		pop 	bx
		pop		ax							; w tym miejscu powinno być przetłumaczone polecenie na [ax] [bx] [cx]
		call	operation
		
		push 	ax
		call	print_output_msg
		pop		ax
		; sprawdzenie czy wynik ujemny
		cmp		ah, 0						; jako że ograniczamy się do 81, warość ta mieści się na 8 bitach, więc jeśli starsze 8 bitów 
											; jest != 0 to oznacza że wynik jest ujemny
		jne		negative
		
neg_ret:
		; wyświetlenie wyniku
		call 	print_result
		call	print_newline
		jmp start2

; funkcja koncząca program
stop:	
		xor		al, al				
		mov 	ah, 4ch				
		int 	21h
;===========================================

; w przypadku negatywnego wyniku jest mnożony przez -1 oraz wyświetlana jest informacja o ujemnej liczbie
negative:
		mov		cx, -1
		imul	cx
		mov		cx, ax
		mov		dx, offset negative_msg
		call	print_text
		mov		ax, cx
		jmp		neg_ret

;---------------  komparator  -----------------

; funkcja porównująca dwa wyrazy
; di i si posiadają wskaźniki obydwa wyrazy
; di na tablicowy, si z buffora
;zwraca:
;	ax = 1 jeśli takie same
;	ax = 0 jeśli różne
compare_strings:
		mov		al, byte ptr ds:[si]
		inc 	si
		mov		ah, byte ptr ds:[di]	
		inc 	di
		cmp 	al, 32				; jeśli buffor się skończy
		jle		end_buffor
		cmp 	ah, '$'				; jeśli doszło tutaj znaczy że słowo się skończyło przed bufforem
		je		end_string
		cmp		al, ah				; porównanie czy znaki są równe
		je		compare_strings
		; różne
		jmp		different

end_buffor:						; trzeba sprawdzić czy słowo też się skończyło
		cmp 	ah, '$'
		je		identical
		jmp		different

end_string:						; tutaj nie trzeba tego sprawdzać, jako że takowe sprawdzenie w takiej sytuacji miałoby miejsce w 'end_buffor'
		jmp		different


identical:						;(1 - są takie same)
		xor 	ax, ax
		inc		ax				; zwróć 1
		ret		

different:
		xor		ax, ax			; zwróć 0
		ret
		
;---------------  operacje na buforze  -----------------

; funkcja czyszcząca bufor po poprzednim zapisie
clear_buffor:
		mov		dl, '$'
		mov		si, offset buff + 1
		xor		ch, ch
		mov		cl, byte ptr ds:[si]
		inc 	cl
clear_loop:
		inc		si
		mov		byte ptr ds:[si], dl
		loop    clear_loop
		mov		si, offset buff
		ret
		


;--------------------------------
;funkcja przeszukująca bufor do nowej litery innej niż biały znak
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
;zwraca cx 20 jeśli nie znajdzie, w przeciwnym wypadku cx przechowuje znalezioną cyfrę

parse_digit:
		call 	check_for_exit
		mov		ax, offset digits_ptr
		mov		es, ax
		mov		bx, 20
		mov		dx, offset digits
		call 	parse
		ret

; zamienia słowo w operator matematyczny
; si - wskaźnik na buffor
; cx :
;	0 jeśli dodawanie
;	1 jeśli odejmowanie
;	2 jeśli mnożenie
;	20 w przeciwnym wypadku
parse_sign:
		call 	check_for_exit
		mov		ax, offset sings_ptr
		mov		es, ax
		mov		bx, 6
		mov		dx, offset signs
		call 	parse
		ret
;--------------------------------

; sprawdzenie czy użytkownik podał wartość wyjścia -'exit'
check_for_exit:
		mov		ax, offset exit
		mov		di, ax
		push	si						
		call	compare_strings	
		pop 	si	
		cmp		ax, 1
		je		stop
		ret
		
;---------------  parser słów  -----------------	

; uniwersalny parser słowo - liczba/operacja. 
; należy podać:
;	si - przechowuje wskaźnik na buffor
;	es - offset na początek wskaźników
;	bx - limit pętli * 2
; 	
parse:			
		xor		cx, cx
loop_parse: 
		
		; ustawienie di
		push	si
		mov 	ax, es			; startujemy z offsetu pointerów
		add 	ax, cx			; dodajemy indeks obecnej iteracji
		mov		si, ax			; zamieniamy na wskaźnik
		mov		ax, word ptr ds:[si]		;odczytujemy wskaźnik
		add 	ax, dx			; dodajemy do niego offset tablicy
		mov		di, ax			; zamienamy na wskaźnik pamięci
		pop 	si
		; porównanie stringów
		push	si						; musimy zapamiętać si, aby przy nieudanym porównaniu wrócić z nim na miejsce
		call	compare_strings	
				
		cmp		ax, 1
		pop		ax
		je		found	
		mov		si,ax
		; jeśli nie znaleziono zwiększamy cx
		add 	cx, 2
		cmp		cx, bx
		je		not_found
		jmp		loop_parse

; jeżeli znajdziemy wprowadzony wyraz wśród cyfr		
found:
		shr		cx, 1		; dzielenie przez dwa ( z faktu iż offsety są 2 bitowe)
		ret
		
; w przeciwnym wypadku
not_found:
		mov		cx, 20
		jmp 	print_error
		
		
;---------------  funkcja wykonująca operacje matematyczną -----------------	

; przyjmuje w 
;	ax - wartość pierwszej cyfry
;	bx - operator
;	cx - wartość drugiej cyfry
operation:
		cmp		bx, 1
		jl 		addition
		jg		multiplication
		; odejmowanie
		sub		ax, cx				
		ret
		
addition:
		add		ax, cx
		ret
		
multiplication:
		mul		cx
		ret

;---------------  pochodne printów  -----------------	
; wiadomość dla urzytkownika do wpisania działania 
print_input_msg:
		mov		dx, offset input_msg
		call	print_text
		ret

; wiadomość przed wynikiem
print_output_msg:
		push 	dx
		mov		dx, offset output_msg
		call	print_text
		pop		dx
		ret

; spacja ( pomiędzy wynikami )
print_space:
		mov		dx, offset space
		call 	print_text
		ret

; znak nowej linii
print_newline:
		mov		dx, offset new_line
		call 	print_text
		ret

; informacja o źle wpisanym działaniu
print_error:
		mov		dx, offset messege_err
		call 	print_text
		call	print_newline
		jmp 	start1

; wartość wyniku działania
; argument: ax - wynik
print_result:
		cmp		ax, 19			;jeśli wartość jest <= 19 wystarczy same cyfry ( poszerzone do -naście) 
		jle		print_digit	
		mov		bx, 10
		div		bx
		mov		bx, dx			; reszta z dzielenia jest zapisywana w dx, dlatego musimy ją odzyskać przed pisaniem wyniku
		call	print_tens
		mov		ax, bx
		cmp 	ax, 0
		call	print_space
		jne		print_digit
		ret

;---------------  podstawowe printy  -----------------	
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
		mov 	ah, 9 									
		int		21h 	
		ret				
code1 ends




; definicja segmentu stosu, wraz z jego wierzchołkiem i przestrzenią na przyszłe wejścies
stack1 segment stack
		dw		256 dup(?)					
wstos1	dw		?

stack1 ends

end start1