; DOKOŃCZYĆ

dane1 segment  		


dane1 ends

code1 segment
start1:					
		mov		ax, seg stos1 		
		mov 	ss, ax 				
		mov 	sp, offset wstos1	
		
		; tryb tesktowy
;		mov	 	al, 3
;		mov		ah, 10
;		int 	10h
		; tryb graficzny
		
		mov		ax,	0b800h
		mov		es, ax
		mov		si, 10*160 + 40*2	; chcemy wyświetlić znak na 40 pozycji w 10 rzędzie

		; zapełnianie ekranu 
		mov		di, 0				
		mov 	cx, 2000			; ile razy chcemy go wpisać	
		mov		ah, 00001001b 		; właściwości elementu
		mov		al, 'o'
		
		;cld						
		rep stosw					; stos_ (b-byte, w-word, d-doubleword) - store _ w es:di
									; rep powtarza dopóki cx != 0
;Przeniesione niżej
;		mov		byte ptr es:[si], 'X'	; ustawienie X na pozycji ^
;		mov		byte ptr es:[si+1], 10001101b		
	
p1:		in		al, 60h		; odczytanie jaki ostatni był wciśnięty klawisz ( inny niż ascii normalne)
							; np . escape - 1, strzałki 75, 72,77, 80 <- SCAN CODE
		cmp		al, 1		;escape
		jz 		koniec1
		
		
		; jeśli jest to poprzedni klawisz 
		cmp		al, byte ptr cs:[k1]
		je		p1
		mov		byte ptr cs:[k1], al
		
		
		mov		byte ptr es:[si], 'o'	; ustawienie ' ' na pozycji ^
		mov		byte ptr es:[si+1], 00001001b

		cmp 	al, 75		;left
		jnz		p2
		dec 	si
		dec		si
		
		
p2:		cmp 	al, 77		;right
		jnz		p3
		inc		si
		inc		si
		
		
p3:		cmp		al, 72		;up
		jnz		p4
		sub		si, 160
		
		
p4:		cmp		al, 80		;down
		jnz		p5
		add		si, 160
		
p5:	
		mov		byte ptr es:[si], 'X'	; ustawienie X na pozycji
		mov		byte ptr es:[si+1], 00000101b
		jmp		p1
		
		; koniec programu
koniec1:
		mov		ax, 4c00h	
		int 	21h

;klucz ostatnio wciśniętego klawisza
k1		db		0



		
code1 ends






stos1 segment stack
		dw		300 dup(?)			
wstos1	dw		?				
stos1 ends



end start1	