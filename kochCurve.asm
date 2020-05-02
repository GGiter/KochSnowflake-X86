
section .text
global rotateRight

rotateRight:
	push ebp
	mov ebp,esp
	mov eax,[esp+16]
	sub eax,[esp+8]
	
	shr eax,1
	
	mov ebx,[esp+20]
	sub ebx,[esp+12]
	
	shl ebx,3
	sub ebx,[esp+20]
	add ebx,[esp+12]
	div ebx,8
	
	sub eax,ebx
	add eax,[esp+8]
	
	;push result x2 eax
	
	mov ecx,[esp+16]
	sub ecx,[esp+8]
	
	shl ecx,3
	sub ecx,[esp+16]
	add ecx,[esp+8]
	shr ecx,3
	
	mov edx,[esp+20]
	sub edx,[esp+12]
	
	shr edx,1
	
	add ecx,edx
	add ecx,[esp+12]
	
	mov edx,eax
	
	;push result y2 ecx
	pop ebp
	ret
	
	
	

