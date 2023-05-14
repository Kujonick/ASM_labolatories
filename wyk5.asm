		.387 	; <- będziemy używać koprocesora (GPU)

code1 segment
start1:					
		mov		ax, seg stos1 		
									
		mov 	ss, ax 				
		mov 	sp, offset wstos1
		
		mov 	al, 13h 	; 320x200 256 col
		mov 	ah, 0		; zmien tryb graiczny
		int 	10h
		
		mov 	word ptr cs:[x], 0
		mov 	word ptr cs:[y], 0
		mov 	byte ptr cs:[k], 12
		
p0:	
		call 	clr_screen
		mov 	cx, 320
		
p1:		push 	cx
		call 	sinus
		call	zapal_punkt
		inc 	word ptr cs:[x]
		pop 	cx
		loop 	p1
		mov 	word ptr cs:[x], 0
ppp1:
		in		al, 60h		; odczytanie jaki ostatni był wciśnięty klawisz ( inny niż ascii normalne)
		cmp		al, 1		; np . escape - 1, strzałki 75, 72,77, 80 <- SCAN CODE
		jz 		koniec1
		
		; jeśli jest to poprzedni klawisz 
		cmp		al, byte ptr cs:[k1]
		je		ppp1
		mov		byte ptr cs:[k1], al

		cmp 	al, 75		;left
		jnz		p2
		dec 	word ptr cs:[dziel] ; zmniejsz dzielnik
		
p2:		cmp 	al, 77		;right
		jnz		p3
		inc 	word ptr cs:[dziel] ; zwiększ dzielnik
		
p3:		cmp		al, 72		;up
		jnz		p4
		dec 	word ptr cs:[amp]
		
		
p4:		cmp		al, 80		;down
		jnz		p5
		inc 	word ptr cs:[amp]
		
p5:	
		jmp		p0


koniec1:
		; tryb tesktowy
		mov	 	al, 3
		mov		ah, 0
		int 	10h
		; koniec programu
		mov		al, 0				
		mov 	ah, 4ch				
		int 	21h

;--------------------

dziel 	dw 		10
amp 	dw 		10

sinus:
;		mov 	ax, word ptr cs:[x]
;		mov 	bx, 10
;		cmp 	ax, 40
;		jc		d1
;		mov 	bx, 50
;d1:
;		mov		word ptr cs:[y], bx

		finit
		fild 	word ptr cs:[x]		; wrzuć na stos x
		fild 	word ptr cs:[dziel]	; wrzuć na stos dzienik
		fdiv						; podziel na stosie R1 przez R0
		fsin
		fld1 						; zaladuj na stos 1
		fadd						; dodaj R1 i R0
		fild 	word ptr cs:[amp]
		fmul
		fist 	word ptr cs:[y]
		ret
		
; może być zastąpione przez:	
;		finit
;		fild 	word ptr cs:[x]		; wrzuć na stos x
;		fidiv 	word ptr cs:[dziel]	; i obok f oznacza 'float integer' <- operacja na przecinku i całkowitej
;		fsin
;		fiadd 	word ptr cs:[jeden]	
;		fmul 	word ptr cs:[amp]
;		fist 	word ptr cs:[y]
;		ret	
		
;--------------------
clr_screen:
		mov		ax, 0a000h
		mov 	es, ax
		xor 	ax, ax
		mov 	di, ax
		cld 			; di = di+1
		mov		cx, 320*200
		rep stosb		; byte ptr es:[di], al   ; di= di+1 ; dopóki cs!=0
		; załatwia na m całe
		ret
;--------------------
x		dw 		?
y		dw 		?
k		dw 		?
k1		dw 		?

;--------------------
zapal_punkt:
		mov		ax, 0a000h	; ustawienie es na ekran
		mov 	es, ax
		mov 	ax, word ptr cs:[y]
		mov 	bx, 320
		mul 	bx 	
		mov 	bx, word ptr cs:[x]
		add 	bx, ax				; bx = 320*y + x
		mov 	al, byte ptr cs:[k]
		mov 	byte ptr es:[bx], al
		ret
code1 ends






stos1 segment stack
		dw		300 dup(?)			
wstos1	dw		?				
stos1 ends



end start1	
; dyrektywy:
; org - od którego miejsca ma się znajdować po starcie programu

;code segment
;	ORG 	100h
;-----------
; assume - nie używać za często, piszemy że dany segment będzie posiadał podane segmenty w zmiennych


;-----------
; equ - jak define w C, podstawia 
; TRZY 		EQU 3 <- zostanie podmienione każde wystąpienie


;-----------
; = <- podobnie jak equ, ale pozwala na zmianę 

;LICZ = 10  - od tego momentu LICZ jest 10
;...
;LICZ = LICZ -1 	- w tym momencie zmienia na 9


;-----------
; end


;-----------
; include - pozwala na dołączenie pliku asemmblera 
; INCLUDE moje_proc.asm <- w tym miejscu podmienione zostaje pod procedury z pliku


;-----------
; db, dw, dd, dq, dt
; define - byte, word, double, quad, ...


;-----------
; służą do pisania podprogramów
; proc
; endp
; typy - NEAR lub FAR <- wywoływana jest/nie jest w segmencie wywoływania
; w bliskiej na stos jest jedynie offset wysyłany, a w dalekiej segment i offset
;nazwa PROC typ
;	...
;	ret
;nazwa 	ENDP

;-----------

;9Bh - fwait for FPU
;FPU - operuje na 80 bitowych rejestrach, ma zestaw 8 rejestrów
;budowa rejestru:
;znak, cecha, mantysa

; notacja polska jest stosowana
;a+b -> ab+
;(a+b)c -> ab+c*

; 
; fld word ptr ds:[10] <- load floating point values - pobiera do FPU wartość
; fist word ptr es[zm1] <- w locie zostanie zmienione na integera
; fistp <- pobiera z FPU i usuwa ze stosu
; fldr <- ......................
