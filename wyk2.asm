dane1 segment  		

	
dane1 ends



code1 segment
start1:
					
		mov		ax, seg stos1 											
		mov 	ss, ax 				
		mov 	sp, offset wstos1	
		
; aby uzyskać wartości w parametrach wpisanych przy wywołaniu programu
		;PSP ds:offset 	80h -  ilość wprowadzonych argumentów
		;				81h -  spacja
		; 				82h+ - adresy 
		
		
; tworzenie pętli, argumenty wywołania programu
		
		mov 	ax, seg lin_c
		mov 	es, ax
		mov 	si, 082h 				; wrzucamy do "Source Index" adres argumentów przy odpalaniu
		mov 	di, offset lin_c	
		xor 	cx,cx 					; zerujemy cx aby wrzucić tam wartość z 80h - jedno Bajtowe do dwu (dlatego starszy trzeba wyzerować)
		mov 	cl, byte ptr ds:[080h]	; w tym momencie cx jest = ilość znaków argumentów
		
	
p1:		push 	cx 						; chronimy cx zostawiąjąc go na stosie, a po programie go odbieramy...
		mov 	al, byte ptr ds:[si]	; pobieramy kolejne znaki argumentów, si na początku 082h
		mov 	byte ptr es:[di], al
		inc 	si
		inc 	di
		pop		cx						; ...należy się tylko upewnić czy stos nie zostai jakiś śmieci
		loop 	p1						; cx = cx-1; czy cx == 0? jeśli nie: skacze do p1; jeśli 0, idzie dalej
		mov 	byte ptr es:[di], '$'	; dopisanie na końcu $


		mov 	dx, offset lin_c
		call 	wypisz
		mov		dx, offset newline
		call	wypisz


; print t1
		mov		dx, offset t1		
		call	wypisz				;wywołanie procedury
		
; kopia z wyżej, print t2
		mov		dx, offset t2		
		call	wypisz				;wywołanie procedury			
		


; wczytywanie wartości od użytkownika
		mov 	ax, seg code1
		mov 	ds, ax
		mov		dx, offset buff1
		mov 	ah, 0ah
		int		21h

		mov 	bp, offset buff1 + 1	; wskaźnik na pamięć przechowującą ile danych zapisaliśmy
		mov	 	bl, byte ptr cs:[bp]	; byte pointer, komórka którą umieścimy w bl jest z adresu wskazywanego przez połączonej wartości cs 
										;(bo buff jest w segmencie kodu) i wartości [bp] -> to znaczy ilość zapisanych elem. buffora
		add 	bl, 1					; zwiększamy ilość o jeden (bo jest znak 13 (\r) nie ma 10)
		xor 	bh, bh					;mov	 bh,0  <- wyzerowanie rejestru
		add 	bp, bx					; przesuwamy wskaźnik bp o ilość elementów w bufforze, tak aby znaleźć się na końcu
		mov 	byte ptr cs:[bp], '$'	; zapisanie na ostatniej pozycji $ zamiast \r

		mov		dx, offset newline
		call	wypisz

		mov	 	dx, offset buff1 + 2 	; ze względu na fakt że pierwsze dwa bajty są systemowe
		call 	wypisz


; konczenie programu
		mov		al, 0				
		mov 	ah, 4ch				; funkcja koncząca program
		int 	21h

;----- KONIEC WŁAŚCIWEGO PROGRAMU -------

; możemy przechowywać dane w segmencie kodu, jeżeli nie ingeruje to w kod programu
; wtedy instrukcja 	" seg t1 " zwróci segment kodu, i zostanie zapisany w ds
newline db 	10, 13, '$'
t1		db	"1111111111", 10, 13, "$"		; znak 10 to nowa nowa linia, 13 to karetka do lewej (windowsy tego potrzebują)	
t2		db 	"2222222222$"		
buff1	db	10, ?, 20 dup('$')				; [ile znaków], [bajt zarezerwowany dla systemu, ile jest rzeczywiscie zajęte], prawidłowy buffor 
lin_c	db 200 dup('$')

;deklaracja procedury (do wypisania tesktu)
wypisz:		; in dx - offset tekstu - trzeba umieścić offset napisu do dx
		mov		ax, seg code1 	; ze względu na to że zmienne są w segmencie kodu 			
		mov		ds, ax
		mov 	ah, 9 									
		int		21h 	
	
		ret			 			; powrót do miejsca gdzie zaczęła się procedura

code1 ends





stos1 segment stack
		dw		300 dup(?)		; dlatego że musimy mieć puste miejsce dla stosu, aby nie zaczął nadpisywać segmentu kodu
								; dup - duplikuje podany element - jeśli byłoby '5' to byłyby piątki
								; 300 mówi o ilości powtórzeń
wstos1	dw		?				;definicja 'worda', czyli 2B  '0' zapełnia nam miejsce zerem, a '?' oznacze ze jest nam obojętne
stos1 ends



end start1			; zapewniamy że kompilator zacznie program od start1