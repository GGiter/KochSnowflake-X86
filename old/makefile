CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o koch.o -f elf -l koch.lst  koch.asm
cc :
	$(CC) -lm -freg-struct-return -m32 -fpack-struct -c -g -O0 kochTest.c
link :
	$(CC) -lm -freg-struct-return -m32 -o  kochTest kochTest.o koch.o
clean :
	rm *.o
	rm kochTest
	rm koch.lst