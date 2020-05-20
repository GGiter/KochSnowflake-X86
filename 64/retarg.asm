;=====================================================================
; ARKOC x86-64 - parameter passing test 
;=====================================================================

section	.text
global  retarg

retarg:
	ret

; kolejnosc parametrow calkowitych - rejestry: rdi, rsi, rdx, rcx, r8, r9
; kolejnosc parametrow zmiennopozycyjnych - rejestry xmm0 - xmm7
; kolejne parametry: na stosie od PRAWEJ do LEWEJ
; pierwszy parametr pod adresem [esp + 8]
; rejestr stosu (rsp) musi c wyrownany do 16 bajtow (aprzed call
; (adres powrotu natychmiast psuje to wyrownanie - push rej  lub  sub rsp, 8
; trzeba zachowac: rbp, rbx, r12, r13, r14, r15
; wartosc funkcji: rax (lub rdx:rax) albo xmm0 (lub xmm1:xmm0) 

; Rejestry 64-bitowe
; R0  R1  R2  R3  R4  R5  R6  R7  R8  R9  R10  R11  R12  R13  R14  R15
; RAX RCX RDX RBX RSP RBP RSI RDI

; Rejestry 32-bitowe (mlodsze bity rejestrow wyzej)
; R0D R1D R2D R3D R4D R5D R6D R7D R8D R9D R10D R11D R12D R13D R14D R15D
; EAX ECX EDX EBX ESP EBP ESI EDI

; Rejestry 16-bitowe (mlodsze bity rejestrow wyzej)
; R0W R1W R2W R3W R4W R5W R6W R7W R8W R9W R10W R11W R12W R13W R14W R15W
; AX  CX  DX  BX  SP  BP  SI  DI

; Rejestry 8-bitowe (mlodsze bity rejestrow wyzej)
; R0B R1B R2B R3B R4B R5B R6B R7B R8B R9B R10B R11B R12B R13B R14B R15B
; AL  CL  DL  BL  SPL BPL SIL DIL

; Rejestry 8-bitowe (brzemie historii)
; AH  CH  DH  BH

; Rejestry zmiennoprzecinkowe (128 bitowe)
; XMM0 - XMM15