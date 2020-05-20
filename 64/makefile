CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o retarg.o -f elf64 retarg.asm
cc :
	$(CC) -c -g -O0 retarg_test.c
link :
	$(CC) -o retarg_test retarg_test.o retarg.o
clean :
	rm *.o
	rm retarg_test
