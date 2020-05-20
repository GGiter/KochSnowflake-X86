struc   LINE
    .x2 resq    1
    .y2 resq    1
    .dx resq    1
    .dy resq    1
    .ai resq    1
    .bi resq    1
    .SIZE   resb    1
endstruc
section .text
global rotate
global draw_line
global put_pixel
rotate:
	sub rsp , 8
	push rbx  
	push rbp

	mov rbx,rdi ;x2
	
	sar rbx,1 ;x2*0.5
	
	mov rax,rsi ;y2

	sal rax,3 ;y2*8
	sub rax,rsi ;y2-y2
	sar rax,3 ;y2/8

	;negate y2 if we are rotating left
	imul rax,rdx ;y2*(1 or -1)
	sub rbx,rax ;x2-y2
	
	;result x2 -> ebx
	
	mov rcx,rdi ;x2
	
	sal rcx,3 ;x2*8
	sub rcx,rdi ;x2-x2
	sar rcx,3 ;x2/8
	
	mov r10,rsi ;y2

	sar r10,1 ;y2*0,5
	

	;negate x2 as we are rotating left
	imul rcx,rdx;x2*(1 or -1)

	
	add rcx,r10 ;x2*7/8 + y2*0,5
	
	;result y2 -> ecx
	
	mov rax,rbx ;int x 
	mov rdx,rcx ;int y
	
	pop rbp 
	pop rbx
	add rsp , 8 
	
	ret
	
	
; draw line algorithm based on LineTo from C file
draw_line:
	sub rsp , 8
	push rbx  
	push rbp

	push rdx
	mov rdx, rdi ;X1
	mov rax, rsi ;Y1
	pop rbx
	mov rcx, rcx ;Y2
	
    ; save space for local variables
    sub rsp,    LINE.SIZE
	 ; save position of the start of the line
    mov rsi,    rdx
    mov rdi,    rax
	
    ; save position for the end of the line
    mov qword [rsp + LINE.x2], rbx
    mov qword [rsp + LINE.y2], rcx
	


.check_x:	
    ; x1 > x2
    cmp rsi,    qword [rsp + LINE.x2]
    ja  .reverse_x

    ; axis x is increasing
   	mov qword [rsp + LINE.dx], rbx ; dx =  x2
    sub qword [rsp + LINE.dx], rsi ; dx -= x1
    mov rbx,    1   ; xi =  1

    ; check y
    jmp .check_y

.reverse_x:
    ; axis x is decreasing
    mov qword [rsp + LINE.dx], rsi ; dx =  x1
    sub qword [rsp + LINE.dx], rbx ; dx -= x2
    mov rbx,    -1  ; xi =  -1

.check_y:	
	; check y
    ; y1 > y2
    cmp rdi,    qword [rsp + LINE.y2]
    ja  .reverse_y

    ;axis y is increasing
    mov qword [rsp + LINE.dy], rcx ; dy =  y2
    sub qword [rsp + LINE.dy], rdi ; dy -= y1
    mov rcx,    1   ; yi =  1

    ; continue
    jmp .done

.reverse_y:
    ; axis x is decreasing
    mov qword [rsp + LINE.dy], rdi ; dy =  y1
    sub qword [rsp + LINE.dy], rcx ; dy -= y2
    mov rcx,    -1  ; yi =  -1

.done:
    ; dy > dx
    mov rax,    qword [rsp + LINE.dy]
    cmp rax,    qword [rsp + LINE.dx]
    ja  .osY

    ; draw line in regard to axis X
    ; ai = dy
    ; d = dy
    mov rdx,    rax ; d =   dy
    sub rax,    qword [rsp + LINE.dx]  ; ai -= dx
    shl rax,    2
    mov qword [rsp + LINE.ai], rax
    shl rdx,    2 ; d *   2
    mov qword [rsp + LINE.bi], rdx ; bi =  dy*2
    mov rax,    qword [rsp + LINE.dx]
    sub rdx,    rax ; d -=  dx

.loop_x: ; horizontal draw
    ; x = esi, y = edi
	; push values on the stack
	push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
	; used to determine which label to call next
	mov r12,0
	
	jmp .put_pixel	
					

.loop_x_end:
	; pop values from the stack
	pop    rsi
    pop    rdx
    pop    rcx
    pop    rbx
    pop    rax
	
    ; x1 == x2
    cmp rsi,    qword [rsp + LINE.x2]
	je .end
	
    ; d < 0 ?
    cmp  rdx,    0
    jl  .loop_x_minus

    ; calculate position of the next pixel
    add rsi,    rbx ; x +=  xi
    add rdi,    rcx ; y +=  yi
    add rdx,    qword [rsp + LINE.ai]  ; d +=  ai
	
	
    ; draw line
    jmp .loop_x
.loop_x_minus: ; vertical draw
    ; calculate position of the next pixel
    add rdx,    qword [rsp + LINE.bi]  ; d +=  bi
    add rsi,    rbx ; x +=  xi

    ; draw line
    jmp .loop_x

.osY:
    ; draw line in regard to axis Y
    mov rax,    qword [rsp + LINE.dx]  ; ai = dx
    mov rdx,    rax ; d =   dx
    sub rax,    qword [rsp + LINE.dy]  ; ai -= dy
    shl rax,    2
    mov qword [rsp + LINE.ai], rax
    shl rdx,    2  ; d *   2
    mov qword [rsp + LINE.bi], rdx ; bi =  d
    mov rax,    qword [rsp + LINE.dy]
    sub rdx,    rax ; d -=  dy

.loop_y:
    ; x = esi, y = edi
	; push values on the stack
	push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
	; used to determine which label to call next
	mov r12,1
	
	jmp .put_pixel
   		

.loop_y_end:						
	; pop values from the stack
	pop    rsi
    pop    rdx
    pop    rcx
    pop    rbx
    pop    rax

    ; y1 == y2
    cmp rdi,    qword [rsp + LINE.y2]
    je  .end
	
    ; d < 0
    cmp  rdx,    0
    jl  .loop_y_minus

    ; calculate position of the next pixel
    add rsi,    rbx ; x +=  xi
    add rdi,    rcx ; y +=  yi
    add rdx,    qword [rsp + LINE.ai]  ; d +=  ai
    ; draw line
    jmp .loop_y

.loop_y_minus:
    ; calculate position of the next pixel
    add rdx,    qword [rsp + LINE.bi]  ; d +=  bi
    add rdi,    rcx ; y +=  yi

    ; draw line
    jmp .loop_y

.end:
    ; remove local variables
    add rsp,    LINE.SIZE
	
	pop rbp 
	pop rbx
	add rsp , 8 
	
    ret
	
	
.put_pixel:	
	mov  rbx, qword [r9]  ;address of bitmap
	mov rax ,r8 ; image width
	; calculate position
	add rax,31 ; + 31
	sar rax,5 ; >> 5
	sal rax,2 ; << 2
	
	mov rcx , rdi ; y
	mul rcx ; *y
	add rbx, rax
	
	mov rax , rsi ; x
	shr rax, 3 ; x >> 3
	
	add rbx, rax
	; current position done
	
	mov  rdx, qword [rbx]    ;load value at address
	
	; caulculate mask
	mov rax,0x80
	mov  cl, sil ; x
	and cl , 0x07
	sar rax, cl
	not rax
	and  rdx , rax
	
	mov  qword [rbx], rdx    ; writeback updated pixel value	
	
	; determine which label to call next
	mov rax, 1
	cmp rax,r12
	
	je .loop_y_end
	
	jmp .loop_x_end
	
	
	
	

