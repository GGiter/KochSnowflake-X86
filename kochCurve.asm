
section .text
global rotateRight
global rotateLeft

rotateRight:
	push ebp
	mov ebp,esp
	mov ebx,[ebp+12]
	sub ebx,[ebp+8]
	
	sar ebx,1
	
	mov eax,[ebp+20]
	sub eax,[ebp+12]
	
	sal eax,3
	sub eax,[ebp+20]
	add eax,[ebp+12]
	sar eax,3
	;let's see if this works
	sub ebx,eax
	add ebx,[ebp+8]
	
	;push result x2 ebx
	
	mov ecx,[ebp+16]
	sub ecx,[ebp+8]
	
	sal ecx,3
	sub ecx,[ebp+16]
	add ecx,[ebp+8]
	sar ecx,3
	
	mov edx,[ebp+20]
	sub edx,[ebp+12]
	
	sar edx,1
	
	add ecx,edx
	add ecx,[ebp+12]
	
	mov eax,ebx
	mov edx,ecx

	leave
	ret
	
	
rotateLeft:
	push ebp
	mov ebp,esp
	mov ebx,[ebp+12]
	sub ebx,[ebp+8]
	
	sar ebx,1
	
	mov eax,[ebp+20]
	sub eax,[ebp+12]
	
	sal eax,3
	sub eax,[ebp+20]
	add eax,[ebp+12]
	sar eax,3
	;let's see if this works
	
	;negate y2 if we are rotating left
	neg eax
	sub ebx,eax
	add ebx,[ebp+8]
	
	;push result x2 ebx
	
	mov ecx,[ebp+16]
	sub ecx,[ebp+8]
	
	sal ecx,3
	sub ecx,[ebp+16]
	add ecx,[ebp+8]
	sar ecx,3
	
	mov edx,[ebp+20]
	sub edx,[ebp+12]
	
	sar edx,1
	
	;negate x2 as we are rotating left
	neg ecx
	
	add ecx,edx
	add ecx,[ebp+12] ;x2*7/8 + y2*0,5
	
	mov eax,ebx
	mov edx,ecx

	leave
	ret
	
	
	

