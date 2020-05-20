CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o koch.o -f elf64  koch.asm
cc :
	$(CC) -lm -freg-struct-return -fpack-struct -c -g -O0 kochTest.c
link :
	$(CC) -lm -freg-struct-return -o  kochTest kochTest.o koch.o
clean :
	rm *.o
	rm kochTest
	