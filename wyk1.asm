dane1 segment  		; maksymalny rozmiar segmentu 64kB

t1		db	1,2,3,4,5 			; definicja po jednym bajcie 1,2,3,4 i 5
t2		db 	"To jest tekst$"	; definicja stringa, kazdy znak jest na kolejnym bajcie rosnąco
								; $ na zakończenie stringa żeby wypisał tylko do końca
dane1 ends



; nazwy symboliczne to defacto offset
; w segmencie kodu muszą być zakończone z ":", w danych nie muszą być 

code1 segment
start1:					; zaznacza offset w segmencie, możemy dzięki temu odwoływać się do konkretnego miejsca ( coś jak goto )
		mov		ax, seg stos1 		; seg zwraca adres segmentu o podanej nazwie
									; nie ma operacji bezpośredniego przeniesienia danych do rejestru segmentowego, dlatego ax
		mov 	ss, ax 				; przeniesienie z ax do cs
		mov 	sp, offset wstos1	; offset zwraca nam przesuniecie na zmienna wstos1 sp - bieżace położenie wierzchołka stosu
									; w cs mam segment stosu, a w sp wierzchołek stosu
		
		mov		ax, seg t2			;wyciągamy adres segmentu t2 (dane1)
		mov		ds, ax
		mov		dx, offset t2
		mov 	ah, 9 				; parametr funkcji wykonywanej  niżej,
									; wypis teskt ds:dx
		int		21h 				; 21h wykonanie podprogramu - przerwanie programu


		mov		al, 0				; wartość zwrócona do systemu na koniec progrmau
		mov 	ah, 4ch				; funkcja koncząca program
		int 	21h
		
code1 ends





stos1 segment stack
		dw		300 dup(?)		; dlatego że musimy mieć puste miejsce dla stosu, aby nie zaczął nadpisywać segmentu kodu
								; dup - duplikuje podany element - jeśli byłoby '5' to byłyby piątki
								; 300 mówi o ilości powtórzeń
wstos1	dw		?				;definicja 'worda', czyli 2B  '0' zapełnia nam miejsce zerem, a '?' oznacze ze jest nam obojętne
stos1 ends



end start1			; zapewniamy że kompilator zacznie program od start1