struc   BRESENHAM
    .x2 resd    1
    .y2 resd    1
    .dx resd    1
    .dy resd    1
    .ai resd    1
    .bi resd    1
    .SIZE   resb    1
endstruc
section .text
global rotate
global draw_line
extern SetPixel	
rotate:
	push ebp
	mov ebp,esp
	mov ebx,[ebp+16] ;x2
	
	sar ebx,1 ;x2*0.5
	
	mov eax,[ebp+20] ;y2

	sal eax,3 ;y2*8
	sub eax,[ebp+20] ;y2-y2
	sar eax,3 ;y2/8

	;negate y2 if we are rotating left
	imul eax,[ebp+24] ;y2*(1 or -1)
	sub ebx,eax ;x2-y2
	
	;result x2 -> ebx
	
	mov ecx,[ebp+16] ;x2
	
	sal ecx,3 ;x2*8
	sub ecx,[ebp+16] ;x2-x2
	sar ecx,3 ;x2/8
	
	mov edx,[ebp+20] ;y2

	sar edx,1 ;y2*0,5
	
	;negate x2 as we are rotating left
	imul ecx,[ebp+24] ;x2*(1 or -1)
	
	add ecx,edx ;x2*7/8 + y2*0,5
	
	;result y2 -> ecx
	
	mov eax,ebx ;int x 
	mov edx,ecx ;int y

	leave
	ret
	
	



; edx - x1
; eax - y1
; ebx - x2
; ecx - y2
draw_line:

	;mov edx, [esp+8]
	;mov eax, [esp+12]
	;mov ebx, [esp+16]
	;mov ecx, [esp+20]
	;mov edx, 50
	;mov eax, 10
	;mov ebx, 60
	;mov ecx, 10
	
	mov edx, [esp+4]
	mov eax, [esp+8]
	mov ebx, [esp+12]
	mov ecx, [esp+16]

    ; keep original registers
    push    eax
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
	
	
	
	;mov edx, [esp+8]
	;mov eax, [esp+12]
	;mov ebx, [esp+16]
	;mov ecx, [esp+20]


    ; save space for variables
    sub esp,    BRESENHAM.SIZE

    ; save position of the start of the line
    mov esi,    edx
    mov edi,    eax

    ; save position for the end of the line
    mov dword [esp + BRESENHAM.x2], ebx
    mov dword [esp + BRESENHAM.y2], ecx

.check_x:	
    ; x1 > x2
    cmp esi,    dword [esp + BRESENHAM.x2]
    ja  .reverse_x

    ; axis x is increasing
   	mov dword [esp + BRESENHAM.dx], ebx ; dx =  x2
    sub dword [esp + BRESENHAM.dx], esi ; dx -= x1
    mov ebx,    1   ; xi =  1

    ; check y
    jmp .check_y

.reverse_x:
    ; axis x is decrasing
    mov dword [esp + BRESENHAM.dx], esi ; dx =  x1
    sub dword [esp + BRESENHAM.dx], ebx ; dx -= x2
    mov ebx,    -1  ; xi =  -1

.check_y:	
	; check y
    ; y1 > y2
    cmp edi,    dword [esp + BRESENHAM.y2]
    ja  .reverse_y

    ;axis y is increasing
    mov dword [esp + BRESENHAM.dy], ecx ; dy =  y2
    sub dword [esp + BRESENHAM.dy], edi ; dy -= y1
    mov ecx,    1   ; yi =  1

    ; continue
    jmp .done

.reverse_y:
    ; axis x is decreasing
    mov dword [esp + BRESENHAM.dy], edi ; dy =  y1
    sub dword [esp + BRESENHAM.dy], ecx ; dy -= y2
    mov ecx,    -1  ; yi =  -1

.done:
    ; dy > dx
    mov eax,    dword [esp + BRESENHAM.dy]
    cmp eax,    dword [esp + BRESENHAM.dx]
    ja  .osY

    ; draw line in regard to axis X
    ; ai = dy
    ; d = dy
    mov edx,    eax ; d =   dy
    sub eax,    dword [esp + BRESENHAM.dx]  ; ai -= dx
    shl eax,    2
    mov dword [esp + BRESENHAM.ai], eax
    shl edx,    2 ; d *   2
    mov dword [esp + BRESENHAM.bi], edx ; bi =  dy*2
    mov eax,    dword [esp + BRESENHAM.dx]
    sub edx,    eax ; d -=  dx

.loop_x:
    ; X = ESI, Y = EDI
	push    eax
    push    ebx
    push    ecx
    push    edx
    push    edi
    push    esi
	
    call SetPixel 
	pop    esi
    pop    edi
    pop    edx
    pop    ecx
    pop    ebx
    pop    eax
	
	


    ; x1 == x2
    cmp esi,    dword [esp + BRESENHAM.x2]
	je .end
	
	

    
    ; d < 0 ?
    cmp  edx,    0
    jl  .loop_x_minus

    ; calculate position of the next pixel
    add esi,    ebx ; x +=  xi
    add edi,    ecx ; y +=  yi
    add edx,    dword [esp + BRESENHAM.ai]  ; d +=  ai
	
	
    ; draw line
    jmp .loop_x
.loop_x_minus:
    ; calculate position of the next pixel
    add edx,    dword [esp + BRESENHAM.bi]  ; d +=  bi
    add esi,    ebx ; x +=  xi

    ; draw line
    jmp .loop_x

.osY:
    ; draw line in regard to axis Y
    mov eax,    dword [esp + BRESENHAM.dx]  ; ai = dx
    mov edx,    eax ; d =   dx
    sub eax,    dword [esp + BRESENHAM.dy]  ; ai -= dy
    shl eax,    2
    mov dword [esp + BRESENHAM.ai], eax
    shl edx,    2  ; d *   2
    mov dword [esp + BRESENHAM.bi], edx ; bi =  d
    mov eax,    dword [esp + BRESENHAM.dy]
    sub edx,    eax ; d -=  dy

.loop_y:
    ; X = ESI, Y = EDI
	push    eax
    push    ebx
    push    ecx
    push    edx
    push    edi
    push    esi
	
    call SetPixel 
	pop    esi
    pop    edi
    pop    edx
    pop    ecx
    pop    ebx
    pop    eax
	
	
	
	

    ; y1 == y2
    cmp edi,    dword [esp + BRESENHAM.y2]
    je  .end
	
    ; 
    ; d < 0
    cmp  edx,    0
    jl  .loop_y_minus

    ; calculate position of the next pixel
    add esi,    ebx ; x +=  xi
    add edi,    ecx ; y +=  yi
    add edx,    dword [esp + BRESENHAM.ai]  ; d +=  ai
    ; draw line
    jmp .loop_y

.loop_y_minus:
    ; calculate position of the next pixel
    add edx,    dword [esp + BRESENHAM.bi]  ; d +=  bi
    add edi,    ecx ; y +=  yi

    ; draw line
    jmp .loop_y

.end:

	;cmp edi,    dword [esp + BRESENHAM.y2]
    ;jne  .check_x
	
	;cmp esi,    dword [esp + BRESENHAM.x2]
   ; jne  .check_x

    ; remove local variables
    add esp,    BRESENHAM.SIZE
	

    ; restore registers
    pop    edi
    pop    esi
    pop    edx
    pop    ecx
    pop    ebx
    pop    eax

    ret
	
	
	

