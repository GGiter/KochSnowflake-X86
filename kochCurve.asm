
section .text
global rotate
global draw_line
extern SetPixel	
rotate:
	push ebp
	mov ebp,esp
	mov ebx,[ebp+16] ;x2
	sub ebx,[ebp+8] ;x2-x1
	
	sar ebx,1 ;x2*0.5
	
	mov eax,[ebp+20] ;y2
	sub eax,[ebp+12] ;y2-y1
	
	sal eax,3 ;y2*8
	sub eax,[ebp+20] ;y2-y2
	add eax,[ebp+12] ;y2+y1
	sar eax,3 ;y2/8
	;mov edx,0
	;mov ecx,8
	;idiv ecx
	;let's see if this works
	
	;negate y2 if we are rotating left
	imul eax,[ebp+24] ;y2*(1 or -1)
	sub ebx,eax ;x2-y2
	add ebx,[ebp+8] ;x2+x1
	
	;result x2 -> ebx
	
	mov ecx,[ebp+16] ;x2
	sub ecx,[ebp+8] ;x2 - x1
	
	sal ecx,3 ;x2*8
	sub ecx,[ebp+16] ;x2-x2
	add ecx,[ebp+8]; x2+x1
	sar ecx,3 ;x2/8
	
	mov edx,[ebp+20] ;y2
	sub edx,[ebp+12] ;y2-y1
	
	sar edx,1 ;y2*0,5
	
	;negate x2 as we are rotating left
	imul ecx,[ebp+24] ;x2*(1 or -1)
	
	add ecx,edx ;x2*7/8 + y2*0,5
	add ecx,[ebp+12] ;y2+y1
	
	;result y2 -> ecx
	
	mov eax,ebx ;int x 
	mov edx,ecx ;int y

	leave
	ret
	
	
struc   BRESENHAM
    .x2 resd    1
    .y2 resd    1
    .dx resd    1
    .dy resd    1
    .ai resd    1
    .bi resd    1
    .SIZE   resb    1
endstruc


; edx - x1
; eax - y1
; ebx - x2
; ecx - y2
draw_line:
    ; zachowaj oryginalne rejestry
    push    ax
    push    bx
    push    cx
    push    dx
    push    si
    push    di

    ; przygotuj miejsce pod zmienne
    sub esp,    BRESENHAM.SIZE

    ; zachowaj pozycje początku linii
    mov esi,    edx
    mov edi,    eax

    ; zachowaj pozycje końca linii
    mov dword [esp + BRESENHAM.x2], ebx
    mov dword [esp + BRESENHAM.y2], ecx

    ; sprawdź oś x
    ; x1 > x2
    cmp esi,    dword [esp + BRESENHAM.x2]
    ja  .reverse_x

    ; kierunek osi x rosnąco
    mov dword [esp + BRESENHAM.dx], ebx ; dx =  x2
    sub dword [esp + BRESENHAM.dx], esi ; dx -= x1
    mov ebx,    1   ; xi =  1

    ; sprawdź oś y
    jmp .check_y

.reverse_x:
    ; kierunek osi x malejąco
    mov dword [esp + BRESENHAM.dx], esi ; dx =  x1
    sub dword [esp + BRESENHAM.dx], ebx ; dx -= x2
    mov ebx,    -1  ; xi =  -1

.check_y:
    ; sprawdź oś y
    ; y1 > y2
    cmp edi,    dword [esp + BRESENHAM.y2]
    ja  .reverse_y

    ; kierunek osi y rosnąco
    mov dword [esp + BRESENHAM.dy], ecx ; dy =  y2
    sub dword [esp + BRESENHAM.dy], edi ; dy -= y1
    mov ecx,    1   ; yi =  1

    ; kontynuuj
    jmp .done

.reverse_y:
    ; kierunek osi y malejąco
    mov dword [esp + BRESENHAM.dy], edi ; dy =  y1
    sub dword [esp + BRESENHAM.dy], ecx ; dy -= y2
    mov ecx,    -1  ; yi =  -1

.done:
    ; względem której osi rysować linię?
    ; dy > dx
    mov eax,    dword [esp + BRESENHAM.dy]
    cmp eax,    dword [esp + BRESENHAM.dx]
    ja  .osY

    ; rysuj linię względem osi X
    ; ai = dy
    ; d = dy
    mov edx,    eax ; d =   dy
    sub eax,    dword [esp + BRESENHAM.dx]  ; ai -= dx
    shl eax,    VARIABLE_MULTIPLE_BY_2
    mov dword [esp + BRESENHAM.ai], eax
    shl edx,    VARIABLE_MULTIPLE_BY_2  ; d *   2
    mov dword [esp + BRESENHAM.bi], edx ; bi =  d
    mov eax,    dword [esp + BRESENHAM.dx]
    sub edx,    eax ; d -=  dx

.loop_x:
    ; wyświetl piksel o zdefiniowanym kolorze
    ; ZAMIEŃ NA WŁASNĄ PROCEDURĘ WYŚWIETLANIA PIKSELI
    ; X = ESI, Y = EDI
    push EDI
	push ESI
    call SETPIXEL 
	add esp,8

    ; jeśli wyświetlony piksel znajduje się w punkcie końca linii, koniec
    ; x1 == x2
    cmp esi,    dword [esp + BRESENHAM.x2]
    je  .end

    ; współczynnik ujemny?
    ; d
    bt  edx,    VARIABLE_DWORD_SIGN
    jc  .loop_x_minus

    ; oblicz pozycję następnego piksela w linii
    add esi,    ebx ; x +=  xi
    add edi,    ecx ; y +=  yi
    add edx,    dword [esp + BRESENHAM.ai]  ; d +=  ai

    ; rysuj linię
    jmp .loop_x

.loop_x_minus:
    ; oblicz pozycję następnego piksela w linii
    add edx,    dword [esp + BRESENHAM.bi]  ; d +=  bi
    add esi,    ebx ; x +=  xi

    ; rysuj linię
    jmp .loop_x

.osY:
    ; rysuj linię względem osi Y
    mov eax,    dword [esp + BRESENHAM.dx]  ; ai = dx
    mov edx,    eax ; d =   dx
    sub eax,    dword [esp + BRESENHAM.dy]  ; ai -= dy
    shl eax,    VARIABLE_MULTIPLE_BY_2
    mov dword [esp + BRESENHAM.ai], eax
    shl edx,    VARIABLE_MULTIPLE_BY_2  ; d *   2
    mov dword [esp + BRESENHAM.bi], edx ; bi =  d
    mov eax,    dword [esp + BRESENHAM.dy]
    sub edx,    eax ; d -=  dy

.loop_y:
    ; wyświetl piksel o zdefiniowanym kolorze
    ; ZAMIEŃ NA WŁASNĄ PROCEDURĘ WYŚWIETLANIA PIKSELI
    ; X = ESI, Y = EDI
	push EDI
	push ESI
    call SETPIXEL 
	add esp,8

    ; jeśli wyświetlony piksel znajduje się w punkcie końca linii, koniec
    ; y1 == y2
    cmp edi,    dword [esp + BRESENHAM.y2]
    je  .end

    ; współczynnik ujemny?
    ; d
    bt  edx,    VARIABLE_DWORD_SIGN
    jc  .loop_y_minus

    ; oblicz pozycję następnego piksela w linii
    add esi,    ebx ; x +=  xi
    add edi,    ecx ; y +=  yi
    add edx,    dword [esp + BRESENHAM.ai]  ; d +=  ai

    ; rysuj linię
    jmp .loop_y

.loop_y_minus:
    ; oblicz pozycję następnego piksela w linii
    add edx,    dword [esp + BRESENHAM.bi]  ; d +=  bi
    add edi,    ecx ; y +=  yi

    ; rysuj linię
    jmp .loop_y

.end:
    ; usuń zmienne lokalne
    add esp,    BRESENHAM.SIZE

    ; przywróć oryginalne rejestry
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ; powrót z procedury
    ret
	
	
	

