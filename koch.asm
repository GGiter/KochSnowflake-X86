struc   LINE
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
global put_pixel
rotate:
	push ebp
	mov ebp,esp
	mov ebx,[ebp+8] ;x2
	
	sar ebx,1 ;x2*0.5
	
	mov eax,[ebp+12] ;y2

	sal eax,3 ;y2*8
	sub eax,[ebp+12] ;y2-y2
	sar eax,3 ;y2/8

	;negate y2 if we are rotating left
	imul eax,[ebp+16] ;y2*(1 or -1)
	sub ebx,eax ;x2-y2
	
	;result x2 -> ebx
	
	mov ecx,[ebp+8] ;x2
	
	sal ecx,3 ;x2*8
	sub ecx,[ebp+8] ;x2-x2
	sar ecx,3 ;x2/8
	
	mov edx,[ebp+12] ;y2

	sar edx,1 ;y2*0,5
	
	;negate x2 as we are rotating left
	imul ecx,[ebp+16] ;x2*(1 or -1)
	
	add ecx,edx ;x2*7/8 + y2*0,5
	
	;result y2 -> ecx
	
	mov eax,ebx ;int x 
	mov edx,ecx ;int y
	
	pop ebp
	ret
	
	
; draw line algorithm based on LineTo from C file
draw_line:
	mov edx, [esp+4] ;X1
	mov eax, [esp+8] ;Y1
	mov ebx, [esp+12] ;X2
	mov ecx, [esp+16] ;Y2
	
    ; save space for local variables
    sub esp,    LINE.SIZE
	 ; save position of the start of the line
    mov esi,    edx
    mov edi,    eax
	
    ; save position for the end of the line
    mov dword [esp + LINE.x2], ebx
    mov dword [esp + LINE.y2], ecx

.check_x:	
    ; x1 > x2
    cmp esi,    dword [esp + LINE.x2]
    ja  .reverse_x

    ; axis x is increasing
   	mov dword [esp + LINE.dx], ebx ; dx =  x2
    sub dword [esp + LINE.dx], esi ; dx -= x1
    mov ebx,    1   ; xi =  1

    ; check y
    jmp .check_y

.reverse_x:
    ; axis x is decreasing
    mov dword [esp + LINE.dx], esi ; dx =  x1
    sub dword [esp + LINE.dx], ebx ; dx -= x2
    mov ebx,    -1  ; xi =  -1

.check_y:	
	; check y
    ; y1 > y2
    cmp edi,    dword [esp + LINE.y2]
    ja  .reverse_y

    ;axis y is increasing
    mov dword [esp + LINE.dy], ecx ; dy =  y2
    sub dword [esp + LINE.dy], edi ; dy -= y1
    mov ecx,    1   ; yi =  1

    ; continue
    jmp .done

.reverse_y:
    ; axis x is decreasing
    mov dword [esp + LINE.dy], edi ; dy =  y1
    sub dword [esp + LINE.dy], ecx ; dy -= y2
    mov ecx,    -1  ; yi =  -1

.done:
    ; dy > dx
    mov eax,    dword [esp + LINE.dy]
    cmp eax,    dword [esp + LINE.dx]
    ja  .osY

    ; draw line in regard to axis X
    ; ai = dy
    ; d = dy
    mov edx,    eax ; d =   dy
    sub eax,    dword [esp + LINE.dx]  ; ai -= dx
    shl eax,    2
    mov dword [esp + LINE.ai], eax
    shl edx,    2 ; d *   2
    mov dword [esp + LINE.bi], edx ; bi =  dy*2
    mov eax,    dword [esp + LINE.dx]
    sub edx,    eax ; d -=  dx

.loop_x: ; horizontal draw
    ; x = esi, y = edi
	; push values on the stack
	push    eax
    push    ebx
    push    ecx
    push    edx
    push    esi
	; used to determine which label to call next
	mov esi,0
	
	jmp .put_pixel	
					

.loop_x_end:
	; pop values from the stack
	pop    esi
    pop    edx
    pop    ecx
    pop    ebx
    pop    eax
	
    ; x1 == x2
    cmp esi,    dword [esp + LINE.x2]
	je .end
	
    ; d < 0 ?
    cmp  edx,    0
    jl  .loop_x_minus

    ; calculate position of the next pixel
    add esi,    ebx ; x +=  xi
    add edi,    ecx ; y +=  yi
    add edx,    dword [esp + LINE.ai]  ; d +=  ai
	
	
    ; draw line
    jmp .loop_x
.loop_x_minus: ; vertical draw
    ; calculate position of the next pixel
    add edx,    dword [esp + LINE.bi]  ; d +=  bi
    add esi,    ebx ; x +=  xi

    ; draw line
    jmp .loop_x

.osY:
    ; draw line in regard to axis Y
    mov eax,    dword [esp + LINE.dx]  ; ai = dx
    mov edx,    eax ; d =   dx
    sub eax,    dword [esp + LINE.dy]  ; ai -= dy
    shl eax,    2
    mov dword [esp + LINE.ai], eax
    shl edx,    2  ; d *   2
    mov dword [esp + LINE.bi], edx ; bi =  d
    mov eax,    dword [esp + LINE.dy]
    sub edx,    eax ; d -=  dy

.loop_y:
    ; x = esi, y = edi
	; push values on the stack
	push    eax
    push    ebx
    push    ecx
    push    edx
    push    esi
	; used to determine which label to call next
	mov esi,1
	
	jmp .put_pixel
   		

.loop_y_end:						
	; pop values from the stack
	pop    esi
    pop    edx
    pop    ecx
    pop    ebx
    pop    eax

    ; y1 == y2
    cmp edi,    dword [esp + LINE.y2]
    je  .end
	
    ; d < 0
    cmp  edx,    0
    jl  .loop_y_minus

    ; calculate position of the next pixel
    add esi,    ebx ; x +=  xi
    add edi,    ecx ; y +=  yi
    add edx,    dword [esp + LINE.ai]  ; d +=  ai
    ; draw line
    jmp .loop_y

.loop_y_minus:
    ; calculate position of the next pixel
    add edx,    dword [esp + LINE.bi]  ; d +=  bi
    add edi,    ecx ; y +=  yi

    ; draw line
    jmp .loop_y

.end:
    ; remove local variables
    add esp,    LINE.SIZE
    ret
	
	
.put_pixel:	
	mov  ebx, DWORD [esp+24 + LINE.SIZE + 20]  ;address of bitmap
	mov eax ,[esp+20 + LINE.SIZE + 20] ; image width
	; calculate position
	add eax,31 ; + 31
	sar eax,5 ; >> 5
	sal eax,2 ; << 2
	
	mov ecx , edi ; y
	mul ecx ; *y
	add ebx, eax
	
	mov eax , [esp] ; x
	shr eax, 3 ; x >> 3
	
	add ebx, eax
	; current position done
	
	mov  edx, DWORD [ebx]    ;load value at address
	
	; caulculate mask
	mov eax,0x80
	mov  cl, [esp] ; x
	and cl , 0x07
	sar eax, cl
	not eax
	and  edx , eax
	
	mov  DWORD [ebx], edx    ; writeback updated pixel value	
	
	; determine which label to call next
	mov eax, 1
	cmp eax,esi
	
	je .loop_y_end
	
	jmp .loop_x_end
	
	
	
	

